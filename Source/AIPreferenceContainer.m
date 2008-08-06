//
//  AIPreferenceContainer.m
//  Adium
//
//  Created by Evan Schoenberg on 1/8/08.
//

#import "AIPreferenceContainer.h"
#import "AIPreferenceController.h"
#import <Adium/AIListObject.h>
#import <Adium/AILoginControllerProtocol.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAccount.h>

@interface AIPreferenceContainer (PRIVATE)
- (id)initForGroup:(NSString *)inGroup object:(AIListObject *)inObject;
- (void)emptyCache;
- (void)save;
+ (void)performObjectPrefsSave;
@end

#define EMPTY_CACHE_DELAY		120.0
#define	SAVE_OBJECT_PREFS_DELAY	10.0

/* XXX Remove me */
#ifdef DEBUG_BUILD
	#define PREFERENCE_CONTAINER_DEBUG
#endif

static NSMutableDictionary	*objectPrefs = nil;
static int					usersOfObjectPrefs = 0;
static NSTimer				*timer_savingOfObjectCache = nil;

static NSMutableDictionary	*accountPrefs = nil;
static int					usersOfAccountPrefs = 0;
static NSTimer				*timer_savingOfAccountCache = nil;

static NSConditionLock		*writingLock;

typedef enum {
	AIReadyToWrite,
	AIWriting,
} AIWritingLockState;
	
/*!
 * @brief Preference Container
 *
 * A single AIPreferenceContainer instance provides read/write access preferences to a specific preference group, either
 * for the global preferences or for a specific object.  After EMPTY_CACHE_DELAY seconds, it releases its preferences from memory;
 * it will reload them from disk as needed when accessed again.
 *
 * All contacts share a single plist on-disk, loaded into a single mutable dictionary in-memory, objectPrefs.
 * All accounts share a single plist on-disk, loaded into a single mutable dictionary in-memory, accountPrefs.
 * These global dictionaries provide per-object preference dictionaries, keyed by the object's internalObjectID.
 *
 * Individual instances of AIPreferenceContainer make use of this shared store.  Saving of changes is batched for all changes made during a
 * SAVE_OBJECT_PREFS_DELAY interval across all instances of AIPreferenceContainer for a given global dictionary. Because creating
 * the data representation of a large dictionary and writing it out can be time-consuming (certainly less than a second, but still long
 * enough to cause a perceptible delay for a user actively typing or interacting with Adium), saving is performed on a thread.
 *
 * When no instances are currently making use of a global dictionary, it is removed from memory; it will be reloaded from disk as needed.
 */
@implementation AIPreferenceContainer

+ (AIPreferenceContainer *)preferenceContainerForGroup:(NSString *)inGroup object:(AIListObject *)inObject
{
	return [[[self alloc] initForGroup:inGroup object:inObject] autorelease];
}

+ (void)preferenceControllerWillClose
{
	//Wait until any threaded save is complete
	[writingLock lockWhenCondition:AIReadyToWrite];

	//If a save of the object prefs is pending, perform it immediately since we are quitting
	if (timer_savingOfObjectCache) {
		@synchronized(objectPrefs) {
			[objectPrefs writeToPath:[[adium loginController] userDirectory]
							withName:@"ByObjectPrefs"];
		}
		/* There's no guarantee that 'will close' is called in the same run loop as the actual program termination.
		 * We've done our final save, though; don't let the timer fire again.
		 */
		@synchronized(timer_savingOfObjectCache) {
			[timer_savingOfObjectCache invalidate];
			[timer_savingOfObjectCache release]; timer_savingOfObjectCache = nil;
		}		
	}

	//If a save of the account prefs is pending, perform it immediately since we are quitting
	if (timer_savingOfAccountCache) {
		@synchronized(accountPrefs) {
			[accountPrefs writeToPath:[[adium loginController] userDirectory]
							 withName:@"AccountPrefs"];
		}
		/* There's no guarantee that 'will close' is called in the same run loop as the actual program termination.
		 * We've done our final save, though; don't let the timer fire again.
		 */		
		@synchronized(timer_savingOfAccountCache) {
			[timer_savingOfAccountCache invalidate];
			[timer_savingOfAccountCache release]; timer_savingOfObjectCache = nil;
		}		
	}

	//Relinguish the lock
	[writingLock unlockWithCondition:AIReadyToWrite];
}

