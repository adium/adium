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
#ifdef __LP64__
#	import <CoreAudio/AudioHardware.h>
#else
#	import <QTKit/QTKit.h>
#endif
#import <CoreServices/CoreServices.h>
#import <sys/sysctl.h>

#define SOUND_DEFAULT_PREFS				@"SoundPrefs"
#define MAX_CACHED_SOUNDS				4			//Max cached sounds

@interface AdiumSound ()
- (void)_stopAndReleaseAllSounds;
- (void)_setVolumeOfAllSoundsTo:(float)inVolume;
- (void)cachedPlaySound:(NSString *)inPath;
- (void)_uncacheLeastRecentlyUsedSound;
#ifdef __LP64__
- (NSString *)systemAudioDeviceID;
- (void)configureAudioContextForSound:(NSSound *)sound;
#else
- (QTAudioContextRef)createAudioContextWithSystemOutputDevice;
- (void)configureAudioContextForMovie:(QTMovie *)movie;
#endif
- (NSArray *)allSounds;
- (void)workspaceSessionDidBecomeActive:(NSNotification *)notification;
- (void)workspaceSessionDidResignActive:(NSNotification *)notification;
- (void)systemWillSleep:(NSNotification *)notification;
@end

@interface NSProcessInfo (AIProcessorInfoAdditions)
- (BOOL)processorFamilyIsG5;
@end

static OSStatus systemOutputDeviceDidChange(AudioHardwarePropertyID property, void *refcon);

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
		
		/* Sign up for notification when the user changes the system output device in the Sound pane of System Preferences.
		 *
		 * However, we avoid doing this on G5 machines. G5s spew a continuous stream of
		 * kAudioHardwarePropertyDefaultSystemOutputDevice notifications without the device actually changing;
		 * rather than stutter our audio and eat CPU continuously, we just won't try to update.
		 */
		if (![[NSProcessInfo processInfo] processorFamilyIsG5]) {
			OSStatus err = AudioHardwareAddPropertyListener(kAudioHardwarePropertyDefaultSystemOutputDevice, systemOutputDeviceDidChange, /*refcon*/ self);
			if (err != noErr)
				NSLog(@"%s: Couldn't sign up for system-output-device-changed notification, because AudioHardwareAddPropertyListener returned %i. Adium will not know when the default system audio device changes.", __PRETTY_FUNCTION__, err);			
		} else {
			//We won't be updating automatically, so reconfigure before a sound is played again
			reconfigureAudioContextBeforeEachPlay = YES;
		}
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
#ifdef __LP64__
	NSSound *sound = [soundCacheDict objectForKey:inPath];
	if (sound) {
		[sound stop];
	}
#else
    QTMovie *movie = [soundCacheDict objectForKey:inPath];
    if (movie) {
		[movie stop];
	}
#endif
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
 * @brief Play a QTMovie, possibly cached
 * 
 * @param inPath path to the sound file
 */
- (void)cachedPlaySound:(NSString *)inPath
{
#ifdef __LP64__
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
		
		if (reconfigureAudioContextBeforeEachPlay) {
			[sound stop];
			[self configureAudioContextForSound:sound];
		}
    }
	
    //Engage!
    if (sound) {
		//Ensure the sound is starting from the beginning; necessary for cached sounds that have already been played
		[sound setCurrentTime:0.0];
		
		//This only has an effect if the movie is not already playing. It won't stop it, and it won't start it over (the latter is what setCurrentTime: is for).
		[sound play];
    }
