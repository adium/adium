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

#import "adiumPurpleConversation.h"
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIContentControllerProtocol.h>
#import <AINudgeBuzzHandlerPlugin.h>

#pragma mark Purple Images

#pragma mark Conversations
static void adiumPurpleConvCreate(PurpleConversation *conv)
{
	//Pass chats along to the account
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_CHAT) {
		
		AIChat *chat = groupChatLookupFromConv(conv);
		
		[accountLookup(purple_conversation_get_account(conv)) addChat:chat];
	}
}

static void adiumPurpleConvDestroy(PurpleConversation *conv)
{
	/* Purple is telling us a conv was destroyed.  We've probably already cleaned up, but be sure in case purple calls this
	 * when we don't ask it to (for example if we are summarily kicked from a chat room and purple closes the 'window').
	 */
	AIChat *chat = (AIChat *)conv->ui_data;

	AILogWithSignature(@"%p: %@", conv, chat);

	//Chat will be nil if we've already cleaned up, at which point no further action is needed.
	if (chat) {
		[accountLookup(purple_conversation_get_account(conv)) chatWasDestroyed:chat];

		[chat setIdentifier:nil];
		[chat release];
		conv->ui_data = nil;
	}
}

static void adiumPurpleConvWriteChat(PurpleConversation *conv, const char *who,
								   const char *message, PurpleMessageFlags flags,
								   time_t mtime)
{
	/* We only care about this if:
	 *	1) It does not have the PURPLE_MESSAGE_SEND flag, which is set if Purple is sending a sent message back to us -or-
	 *  2) It is a delayed (history) message from a chat
	 */
	if (!(flags & PURPLE_MESSAGE_SEND) || (flags & PURPLE_MESSAGE_DELAYED)) {
		NSDictionary	*messageDict;
		NSString		*messageString;

		messageString = [NSString stringWithUTF8String:message];
		AILog(@"Source: %s \t Name: %s \t MyNick: %s : Message %@", 
			  who,
			  purple_conversation_get_name(conv),
			  purple_conv_chat_get_nick(PURPLE_CONV_CHAT(conv)),
			  messageString);

		NSAttributedString	*attributedMessage = [AIHTMLDecoder decodeHTML:messageString];
		NSNumber			*purpleMessageFlags = [NSNumber numberWithInt:flags];
		NSDate				*date = [NSDate dateWithTimeIntervalSince1970:mtime];
		
		if (who && strlen(who)) {
			messageDict = [NSDictionary dictionaryWithObjectsAndKeys:attributedMessage, @"AttributedMessage",
						   [NSString stringWithUTF8String:who], @"Source",
						   purpleMessageFlags, @"PurpleMessageFlags",
						   date, @"Date",nil];
			
		} else {
			messageDict = [NSDictionary dictionaryWithObjectsAndKeys:attributedMessage, @"AttributedMessage",
						   purpleMessageFlags, @"PurpleMessageFlags",
						   date, @"Date",nil];
		}

		[accountLookup(purple_conversation_get_account(conv)) receivedMultiChatMessage:messageDict inChat:groupChatLookupFromConv(conv)];
	}
}

