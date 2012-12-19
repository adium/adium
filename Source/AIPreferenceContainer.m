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

#import "AIPreferenceContainer.h"
#import <Adium/AIListObject.h>
#import <Adium/AILoginControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAccount.h>

@interface AIPreferenceContainer ()
- (id)initForGroup:(NSString *)inGroup object:(AIListObject *)inObject;
- (void)save;
@property (readonly, nonatomic) NSMutableDictionary *prefs;
+ (void) loadGlobalPrefsForObject:(AIListObject *)object;

//Lazily sets up our pref dict if needed
- (void) setPrefValue:(id)val forKey:(id)key;
@end

#define	SAVE_OBJECT_PREFS_DELAY	10.0

/* XXX Remove me */
#ifdef DEBUG_BUILD
	#define PREFERENCE_CONTAINER_DEBUG
#endif

static NSMutableDictionary	*objectPrefs = nil;
static NSTimer				*timer_savingOfObjectCache = nil;

static NSMutableDictionary	*accountPrefs = nil;
static NSTimer				*timer_savingOfAccountCache = nil;
	
/*!
 * @brief Preference Container
 *
 * A single AIPreferenceContainer instance provides read/write access preferences to a specific preference group, either
 * for the global preferences or for a specific object.
 *
 * All contacts share a single plist on-disk, loaded into a single mutable dictionary in-memory, objectPrefs.
 * All accounts share a single plist on-disk, loaded into a single mutable dictionary in-memory, accountPrefs.
 * These global dictionaries provide per-object preference dictionaries, keyed by the object's internalObjectID.
 *
 * Individual instances of AIPreferenceContainer make use of this shared store.  Saving of changes is batched for all changes made during a
 * SAVE_OBJECT_PREFS_DELAY interval across all instances of AIPreferenceContainer for a given global dictionary. Because creating
 * the data representation of a large dictionary and writing it out can be time-consuming (certainly less than a second, but still long
 * enough to cause a perceptible delay for a user actively typing or interacting with Adium), saving is performed on a thread.
 */
@implementation AIPreferenceContainer

static NSString *globalPrefsNameForObject(AIListObject *object) {
    if (!object) return NULL;
    return [object isKindOfClass:[AIAccount class]] ? @"AccountPrefs" : @"ByObjectPrefs";
}
#define globalPrefsName globalPrefsNameForObject(object)

static NSMutableDictionary * __strong *globalPrefsPtrForObject(AIListObject *object) {
    if (!object) return NULL;
    return [object isKindOfClass:[AIAccount class]] ? &accountPrefs : &objectPrefs;
}
#define myGlobalPrefs globalPrefsPtrForObject(object)

static NSTimer * __strong *globalPrefsSaveTimerForObject(AIListObject *object) {
    if (!object) return NULL;
    return [object isKindOfClass:[AIAccount class]] ? &timer_savingOfAccountCache : &timer_savingOfObjectCache;
}
#define myTimerForSavingGlobalPrefs globalPrefsSaveTimerForObject(object)

+ (AIPreferenceContainer *)preferenceContainerForGroup:(NSString *)inGroup object:(AIListObject *)inObject create:(BOOL)create
{
    BOOL found = YES;
    if (inObject) {
        NSMutableDictionary * __strong *prefs = globalPrefsPtrForObject(inObject);
        if (!*prefs) {
            [self loadGlobalPrefsForObject:inObject];
            prefs = globalPrefsPtrForObject(inObject);
        }
        
        NSString *globalPrefsKey = [inObject.internalObjectID safeFilenameString];
        found = (nil != [*prefs objectForKey:globalPrefsKey]);
    }

    if (inObject && !found && !create) return nil;
	return [[self alloc] initForGroup:inGroup object:inObject];
}