#else
    QTMovie *movie = [soundCacheDict objectForKey:inPath];

	//Load the sound if necessary
    if (!movie) {
		//If the cache is full, remove the least recently used cached sound
		if ([soundCacheDict count] >= MAX_CACHED_SOUNDS) {
			[self _uncacheLeastRecentlyUsedSound];
		}

		//Load and cache the sound
		NSError *error = nil;
		movie = [[QTMovie alloc] initWithFile:inPath
		                                error:&error];
		if (movie) {
			//Insert the player at the front of our cache
			[soundCacheArray insertObject:inPath atIndex:0];
			[soundCacheDict setObject:movie forKey:inPath];
			[movie release];

			//Set the volume (otherwise #2283 happens)
			[movie setVolume:customVolume];

			[self configureAudioContextForMovie:movie];
		} else {
			AILogWithSignature(@"Error loading %@: %@", inPath, error);
		}

    } else {
		//Move this sound to the front of the cache (This will naturally move lesser used sounds to the back for removal)
		[soundCacheArray removeObject:inPath];
		[soundCacheArray insertObject:inPath atIndex:0];
		
		if (reconfigureAudioContextBeforeEachPlay) {
			[movie stop];
			[self configureAudioContextForMovie:movie];
		}
    }

    //Engage!
    if (movie) {
		//Ensure the sound is starting from the beginning; necessary for cached sounds that have already been played
		QTTime startOfMovie = {
			.timeValue = 0LL,
			.timeScale = [[movie attributeForKey:QTMovieTimeScaleAttribute] longValue],
			.flags = 0,
		};
		[movie setCurrentTime:startOfMovie];

		//This only has an effect if the movie is not already playing. It won't stop it, and it won't start it over (the latter is what setCurrentTime: is for).
		[movie play];
    }
#endif
}

/*!
 * @brief Remove the least recently used sound from the cache
 */
- (void)_uncacheLeastRecentlyUsedSound
{
	NSString			*lastCachedPath = [soundCacheArray lastObject];
#ifdef __LP64__
	NSSound *sound = [soundCacheDict objectForKey:lastCachedPath];
	
	//Remove it from the cache only if it is not playing.
	if (![sound isPlaying]) {
		[soundCacheDict removeObjectForKey:lastCachedPath];
		[soundCacheArray removeLastObject];
	}
#else
	QTMovie *movie = [soundCacheDict objectForKey:lastCachedPath];

	//If a movie is stopped, then its rate is zero. Thus, this tests whether the movie is playing. We remove it from the cache only if it is not playing.
	if ([movie rate] == 0.0) {
		[soundCacheDict removeObjectForKey:lastCachedPath];
		[soundCacheArray removeLastObject];
	}
#endif
}

#ifndef __LP64__
- (QTAudioContextRef)createAudioContextWithSystemOutputDevice
{
	QTAudioContextRef newAudioContext = NULL;
	OSStatus err;
	UInt32 dataSize;

	//First, obtain the device itself.
	AudioDeviceID systemOutputDevice = 0;
	dataSize = sizeof(systemOutputDevice);
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultSystemOutputDevice, &dataSize, &systemOutputDevice);
	if (err != noErr) {
		NSLog(@"%s: Could not get the system output device: AudioHardwareGetProperty returned error %i", __PRETTY_FUNCTION__, err);
		return NULL;
	}

	//Now get its UID. We'll need to release this.
	CFStringRef deviceUID = NULL;
	dataSize = sizeof(deviceUID);
	err = AudioDeviceGetProperty(systemOutputDevice, /*channel*/ 0, /*isInput*/ false, kAudioDevicePropertyDeviceUID, &dataSize, &deviceUID);
	if (err != noErr) {
		NSLog(@"%s: Could not get the device UID for device %p: AudioDeviceGetProperty returned error %i", __PRETTY_FUNCTION__, systemOutputDevice, err);
		return NULL;
	}
	[(NSObject *)deviceUID autorelease];

	//Create an audio context for this device so that our movies can play into it.
	err = QTAudioContextCreateForAudioDevice(kCFAllocatorDefault, deviceUID, /*options*/ NULL, &newAudioContext);
	if (err != noErr) {
		NSLog(@"%s: QTAudioContextCreateForAudioDevice with device UID %@ returned error %i", __PRETTY_FUNCTION__, deviceUID, err);
		return NULL;
	}

	return newAudioContext;
}

#else

- (NSString *)systemAudioDeviceID
{
	OSStatus err;
	UInt32 dataSize;
	
	//First, obtain the device itself.
	AudioDeviceID systemOutputDevice = 0;
	dataSize = sizeof(systemOutputDevice);
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultSystemOutputDevice, &dataSize, &systemOutputDevice);
	if (err != noErr) {
		NSLog(@"%s: Could not get the system output device: AudioHardwareGetProperty returned error %i", __PRETTY_FUNCTION__, err);
		return NULL;
	}
	
	//Now get its UID. We'll need to release this.
	CFStringRef deviceUID = NULL;
	dataSize = sizeof(deviceUID);
	err = AudioDeviceGetProperty(systemOutputDevice, /*channel*/ 0, /*isInput*/ false, kAudioDevicePropertyDeviceUID, &dataSize, &deviceUID);
	if (err != noErr) {
		NSLog(@"%s: Could not get the device UID for device %u: AudioDeviceGetProperty returned error %i", __PRETTY_FUNCTION__, systemOutputDevice, err);
		return NULL;
	}
	[(NSString *)deviceUID autorelease];
	
	return (NSString *)deviceUID;
}
#endif

