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
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AILocalizationButton.h>

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
        [popUp_voices selectItemWithTitle:voice];
    } else {
        [popUp_voices selectItemAtIndex:0]; //"Default"
    }
	
    if ((pitchNumber = [inDetails objectForKey:KEY_PITCH])) {
		[slider_pitch setDoubleValue:[pitchNumber doubleValue]];
    } else {
		[slider_pitch setDoubleValue:[adium.soundController defaultPitch]];
    }
	
	[checkBox_customPitch setState:[[inDetails objectForKey:KEY_PITCH_CUSTOM] boolValue]];
	
    if ((rateNumber = [inDetails objectForKey:KEY_RATE])) {
		[slider_rate setDoubleValue:[rateNumber doubleValue]];
    } else {
		[slider_rate setDoubleValue:[adium.soundController defaultRate]];
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
	pitch = [NSNumber numberWithDouble:[slider_pitch doubleValue]];
	rate = [NSNumber numberWithDouble:[slider_rate doubleValue]];
	
	if (voice) {
		[actionDetails setObject:voice
						  forKey:KEY_VOICE_STRING];
	}

	if ([pitch doubleValue] != [adium.soundController defaultPitch]) {
		[actionDetails setObject:pitch
						  forKey:KEY_PITCH];
	}
	
	if ([rate doubleValue] != [adium.soundController defaultRate]) {
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
	NSArray			*voicesArray;
	NSMenu			*voicesMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSMenuItem		*menuItem;
	NSString		*voice;
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Use System Default",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[voicesMenu addItem:menuItem];
	[voicesMenu addItem:[NSMenuItem separatorItem]];

	voicesArray = [[adium.soundController voices] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	for (voice in voicesArray) {
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:voice
																					  target:nil
																					  action:nil
																			   keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:voice];
		[voicesMenu addItem:menuItem];
	}
	
	return voicesMenu;
}

/*!
 * @brief Preference changed
 */
-(IBAction)changePreference:(id)sender
{
	//If the Default voice is selected, also set the pitch and rate to defaults
	if (sender == popUp_voices) {
		if (![[popUp_voices selectedItem] representedObject]) {
			[slider_pitch setDoubleValue:[adium.soundController defaultPitch]];
			[slider_rate setDoubleValue:[adium.soundController defaultRate]];
		}
	}

	if (sender == popUp_voices ||
	   (sender == slider_pitch || sender == checkBox_customPitch) ||
	   (sender == slider_rate ||  sender == checkBox_customRate)) {
		[adium.soundController speakDemoTextForVoice:[[popUp_voices selectedItem] representedObject]
											 withPitch:([checkBox_customPitch state] ? [slider_pitch doubleValue] : 0.0)
											   andRate:([checkBox_customRate state] ? [slider_rate doubleValue] : 0.0)];
	}
	
	[super changePreference:sender];
}

@end
