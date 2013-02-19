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

#import "AISoundController.h"
#import "ESAnnouncerAbstractDetailPane.h"
#import "ESAnnouncerPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>

@interface ESAnnouncerAbstractDetailPane ()
- (NSMenu *)voicesMenu;
@end

/*!
 * @class ESAnnouncerAbstractDetailPane
 * @brief Abstract superclass for Announcer action (Speak Event and Speak Text) detail panes
 */
@implementation ESAnnouncerAbstractDetailPane

/*!
 * @brief View did load
 */
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[checkBox_speakEventTime setTitle:SPEAK_EVENT_TIME];
	[checkBox_speakContactName setLocalizedString:AILocalizedString(@"Speak Name",nil)];
	[checkBox_customPitch setLocalizedString:AILocalizedString(@"Use custom pitch:",nil)];
	[checkBox_customRate setLocalizedString:AILocalizedString(@"Use custom rate:",nil)];
	[label_voice setLocalizedString:AILocalizedString(@"Voice:", nil)];
	
	[popUp_voices setMenu:[self voicesMenu]];
}

/*!
 * @brief Configure for the action
 */
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	BOOL		speakTime, speakContactName;
	NSString	*voice;
	NSNumber	*pitchNumber, *rateNumber;

	if (!inDetails) inDetails = [adium.preferenceController preferenceForKey:[self defaultDetailsKey]
																		group:PREF_GROUP_ANNOUNCER];

	speakTime = [[inDetails objectForKey:KEY_ANNOUNCER_TIME] boolValue];
	speakContactName = [[inDetails objectForKey:KEY_ANNOUNCER_SENDER] boolValue];

	if ((voice = [inDetails objectForKey:KEY_VOICE_STRING])) {
		[popUp_voices selectItemWithRepresentedObject:voice];
	} else {
		[popUp_voices selectItemAtIndex:0]; //"Default"
	}

	if ((pitchNumber = [inDetails objectForKey:KEY_PITCH])) {
		[slider_pitch setFloatValue:[pitchNumber floatValue]];
	} else {
		[slider_pitch setFloatValue:[adium.soundController defaultPitch]];
	}
	
	[checkBox_customPitch setState:[[inDetails objectForKey:KEY_PITCH_CUSTOM] boolValue]];
	
	if ((rateNumber = [inDetails objectForKey:KEY_RATE])) {
		[slider_rate setFloatValue:[rateNumber floatValue]];
	} else {
		[slider_rate setFloatValue:[adium.soundController defaultRate]];
	}

	[checkBox_customRate setState:[[inDetails objectForKey:KEY_RATE_CUSTOM] boolValue]];

	[checkBox_speakEventTime setState:speakTime];
	[checkBox_speakContactName setState:speakContactName];
	
	[self configureControlDimming];
}

- (void)configureControlDimming
{
	[super configureControlDimming];
	
	[slider_rate setEnabled:[checkBox_customRate state]];
	[slider_pitch setEnabled:[checkBox_customPitch state]];
}

/*!
 * @brief Configure controls specially for message events.
 *
 * Speaking of the name is only disable-able for message events.
 */
- (void)configureForEventID:(NSString *)eventID listObject:(AIListObject *)inObject
{
	if ([adium.contactAlertsController isMessageEvent:eventID]) {
		[checkBox_speakContactName setEnabled:YES];
	} else {
		[checkBox_speakContactName setEnabled:NO];
		[checkBox_speakContactName setState:NSOnState];
	}
}

/*!
 * @brief Return action details
 *
 * Should be overridden, with the subclass returning [self actionDetailsDromDict:actionDetails]
 * where actionDetails is the dictionary of what it itself needs to store
 */
- (NSDictionary *)actionDetails
{
	NSDictionary	*actionDetails = [self actionDetailsFromDict:nil];

	//Save the preferred settings for future use as defaults
	[adium.preferenceController setPreference:actionDetails
										 forKey:[self defaultDetailsKey]
										  group:PREF_GROUP_ANNOUNCER];

	return actionDetails;
}