+ (void)preferenceControllerWillClose
{
	//If a save of the object prefs is pending, perform it immediately since we are quitting
	if (timer_savingOfObjectCache) {
			[objectPrefs writeToPath:[adium.loginController userDirectory]
							withName:@"ByObjectPrefs"];
		/* There's no guarantee that 'will close' is called in the same run loop as the actual program termination.
		 * We've done our final save, though; don't let the timer fire again.
		 */
		[timer_savingOfObjectCache invalidate];
		timer_savingOfObjectCache = nil;
	}

	//If a save of the account prefs is pending, perform it immediately since we are quitting
	if (timer_savingOfAccountCache) {
		[accountPrefs writeToPath:[adium.loginController userDirectory]
						 withName:@"AccountPrefs"];
		/* There's no guarantee that 'will close' is called in the same run loop as the actual program termination.
		 * We've done our final save, though; don't let the timer fire again.
		 */		
		[timer_savingOfAccountCache invalidate];
		timer_savingOfObjectCache = nil;
	}
}

- (id)initForGroup:(NSString *)inGroup object:(AIListObject *)inObject
{
	if ((self = [super init])) {
		group = inGroup;
		object = inObject;
	}

	return self;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
	return NO;
}

#pragma mark Defaults

@synthesize defaults, group;

/*!
 * @brief Register defaults
 *
 * These defaults will be added to any existing defaults; if there is overlap between keys, the new key-value pair will be used.
 */
- (void)registerDefaults:(NSDictionary *)inDefaults
{
	if (!defaults) defaults = [[NSMutableDictionary alloc] init];
	
	[defaults addEntriesFromDictionary:inDefaults];
}

#pragma mark Get and set

+ (void) loadGlobalPrefsForObject:(AIListObject *)object
{
	NSAssert(*myGlobalPrefs == nil, @"Attempting to load global prefs when they're already loaded");
	NSString	*objectPrefsPath = [[adium.loginController.userDirectory stringByAppendingPathComponent:globalPrefsName] stringByAppendingPathExtension:@"plist"];
	NSString	*errorString = nil;
	NSError		*error = nil;
	NSData		*data = [NSData dataWithContentsOfFile:objectPrefsPath
										   options:NSUncachedRead
											 error:&error];
	
	if (error) {
		NSLog(@"Error reading data for preferences file %@: %@ (%@ %ld: %@)", objectPrefsPath, error,
			  [error domain], (long)[error code], [error userInfo]);
		AILogWithSignature(@"Error reading data for preferences file %@: %@ (%@ %li: %@)", objectPrefsPath, error,
						   [error domain], [error code], [error userInfo]);
		if ([[NSFileManager defaultManager] fileExistsAtPath:objectPrefsPath]) {
			while (!data) {
				AILogWithSignature(@"Preferences file %@'s attributes: %@. Reattempting to read the file...", globalPrefsName, [[NSFileManager defaultManager] attributesOfItemAtPath:objectPrefsPath error:NULL]);
				data = [NSData dataWithContentsOfFile:objectPrefsPath
											  options:NSUncachedRead
												error:&error];
				if (error) {
					AILogWithSignature(@"Error reading data for preferences file %@: %@ (%@ %li: %@)", objectPrefsPath, error,
									   [error domain], [error code], [error userInfo]);
				}	
			}
		}
	}
	
	//We want to load a mutable dictioanry of mutable dictionaries.
	if (data) {
		*myGlobalPrefs = [NSPropertyListSerialization propertyListFromData:data 
														   mutabilityOption:NSPropertyListMutableContainers 
																	 format:NULL 
														   errorDescription:&errorString];
	}
	
	/* Log any error */
	if (errorString) {
		NSLog(@"Error reading preferences file %@: %@", objectPrefsPath, errorString);
		AILogWithSignature(@"Error reading preferences file %@: %@", objectPrefsPath, errorString);
	}
	
#ifdef PREFERENCE_CONTAINER_DEBUG
	AILogWithSignature(@"I read in %@ with %li items", globalPrefsName, [*myGlobalPrefs count]);
#endif
	
	/* If we don't get a dictionary, create a new one */
	if (!*myGlobalPrefs) {
		/* This wouldn't be an error if this were a new Adium installation; the below is temporary debug logging. */
		NSLog(@"WARNING: Unable to parse preference file %@ (data was %@)", objectPrefsPath, data);
		AILogWithSignature(@"WARNING: Unable to parse preference file %@ (data was %@)", objectPrefsPath, data);
		
		*myGlobalPrefs = [[NSMutableDictionary alloc] init];
	}
}

