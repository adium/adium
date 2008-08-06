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

#import "AdiumSpeech.h"
#import "AISoundController.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import "SUSpeaker.h"
#import <Adium/AIListObject.h>

#define TEXT_TO_SPEAK			@"Text"
#define VOICE					@"Voice"
#define PITCH					@"Pitch"
#define RATE					@"Rate"

/* Text to Speech  
 * We use SUSpeaker to provide maximum flexibility over speech.  NSSpeechSynthesizer does not gives us pitch/rate controls.  
 * The only significant bug in SUSpeaker is that it does not reset to the system default voice when it is asked to. We  
 * therefore use 2 instances of SUSpeaker: one for default settings, and one for custom settings.  
 */  

@interface AdiumSpeech (PRIVATE)
- (SUSpeaker *)defaultVoice;
- (SUSpeaker *)variableVoice;
- (void)_speakNext;
- (void)_stopSpeaking;
- (SUSpeaker *)_speakerForVoice:(NSString *)voiceString index:(int *)voiceIndex;
- (void)_setVolumeOfVoicesTo:(float)newVolume;
@end

@implementation AdiumSpeech

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		speechArray = [[NSMutableArray alloc] init];
		workspaceSessionIsActive = YES;
		speaking = NO;

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
	}
	
	return self;
}

/*!
 * @brief Load the array of voices
 */
- (void)loadVoices
{
	//Load voices
	//Vicki, a new voice in 10.3, returns an invalid name to SUSpeaker, Vicki3Smallurrent. If we see that name,
	//replace it with just Vicki.  If this gets fixed in a future release of OS X, this code will simply do nothing.
	voiceArray = [[SUSpeaker voiceNames] mutableCopy];
	int messedUpIndex = [voiceArray indexOfObject:@"Vicki3Smallurrent"];
	if (messedUpIndex != NSNotFound) {
		[voiceArray replaceObjectAtIndex:messedUpIndex withObject:@"Vicki"];
	}
}

/*!
 * @brief Close
 */
- (void)dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];

	[self _stopSpeaking];

	[speechArray release]; speechArray = nil;
	if(voiceArray)
	{
		[voiceArray release]; 
		voiceArray = nil;
	}
	
	[super dealloc];
}

/*!
* @brief Finish Initing
 *
 * Requires:
 * 1) Preference controller is ready
 */
- (void)controllerDidLoad
{
	//Observe changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_SOUNDS];	
}

#pragma mark Preferences

/*!
* @brief Preferences changed, adjust to the new values
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	float newVolume = [[prefDict objectForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL] floatValue];
	
	//If sound volume has changed, we must update all existing sounds to the new volume
	if (customVolume != newVolume) {
		[self _setVolumeOfVoicesTo:newVolume];
	}
	
	//Load the new preferences
	customVolume = newVolume;
}

- (void)_setVolumeOfVoicesTo:(float)newVolume
{
	if (_defaultVoice) [_defaultVoice setVolume:newVolume];
	if (_variableVoice) [_variableVoice setVolume:newVolume]; 
}

#pragma mark Speech

/*!
 * @brief Speak text with the default values
 *
 * @param text NSString to speak
 */
- (void)speakText:(NSString *)text
{
    [self speakText:text withVoice:nil pitch:0 rate:0];
}

/*!
 * @brief Speak text with a specific voice, pitch, and rate
 *
 * If text is already being spoken, this text will be queued and spoken at the next available opportunity
 * @param text NSString to speak
 * @param voiceString NSString voice identifier
 * @param pitch Speaking pitch
 * @param rate Speaking rate
 */
- (void)speakText:(NSString *)text withVoice:(NSString *)voiceString pitch:(float)pitch rate:(float)rate
{
    if (text && [text length] && workspaceSessionIsActive) {
		NSMutableDictionary *dict;
		
		dict = [[NSMutableDictionary alloc] init];
		
		if (text) {
			[dict setObject:text forKey:TEXT_TO_SPEAK];
		}
		
		if (voiceString) [dict setObject:voiceString forKey:VOICE];			
		if (pitch > FLT_EPSILON) [dict setObject:[NSNumber numberWithFloat:pitch] forKey:PITCH];
		if (rate  > FLT_EPSILON) [dict setObject:[NSNumber numberWithFloat:rate]  forKey:RATE];
		AILog(@"AdiumSpeech: %@",dict);
		[speechArray addObject:dict];
		[dict release];
		
		[self _speakNext];
    }
}

/*!
 * @brief Speak a voice-specific sample text at the passed settings
 *
 * @param voiceString NSString voice identifier
 * @param pitch Speaking pitch
 * @param rate Speaking rate
 */
- (void)speakDemoTextForVoice:(NSString *)voiceString withPitch:(float)pitch andRate:(float)rate
{
	if(workspaceSessionIsActive){
		int			voiceIndex;
		SUSpeaker	*theSpeaker = [self _speakerForVoice:voiceString index:&voiceIndex];
		NSString	*demoText = [theSpeaker demoTextForVoiceAtIndex:((voiceIndex != NSNotFound) ? voiceIndex : -1)];
		
		[self _stopSpeaking];
		[self speakText:demoText withVoice:voiceString pitch:pitch rate:rate];
	}
}


