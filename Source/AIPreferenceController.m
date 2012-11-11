/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIPreferenceController.h"

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContactObserverManager.h>
#import <Adium/AILoginControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>

#import "AIPreferenceWindowController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListObject.h>
#import "AIPreferenceContainer.h"
#import "AIPreferencePane.h"


#define TITLE_OPEN_PREFERENCES	AILocalizedString(@"Open Preferences",nil)

#define LOADED_OBJECT_PREFS_KEY @"Loaded individual object & account prefs"
#define PREFS_GROUP				@"Preferences"

@interface AIPreferenceController ()
- (AIPreferenceContainer *)preferenceContainerForGroup:(NSString *)group object:(AIListObject *)object create:(BOOL)create;
- (void)upgradeToSingleObjectPrefsDictIfNeeded;
@end

/*!
 * @class AIPreferenceController
 * @brief Preference Controller
 *
 * Handles loading and saving preferences, default preferences, and preference changed notifications
 */
@implementation AIPreferenceController

/*!
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init])) {
		//
		paneArray = [[NSMutableArray alloc] init];
		advancedPaneArray = [[NSMutableArray alloc] init];

		prefCache = [[NSMutableDictionary alloc] init];
		objectPrefCache = [[NSMutableDictionary alloc] init];
		
		observers = [[NSMutableDictionary alloc] init];
		delayedNotificationGroups = [[NSMutableSet alloc] init];
		preferenceChangeDelays = 0;
	}
	
	return self;
}

/*!
 * @brief Finish initialization
 */
- (void)controllerDidLoad
{
	[self upgradeToSingleObjectPrefsDictIfNeeded];
}

/*!
 * @brief Upgrade to a single, monolithic prefs dictionary for all objects
 *
 * Adium 1.2 and below used a separate plist file on disk for each object. This is a nice memory optimization but a nasty performance hit.
 * This code moves all those plists into a single file when first run and is a no-op after that.
 */
- (void)upgradeToSingleObjectPrefsDictIfNeeded
{
	if (![[self preferenceForKey:LOADED_OBJECT_PREFS_KEY group:PREF_GROUP_GENERAL] boolValue]) {
		NSString	*userDirectory = [adium.loginController userDirectory];
		NSMutableDictionary *prefsDict;
		NSString *dir;
		
		dir = [userDirectory stringByAppendingPathComponent:OBJECT_PREFS_PATH];
		prefsDict = [NSMutableDictionary dictionary];		
		for (NSString *file in [[NSFileManager defaultManager] enumeratorAtPath:dir]) {
			NSString *name = [file stringByDeletingPathExtension];
			NSMutableDictionary *thisDict = [NSMutableDictionary dictionaryAtPath:dir
																		 withName:name
																		   create:NO];
			if ([thisDict count]) {
				[thisDict removeObjectForKey:@"Message Context"];

				//This was previously written out for every single contact. It's only needed for the exceptions
				[thisDict removeObjectForKey:@"Last Used Spelling Languge"];
				//This was previously written out for every single contact. It's only needed for the exceptions
				[thisDict removeObjectForKey:@"Base Writing Direction"];

				[prefsDict setObject:thisDict
							  forKey:name];
			}
		}

		[prefsDict asyncWriteToPath:userDirectory
					  withName:@"ByObjectPrefs"];

		dir = [userDirectory stringByAppendingPathComponent:ACCOUNT_PREFS_PATH];
		prefsDict = [NSMutableDictionary dictionary];		
		for (NSString *file in [[NSFileManager defaultManager] enumeratorAtPath:dir]) {
			NSString *name = [file stringByDeletingPathExtension];
			NSDictionary *thisDict = [NSDictionary dictionaryAtPath:dir
														   withName:name
															 create:NO];
			if ([thisDict count]) {
				[prefsDict setObject:thisDict
							  forKey:name];
			}
		}

		[prefsDict asyncWriteToPath:userDirectory
					  withName:@"AccountPrefs"];

		[self setPreference:[NSNumber numberWithBool:YES]
					 forKey:LOADED_OBJECT_PREFS_KEY group:PREF_GROUP_GENERAL];
	}
}

