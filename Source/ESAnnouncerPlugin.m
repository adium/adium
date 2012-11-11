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
#import "ESAnnouncerPlugin.h"
#import "ESAnnouncerSpeakEventAlertDetailPane.h"
#import "ESAnnouncerSpeakTextAlertDetailPane.h"
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListObject.h>

#define	CONTACT_ANNOUNCER_NIB		@"ContactAnnouncer"		//Filename of the announcer info view
#define ANNOUNCER_ALERT_SHORT		AILocalizedString(@"Speak Specific Text",nil)
#define ANNOUNCER_ALERT_LONG		AILocalizedString(@"Speak the text \"%@\"",nil)

#define	ANNOUNCER_EVENT_ALERT_SHORT	AILocalizedString(@"Speak Event","short phrase for the contact alert which speaks the event")
#define	ANNOUNCER_EVENT_ALERT_LONG	AILocalizedString(@"Speak the event aloud","short phrase for the contact alert which speaks the event")

/*!
 * @class ESAnnouncerPlugin
 * @brief Component which provides Speak Event and Speak Text actions
 */
@implementation ESAnnouncerPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //Install our contact alerts
	[adium.contactAlertsController registerActionID:SPEAK_TEXT_ALERT_IDENTIFIER
										  withHandler:self];
	[adium.contactAlertsController registerActionID:SPEAK_EVENT_ALERT_IDENTIFIER
										  withHandler:self];
    
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:ANNOUNCER_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_ANNOUNCER];
	
    lastSenderString = nil;
}

/*!
 * @brief Short description
 * @result A short localized description of the action
 */
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	if ([actionID isEqualToString:SPEAK_TEXT_ALERT_IDENTIFIER]) {
		return ANNOUNCER_ALERT_SHORT;
	} else { /*Speak Event*/
		return ANNOUNCER_EVENT_ALERT_SHORT;
	}
}

/*!
 * @brief Long description
 * @result A longer localized description of the action which should take into account the details dictionary as appropraite.
 */
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	if ([actionID isEqualToString:SPEAK_TEXT_ALERT_IDENTIFIER]) {		
		NSString *textToSpeak = [details objectForKey:KEY_ANNOUNCER_TEXT_TO_SPEAK];
		
		if (textToSpeak && [textToSpeak length]) {
			return [NSString stringWithFormat:ANNOUNCER_ALERT_LONG, textToSpeak];
		} else {
			return ANNOUNCER_ALERT_SHORT;
		}
	} else { /*Speak Event*/
		return ANNOUNCER_EVENT_ALERT_LONG;
	}
}

/*!
 * @brief Image
 */
- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"events-announcer-alert" forClass:[self class]];
}

/*!
 * @brief Details pane
 * @result An <tt>AIActionDetailsPane</tt> to use for configuring this action, or nil if no configuration is possible.
 */
- (AIActionDetailsPane *)detailsPaneForActionID:(NSString *)actionID
{
	if ([actionID isEqualToString:SPEAK_TEXT_ALERT_IDENTIFIER]) {
		return [ESAnnouncerSpeakTextAlertDetailPane actionDetailsPane];
	} else { /*Speak Event*/
		return [ESAnnouncerSpeakEventAlertDetailPane actionDetailsPane];
	}
}

/*!
 * @brief Perform an action
 *
 * @param actionID The ID of the action to perform
 * @param listObject The listObject associated with the event triggering the action. It may be nil
 * @param details If set by the details pane when the action was created, the details dictionary for this particular action
 * @param eventID The eventID which triggered this action
 * @param userInfo Additional information associated with the event; userInfo's type will vary with the actionID.
 */