- (id)initForGroup:(NSString *)inGroup object:(AIListObject *)inObject
{
	if ((self = [super init])) {
		group = [inGroup retain];
		object = [inObject retain];
		if (!writingLock) writingLock = [[NSConditionLock alloc] initWithCondition:AIReadyToWrite];
		if (object) {
			if ([object isKindOfClass:[AIAccount class]]) {
				myGlobalPrefs = &accountPrefs;
				myUsersOfGlobalPrefs = &usersOfAccountPrefs;
				myTimerForSavingGlobalPrefs = &timer_savingOfAccountCache;
				globalPrefsName = [@"AccountPrefs" retain];
				
			} else {
				myGlobalPrefs = &objectPrefs;
				myUsersOfGlobalPrefs = &usersOfObjectPrefs;
				myTimerForSavingGlobalPrefs = &timer_savingOfObjectCache;
				globalPrefsName = [@"ByObjectPrefs" retain];
			}
		}
	}

	return self;
}

- (void)dealloc
{
	[defaults release]; defaults = nil;
	[group release];
	[object release];
	[timer_clearingOfCache release]; timer_clearingOfCache = nil;
	[globalPrefsName release]; globalPrefsName = nil;

	[self emptyCache];
	
	[super dealloc];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
	return NO;
}

#pragma mark Cache

/*!
 * @brief Empty our cache
 */
- (void)emptyCache:(NSTimer *)inTimer
{
	if (object) {
		@synchronized(*myGlobalPrefs) {
			(*myUsersOfGlobalPrefs)--;
			
			[prefs release]; prefs = nil;
			[prefsWithDefaults release]; prefsWithDefaults = nil;
			
			if ((*myUsersOfGlobalPrefs) == 0) {
				[*myGlobalPrefs release]; *myGlobalPrefs = nil;
			}
		}

	} else {
		[prefs release]; prefs = nil;
		[prefsWithDefaults release]; prefsWithDefaults = nil;
	}
	
	[timer_clearingOfCache release]; timer_clearingOfCache = nil;
}

/*!
 * @brief Queue clearing of the cache
 *
 * If this method isn't called again within 30 seconds, the passed key will be removed from the passed cache dictionary.
 */
- (void)queueClearingOfCache
{
	if (!timer_clearingOfCache) {
		timer_clearingOfCache = [[NSTimer scheduledTimerWithTimeInterval:EMPTY_CACHE_DELAY
																  target:self
																selector:@selector(emptyCache:)
																userInfo:nil
																 repeats:NO] retain];
	} else {
		[timer_clearingOfCache setFireDate:[NSDate dateWithTimeIntervalSinceNow:EMPTY_CACHE_DELAY]];
	}
}

#pragma mark Defaults

- (NSDictionary *)defaults
{
	return defaults;
}

/*!
 * @brief Register defaults
 *
 * These defaults will be added to any existing defaults; if there is overlap between keys, the new key-value pair will be used.
 */
- (void)registerDefaults:(NSDictionary *)inDefaults
{
	if (!defaults) defaults = [[NSMutableDictionary alloc] init];
	
	[defaults addEntriesFromDictionary:inDefaults];
	
	//Clear the cached defaults dictionary so it will be recreated as needed
	[prefsWithDefaults release]; prefsWithDefaults = nil;
}

#pragma mark Get and set

/*!
 * @brief Return a dictionary of our preferences, loading it from disk as needed
 */