/*!
 * @brief Close
 */
- (void)controllerWillClose
{
	[AIPreferenceContainer preferenceControllerWillClose];
}

//Preference Window ----------------------------------------------------------------------------------------------------
#pragma mark Preference Window
/*!
 * @brief Show the preference window
 */
- (IBAction)showPreferenceWindow:(id)sender
{
	[AIPreferenceWindowController openPreferenceWindow];
}

- (IBAction)closePreferenceWindow:(id)sender
{
	[AIPreferenceWindowController closePreferenceWindow];
}

/*!
 * @brief Show a specific category of the preference window
 *
 * Opens the preference window if necessary
 *
 * @param category The category to show
 */
- (void)openPreferencesToCategoryWithIdentifier:(NSString *)identifier
{
	[AIPreferenceWindowController openPreferenceWindowToCategoryWithIdentifier:identifier];
}

/*!
 * @brief Add a view to the preferences
 */
- (void)addPreferencePane:(AIPreferencePane *)inPane
{
    [paneArray addObject:inPane];
}

/*!
 * @brief Add a view to the preferences
 */
- (void)removePreferencePane:(AIPreferencePane *)inPane
{
    [paneArray removeObject:inPane];
}

/*!
 * @brief Returns all currently available preference panes
 */
- (NSArray *)paneArray
{
    return paneArray;
}

- (NSArray *)paneArrayForCategory:(AIPreferenceCategory)paneCategory
{
	return [paneArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		return ([evaluatedObject category] == paneCategory);
	}]];
}

//Observing ------------------------------------------------------------------------------------------------------------
#pragma mark Observing
/*!
 * @brief Register a preference observer
 *
 * The preference observer will be notified when preferences in group change and passed the preference dictionary for that group
 * The observer must implement:
 *		- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
 *
 */
- (void)registerPreferenceObserver:(id)observer forGroup:(NSString *)group
{
	NSMutableArray	*groupObservers;
	
	NSParameterAssert([observer respondsToSelector:@selector(preferencesChangedForGroup:key:object:preferenceDict:firstTime:)]);
	
	//Fetch the observers for this group
	if (!(groupObservers = [observers objectForKey:group])) {
		groupObservers = [[NSMutableArray alloc] init];
		[observers setObject:groupObservers forKey:group];
	}

	//Add our new observer
	[groupObservers addObject:[NSValue valueWithNonretainedObject:observer]];

	//Blanket change notification for initialization
	[observer preferencesChangedForGroup:group
									 key:nil
								  object:nil
						  preferenceDict:[[self preferenceContainerForGroup:group object:nil create:NO] dictionary] ?: [NSDictionary dictionary]
							   firstTime:YES];
}

/*!
 * @brief Unregister a preference observer
 */
- (void)unregisterPreferenceObserver:(id)observer
{
	NSValue			*observerValue = [NSValue valueWithNonretainedObject:observer];
	[observers enumerateKeysAndObjectsUsingBlock:^(id key, id observerArray, BOOL *stop) {
		[observerArray removeObject:observerValue];
	}];
}

/*!
 * @brief Broadcast a key changed notification.  
 *
 * Broadcasts a group changed notification if key is nil.
 *
 * If notifications are delayed, remember the group that changed and broadcast this notification when the delay is
 * lifted instead of immediately. Currently, our delayed notification system isn't setup to handle object-specific 
 * preferences, so always notify if there is an object present for now.
 *
 * @param key The key
 * @param group The group
 * @param object The object, or nil if global
 */