- (BOOL)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	NSString			*textToSpeak = nil;

	//Do nothing if sounds are muted for this object
	if ([listObject soundsAreMuted]) return NO;

	if ([actionID isEqualToString:SPEAK_TEXT_ALERT_IDENTIFIER]) {
		NSMutableString	*userText = [[details objectForKey:KEY_ANNOUNCER_TEXT_TO_SPEAK] mutableCopy];
		
		if ([userText rangeOfString:@"%n"].location != NSNotFound) {
			NSString	*replacementText = listObject.formattedUID;
			
			[userText replaceOccurrencesOfString:@"%n"
									  withString:(replacementText ? replacementText : @"")
										 options:NSLiteralSearch 
										   range:NSMakeRange(0,[userText length])];
		}
		
		if ([userText rangeOfString:@"%a"].location != NSNotFound) {
			NSString	*replacementText = [listObject phoneticName];
			
			[userText replaceOccurrencesOfString:@"%a"
									  withString:(replacementText ? replacementText : @"")
										 options:NSLiteralSearch 
										   range:NSMakeRange(0,[userText length])];
			
		}
		
		if ([userText rangeOfString:@"%t"].location != NSNotFound) {			
			[NSDateFormatter withLocalizedDateFormatterShowingSeconds:YES showingAMorPM:NO perform:^(NSDateFormatter *timeFormatter){
				[userText replaceOccurrencesOfString:@"%t"
										  withString:[timeFormatter stringFromDate:[NSDate date]]
											 options:NSLiteralSearch 
											   range:NSMakeRange(0,[userText length])];
			}];
			
		}
		
		
		if ([userText rangeOfString:@"%m"].location != NSNotFound) {
			NSString			*message;
			
			if ([adium.contactAlertsController isMessageEvent:eventID] &&
				[userInfo objectForKey:@"AIContentObject"]) {
				AIContentMessage	*content = [userInfo objectForKey:@"AIContentObject"];
				message = [[[content message] attributedStringByConvertingAttachmentsToStrings] string];
				
			} else {
				message = [adium.contactAlertsController naturalLanguageDescriptionForEventID:eventID
																					 listObject:listObject
																					   userInfo:userInfo
																				 includeSubject:NO];
			}
			
			[userText replaceOccurrencesOfString:@"%m"
									  withString:(message ? message : @"")
										 options:NSLiteralSearch 
										   range:NSMakeRange(0,[userText length])];				
		}
		
		textToSpeak = userText;
		
		//Clear out the lastSenderString so the next Speak Event action will get tagged with the sender's name
		lastSenderString = nil;
		
	} else { /*Speak Event*/	
		BOOL			speakSender = [[details objectForKey:KEY_ANNOUNCER_SENDER] boolValue];
		BOOL			speakTime = [[details objectForKey:KEY_ANNOUNCER_TIME] boolValue];
		
		//Handle messages in a custom manner
		if ([adium.contactAlertsController isMessageEvent:eventID] &&
			[userInfo objectForKey:@"AIContentObject"]) {
			AIContentMessage	*content = [userInfo objectForKey:@"AIContentObject"];
			NSString			*message = [[[content message] attributedStringByConvertingAttachmentsToStrings] string];
			AIListObject		*source = [content source];
			BOOL				isOutgoing = [content isOutgoing];
			BOOL				newParagraph = NO;
			NSMutableString		*theMessage = [NSMutableString string];
			
			if (speakSender && !isOutgoing) {
				NSString	*senderString;
				
				//Get the sender string
				senderString = [source phoneticName];
				
				//Don't repeat the same sender string for messages twice in a row
				if (!lastSenderString || ![senderString isEqualToString:lastSenderString]) {
					NSMutableString		*senderStringToSpeak;
					
					//Track the sender string before modifications
					lastSenderString = senderString;
					
					senderStringToSpeak = [senderString mutableCopy];
					
					//deemphasize all words after first in sender's name, approximating human name pronunciation better
					[senderStringToSpeak replaceOccurrencesOfString:@" " 
														 withString:@" [[emph -]] " 
															options:NSCaseInsensitiveSearch
															  range:NSMakeRange(0, [senderStringToSpeak length])];
					//emphasize first word in sender's name
					[theMessage appendFormat:@"[[emph +]] %@...",senderStringToSpeak];
					newParagraph = YES;
				}
			}
			
			//Append the date if desired, after the sender name if that was added
			if (speakTime) {
				[NSDateFormatter withLocalizedDateFormatterShowingSeconds:YES showingAMorPM:NO perform:^(NSDateFormatter *timeFormatter){
					[theMessage appendFormat:@" %@...", [timeFormatter stringFromDate:[content date]]];
				}];
			}
			
			if (newParagraph) [theMessage appendFormat:@" [[pmod +1; pbas +1]]"];
			
			//Finally, append the actual message
			[theMessage appendFormat:@" %@",message];
			
			//theMessage is now the final string which will be passed to the speech engine
			textToSpeak = theMessage;
			
		} else {
			//All non-message events use the normal naturalLanguageDescription methods, optionally prepending
			//the time
			NSString	*eventDescription;
			
			eventDescription = [adium.contactAlertsController naturalLanguageDescriptionForEventID:eventID
																						  listObject:listObject
																							userInfo:userInfo
																					  includeSubject:YES];
			
			if (speakTime) {
				__block NSString	*timeString;
				
				[NSDateFormatter withLocalizedDateFormatterShowingSeconds:YES showingAMorPM:NO perform:^(NSDateFormatter *timeFormatter){
					timeString = [NSString stringWithFormat:@"%@... ", [timeFormatter stringFromDate:[NSDate date]]];
				}];
				
				textToSpeak = [timeString stringByAppendingString:eventDescription];
			} else {
				textToSpeak = eventDescription;
			}
			
			//Clear out the lastSenderString so the next speech event will get tagged with the sender's name
			lastSenderString = nil;
		}
	}
	
	//Do the speech, with custom voice/pitch/rate as desired
	if (textToSpeak) {
		NSNumber	*pitchNumber = nil, *rateNumber = nil;
		NSNumber	*customPitch, *customRate;
		
		if ((customPitch = [details objectForKey:KEY_PITCH_CUSTOM]) &&
			([customPitch boolValue])) {
			pitchNumber = [details objectForKey:KEY_PITCH];
		}
		
		if ((customRate = [details objectForKey:KEY_RATE_CUSTOM]) &&
			([customRate boolValue])) {
			rateNumber = [details objectForKey:KEY_RATE];
		}
		
		[adium.soundController speakText:textToSpeak
								 withVoice:[details objectForKey:KEY_VOICE_STRING]
									 pitch:(pitchNumber ? [pitchNumber floatValue] : 0.0f)
									  rate:(rateNumber ? [rateNumber floatValue] : 0.0f)];
	}
	
	return (textToSpeak != nil);
}

/*!
 * @brief Allow multiple actions?
 *
 * If this method returns YES, every one of this action associated with the triggering event will be executed.
 * If this method returns NO, only the first will be.
 *
 * These are sound-based actions, so only allow one.
 */
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

@end