//Voices ---------------------------------------------------------------------------------------------------------------
#pragma mark Voices
/*!
 * @brief Returns an array of available voices
 */
- (NSArray *)voices
{
	if(!voiceArray) [self loadVoices];
    return voiceArray;
}

/*!
 * @brief Returns the systemwide default rate
 */
- (float)defaultRate
{
	if (!_defaultRate) { //Cache this, since the calculation may be slow
		_defaultRate = [[self defaultVoice] rate];
	}
	return _defaultRate;
}

/*!
 * @brief Returns the systemwide default pitch
 */
- (float)defaultPitch
{ 
	if (!_defaultPitch) { //Cache this, since the calculation may be slow
		_defaultPitch = [[self defaultVoice] pitch];
	}
	return _defaultPitch;
}

/*!
 * @brief Returns the default voice, creating if necessary
 */
- (SUSpeaker *)defaultVoice
{
    if (!_defaultVoice) {
		_defaultVoice = [[SUSpeaker alloc] init];
		[_defaultVoice setDelegate:self];
		[_defaultVoice setVolume:customVolume];
    }
	return _defaultVoice;
}

/*!
 * @brief Returns the variable voice, creating if necessary
 */
- (SUSpeaker *)variableVoice
{
    if (!_variableVoice) {
		_variableVoice = [[SUSpeaker alloc] init];
		[_variableVoice setDelegate:self];
		[_variableVoice setVolume:customVolume];
    }
	return _variableVoice;
}


//Speaking -------------------------------------------------------------------------------------------------------------
#pragma mark Speaking
/*!
 * @brief Attempt to speak the next item in the queue
 */
- (void)_speakNext
{
    //we have items left to speak and aren't already speaking
    if ([speechArray count] && !speaking) {
		//Don't speak on top of other apps; instead, wait 1 second and try again
		if (SpeechBusySystemWide() > 0) {
			[self performSelector:@selector(_speakNext)
					   withObject:nil
					   afterDelay:1.0];
		} else {			
			speaking = YES;

			//Speak the next entry in our queue
			NSMutableDictionary *dict = [speechArray objectAtIndex:0];
			NSString 			*text = [dict objectForKey:TEXT_TO_SPEAK];
			NSNumber 			*pitchNumber = [dict objectForKey:PITCH];
			NSNumber 			*rateNumber = [dict objectForKey:RATE];
			SUSpeaker 			*theSpeaker = [self _speakerForVoice:[dict objectForKey:VOICE] index:NULL];

			[theSpeaker setPitch:(pitchNumber ? [pitchNumber floatValue] : [self defaultPitch])];
			[theSpeaker setRate:  (rateNumber ?  [rateNumber floatValue] : [self defaultRate])];
			[theSpeaker setVolume:customVolume];

			[theSpeaker speakText:text];
			[speechArray removeObjectAtIndex:0];
		}
	}
}

/*!
 * @brief Speaking has finished, begin speaking the next item in our queue
 */
- (IBAction)didFinishSpeaking:(SUSpeaker *)theSpeaker
{
	speaking = NO;
    [self _speakNext];
}

/*!
 * @brief Immediately stop speaking
 */
- (void)_stopSpeaking
{
	[speechArray removeAllObjects];

	[_defaultVoice stopSpeaking];
	[_variableVoice stopSpeaking];
}

/*!
 * @brief Return the SUSpeaker which should be used for a given voice name, configured for that voice.
 * Optionally, return the index of that voice in our array by reference.
 */
- (SUSpeaker *)_speakerForVoice:(NSString *)voiceString index:(int *)voiceIndex
{
	SUSpeaker	*speaker;
	int 		theIndex;
	if(voiceString)
	{
		if(!voiceArray) [self loadVoices];
		theIndex = [voiceArray indexOfObject:voiceString];
	}
	else
		theIndex = NSNotFound;

	//Return the voice index by reference
	if (voiceIndex) *voiceIndex = theIndex;

	//Configure and return the voice
	if (theIndex != NSNotFound) {
		speaker = [self variableVoice];
		[speaker setVoiceUsingIndex:theIndex];		
	} else {
		speaker = [self defaultVoice];
	}
	
	return speaker;
}


//Misc -----------------------------------------------------------------------------------------------------------------
#pragma mark Misc
/*!
 * @brief Workspace activated (Computer switched to our user)
 */
- (void)workspaceSessionDidBecomeActive:(NSNotification *)notification
{
	workspaceSessionIsActive = YES;
}

/*!
 * @brief Workspace resigned (Computer switched to another user)
 */
- (void)workspaceSessionDidResignActive:(NSNotification *)notification
{
	workspaceSessionIsActive = NO;
	[self _stopSpeaking];	
}

@end