- (void)informObserversOfChangedKey:(NSString *)key inGroup:(NSString *)group object:(AIListObject *)object
{
	if (!object && preferenceChangeDelays > 0) {
        [delayedNotificationGroups addObject:group];
    } else {
		NSDictionary	*preferenceDict = [[self preferenceContainerForGroup:group object:object create:NO] dictionary] ?: [NSDictionary dictionary];
		for (NSValue *observerValue in [[observers objectForKey:group] copy]) {
			id observer = observerValue.nonretainedObjectValue;
			[observer preferencesChangedForGroup:group
											 key:key
										  object:object
								  preferenceDict:preferenceDict
									   firstTime:NO];
		}
    }
}

/*!
 * @brief Set if preference changed notifications should be delayed
 *
 * Changing large amounts of preferences at once causes a lot of notification overhead. This should be used like
 * [lockFocus] / [unlockFocus] around groups of preference changes to improve performance.
 */
- (void)delayPreferenceChangedNotifications:(BOOL)inDelay
{
	if (inDelay) {
		preferenceChangeDelays++;
	} else {
		preferenceChangeDelays--;
	}
	
	//If changes are no longer delayed, save and notify of all preferences modified while delayed
    if (!preferenceChangeDelays) {
		NSString        *group;
		
		[[AIContactObserverManager sharedManager] delayListObjectNotifications];

		for (group in delayedNotificationGroups) {
			[self informObserversOfChangedKey:nil inGroup:group object:nil];
		}

		[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
		
		[delayedNotificationGroups removeAllObjects];
    }
}

    
//Setting Preferences -------------------------------------------------------------------
#pragma mark Setting Preferences
/*!
 * @brief Set a global preference
 *
 * Set and save a preference at the global level.
 *
 * @param value The preference, which must be plist-encodable
 * @param key An arbitrary NSString key
 * @param group An arbitrary NSString group
 */
- (void)setPreference:(id)value forKey:(NSString *)key group:(NSString *)group{
	[self setPreference:value forKey:key group:group object:nil];
}

/*!
* @brief Set multiple preferences at once
 *
 * @param inPrefDict An NSDictionary whose keys are preference keys and objects are the preferences for those keys. All must be plist-encodable.
 * @param group An arbitrary NSString group
 */
- (void)setPreferences:(NSDictionary *)inPrefDict inGroup:(NSString *)group object:(AIListObject *)object
{
	AIPreferenceContainer	*prefContainer = [self preferenceContainerForGroup:group object:object create:YES];

	[prefContainer setPreferenceChangedNotificationsEnabled:NO];
	[prefContainer setValuesForKeysWithDictionary:inPrefDict];
	[prefContainer setPreferenceChangedNotificationsEnabled:YES];
}

/*!
 * @brief Set multiple global preferences at once
 *
 * @param inPrefDict An NSDictionary whose keys are preference keys and objects are the preferences for those keys. All must be plist-encodable.
 * @param group An arbitrary NSString group
 */
- (void)setPreferences:(NSDictionary *)inPrefDict inGroup:(NSString *)group
{
	[self setPreferences:inPrefDict inGroup:group object:nil];
}

/*!
 * @brief Set a global or object-specific preference
 *
 * Set and save a preference.  This should not be called directly from plugins or components.  To set an object-specific
 * preference, use the appropriate method on the object. To set a global preference, use setPreference:forKey:group:
 */
- (void)setPreference:(id)value
			   forKey:(NSString *)key
				group:(NSString *)group
			   object:(AIListObject *)object
{
	[[self preferenceContainerForGroup:group object:object create:YES] setValue:value forKey:key];
}


//Retrieving Preferences ----------------------------------------------------------------
#pragma mark Retrieving Preferences
/*!
 * @brief Retrieve a preference
 */
- (id)preferenceForKey:(NSString *)key group:(NSString *)group
{
	return [self preferenceForKey:key group:group objectIgnoringInheritance:nil];
}

/*!
 * @brief Retrieve an object specific preference with inheritance, ignoring defaults
 *
 * Should only be used within AIPreferenceController. See preferenceForKey:group:object: for details.
 */
- (id)_noDefaultsPreferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object
{
	return [[self preferenceContainerForGroup:group object:object create:NO] valueForKey:key ignoringDefaults:YES];
}

/*!
 * @brief Retrieve an object specific default preference with inheritance
 */
- (id)defaultPreferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object
{
	return [[self preferenceContainerForGroup:group object:object create:NO] defaultValueForKey:key];
}

/*!
 * @brief Retrieve an object specific preference with inheritance.
 *
 * Objects inherit from their containing objects, up to the global preference.  If this entire tree has no set preference,
 * defaults are searched, starting against with the object and proceeding up to the global defaults.
 */
- (id)preferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object
{
	//Don't use the defaults initially
	id result = [self _noDefaultsPreferenceForKey:key group:group object:object];
	
	//If no result, try defaults
	if (!result) result = [self defaultPreferenceForKey:key group:group object:object];
	
	return result;
}

/*!
 * @brief Retrieve an object specific preference ignoring inheritance.
 *
 * If object is nil, this returns the global preference.  Uses defaults only for the specified preference level,
 * not inherited defaults, as expected.
 */
- (id)preferenceForKey:(NSString *)key group:(NSString *)group objectIgnoringInheritance:(AIListObject *)object
{
	//We are ignoring inheritance, so we can ignore inherited defaults, too, and use the preferenceContainerForGroup:object: dict
	id result = [[self preferenceContainerForGroup:group object:object create:NO] valueForKey:key];
	
	return result;
}

/*!
 * @brief Retrieve all the preferences in a group
 *
 * @result A dictionary of preferences for the group, including default values as appropriate
 */
- (NSDictionary *)preferencesForGroup:(NSString *)group
{
    return [[self preferenceContainerForGroup:group object:nil create:NO] dictionary];
}

//Defaults -------------------------------------------------------------------------------------------------------------
#pragma mark Defaults
/*!
 * @brief Register a dictionary of defaults.
 */
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)group{
	[self registerDefaults:defaultDict forGroup:group object:nil];
}