#ifdef __LP64__
- (void)configureAudioContextForSound:(NSSound *)sound
{
	[sound pause];
	
	//Exchange the audio context for a new one with the new device.
	NSString *deviceUID = [self systemAudioDeviceID];
	
	[sound setPlaybackDeviceIdentifier:deviceUID];
	
	//Resume playback, now on the new device.
	[sound resume];
}
#else
- (void)configureAudioContextForMovie:(QTMovie *)movie
{
	//QTMovie gets confused if we're playing when we do this, so pause momentarily.
	CGFloat savedRate = [movie rate];
	[movie setRate:0.0f];
	
	//Exchange the audio context for a new one with the new device.
	QTAudioContextRef newAudioContext = [self createAudioContextWithSystemOutputDevice];
	
	if (newAudioContext) {
		OSStatus err = SetMovieAudioContext([movie quickTimeMovie], newAudioContext);
		if (err != noErr) {
			NSLog(@"%s: Could not set audio context of movie %@ to %p: SetMovieAudioContext returned error %i. Sounds may be routed to the default audio device instead of the system alert audio device.", __PRETTY_FUNCTION__, movie, newAudioContext, err);
		}
		
		//We created it, so we must release it.
		QTAudioContextRelease(newAudioContext);
	} else {
		NSLog(@"%s: Could not set audio context because -[AdiumSound createAudioContextWithSystemOutputDevice] returned NULL", __PRETTY_FUNCTION__);
	}
	
	//Resume playback, now on the new device.
	[movie setRate:savedRate];
}
#endif

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
#ifdef __LP64__
	for (NSSound *sound in [self allSounds]) {
		[self configureAudioContextForSound:sound];
	}
#else
	NSEnumerator	*soundsEnum = [[self allSounds] objectEnumerator];
	QTMovie			*movie;

	while ((movie = [soundsEnum nextObject])) {
		[self configureAudioContextForMovie:movie];
	}
#endif
}

@end

static OSStatus systemOutputDeviceDidChange(AudioHardwarePropertyID property, void *refcon)
{
#pragma unused(property)
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	AdiumSound *self = (id)refcon;
	NSCAssert1(self, @"AudioHardware property listener function %s called with nil refcon, which we expected to be the AdiumSound instance", __PRETTY_FUNCTION__);

	[self performSelectorOnMainThread:@selector(systemOutputDeviceDidChange)
						   withObject:nil
						waitUntilDone:NO];
	[pool release];

	return noErr;
}

@implementation NSProcessInfo (AIProcessorInfoAdditions)

- (BOOL)processorFamilyIsG5
{
	/* Credit to http://www.cocoadev.com/index.pl?MacintoshModels */
	BOOL	isG5 = NO;
	char	buffer[128];
	size_t	length = sizeof(buffer);
	if (sysctlbyname("hw.model", &buffer, &length, NULL, 0) == 0) {
		NSString	*hardwareModel = [NSString stringWithUTF8String:buffer];
		NSArray		*knownG5Macs = [NSArray arrayWithObjects:@"PowerMac11,2" /* G5 PCIe */, @"PowerMac12,1" /* iMac G5 (iSight) */, 
									@"PowerMac7,2" /* PowerMac G5 */, @"PowerMac7,3" /* PowerMac G5 */, @"PowerMac8,1" /* iMac G5 */,
									@"PowerMac8,2" /* iMac G5 Ambient Light Sensor */, @"PowerMac9,1" /* Power Mac G5 (Late 2004) */,
									@"RackMac3,1" /* Xserve G5 */, nil];

		if ([knownG5Macs containsObject:hardwareModel]) {
			AILogWithSignature(@"On a G5 Mac.");
			isG5 = YES;
		}
	}
	
	return isG5;
}

@end