- (void) setPrefValue:(id)value forKey:(id)key
{
	NSAssert([NSThread currentThread] == [NSThread mainThread], @"AIPreferenceContainer is not threadsafe! Don't set prefs from non-main threads");
	NSMutableDictionary *prefDict = self.prefs;
	if (object && !prefDict) {
		//For compatibility with having loaded individual object prefs from previous version of Adium, we key by the safe filename string
		NSString *globalPrefsKey = [object.internalObjectID safeFilenameString];
		prefs = [[NSMutableDictionary alloc] init];
		[*myGlobalPrefs setObject:prefs
						   forKey:globalPrefsKey];
	}
	[self.prefs setValue:value forKey:key];
}

/*!
 * @brief Return a dictionary of our preferences, loading it from disk as needed
 */
- (NSMutableDictionary *)prefs
{
	if (!prefs) {
		NSString	*userDirectory = adium.loginController.userDirectory;
		
		if (object) {
			//For compatibility with having loaded individual object prefs from previous version of Adium, we key by the safe filename string
			NSString *globalPrefsKey = [object.internalObjectID safeFilenameString];
			prefs = [*myGlobalPrefs objectForKey:globalPrefsKey];

		} else {
			prefs = [NSMutableDictionary dictionaryAtPath:userDirectory
												  withName:group
													create:YES];
		}
	}
	
	return prefs;
}

/*!
 * @brief Return a dictionary of preferences and defaults, appropriately merged together
 */
- (NSDictionary *)dictionary
{
    NSDictionary *myPrefs = self.prefs;
    if (!defaults) return [myPrefs copy];
    
    NSMutableDictionary *prefsWithDefaults = [defaults mutableCopy];
    //Add our own preferences to the defaults dictionary to get a dict with the set keys overriding the default keys
    if (myPrefs) [prefsWithDefaults addEntriesFromDictionary:myPrefs];
    return prefsWithDefaults;
}

/*!
 * @brief Set value for key
 *
 * This sets and saves a preference for the given key
 */
- (void)setValue:(id)value forKey:(NSString *)key
{
	BOOL	valueChanged = YES;
	/* Comparing pointers, numbers, and strings is far cheaper than writing out to disk;
	 * check to see if we don't need to change anything at all. However, we still want to post notifications
	 * for observers that we were set.
	 */
	id oldValue = [self valueForKey:key];
	if ((!value && !oldValue) || (value && oldValue && [value isEqual:oldValue]))
		valueChanged = NO;

	[self willChangeValueForKey:key];

	if (valueChanged) {
		[self setPrefValue:value forKey:key];		
	}

	[self didChangeValueForKey:key];

	//Now tell the preference controller
	if (!preferenceChangeDelays) {
		[adium.preferenceController informObserversOfChangedKey:key inGroup:group object:object];
		if (valueChanged)
			[self save];
	}
}

- (id)valueForKey:(NSString *)key
{
    id result = nil;
    result = [self.prefs objectForKey:key];
    if (!result) result = [self.defaults objectForKey:key];
    return result;
}

/*!
 * @brief Get a preference, possibly ignoring the defaults
 *
 * @param key The key
 * @param ignoreDefaults If YES, the preferences are accessed diretly, without including the default values
 */
- (id)valueForKey:(NSString *)key ignoringDefaults:(BOOL)ignoreDefaults
{
	if (ignoreDefaults)
		return [self.prefs valueForKey:key];
	else
		return [self valueForKey:key];
}

