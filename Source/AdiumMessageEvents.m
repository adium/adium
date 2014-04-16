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

#import "AdiumMessageEvents.h"
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListGroup.h>

@interface AdiumMessageEvents()
- (NSString *)stringFromMessageAttributedString:(NSAttributedString *)attributedString;
@end

@implementation AdiumMessageEvents

- (id)init
{
	if ((self = [super init])) {
		//Empty
	}
	
	return self;
}

//Requires contactAlertController loaded
- (void)controllerDidLoad
{
	//Register the events we generate
	[adium.contactAlertsController registerEventID:CONTENT_MESSAGE_SENT withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTENT_MESSAGE_SENT_GROUP withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTENT_MESSAGE_RECEIVED withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTENT_MESSAGE_RECEIVED_FIRST withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTENT_MESSAGE_RECEIVED_BACKGROUND withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTENT_MESSAGE_RECEIVED_GROUP withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTENT_MESSAGE_RECEIVED_BACKGROUND_GROUP withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTENT_MESSAGE_RECEIVED_AWAY withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
    [adium.contactAlertsController registerEventID:CONTENT_MESSAGE_RECEIVED_AWAY_GROUP withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTENT_GROUP_CHAT_MENTION withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	
	//Observe chat changes
	[adium.chatController registerChatObserver:self];
}

- (void)dealloc
{
	[adium.chatController unregisterChatObserver:self];
	
	[super dealloc];
}

#pragma mark Message event handling
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if (inModifiedKeys == nil ||
		[inModifiedKeys containsObject:KEY_CHAT_TIMED_OUT] ||
		[inModifiedKeys containsObject:KEY_CHAT_CLOSED_WINDOW] ||
		[inModifiedKeys containsObject:KEY_CHAT_ERROR]) {
		
		NSString		*message = nil;
		NSString		*type = nil;
		AIListContact	*listObject = [inChat listObject];
		
		if ([inChat valueForProperty:KEY_CHAT_ERROR] != nil) {
			
			AIChatErrorType errorType = [inChat intValueForProperty:KEY_CHAT_ERROR];
			type = @"chat-error";
			
			switch (errorType) {
				case AIChatUnknownError:
					message = AILocalizedString(@"Unknown conversation error.",nil);
					break;
					
				case AIChatMessageSendingUserNotAvailable:
					message = [NSString stringWithFormat:AILocalizedString(@"Could not send because %@ is not available.",nil),listObject.formattedUID];
					break;
					
				case AIChatMessageSendingUserIsBlocked:
					message = [NSString stringWithFormat:AILocalizedString(@"Could not send because %@ is blocked.",nil),listObject.formattedUID];
					break;
					
				case AIChatMessageSendingTooLarge:
					message = AILocalizedString(@"Could not send the last message because it was too large.",nil);
					break;
					
				case AIChatMessageSendingTimeOutOccurred:
					message = AILocalizedString(@"A message may not have been sent; a timeout occurred.",nil);
					break;
					
				case AIChatMessageSendingMissedRateLimitExceeded:
					message = AILocalizedString(@"Could not send the last message because the rate limit has been exceeded. Please wait a moment and then try again.",nil);
					break;

				case AIChatMessageReceivingMissedTooLarge:
					message = AILocalizedString(@"Could not receive the last message because it was too large.",nil);
					break;
					
				case AIChatMessageReceivingMissedInvalid:
					message = AILocalizedString(@"Could not receive the last message because it was invalid.",nil);
					break;
					
				case AIChatMessageReceivingMissedRateLimitExceeded:
					message = AILocalizedString(@"Could not receive the last message because the rate limit has been exceeded. Please wait a moment and then try again.",nil);
					break;
					
				case AIChatMessageReceivingMissedRemoteIsTooEvil:
					message = [NSString stringWithFormat:AILocalizedString(@"Could not receive; %@ is too evil.",nil),listObject.formattedUID];
					
					break;
				case AIChatMessageReceivingMissedLocalIsTooEvil:
					message = AILocalizedString(@"Could not receive: you are too evil.",nil);
					break;
					
				case AIChatCommandFailed:
					message = AILocalizedString(@"Command failed.",nil);
					break;
					
				case AIChatInvalidNumberOfArguments:
					message = AILocalizedString(@"Incorrect number of command arguments.",nil);
					break;
					
				case AIChatMessageSendingConnectionError:
					message = AILocalizedString(@"Could not send; a connection error occurred.",nil);
					break;
					
				case AIChatMessageSendingNotAllowedWhileInvisible:
					message = AILocalizedString(@"Could not send; not allowed while invisible.",nil);
					break;
			}
			
		} else if ([inChat boolValueForProperty:KEY_CHAT_CLOSED_WINDOW] && listObject) {
			message = [NSString stringWithFormat:AILocalizedString(@"%@ closed the conversation window.",nil),listObject.displayName];
			type = @"closed";
		} else if ([inChat boolValueForProperty:KEY_CHAT_TIMED_OUT] && listObject) {
			message = [NSString stringWithFormat:AILocalizedString(@"The conversation with %@ timed out.",nil),listObject.displayName];			
			type = @"timed_out";
		}
		
		if (message) {
			[adium.contentController displayEvent:message
											 ofType:type
											 inChat:inChat];
		}
	}
	
	return nil;
}

#pragma mark Event descriptions
- (NSString *)shortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:CONTENT_MESSAGE_SENT]) {
		description = AILocalizedString(@"Is sent a message",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_SENT_GROUP]) {
		description = AILocalizedString(@"Is sent a message in a group chat",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]) {
		description = AILocalizedString(@"Sends a message",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]) {
		description = AILocalizedString(@"Sends an initial message",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND]) {
		description = AILocalizedString(@"Sends a message in a background chat",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_GROUP]) {
		description = AILocalizedString(@"Sends a message in a group chat",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND_GROUP]) {
		description = AILocalizedString(@"Sends a message in a background group chat",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY]) {
		description = AILocalizedString(@"Sends a message while away",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY_GROUP]) {
		description = AILocalizedString(@"Sends a message in a group chat while away",nil);
	} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_MENTION]) {
		description = AILocalizedString(@"Is mentioned in a group chat message", nil);
	} else {
		description = @"";
	}
	
	return description;
}

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:CONTENT_MESSAGE_SENT]) {
		description = AILocalizedString(@"Message sent",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_SENT_GROUP]) {
		description = AILocalizedString(@"Message sent (Group Chat)",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]) {
		description = AILocalizedString(@"Message received",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]) {
		description = AILocalizedString(@"Message received (Initial)",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND]) {
		description = AILocalizedString(@"Message received (Background Chat)",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_GROUP]) {
		description = AILocalizedString(@"Message received (Group Chat)",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND_GROUP]) {
		description = AILocalizedString(@"Message received (Background Group Chat)",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY]) {
		description = AILocalizedString(@"Message received (Away)",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY_GROUP]) {
		description = AILocalizedString(@"Message received (Away Group Chat)",nil);
	} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_MENTION]) {
		description = AILocalizedString(@"You are mentioned (Group Chat)", nil);
	} else {
		description = @"";
	}
	
	return description;
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:CONTENT_MESSAGE_SENT]) {
		description = @"Message Sent";
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_SENT_GROUP]) {
		description = @"Message Sent (Group Chat)";
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]) {
		description = @"Message Received";
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]) {
		description = @"Message Received (New)";
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND]) {
		description = @"Message Received (Background Chat)";
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_GROUP]) {
		description = @"Message Received (Group Chat)";
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND_GROUP]) {
		description = @"Message Received (Background Group Chat)";
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY]) {
		description = @"Message Received (Away)";
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY_GROUP]) {
		description = @"Message Received (Away Group Chat)";
	} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_MENTION]) {
		description = @"You Are Mentioned (Group Chat)";
	} else {
		description = @"";
	}
	
	return description;
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	NSString	*description = nil;
	
	if (listObject) {
		NSString	*name;
		NSString	*format;
		
		if ([eventID isEqualToString:CONTENT_MESSAGE_SENT]) {
			format = AILocalizedString(@"When you send %@ a message",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_SENT_GROUP]) {
			format = AILocalizedString(@"When you send %@ a message in a group chat",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]) {
			format = AILocalizedString(@"When %@ sends a message to you",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]) {
			format = AILocalizedString(@"When %@ sends an initial message to you",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND]) {
			format = AILocalizedString(@"When %@ sends a message to you in a background chat",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_GROUP]) {
			format = AILocalizedString(@"When %@ sends a message to you in a group chat",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND_GROUP]) {
			format = AILocalizedString(@"When %@ sends a message to you in a background group chat",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY]) {
			format = AILocalizedString(@"When %@ sends a message to you while you are away",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY_GROUP]) {
			format = AILocalizedString(@"When %@ sends a message to you in a group chat while you are way",nil);
		} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_MENTION]) {
			format = AILocalizedString(@"When %@ sends a message that mentions your name in a group chat", nil);
		} else {
			format = nil;
		}
		
		if (format) {
			name = ([listObject isKindOfClass:[AIListGroup class]] ?
					[NSString stringWithFormat:AILocalizedString(@"a member of %@",nil),listObject.displayName] :
					listObject.displayName);
			
			description = [NSString stringWithFormat:format, name];
		}
		
	} else {
		if ([eventID isEqualToString:CONTENT_MESSAGE_SENT]) {
			description = AILocalizedString(@"When you send a message",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_SENT_GROUP]) {
			description = AILocalizedString(@"When you send a message in a group chat",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]) {
			description = AILocalizedString(@"When you receive any message",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]) {
			description = AILocalizedString(@"When you receive an initial message",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND]) {
			description = AILocalizedString(@"When you receive a message in a background chat",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_GROUP]) {
			description = AILocalizedString(@"When you receive a message in a group chat",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND_GROUP]) {
			description = AILocalizedString(@"When you receive a message in a background group chat",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY]) {
			description = AILocalizedString(@"When you receive a message while away",nil);
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY_GROUP]) {
			description = AILocalizedString(@"When you receive a message in a group chat while away",nil);
		} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_MENTION]) {
			description = AILocalizedString(@"When you receive a message that mentions your name in a group chat", nil);
		} else {
			description = @"";
		}
	}
	
	return description;
}

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	NSString		*description = nil;
	AIContentObject	*contentObject;
	NSString		*messageText;
	NSString		*displayName;
	
	NSParameterAssert([userInfo isKindOfClass:[NSDictionary class]]);
	
	contentObject = [(NSDictionary *)userInfo objectForKey:@"AIContentObject"];
	messageText = [self stringFromMessageAttributedString:contentObject.message];

	if (includeSubject) {
		
		if ([eventID isEqualToString:CONTENT_MESSAGE_SENT] ||
			[eventID isEqualToString:CONTENT_MESSAGE_SENT_GROUP]) {
			displayName = (listObject ? listObject.displayName : contentObject.chat.name);
		
			if (messageText && messageText.length) {
				description = [NSString stringWithFormat:
					AILocalizedString(@"You said %@ to %@","You said Message to Contact"),
					messageText,
					displayName];

			} else {
				description = [NSString stringWithFormat:
					AILocalizedString(@"You sent a message to %@","You sent a message to Contact"),
					displayName];
			}
			
		} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED] ||
				   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST] ||
				   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND] ||
				   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY] ||
                   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY_GROUP]) {
			displayName = contentObject.source.displayName;
			
			if (messageText && [messageText length]) {
				description = [NSString stringWithFormat:
					AILocalizedString(@"%@ said %@","Contact said Message"),
					displayName,
					messageText];

			} else {
				description = [NSString stringWithFormat:
					AILocalizedString(@"%@ sent you a message","Contact sent you a message"),
					displayName];				
			}
		}	
		
	} else {
		if (messageText && [messageText length]) {
			description = messageText;
		} else {
			if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED] ||
				[eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST] ||
				[eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND] ||
				[eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_GROUP] ||
				[eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND_GROUP] || 
				[eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY] ||
                [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY_GROUP] ||
				[eventID isEqualToString:CONTENT_GROUP_CHAT_MENTION]) {
				//Use the message received text for all message received events if we don't have a message
				description = [self globalShortDescriptionForEventID:CONTENT_MESSAGE_RECEIVED];
			} else {
				description = [self globalShortDescriptionForEventID:eventID];				
			}
		}
	}
	
	return description;
}

