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
#import <Adium/AIListObject.h>

#define TEXT_TO_SPEAK			@"Text"
#define VOICE					@"Voice"
#define PITCH					@"Pitch"
#define RATE					@"Rate"

@interface AdiumSpeech ()
- (NSSpeechSynthesizer *)defaultVoice;
- (NSSpeechSynthesizer *)variableVoice;
- (void)_speakNext;
- (void)_stopSpeaking;
- (void)_setVolumeOfVoicesTo:(float)newVolume;
- (void)workspaceSessionDidBecomeActive:(NSNotification *)notification;
- (void)workspaceSessionDidResignActive:(NSNotification *)notification;
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
 * @brief Close
 */
- (void)dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];

	[speechArray release]; speechArray = nil;
	[self _stopSpeaking];
	
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
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_SOUNDS];	
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
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		
		if (text) {
			[dict setObject:text forKey:TEXT_TO_SPEAK];
		}
		
		if (voiceString) [dict setObject:voiceString forKey:VOICE];			
		if (pitch > FLT_EPSILON) [dict setObject:[NSNumber numberWithDouble:pitch] forKey:PITCH];
		if (rate  > FLT_EPSILON) [dict setObject:[NSNumber numberWithDouble:rate]  forKey:RATE];
		AILog(@"AdiumSpeech: %@",dict);
		[speechArray addObject:dict];
		
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
	if(workspaceSessionIsActive) {		
		[self _stopSpeaking];
		[self speakText:[[NSSpeechSynthesizer attributesForVoice:voiceString] objectForKey:NSVoiceDemoText] withVoice:voiceString pitch:pitch rate:rate];
	}
}


//Voices ---------------------------------------------------------------------------------------------------------------
#pragma mark Voices

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
		NSNumber *pitchNumber = [[self defaultVoice] objectForProperty:NSSpeechPitchBaseProperty error:NULL];
		if (pitchNumber) {
			_defaultPitch = [pitchNumber floatValue];
		} else {
			NSLog(@"Couldn't get a pitch from the default voice. How strange.");
			_defaultPitch = 0.0f;
		}
	}
	return _defaultPitch;
}

/*!
 * @brief Returns the default voice, creating if necessary
 */
- (NSSpeechSynthesizer *)defaultVoice
{
	if (!_defaultVoice) {
		_defaultVoice = [[NSSpeechSynthesizer alloc] init];
		[_defaultVoice setDelegate:self];
		[_defaultVoice setVolume:customVolume];
	}
	return _defaultVoice;
}

/*!
 * @brief Returns the variable voice, creating if necessary
 */
- (NSSpeechSynthesizer *)variableVoice
{
	if (!_variableVoice) {
		_variableVoice = [[NSSpeechSynthesizer alloc] init];
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
		if ([NSSpeechSynthesizer isAnyApplicationSpeaking]) {
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
			NSSpeechSynthesizer *theSpeaker = [self variableVoice];
			[theSpeaker setVoice:[dict objectForKey:VOICE]];

			if (!pitchNumber)
				pitchNumber = [NSNumber numberWithFloat:[self defaultPitch]];
			[theSpeaker setObject:pitchNumber forProperty:NSSpeechPitchBaseProperty error:NULL];
			[theSpeaker setRate:(rateNumber ?  [rateNumber floatValue] : [self defaultRate])];
			[theSpeaker setVolume:customVolume];

			[theSpeaker startSpeakingString:text];
			[speechArray removeObjectAtIndex:0];
		}
	}
}

/*!
 * @brief Speaking has finished, begin speaking the next item in our queue
 */
- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
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