/*!
 * @brief Register a dictionary of object-specific defaults.
 */
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)group object:(AIListObject *)object
{
	AIPreferenceContainer	*prefContainer = [self preferenceContainerForGroup:group object:object create:YES];

	[prefContainer registerDefaults:defaultDict];
	
	[self informObserversOfChangedKey:nil inGroup:group object:object];
}

#pragma mark Preference Container

/*!
 * @brief Retrieve an AIPreferenceContainer
 *
 * @param group The group
 * @param object The object, or nil for global
 */
- (AIPreferenceContainer *)preferenceContainerForGroup:(NSString *)group object:(AIListObject *)object create:(BOOL)create
{
	AIPreferenceContainer	*prefContainer;
	
	if (object) {
		NSString	*cacheKey = [object.internalObjectID stringByAppendingString:group];
		
		if ((prefContainer = [objectPrefCache objectForKey:cacheKey])) {
			//Until we access this pref container again, it will be associated with the passed group
			[prefContainer setGroup:group];

		} else {
			prefContainer = [AIPreferenceContainer preferenceContainerForGroup:group
																		object:object
                                                                        create:create];
			if (prefContainer) [objectPrefCache setObject:prefContainer forKey:cacheKey];
		}
		
	} else {
		if (!(prefContainer = [prefCache objectForKey:group])) {
			prefContainer = [AIPreferenceContainer preferenceContainerForGroup:group
																		object:object
                                                                        create:YES];
			[prefCache setObject:prefContainer forKey:group];
		}
	}
	
	return prefContainer;	
}

//Default download locaiton --------------------------------------------------------------------------------------------
#pragma mark Default download location
/*!
 * @brief Get the default download location
 *
 * This will use an Adium-specific preference if set, or the systemwide download location if not
 *
 * @result A full path to the download location
 */