/*!
 * @brief Used by subclasses; adds the general information managed by the superclass to the details dictionary.
 */
- (NSDictionary *)actionDetailsFromDict:(NSMutableDictionary *)actionDetails
{
	NSNumber		*speakTime, *speakContactName, *pitch, *rate;
	NSString		*voice;

	if (!actionDetails) actionDetails = [NSMutableDictionary dictionary];

	speakTime = [NSNumber numberWithBool:([checkBox_speakEventTime state] == NSOnState)];
	speakContactName = [NSNumber numberWithBool:([checkBox_speakContactName state] == NSOnState)];

	voice = [[popUp_voices selectedItem] representedObject];	
	pitch = [NSNumber numberWithFloat:[slider_pitch floatValue]];
	rate = [NSNumber numberWithFloat:[slider_rate floatValue]];
	
	if (voice) {
		[actionDetails setObject:voice
						  forKey:KEY_VOICE_STRING];
	}

	if ([pitch floatValue] != [adium.soundController defaultPitch]) {
		[actionDetails setObject:pitch
						  forKey:KEY_PITCH];
	}
	
	if ([rate floatValue] != [adium.soundController defaultRate]) {
		[actionDetails setObject:rate
						  forKey:KEY_RATE];
	}
	[actionDetails setObject:[NSNumber numberWithBool:[checkBox_customRate state]]
					  forKey:KEY_RATE_CUSTOM];
	[actionDetails setObject:[NSNumber numberWithBool:[checkBox_customPitch state]]
					  forKey:KEY_PITCH_CUSTOM];
	
	[actionDetails setObject:speakTime
					  forKey:KEY_ANNOUNCER_TIME];
	[actionDetails setObject:speakContactName
					  forKey:KEY_ANNOUNCER_SENDER];
	
	return actionDetails;
}

/*!
 * @brief Key on which to store our defaults
 *
 * Must be overridden by subclasses
 */
- (NSString *)defaultDetailsKey
{
	return nil;
}

/*!
 * @brief Speech voices menu
 */
- (NSMenu *)voicesMenu
{
	NSMenu			*voicesMenu = [[NSMenu alloc] init];
	
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Use System Default",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[voicesMenu addItem:menuItem];
	[voicesMenu addItem:[NSMenuItem separatorItem]];

	NSMutableDictionary *voices = [NSMutableDictionary dictionary];
	NSArray *rawVoices = [[NSSpeechSynthesizer availableVoices] sortedArrayUsingSelector:@selector(compare:)];
	for (NSString *voiceID in rawVoices) {
		[voices setObject:[[NSSpeechSynthesizer attributesForVoice:voiceID] objectForKey:NSVoiceName] forKey:voiceID];
	}
	for (NSString *voiceID in rawVoices) {
		menuItem = [[NSMenuItem alloc] initWithTitle:[voices objectForKey:voiceID]
																					  target:nil
																					  action:nil
																			   keyEquivalent:@""];
		[menuItem setRepresentedObject:voiceID];
		[voicesMenu addItem:menuItem];
	}
	
	return voicesMenu;
}

/*!
 * @brief Preference changed
 */
-(IBAction)changePreference:(id)sender
{
	NSString *voice = [[popUp_voices selectedItem] representedObject];
	//If the Default voice is selected, also set the pitch and rate to defaults
	if (sender == popUp_voices) {
		if (!voice) {
			[slider_pitch setFloatValue:[adium.soundController defaultPitch]];
			[slider_rate setFloatValue:[adium.soundController defaultRate]];
			voice = [NSSpeechSynthesizer defaultVoice];
		}
	}

	if (sender == popUp_voices ||
	   (sender == slider_pitch || sender == checkBox_customPitch) ||
	   (sender == slider_rate ||  sender == checkBox_customRate)) {
		[adium.soundController speakDemoTextForVoice:voice
											 withPitch:([checkBox_customPitch state] ? [slider_pitch floatValue] : 0.0f)
											   andRate:([checkBox_customRate state] ? [slider_rate floatValue] : 0.0f)];
	}
	
	[super changePreference:sender];
}

@end