- (id)defaultValueForKey:(NSString *)key
{
	return [self.defaults valueForKey:key];
}

/*!
 * @brief Set all preferences for this group
 *
 * All existing preferences are removed for this group; the passed dictionary becomes the new preferences
 */
- (void)setPreferences:(NSDictionary *)inPreferences
{	
	[self setPreferenceChangedNotificationsEnabled:NO];
	
	[self setValuesForKeysWithDictionary:inPreferences];
	
	[self setPreferenceChangedNotificationsEnabled:YES];
}

- (void)setPreferenceChangedNotificationsEnabled:(BOOL)inEnabled
{
	if (inEnabled) 
		preferenceChangeDelays--;
	else
		preferenceChangeDelays++;
	
	if (preferenceChangeDelays == 0) {
		[adium.preferenceController informObserversOfChangedKey:nil inGroup:group object:object];
		[self save];
	}
}

#pragma mark Saving

- (void)performObjectPrefsSave:(NSTimer *)inTimer
{
	NSDictionary *immutablePrefsToWrite = [[NSDictionary alloc] initWithDictionary:inTimer.userInfo copyItems:YES];
	/* Data verification */
#ifdef PREFERENCE_CONTAINER_DEBUG
//	{
//		NSData		 *data = [NSData dataWithContentsOfFile:[adium.loginController.userDirectory stringByAppendingPathComponent:[globalPrefsName stringByAppendingPathExtension:@"plist"]]];
//		NSString	 *errorString = nil;
//		NSDictionary *theDict = [NSPropertyListSerialization propertyListFromData:data 
//																 mutabilityOption:NSPropertyListMutableContainers 
//																		   format:NULL 
//																 errorDescription:&errorString];
//		if (theDict && [theDict count] > 0 && [immutablePrefsToWrite count] == 0)
//		{
//			NSLog(@"Writing out an empty ByObjectPrefs when we have an existing non-empty one!");
//			abort();
//		}
//	}
#endif
#warning figure this out
	if ([immutablePrefsToWrite count] > 0) {
		[immutablePrefsToWrite asyncWriteToPath:adium.loginController.userDirectory withName:globalPrefsName];
	} else {
		NSLog(@"Attempted to write an empty ByObject Prefs. Uh oh!");
		abort();
	}
	if (inTimer == timer_savingOfObjectCache) {
			timer_savingOfObjectCache = nil;
	} else if (inTimer == timer_savingOfAccountCache) {
			timer_savingOfAccountCache = nil;
	}
}

/*!
 * @brief Save to disk
 */
- (void)save
{
	if (object) {
		//For an object's pref changes, batch all changes in a SAVE_OBJECT_PREFS_DELAY second period. We'll force an immediate save if Adium quits.
		if (*myTimerForSavingGlobalPrefs) {
				[*myTimerForSavingGlobalPrefs setFireDate:[NSDate dateWithTimeIntervalSinceNow:SAVE_OBJECT_PREFS_DELAY]];
		} else {
				
#ifdef PREFERENCE_CONTAINER_DEBUG
			// This shouldn't be happening at all.
			if (!*myGlobalPrefs) {
				NSLog(@"Attempted to detach to save for %@ [%@], but info was nil.", self, globalPrefsName);
				AILogWithSignature(@"Attempted to detach to save for %@ [%@], but info was nil.", self, globalPrefsName);
			}
#endif

			*myTimerForSavingGlobalPrefs = [NSTimer scheduledTimerWithTimeInterval:SAVE_OBJECT_PREFS_DELAY
																			 target:self
																		   selector:@selector(performObjectPrefsSave:)
																		   userInfo:*myGlobalPrefs
																			repeats:NO];
		}


	} else {
		//Save the preference change immediately
		[self.prefs writeToPath:adium.loginController.userDirectory withName:group];
	}
}

#pragma mark Debug
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p: Group %@, object %@>", NSStringFromClass([self class]), self, group, object];
}
@end
