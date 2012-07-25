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

#import "AdiumSound.h"
#import "AISoundController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AISleepNotification.h>
#import <CoreAudio/AudioHardware.h>
#import <CoreServices/CoreServices.h>
#import <sys/sysctl.h>

#define SOUND_DEFAULT_PREFS				@"SoundPrefs"
#define MAX_CACHED_SOUNDS				4			//Max cached sounds

@interface AdiumSound ()
- (void)_stopAndReleaseAllSounds;
- (void)_setVolumeOfAllSoundsTo:(float)inVolume;
- (void)cachedPlaySound:(NSString *)inPath;
- (void)_uncacheLeastRecentlyUsedSound;
- (NSString *)systemAudioDeviceID;
- (void)configureAudioContextForSound:(NSSound *)sound;
- (NSArray *)allSounds;
- (void)workspaceSessionDidBecomeActive:(NSNotification *)notification;
- (void)workspaceSessionDidResignActive:(NSNotification *)notification;
- (void)systemWillSleep:(NSNotification *)notification;
@end

static dispatch_queue_t soundPlayingQueue;

static OSStatus systemOutputDeviceDidChange(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void* refcon);

@implementation AdiumSound

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		soundCacheDict = [[NSMutableDictionary alloc] init];
		soundCacheArray = [[NSMutableArray alloc] init];
		soundCacheCleanupTimer = nil;
		soundsAreMuted = NO;
		
		soundPlayingQueue = dispatch_queue_create("im.adium.AdiumSound.soundPlayingQueue", 0);

		//Observe workspace activity changes so we can mute sounds as necessary
		NSNotificationCenter *workspaceCenter = [[NSWorkspace sharedWorkspace] notificationCenter];

		[workspaceCenter addObserver:self
							selector:@selector(workspaceSessionDidBecomeActive:)
								name:NSWorkspaceSessionDidBecomeActiveNotification
							  object:nil];

		[workspaceCenter addObserver:self
							selector:@selector(workspaceSessionDidResignActive:)
								name:NSWorkspaceSessionDidResignActiveNotification
							  object:nil];

		//Monitor system sleep so we can stop sounds before sleeping; otherwise, we may crash while waking
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(systemWillSleep:)
													 name:AISystemWillSleep_Notification
												   object:nil];
		
		// Sign up for notification when the user changes the system output device in the Sound pane of System Preferences.
		AudioObjectPropertyAddress audioAddress = {
			kAudioHardwarePropertyDefaultSystemOutputDevice,
			kAudioObjectPropertyScopeGlobal,
			kAudioObjectPropertyElementMaster
		};
		OSStatus err = AudioObjectAddPropertyListener(kAudioObjectSystemObject, &audioAddress, systemOutputDeviceDidChange, self);

		if (err != noErr)
			NSLog(@"%s: Couldn't sign up for system-output-device-changed notification, because AudioHardwareAddPropertyListener returned %ld. Adium will not know when the default system audio device changes.", __PRETTY_FUNCTION__, (long)err);
	}

	return self;
}

- (void)controllerDidLoad
{
	//Register our default preferences and observe changes
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:SOUND_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_SOUNDS];
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_SOUNDS];
}

- (void)dealloc
{
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[self _stopAndReleaseAllSounds];

	[soundCacheDict release]; soundCacheDict = nil;
	[soundCacheArray release]; soundCacheArray = nil;
	[soundCacheCleanupTimer invalidate]; [soundCacheCleanupTimer release]; soundCacheCleanupTimer = nil;

	[super dealloc];
}

- (void)playSoundAtPath:(NSString *)inPath
{
	if (inPath && customVolume != 0.0 && !soundsAreMuted) {
		[self cachedPlaySound:inPath];
	}
}

- (void)stopPlayingSoundAtPath:(NSString *)inPath
{
	NSSound *sound = [soundCacheDict objectForKey:inPath];
	if (sound) {
		[sound stop];
	}
}

/*!
 * @brief Preferences changed, adjust to the new values
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	float newVolume = [[prefDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue];

	//If sound volume has changed, we must update all existing sounds to the new volume
	if (customVolume != newVolume) {
		[self _setVolumeOfAllSoundsTo:newVolume];
	}

	//Load the new preferences
	customVolume = newVolume;
}

/*!
 * @brief Stop and release all cached sounds
 */
- (void)_stopAndReleaseAllSounds
{
	[[soundCacheDict allValues] makeObjectsPerformSelector:@selector(stop)];
	[soundCacheDict removeAllObjects];
	[soundCacheArray removeAllObjects];
}

/*!
 * @brief Update the volume of all cached sounds
 */
- (void)_setVolumeOfAllSoundsTo:(float)inVolume
{
	for(id sound in  [soundCacheDict allValues]) {
		[(NSSound *)sound setVolume:inVolume];
	}
}

/*!
 * @brief Play an NSSound, possibly cached
 * 
 * @param inPath path to the sound file
 */