static void adiumPurpleConvWriteIm(PurpleConversation *conv, const char *who,
								 const char *message, PurpleMessageFlags flags,
								 time_t mtime)
{
	//We only care about this if it does not have the PURPLE_MESSAGE_SEND flag, which is set if Purple is sending a sent message back to us
	if ((flags & PURPLE_MESSAGE_SEND) == 0) {
		if (flags & PURPLE_MESSAGE_NOTIFY) {
			// We received a notification (nudge or buzz). Send a notification of such.
			NSString *type, *messageString = [NSString stringWithUTF8String:message];

			// Determine what we're actually notifying about.
			if ([messageString rangeOfString:@"nudge" options:(NSCaseInsensitiveSearch | NSLiteralSearch)].location != NSNotFound) {
				type = @"Nudge";
			} else if ([messageString rangeOfString:@"buzz" options:(NSCaseInsensitiveSearch | NSLiteralSearch)].location != NSNotFound) {
				type = @"Buzz";
			} else {
				// Just call an unknown type a "notification"
				type = @"notification";
			}

			[[adium notificationCenter] postNotificationName:Chat_NudgeBuzzOccured
																			   object:chatLookupFromConv(conv)
																			 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																					   type, @"Type",
																					   nil]];
		} else {
			NSDictionary		*messageDict;
			CBPurpleAccount		*adiumAccount = accountLookup(purple_conversation_get_account(conv));
			NSString			*messageString;
			AIChat				*chat;
			
			messageString = [NSString stringWithUTF8String:message];
			chat = chatLookupFromConv(conv);
			
			AILog(@"adiumPurpleConvWriteIm: Received %@ from %@", messageString, [[chat listObject] UID]);
			
			//Process any purple imgstore references into real HTML tags pointing to real images
			messageString = processPurpleImages(messageString, adiumAccount);
			
			messageDict = [NSDictionary dictionaryWithObjectsAndKeys:messageString,@"Message",
						   [NSNumber numberWithInt:flags],@"PurpleMessageFlags",
						   [NSDate dateWithTimeIntervalSince1970:mtime],@"Date",nil];
			
			[adiumAccount receivedIMChatMessage:messageDict
										 inChat:chat];
		}
	}
}