- (NSMutableDictionary *)prefs
{
	if (!prefs) {
		NSString	*userDirectory = [[adium loginController] userDirectory];
		
		if (object) {
			if (!(*myGlobalPrefs)) {
				NSString	*objectPrefsPath = [[userDirectory stringByAppendingPathComponent:globalPrefsName] stringByAppendingPathExtension:@"plist"];
				NSString	*errorString = nil;
				NSError		*error = nil;
				NSData		*data = [NSData dataWithContentsOfFile:objectPrefsPath
													   options:NSUncachedRead
														 error:&error];

				if (error) {
					NSLog(@"Error reading data for preferences file %@: %@ (%@ %i: %@)", objectPrefsPath, error,
						  [error domain], [error code], [error userInfo]);
					AILogWithSignature(@"Error reading data for preferences file %@: %@ (%@ %i: %@)", objectPrefsPath, error,
									   [error domain], [error code], [error userInfo]);
					if ([[NSFileManager defaultManager] fileExistsAtPath:objectPrefsPath]) {
						while (!data) {
							AILogWithSignature(@"Preferences file %@'s attributes: %@. Reattempting to read the file...", globalPrefsName, [[NSFileManager defaultManager] fileAttributesAtPath:objectPrefsPath traverseLink:NO]);
							data = [NSData dataWithContentsOfFile:objectPrefsPath
														  options:NSUncachedRead
															error:&error];
							if (error) {
								AILogWithSignature(@"Error reading data for preferences file %@: %@ (%@ %i: %@)", objectPrefsPath, error,
												   [error domain], [error code], [error userInfo]);
							}	
						}
					}
				}
				
				//We want to load a mutable dictioanry of mutable dictionaries.
				if (data) {
					*myGlobalPrefs = [[NSPropertyListSerialization propertyListFromData:data 
																	   mutabilityOption:NSPropertyListMutableContainers 
																				 format:NULL 
																	   errorDescription:&errorString] retain];
				}
				
				/* Log any error */
				if (errorString) {
					NSLog(@"Error reading preferences file %@: %@", objectPrefsPath, errorString);
					AILogWithSignature(@"Error reading preferences file %@: %@", objectPrefsPath, errorString);
					
					/* Memory managed for us in 10.5+ */
					if (![NSApp isOnLeopardOrBetter])
						[errorString release];
				}
				
				#ifdef PREFERENCE_CONTAINER_DEBUG
					AILogWithSignature(@"I read in %@ with %i items", globalPrefsName, [*myGlobalPrefs count]);
				#endif

				/* If we don't get a dictionary, create a new one */
				if (!*myGlobalPrefs) {
					/* This wouldn't be an error if this were a new Adium installation; the below is temporary debug logging. */
					NSLog(@"WARNING: Unable to parse preference file %@ (data was %@)", objectPrefsPath, data);
					AILogWithSignature(@"WARNING: Unable to parse preference file %@ (data was %@)", objectPrefsPath, data);

					*myGlobalPrefs = [[NSMutableDictionary alloc] init];
				}
			}

			//For compatibility with having loaded individual object prefs from previous version of Adium, we key by the safe filename string
			NSString *globalPrefsKey = [[object internalObjectID] safeFilenameString];
			prefs = [[*myGlobalPrefs objectForKey:globalPrefsKey] retain];
			if (!prefs) {
				/* If this particular object has no dictionary within the global one,
				 * create it and store it for future use.
				 */
				@synchronized(*myGlobalPrefs) {
					prefs = [[NSMutableDictionary alloc] init];
					[*myGlobalPrefs setObject:prefs
									   forKey:globalPrefsKey];
				}
			}
			(*myUsersOfGlobalPrefs)++;

		} else {
			prefs = [[NSMutableDictionary dictionaryAtPath:userDirectory
												  withName:group
													create:YES] retain];
		}
		
		[self queueClearingOfCache];
	}
	
	return prefs;
}

/*!
 * @brief Return a dictionary of preferences and defaults, appropriately merged together
 */
- (NSDictionary *)dictionary
{
	if (!prefsWithDefaults) {
		//Add our own preferences to the defaults dictionary to get a dict with the set keys overriding the default keys
		if (defaults) {
			prefsWithDefaults = [defaults mutableCopy];
			[prefsWithDefaults addEntriesFromDictionary:[self prefs]];

		} else {
			prefsWithDefaults = [[self prefs] retain];
		}
		
		[self queueClearingOfCache];
	}

	return prefsWithDefaults;
}

/*!
 * @brief Set value for key
 *
 * This sets and saves a preference for the given key
 */
- (void)setValue:(id)value forKey:(NSString *)key
{
	BOOL	valueChanged;
	/* Comparing pointers, numbers, and strings is far cheapear than writing out to disk;
	 * check to see if we don't need to change anything at all. However, we still want to post notifications
	 * for observers that we were set.
	 */
	id oldValue;
	if ((!value && ![self valueForKey:key]) ||
		((value && (oldValue = [self valueForKey:key])) && 
		 (([value isKindOfClass:[NSNumber class]] && [(NSNumber *)value isEqualToNumber:oldValue]) ||
		  ([value isKindOfClass:[NSString class]] && [(NSString *)value isEqualToString:oldValue])))) {
		valueChanged = NO;
	} else {
		valueChanged = YES;
	}

	[self willChangeValueForKey:key];

	if (valueChanged) {
		//Clear the cached defaults dictionary so it will be recreated as needed
		if (value)
			[prefsWithDefaults setValue:value forKey:key];
		else {
			[prefsWithDefaults autorelease]; prefsWithDefaults = nil;
		}
		
		if (object) {
			@synchronized(*myGlobalPrefs) {
				[[self prefs] setValue:value forKey:key];
			}
		} else {
			[[self prefs] setValue:value forKey:key];		
		}
	}

	[self didChangeValueForKey:key];

	//Now tell the preference controller
	if (!preferenceChangeDelays) {
		[[adium preferenceController] informObserversOfChangedKey:key inGroup:group object:object];
		if (valueChanged)
			[self save];
	}
}

- (id)valueForKey:(NSString *)key
{
	return [[self dictionary] valueForKey:key];
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
		return [[self prefs] valueForKey:key];
	else
		return [self valueForKey:key];
}

- (id)defaultValueForKey:(NSString *)key
{
	return [[self defaults] valueForKey:key];
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
		[[adium preferenceController] informObserversOfChangedKey:nil inGroup:group object:object];
		[self save];
	}
}