- (void)cachedPlaySound:(NSString *)inPath
{
	NSSound *sound = [soundCacheDict objectForKey:inPath];
	
	//Load the sound if necessary
    if (!sound) {
		//If the cache is full, remove the least recently used cached sound
		if ([soundCacheDict count] >= MAX_CACHED_SOUNDS) {
			[self _uncacheLeastRecentlyUsedSound];
		}
		
		//Load and cache the sound
		NSError *error = nil;
		sound = [[NSSound alloc] initWithContentsOfFile:inPath byReference:NO];
		if (sound) {
			//Insert the player at the front of our cache
			[soundCacheArray insertObject:inPath atIndex:0];
			[soundCacheDict setObject:sound forKey:inPath];
			[sound release];
			
			//Set the volume (otherwise #2283 happens)
			[sound setVolume:customVolume];
			
			[self configureAudioContextForSound:sound];
		} else {
			AILogWithSignature(@"Error loading %@: %@", inPath, error);
		}
		
    } else {
		//Move this sound to the front of the cache (This will naturally move lesser used sounds to the back for removal)
		[soundCacheArray removeObject:inPath];
		[soundCacheArray insertObject:inPath atIndex:0];
    }
	
    //Engage!
    if (sound) {
		//Ensure the sound is starting from the beginning; necessary for cached sounds that have already been played
		[sound setCurrentTime:0.0];
		
		//This only has an effect if the movie is not already playing. It won't stop it, and it won't start it over (the latter is what setCurrentTime: is for).
		dispatch_async(soundPlayingQueue, ^{
			[sound play];
		});
    }
}

/*!
 * @brief Remove the least recently used sound from the cache
 */
- (void)_uncacheLeastRecentlyUsedSound
{
	NSString			*lastCachedPath = [soundCacheArray lastObject];
	NSSound *sound = [soundCacheDict objectForKey:lastCachedPath];
	
	//Remove it from the cache only if it is not playing.
	if (![sound isPlaying]) {
		[soundCacheDict removeObjectForKey:lastCachedPath];
		[soundCacheArray removeLastObject];
	}
}

- (NSString *)systemAudioDeviceID
{
	OSStatus err;
	UInt32 dataSize;
	
	//First, obtain the device itself.
	AudioDeviceID systemOutputDevice = 0;
	dataSize = sizeof(AudioDeviceID);
	AudioObjectPropertyAddress theAddress = {
		kAudioHardwarePropertyDefaultSystemOutputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &theAddress, 0, NULL, &dataSize, &systemOutputDevice);
	if (err != noErr) {
		NSLog(@"%s: Could not get the system output device: AudioHardwareGetProperty returned error %ld", __PRETTY_FUNCTION__, (long)err);
		return NULL;
	}
	
	//Now get its UID. We'll need to release this.
	CFStringRef deviceUID = NULL;
	dataSize = sizeof(deviceUID);

	AudioObjectPropertyAddress uidAddress = {
		kAudioDevicePropertyDeviceUID,
		kAudioDevicePropertyScopeOutput,
		/*channel*/ 0
	};
	
	err = AudioObjectGetPropertyData(systemOutputDevice, &uidAddress, 0, NULL, &dataSize, &deviceUID);
	if (err != noErr) {
		NSLog(@"%s: Could not get the device UID for device %ld: AudioDeviceGetProperty returned error %ld", __PRETTY_FUNCTION__, (unsigned long)systemOutputDevice, (long)err);
		return NULL;
	}
	[(NSString *)deviceUID autorelease];
	
	return (NSString *)deviceUID;
}

- (void)configureAudioContextForSound:(NSSound *)sound
{
	[sound pause];
	
	//Exchange the audio context for a new one with the new device.
	NSString *deviceUID = [self systemAudioDeviceID];
	
	[sound setPlaybackDeviceIdentifier:deviceUID];
	
	//Resume playback, now on the new device.
	[sound resume];
}

- (NSArray *)allSounds
{
	return [soundCacheDict allValues];
}

/*!
 * @brief Workspace activated (Computer switched to our user)
 */
- (void)workspaceSessionDidBecomeActive:(NSNotification *)notification
{
	[self setSoundsAreMuted:NO];
}

/*!
 * @brief Workspace resigned (Computer switched to another user)
 */
- (void)workspaceSessionDidResignActive:(NSNotification *)notification
{
	[self setSoundsAreMuted:YES];
}

- (void)systemWillSleep:(NSNotification *)notification
{
	[self _stopAndReleaseAllSounds];
}

- (void)setSoundsAreMuted:(BOOL)mute
{
	AILog(@"setSoundsAreMuted: %i",mute);
	if (soundsAreMuted > 0 && !mute)
		soundsAreMuted--;
	else if (mute)
		soundsAreMuted++;

	if (soundsAreMuted == 1)
		[self _stopAndReleaseAllSounds];
}

- (void)systemOutputDeviceDidChange
{
	for (NSSound *sound in [self allSounds]) {
		[self configureAudioContextForSound:sound];
	}
}

@end

static OSStatus systemOutputDeviceDidChange(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void* refcon)
{
#pragma unused(inObjectID)
#pragma unused(inNumberAddresses)
#pragma unused(inAddresses)
	
	@autoreleasepool {
		
		AdiumSound *self = (id)refcon;
		NSCAssert1(self, @"AudioHardware property listener function %s called with nil refcon, which we expected to be the AdiumSound instance", __PRETTY_FUNCTION__);
		
		[self performSelectorOnMainThread:@selector(systemOutputDeviceDidChange)
							   withObject:nil
							waitUntilDone:NO];
		
		return noErr;
	}
}