- (NSString *)userPreferredDownloadFolder
{
	NSString	*userPreferredDownloadFolder;
	
	userPreferredDownloadFolder = [[self preferenceForKey:@"UserPreferredDownloadFolder"
													group:PREF_GROUP_GENERAL] stringByExpandingTildeInPath];

	NSFileManager *fm = [NSFileManager defaultManager];
	if (!userPreferredDownloadFolder) {
		userPreferredDownloadFolder = [[fm URLForDirectory:NSDownloadsDirectory
												  inDomain:NSUserDomainMask
										 appropriateForURL:nil create:YES error:nil] path];
	}

	//If the existing folder doesn't exist anymore, try to create it falling back to the desktop if that fails
	BOOL isDir = NO, created = NO;
	if (userPreferredDownloadFolder && ![fm fileExistsAtPath:userPreferredDownloadFolder isDirectory:&isDir]) {
		//Try to create the saved folder
		created = [fm createDirectoryAtPath:userPreferredDownloadFolder withIntermediateDirectories:YES attributes:nil error:nil];
	}
	if (!isDir && !created) {
		//Try the desktop
		userPreferredDownloadFolder = [[fm URLForDirectory:NSDesktopDirectory
												  inDomain:NSUserDomainMask
										 appropriateForURL:nil create:YES error:nil] path];
	}

	return userPreferredDownloadFolder;
}

/*!
 * @brief Set the location Adium should use for saving files
 *
 * @param A path to an existing folder
 */
- (void)setUserPreferredDownloadFolder:(NSString *)path
{
	[self setPreference:[path stringByAbbreviatingWithTildeInPath]
				 forKey:@"UserPreferredDownloadFolder"
				  group:PREF_GROUP_GENERAL];
}

#pragma mark KVC

static void parseKeypath(NSString *keyPath, NSString **outGroup, NSString **outKeyPath, NSString **outInternalObjectID)
{
	NSRange prefixRange = [keyPath rangeOfString:@"Group:" options:NSLiteralSearch | NSAnchoredSearch];
	NSString *groupWithKeyPath = keyPath;
	NSString *group = nil, *finalKeyPath = nil;
	NSString *internalObjectID = nil;
	
	if (prefixRange.location == 0) {
		//Allow a Group: prefix, stripping it out if present.
		groupWithKeyPath = [keyPath substringFromIndex:prefixRange.length];
	} else {
		prefixRange = [keyPath rangeOfString:@"ByObject:" options:(NSLiteralSearch | NSAnchoredSearch)];
		if (prefixRange.location == 0) {			 
			keyPath = [keyPath substringFromIndex:prefixRange.length];
			
			NSRange nextPeriod = [keyPath rangeOfString:@"." 
												options:NSLiteralSearch
												  range:NSMakeRange(0, [keyPath length])];
			internalObjectID = [keyPath substringToIndex:nextPeriod.location];
			groupWithKeyPath = [keyPath substringFromIndex:nextPeriod.location + 1];			
		}
	}
	
	//We need the key to do AIPC change notifications.
	NSInteger periodIdx = [groupWithKeyPath rangeOfString:@"." options:NSLiteralSearch].location;
	if (periodIdx == NSNotFound) {
		group = groupWithKeyPath;
	} else {
		group = [groupWithKeyPath substringToIndex:periodIdx];
		finalKeyPath = [groupWithKeyPath substringFromIndex:periodIdx + 1];
	}
	
	if (outGroup) *outGroup = group;
	if (outKeyPath) *outKeyPath = finalKeyPath;
	if (outInternalObjectID) *outInternalObjectID = internalObjectID;
}

+ (BOOL) accessInstanceVariablesDirectly {
	return NO;
}

- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
	NSUInteger periodIdx = [keyPath rangeOfString:@"." options:NSLiteralSearch].location;
	if(periodIdx == NSNotFound) {
		[super addObserver:anObserver forKeyPath:keyPath options:options context:context];
		
	} else {
		NSString *group, *newKeyPath, *internalObjectID;
		parseKeypath(keyPath, &group, &newKeyPath, &internalObjectID);

		AIPreferenceContainer *prefContainer = [self preferenceContainerForGroup:group
																		  object:(internalObjectID ? [adium.contactController existingListObjectWithUniqueID:internalObjectID] : nil)
                                                                          create:YES];
		[prefContainer addObserver:anObserver forKeyPath:newKeyPath options:options context:context];
	}	
}

- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath ofObject:(AIListObject *)listObject options:(NSKeyValueObservingOptions)options context:(void *)context
{
	NSString *group, *newKeyPath, *internalObjectID;
	parseKeypath(keyPath, &group, &newKeyPath, &internalObjectID);

	AIPreferenceContainer *prefContainer = [self preferenceContainerForGroup:group object:listObject create:YES];
	[prefContainer addObserver:anObserver forKeyPath:newKeyPath options:options context:context];
}

- (void)removeObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath
{
	NSUInteger periodIdx = [keyPath rangeOfString:@"." options:NSLiteralSearch].location;
	if(periodIdx == NSNotFound) {
		[super removeObserver:anObserver forKeyPath:keyPath];
		
	} else {
		NSString *group, *newKeyPath, *internalObjectID;
		parseKeypath(keyPath, &group, &newKeyPath, &internalObjectID);

		AIPreferenceContainer *prefContainer = [self preferenceContainerForGroup:group
																		  object:(internalObjectID ? [adium.contactController existingListObjectWithUniqueID:internalObjectID] : nil)
                                                                          create:NO];
		[prefContainer removeObserver:anObserver forKeyPath:newKeyPath];
	}	
}

- (id) valueForKey:(NSString *)key {
	return [self preferenceContainerForGroup:key object:nil create:YES];
}

- (id) valueForKeyPath:(NSString *)keyPath {
	NSUInteger periodIdx = [keyPath rangeOfString:@"." options:NSLiteralSearch].location;
	if(periodIdx == NSNotFound) {
		return [self valueForKey:keyPath];
		
	} else {
		NSString *group, *newKeyPath, *internalObjectID;
		parseKeypath(keyPath, &group, &newKeyPath, &internalObjectID);

		return [[self preferenceContainerForGroup:group
										   object:(internalObjectID ? [adium.contactController existingListObjectWithUniqueID:internalObjectID] : nil)
                                           create:YES]
				valueForKeyPath:newKeyPath];
	}
}


/*!
 * @brief Set a dictionary of preferences for a group
 *
 * Note that while setPreferences:inGroup: adds the passed dictionary to the current one, this method replaces the dictionary entirely
 *
 * @param value An NSDictionary which reprsents an entire group of preferences (without defaults)
 * @param key The group name
 */
- (void) setValue:(id)value forKey:(NSString *)key {
	NSString *group = nil;
	NSString *internalObjectID = nil;

	parseKeypath(key, &group, NULL, &internalObjectID);

	[[self preferenceContainerForGroup:group
								object:(internalObjectID ?
										[adium.contactController existingListObjectWithUniqueID:internalObjectID] :
										nil)
                                create:YES] setPreferences:value];
}

/* 
 * Key paths:
 *		No prefix: Group
 *		"Group:": Group
 *		"ByObject" (futar): by-object (objectXyz instead of xyz ivars)
 *
 * For example, General.MyKey would refer to the MyKey value of the General group, as would Group:General.MyKey
 */
- (void) setValue:(id)value forKeyPath:(NSString *)keyPath {
	NSUInteger periodIdx = [keyPath rangeOfString:@"." options:NSLiteralSearch].location;
	if(periodIdx == NSNotFound) {
		NSString *key = [keyPath substringToIndex:periodIdx];

		[self setValue:value forKey:key];
	} else {
		NSString *group, *newKeyPath, *internalObjectID;
		parseKeypath(keyPath, &group, &newKeyPath, &internalObjectID);

		//Change the value.
		AIPreferenceContainer *prefContainer = [self preferenceContainerForGroup:group
																		  object:(internalObjectID ? [adium.contactController existingListObjectWithUniqueID:internalObjectID] : nil)
                                                                          create:YES];
		[prefContainer setValue:value forKeyPath:newKeyPath];
	}
}

@end