static void adiumPurpleConvWriteConv(PurpleConversation *conv, const char *who, const char *alias,
								   const char *message, PurpleMessageFlags flags,
								   time_t mtime)
{
	AILog(@"adiumPurpleConvWriteConv: Received %s from %s [%i]",message,who,flags);
	AIChat	*chat = chatLookupFromConv(conv);

	if (chat) {
		if (flags & PURPLE_MESSAGE_SYSTEM) {
			NSString			*messageString = [NSString stringWithUTF8String:message];
			if (messageString) {
				BOOL				shouldDisplayMessage = TRUE;
				if (strcmp(message, _("Direct IM established")) == 0) {
					[accountLookup(purple_conversation_get_account(conv)) updateContact:[chat listObject]
													   forEvent:[NSNumber numberWithInt:PURPLE_BUDDY_DIRECTIM_CONNECTED]];
					shouldDisplayMessage = FALSE;
					
				} else {
					BOOL isClosingDirectIM = FALSE;
					if ((strcmp(message, _("The remote user has closed the connection.")) == 0) ||
						(strcmp(message, _("The remote user has declined your request.")) == 0) ||
						(strcmp(message, _("Received invalid data on connection with remote user.")) == 0) ||
						(strcmp(message, _("Could not establish a connection with the remote user.")) == 0)) {
						isClosingDirectIM = TRUE;
					}
					
					if (!isClosingDirectIM) {
						//Only works in English - XXX fix me!
						if ([messageString rangeOfString:@"Lost connection with the remote user:"].location != NSNotFound) {
							isClosingDirectIM = TRUE;
						}
					}
					
					if (isClosingDirectIM) {
						if (strcmp(message, _("The remote user has closed the connection.")) != 0) {
							//Display the message if it's not just the one for the other guy closing it...
							[[adium contentController] displayEvent:messageString
																					  ofType:@"directIMDisconnected"
																					  inChat:chat];
						}
						
						[accountLookup(purple_conversation_get_account(conv)) updateContact:[chat listObject] forEvent:[NSNumber numberWithInt:PURPLE_BUDDY_DIRECTIM_DISCONNECTED]];
						shouldDisplayMessage = FALSE;
					}
				}

				if (shouldDisplayMessage) {
					[[adium contentController] displayEvent:messageString
																			  ofType:@"libpurpleMessage"
																			  inChat:chat];
				}
			}
	
		} else if (flags & PURPLE_MESSAGE_ERROR) {
			NSString			*messageString = [NSString stringWithUTF8String:message];

			if (messageString) {
			    if (![messageString rangeOfString:@"User information not available"].location != NSNotFound) {
					//Ignore user information errors; they are irrelevent
					//XXX The user info check only works in English; libpurple should be modified to be better about this useless information spamming

					AIChatErrorType	errorType = AIChatUnknownError;
					
					if (([messageString rangeOfString:[NSString stringWithUTF8String:_("Not logged in")]].location != NSNotFound) || 
						([messageString rangeOfString:[NSString stringWithUTF8String:_("User temporarily unavailable")]].location != NSNotFound)) {
						errorType = AIChatMessageSendingUserNotAvailable;
					} else if ([messageString rangeOfString:[NSString stringWithUTF8String:_("In local permit/deny")]].location != NSNotFound) {
						errorType = AIChatMessageSendingUserIsBlocked;
					} else if (([messageString rangeOfString:[NSString stringWithUTF8String:_("Reply too big")]].location != NSNotFound) ||
							   ([messageString rangeOfString:@"message is too large"].location != NSNotFound)) {
						//XXX - there may be other conditions, but this seems the most common so that's how we'll classify it
						errorType = AIChatMessageSendingTooLarge;
					} else if ([messageString rangeOfString:[NSString stringWithUTF8String:_("Command failed")]].location != NSNotFound) {
						errorType = AIChatCommandFailed;
					} else if ([messageString rangeOfString:[NSString stringWithUTF8String:_("Wrong number of arguments")]].location != NSNotFound) {
						errorType = AIChatInvalidNumberOfArguments;
					} else if ([messageString rangeOfString:[NSString stringWithUTF8String:_("Rate")]].location != NSNotFound) {
						//XXX Is 'Rate' really a standalone translated string?
						errorType = AIChatMessageSendingMissedRateLimitExceeded;
					} else if ([messageString rangeOfString:[NSString stringWithUTF8String:_("Too evil")]].location != NSNotFound) {
						errorType = AIChatMessageReceivingMissedRemoteIsTooEvil;
					}
					/* Another is 'refused by client', which is definitely seen when sending an offline message to an invalid screenname...
					 * but I don't know when else it is sent. -evands
					 */

					/* We will wait until the next run loop, in case this error message was generated by
					 * the sending of a message. This allows the results of sending the message to be displayed
					 * first.
					 */
					if (errorType != AIChatUnknownError) {
						[accountLookup(purple_conversation_get_account(conv)) performSelector:@selector(errorForChat:type:)
						 withObject:chat
						 withObject:[NSNumber numberWithInt:errorType]
						 afterDelay:0];
					} else {
						[[adium contentController] performSelector:@selector(displayEvent:ofType:inChat:)
																				 withObject:messageString
																				 withObject:@"libpurpleMessage"
																				 withObject:chat
																				 afterDelay:0];
					}
				}
			}

			AILog(@"*** Conversation error %@: %@", chat, messageString);
		}
	}
}

static void adiumPurpleConvChatAddUsers(PurpleConversation *conv, GList *cbuddies, gboolean new_arrivals)
{
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_CHAT) {
		NSMutableArray	*usersArray = [NSMutableArray array];
		NSMutableArray	*flagsArray = [NSMutableArray array];
		NSMutableArray	*aliasesArray = [NSMutableArray array];
		
		GList *l;
		for (l = cbuddies; l != NULL; l = l->next) {
			PurpleConvChatBuddy *chatBuddy = (PurpleConvChatBuddy *)l->data;
			
			[usersArray addObject:[NSString stringWithUTF8String:chatBuddy->name]];
			[aliasesArray addObject:(chatBuddy->alias ? [NSString stringWithUTF8String:chatBuddy->alias] : @"")];
			[flagsArray addObject:[NSNumber numberWithInt:GPOINTER_TO_INT(chatBuddy->flags)]];
		}

		[accountLookup(purple_conversation_get_account(conv)) addUsersArray:usersArray
										  withFlags:flagsArray
										 andAliases:aliasesArray
										newArrivals:[NSNumber numberWithBool:new_arrivals]
											 toChat:groupChatLookupFromConv(conv)];
		
	} else {
		AILog(@"adiumPurpleConvChatAddUsers: IM");
	}
}