/*!
 * @brief Return a string fit for display.
 *
 * @param attributedString A message's attributed string.
 * @return A string with any elements not fit for display in reference to the event removed.
 */
- (NSString *)stringFromMessageAttributedString:(NSAttributedString *)attributedString
{
	NSMutableAttributedString *mutableMessage = [[[attributedString attributedStringByConvertingAttachmentsToStrings] mutableCopy] autorelease];

	NSRange messageRange = NSMakeRange(0, 0);
	NSUInteger stringLength = attributedString.length;
	
	for (NSUInteger i = 0; i < stringLength; i+= messageRange.length) {
		if ([mutableMessage attribute:AIHiddenMessagePartAttributeName
							  atIndex:i
				longestEffectiveRange:&messageRange
							  inRange:NSMakeRange(i, stringLength - i)]) {
			[mutableMessage deleteCharactersInRange:messageRange];
			stringLength -= messageRange.length;
			messageRange.length = 0;
		}
	}
	
	return [mutableMessage string];
}

- (NSImage *)imageForEventID:(NSString *)eventID
{
	static NSImage	*eventImage = nil;
	//Use the message icon from the main bundle
	if (!eventImage) eventImage = [[NSImage imageNamed:@"events-message"] retain];
	return eventImage;
}

- (NSString *)descriptionForCombinedEventID:(NSString *)eventID
							  forListObject:(AIListObject *)listObject
									forChat:(AIChat *)chat
								  withCount:(NSUInteger)count
{
	NSString *format = nil;
	
	if ([eventID isEqualToString:CONTENT_MESSAGE_SENT] ||
		[eventID isEqualToString:CONTENT_MESSAGE_SENT_GROUP]) {
		format = AILocalizedString(@"%u messages sent",nil);
	} else if ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED] || 
			   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST] ||
			   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND] ||
			   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_GROUP] ||
			   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_BACKGROUND_GROUP] ||
			   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY] ||
               [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_AWAY_GROUP]) {
		format = AILocalizedString(@"%u messages received", nil);
	} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_MENTION]) {
		format = AILocalizedString(@"%u mentions received", nil);
	}
	
	return format ? [NSString stringWithFormat:format, count] : @"";
}

@end