#pragma mark Saving
- (void)threadedSavePrefs:(NSDictionary *)info
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	//Obtain the lock when no save operations are being performed
	[writingLock lockWhenCondition:AIReadyToWrite];

	//Set the lock's condition to saving so that other threads (including the main one) know what we're up to
	[writingLock unlockWithCondition:AIWriting];
	
	NSDictionary *sourcePrefsToSave = [info objectForKey:@"PrefsToSave"];
	NSDictionary *dictToSave;
	//Don't allow modification of the dictionary while we're copying it...
	@synchronized(sourcePrefsToSave) {
		#ifdef PREFERENCE_CONTAINER_DEBUG
			AILogWithSignature(@"Beginning to save %@ with %i items", [info objectForKey:@"PrefsName"], [sourcePrefsToSave count]);
		#endif
		dictToSave = [[NSDictionary alloc] initWithDictionary:sourcePrefsToSave copyItems:YES];
	}
	//...and now it's safe to write it out, which may take a little while.
	[dictToSave writeToPath:[info objectForKey:@"DestinationDirectory"]
				   withName:[info objectForKey:@"PrefsName"]];

	/* Data verification */
#ifdef PREFERENCE_CONTAINER_DEBUG
	{
		NSData		 *data = [NSData dataWithContentsOfFile:[[info objectForKey:@"DestinationDirectory"] stringByAppendingPathComponent:
															 [[info objectForKey:@"PrefsName"] stringByAppendingPathExtension:@"plist"]]];
		NSString	 *errorString = nil;
		NSDictionary *theDict = [NSPropertyListSerialization propertyListFromData:data 
																 mutabilityOption:NSPropertyListMutableContainers 
																		   format:NULL 
																 errorDescription:&errorString];
		AILogWithSignature(@"I just wrote out %@ with %i items (%@) length of data was %i",
						   [info objectForKey:@"PrefsName"], [theDict count], errorString, [data length]);
	}
#endif

	[dictToSave release];

	//The timer is not a repeating one, so we can just release it
	NSTimer *inTimer = [info objectForKey:@"NSTimer"];
	if (inTimer == timer_savingOfObjectCache) {
		@synchronized(timer_savingOfObjectCache) {
			[timer_savingOfObjectCache release]; timer_savingOfObjectCache = nil;
		}
	} else if (inTimer == timer_savingOfAccountCache) {
		@synchronized(timer_savingOfAccountCache) {
			[timer_savingOfAccountCache release]; timer_savingOfAccountCache = nil;
		}
	}

	//We're no longer using global prefs; if nobody is, the main thread will release its in-memory cache later
	@synchronized(sourcePrefsToSave) {
		(*myUsersOfGlobalPrefs)--;
	}
	
	//Unlock and note that we're ready to quit
	[writingLock lockWhenCondition:AIWriting];
	[writingLock unlockWithCondition:AIReadyToWrite];

	[pool release];
}

- (void)performObjectPrefsSave:(NSTimer *)inTimer
{
	[NSThread detachNewThreadSelector:@selector(threadedSavePrefs:)
							 toTarget:self
						   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
									   [inTimer userInfo], @"PrefsToSave",
									   [[adium loginController] userDirectory], @"DestinationDirectory",
										globalPrefsName, @"PrefsName",
									    inTimer, @"NSTimer",
									   nil]];
}

/*!
 * @brief Save to disk
 */
- (void)save
{
	if (object) {
		//For an object's pref changes, batch all changes in a SAVE_OBJECT_PREFS_DELAY second period. We'll force an immediate save if Adium quits.
		if (*myTimerForSavingGlobalPrefs) {
			@synchronized(*myTimerForSavingGlobalPrefs) {
				[*myTimerForSavingGlobalPrefs setFireDate:[NSDate dateWithTimeIntervalSinceNow:SAVE_OBJECT_PREFS_DELAY]];
			}

		} else {
			(*myUsersOfGlobalPrefs)++;

			*myTimerForSavingGlobalPrefs = [[NSTimer scheduledTimerWithTimeInterval:SAVE_OBJECT_PREFS_DELAY
																			 target:self
																		   selector:@selector(performObjectPrefsSave:)
																		   userInfo:*myGlobalPrefs
																			repeats:NO] retain];
		}


	} else {
		//Save the preference change immediately
		NSString	*userDirectory = [[adium loginController] userDirectory];
		
		NSString	*path = (object ? [userDirectory stringByAppendingPathComponent:[object pathToPreferences]] : userDirectory);
		NSString	*name = (object ? [[object internalObjectID] safeFilenameString] : group);
		
		BOOL success = [[self prefs] writeToPath:path withName:name];
		if (!success)
			NSLog(@"Error writing %@ for %@", self);
	}
}

- (void)setGroup:(NSString *)inGroup
{
	if (group != inGroup) {
		[group release];
		group = [inGroup retain];
	}
}

#pragma mark Debug
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p: Group %@, object %@>", NSStringFromClass([self class]), self, group, object];
}
@end