static void adiumPurpleConvChatRenameUser(PurpleConversation *conv, const char *oldName,
										const char *newName, const char *newAlias)
{
	AILog(@"adiumPurpleConvChatRenameUser: %s: oldName %s, newName %s, newAlias %s",
			   purple_conversation_get_name(conv),
			   oldName, newName, newAlias);
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_CHAT) {

		[accountLookup(purple_conversation_get_account(conv)) renameRoomOccupant:[NSString stringWithUTF8String:purple_normalize(purple_conversation_get_account(conv), oldName)]
																			  to:[NSString stringWithUTF8String:purple_normalize(purple_conversation_get_account(conv), newName)] 
																		  inChat:groupChatLookupFromConv(conv)];
	}
}

static void adiumPurpleConvChatRemoveUsers(PurpleConversation *conv, GList *users)
{
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_CHAT) {
		NSMutableArray	*usersArray = [NSMutableArray array];

		GList *l;
		for (l = users; l != NULL; l = l->next) {
			[usersArray addObject:[NSString stringWithUTF8String:purple_normalize(purple_conversation_get_account(conv), (char *)l->data)]];
		}

		[accountLookup(purple_conversation_get_account(conv)) removeUsersArray:usersArray
											  fromChat:groupChatLookupFromConv(conv)];

	} else {
		AILog(@"adiumPurpleConvChatRemoveUser: IM");
	}
}

static void adiumPurpleConvUpdateUser(PurpleConversation *conv, const char *user)
{
	AILog(@"adiumPurpleConvUpdateUser: %s",user);
}

static void adiumPurpleConvPresent(PurpleConversation *conv)
{
	
}

//This isn't a function we want Purple doing anything with, I don't think
static gboolean adiumPurpleConvHasFocus(PurpleConversation *conv)
{
	return NO;
}

static void adiumPurpleConvUpdated(PurpleConversation *conv, PurpleConvUpdateType type)
{
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_CHAT) {
		PurpleConvChat  *chat = purple_conversation_get_chat_data(conv);
		
		switch(type) {
			case PURPLE_CONV_UPDATE_TOPIC:
				[accountLookup(purple_conversation_get_account(conv)) updateTopic:(purple_conv_chat_get_topic(chat) ?
														   [NSString stringWithUTF8String:purple_conv_chat_get_topic(chat)] :
														   nil)
												  forChat:groupChatLookupFromConv(conv)];
				break;
			case PURPLE_CONV_UPDATE_TITLE:
				[accountLookup(purple_conversation_get_account(conv)) updateTitle:(purple_conversation_get_title(conv) ?
														   [NSString stringWithUTF8String:purple_conversation_get_title(conv)] :
														   nil)
												  forChat:groupChatLookupFromConv(conv)];
				
				AILog(@"Update to title: %s",purple_conversation_get_title(conv));
				break;
			case PURPLE_CONV_UPDATE_CHATLEFT:
				[accountLookup(purple_conversation_get_account(conv)) leftChat:groupChatLookupFromConv(conv)];
				break;
			case PURPLE_CONV_UPDATE_ADD:
			case PURPLE_CONV_UPDATE_REMOVE:
			case PURPLE_CONV_UPDATE_ACCOUNT:
			case PURPLE_CONV_UPDATE_TYPING:
			case PURPLE_CONV_UPDATE_UNSEEN:
			case PURPLE_CONV_UPDATE_LOGGING:
			case PURPLE_CONV_ACCOUNT_ONLINE:
			case PURPLE_CONV_ACCOUNT_OFFLINE:
			case PURPLE_CONV_UPDATE_AWAY:
			case PURPLE_CONV_UPDATE_ICON:
			case PURPLE_CONV_UPDATE_FEATURES:

/*				
				[accountLookup(purple_conversation_get_account(conv)) mainPerformSelector:@selector(convUpdateForChat:type:)
													   withObject:groupChatLookupFromConv(conv)
													   withObject:[NSNumber numberWithInt:type]];
*/				
			default:
				break;
		}

	} else if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_IM) {
		PurpleConvIm  *im = purple_conversation_get_im_data(conv);
		switch (type) {
			case PURPLE_CONV_UPDATE_TYPING: {

				AITypingState typingState;

				switch (purple_conv_im_get_typing_state(im)) {
					case PURPLE_TYPING:
						typingState = AITyping;
						break;
					case PURPLE_TYPED:
						typingState = AIEnteredText;
						break;
					case PURPLE_NOT_TYPING:
					default:
						typingState = AINotTyping;
						break;
				}

				NSNumber	*typingStateNumber = [NSNumber numberWithInt:typingState];

				[accountLookup(purple_conversation_get_account(conv)) typingUpdateForIMChat:imChatLookupFromConv(conv)
															 typing:typingStateNumber];
				break;
			}
			case PURPLE_CONV_UPDATE_AWAY: {
				//If the conversation update is UPDATE_AWAY, it seems to suppress the typing state being updated
				//Reset purple's typing tracking, then update to receive a PURPLE_CONV_UPDATE_TYPING message
				purple_conv_im_set_typing_state(im, PURPLE_NOT_TYPING);
				purple_conv_im_update_typing(im);
				break;
			}
			default:
				break;
		}
	}
}

