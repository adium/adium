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
#import <sys/sysctl.h>

#define SOUND_DEFAULT_PREFS				@"SoundPrefs"

@interface AdiumSound ()
@property (readonly, nonatomic) NSString *systemAudioDeviceID;
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
		currentlyPlayingSounds = [[NSMutableSet alloc] init];
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

	[currentlyPlayingSounds release]; currentlyPlayingSounds = nil;

	[super dealloc];
}

/*!
 * @brief Preferences changed, adjust to the new values
 */
- (void)preferencesChangedForGroup:(NSString *)group 
							   key:(NSString *)key
							object:(AIListObject *)object 
					preferenceDict:(NSDictionary *)prefDict 
						 firstTime:(BOOL)firstTime
{
	CGFloat newVolume = [[prefDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] doubleValue];

	for (NSSound *sound in currentlyPlayingSounds) {
		[sound setVolume:newVolume];
	}

	//Load the new preferences
	customVolume = newVolume;
}

/*!
 * @brief Stop and release all cached sounds
 */
- (void)stopCurrentlyPlayingSounds
{
	[currentlyPlayingSounds removeAllObjects];
}

/*!
 * @brief Play an NSSound, possibly cached
 * 
 * @param inURL file url to the sound file
 */
- (void)playSoundAtURL:(NSURL *)inURL
{
	if (!inURL || customVolume == 0.0 || soundsAreMuted > 0)
		return;

	//Load the sound
	NSSound *sound = [[[NSSound alloc] initWithContentsOfURL:inURL byReference:YES] autorelease];

	//Engage!
	if (sound) {
		[sound setVolume:customVolume];
		[sound setPlaybackDeviceIdentifier:self.systemAudioDeviceID];
		[currentlyPlayingSounds addObject:sound];
		[sound setDelegate:self];
		[sound setCurrentTime:0.0];
		[sound play];
	}
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finishedPlaying
{
	[currentlyPlayingSounds removeObject:sound];
}

- (NSString *)systemAudioDeviceID
{
	if (reconfigureAudioContextBeforeEachPlay) {
		[outputDeviceUID release];
		outputDeviceUID = nil;
	}
	if (!outputDeviceUID) {
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
		outputDeviceUID = (NSString *)deviceUID;
	}
	
	
	return outputDeviceUID;
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
	[self stopCurrentlyPlayingSounds];
}

- (void)setSoundsAreMuted:(BOOL)mute
{
	AILog(@"setSoundsAreMuted: %i",mute);
	if (soundsAreMuted > 0 && !mute)
		soundsAreMuted--;
	else if (mute)
		soundsAreMuted++;

	if (soundsAreMuted == 1)
		[self stopCurrentlyPlayingSounds];
}

- (void)systemOutputDeviceDidChange
{
	[outputDeviceUID release]; outputDeviceUID = nil; //clear our cache
	for (NSSound *sound in currentlyPlayingSounds) {
		[sound pause];
		[sound setPlaybackDeviceIdentifier:self.systemAudioDeviceID];
		[sound resume];
	}
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