#pragma mark Custom smileys
gboolean adiumPurpleConvCustomSmileyAdd(PurpleConversation *conv, const char *smile, gboolean remote)
{
	AILog(@"%s: Added Custom Smiley %s",purple_conversation_get_name(conv),smile);
	[accountLookup(purple_conversation_get_account(conv)) chat:chatLookupFromConv(conv)
			 isWaitingOnCustomEmoticon:[NSString stringWithUTF8String:smile]];

	return TRUE;
}

void adiumPurpleConvCustomSmileyWrite(PurpleConversation *conv, const char *smile,
									const guchar *data, gsize size)
{
	AILog(@"%s: Write Custom Smiley %s (%x %i)",purple_conversation_get_name(conv),smile,data,size);

	[accountLookup(purple_conversation_get_account(conv)) chat:chatLookupFromConv(conv)
					 setCustomEmoticon:[NSString stringWithUTF8String:smile]
						 withImageData:[NSData dataWithBytes:data
													  length:size]];
}

void adiumPurpleConvCustomSmileyClose(PurpleConversation *conv, const char *smile)
{
	AILog(@"%s: Close Custom Smiley %s",purple_conversation_get_name(conv),smile);

	[accountLookup(purple_conversation_get_account(conv)) chat:chatLookupFromConv(conv)
				  closedCustomEmoticon:[NSString stringWithUTF8String:smile]];
}

static PurpleConversationUiOps adiumPurpleConversationOps = {
	adiumPurpleConvCreate,
    adiumPurpleConvDestroy,
    adiumPurpleConvWriteChat,
    adiumPurpleConvWriteIm,
    adiumPurpleConvWriteConv,
    adiumPurpleConvChatAddUsers,
    adiumPurpleConvChatRenameUser,
    adiumPurpleConvChatRemoveUsers,
	adiumPurpleConvUpdateUser,
	
	adiumPurpleConvPresent,
	adiumPurpleConvHasFocus,

	/* Custom Smileys */
	adiumPurpleConvCustomSmileyAdd,
	adiumPurpleConvCustomSmileyWrite,
	adiumPurpleConvCustomSmileyClose,
};

PurpleConversationUiOps *adium_purple_conversation_get_ui_ops(void)
{
	return &adiumPurpleConversationOps;
}

void adiumPurpleConversation_init(void)
{	
	purple_conversations_set_ui_ops(adium_purple_conversation_get_ui_ops());

	purple_signal_connect_priority(purple_conversations_get_handle(), "conversation-updated", adium_purple_get_handle(),
								 PURPLE_CALLBACK(adiumPurpleConvUpdated), NULL,
								 PURPLE_SIGNAL_PRIORITY_LOWEST);
	
}
