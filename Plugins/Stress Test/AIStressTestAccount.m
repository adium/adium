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

#import "AIStressTestAccount.h"
#import "AIStressTestPlugin.h"
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentNotification.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListContact.h>

@implementation AIStressTestAccount
//
- (void)initAccount
{
	[super initAccount];

	listObjectArray = [[NSMutableArray alloc] init];
	commandContact = nil;
}

- (void)connect
{
	[super connect];
	[self didConnect];

	if (!commandContact) {
		commandContact = [[[adium contactController] contactWithService:service 
																account:self
																	UID:@"Command"] retain];
	}
	AILog(@"Created command contact %@",commandContact);
	[commandContact setRemoteGroupName:@"Command"];
	[commandContact setValue:[NSNumber numberWithBool:YES] forProperty:@"Online" notify:YES];

}

- (void)disconnect
{
	[commandContact setRemoteGroupName:nil];
	[commandContact setValue:nil forProperty:@"Online" notify:YES];
	[commandContact release]; commandContact = nil;

	[super disconnect];

	[self didDisconnect];
}

- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage
{
	if ([statusState statusType] == AIOfflineStatusType) {
		[self disconnect];
	} else {
		if ([self online]) {
			[commandContact setStatusWithName:[statusState statusName]
								   statusType:[statusState statusType]
									   notify:NotifyLater];
			[commandContact setStatusMessage:statusMessage
									  notify:NotifyLater];
			[commandContact notifyOfChangedPropertiesSilently:NO];

		} else {
			[self connect];
		}
	}
}

- (void)dealloc
{
	[groupChat release];
	[listObjectArray release];
	
	[super dealloc];
}

//Stress Test certainly doesn't need to receive connect/disconnect requests based on network reachability
- (BOOL)connectivityBasedOnNetworkReachability
{
	return NO;
}

#pragma mark Commands
- (void)createContacts:(int)numContacts
{
	for (int i = 0;i < numContacts; i++) {
		NSString		*buddyUID = [NSString stringWithFormat:@"Buddy%i",i];
		AIListContact	*contact;

		contact = [[adium contactController] contactWithService:service
														account:self
															UID:buddyUID];
		[contact setRemoteGroupName:[NSString stringWithFormat:@"Group %i", (int)(i/5.0)]];
	}
	
	[self echo:[NSString stringWithFormat:@"Created %i contacts", numContacts]];	
}

- (void)setContactsInRange:(NSRange)contactRange online:(BOOL)online silently:(BOOL)silent
{
	[self echo:[NSString stringWithFormat:@"%i contacts %@ %@", contactRange.length,
																(online ? @"signing on" : @" signing off") ,
																(silent ? @"(Silently)" : @"")]];

	if (contactRange.length) {
		if (silent) [[adium contactController] delayListObjectNotifications];

		for (int i = contactRange.location; i < NSMaxRange(contactRange); i++) {
			AIListContact	*contact;
			NSString		*buddyUID = [NSString stringWithFormat:@"Buddy%i",i];
			
			contact = [[adium contactController] contactWithService:service
															account:self
																UID:buddyUID];

			[contact setOnline:online
						notify:NotifyLater
					  silently:silent];

			//Apply any changes
			[contact notifyOfChangedPropertiesSilently:silent];
		}

		if (silent) [[adium contactController] endListObjectNotificationsDelay];
	}
}

#pragma mark Messaging
// Send a content object
- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
    if (![inContentMessage isAutoreply]) {
        NSString	*message;
        NSArray		*commands;
        NSString	*type = 
        
		message = [[inContentMessage message] string];
		AILog(@"Stress Test: Sending %@",message);

		commands = [message componentsSeparatedByString:@" "];
		type = (([commands count]) ? [commands objectAtIndex:0] : nil);
		
        if ([type caseInsensitiveCompare:@"create"] == NSOrderedSame) {
            [self createContacts:[[commands objectAtIndex:1] intValue]];
            
        } else if ([type caseInsensitiveCompare:@"online"] == NSOrderedSame) {
			[self setContactsInRange:NSMakeRange(0, [[commands objectAtIndex:1] intValue])
							  online:YES
							silently:(([commands count] > 2) ? [[commands objectAtIndex:2] isEqualToString:@"silent"] : NO)];

        } else if ([type caseInsensitiveCompare:@"offline"] == NSOrderedSame) {
			[self setContactsInRange:NSMakeRange(0, [[commands objectAtIndex:1] intValue])
							  online:NO
							silently:(([commands count] > 2) ? [[commands objectAtIndex:2] isEqualToString:@"silent"] : NO)];
			
			
		} else if ([type rangeOfString:@"Buddy" options:(NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound) {
			[self setContactsInRange:NSMakeRange([[type substringFromIndex:5] intValue], 1)
							  online:NO
							silently:(([commands count] > 2) ? [[commands objectAtIndex:2] isEqualToString:@"silent"] : NO)];

		} else if ([type caseInsensitiveCompare:@"msgin"] == NSOrderedSame) {
			int			count = [[commands objectAtIndex:1] intValue];
			int			spread = [[commands objectAtIndex:2] intValue];
			
			//Get the full message, which comes after the first three command parts
			int			messageIndex = ([(NSString *)[commands objectAtIndex:0] length] + 1 +
										[(NSString *)[commands objectAtIndex:1] length] + 1 +
										[(NSString *)[commands objectAtIndex:2] length] + 1);
			
            NSString	*messageIn = ((messageIndex < [message length]) ?
									  [message substringFromIndex:messageIndex] :
									  nil);
			
			if (messageIn) {
				[NSTimer scheduledTimerWithTimeInterval:0.00001
												 target:self
											   selector:@selector(timer_msgin:)
											   userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"i",
												   [NSNumber numberWithInt:count],@"count",
												   [NSNumber numberWithInt:spread],@"spread",
												   messageIn,@"message",nil] 
												repeats:YES];
			}

		} else if ([type caseInsensitiveCompare:@"msginout"] == NSOrderedSame) {
            int 		count = [[commands objectAtIndex:1] intValue];
            int 		spread = [[commands objectAtIndex:2] intValue];
			int			messageIndex = ([(NSString *)[commands objectAtIndex:0] length] + 1 +
										[(NSString *)[commands objectAtIndex:1] length] + 1 +
										[(NSString *)[commands objectAtIndex:2] length] + 1);
            NSString	*messageOut = ((messageIndex < [message length]) ?
									   [message substringFromIndex:messageIndex] : 
									   nil);
			
			if (messageOut) {
				[NSTimer scheduledTimerWithTimeInterval:0.00001 
												 target:self 
											   selector:@selector(timer_msginout:)
											   userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"i",
												   [NSNumber numberWithInt:count],@"count",
												   [NSNumber numberWithInt:spread],@"spread",
												   messageOut,@"message",
												   [NSNumber numberWithBool:NO],@"in",nil] 
												repeats:YES];
            }
			
		} else if ([type caseInsensitiveCompare:@"groupchat"] == NSOrderedSame) {
            int 		count = [[commands objectAtIndex:1] intValue];
			NSString	*messageIn = [commands objectAtIndex:2];
			
			[NSTimer scheduledTimerWithTimeInterval:0.00001
											 target:self
										   selector:@selector(timer_groupchat:)
										   userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"i",
											   [NSNumber numberWithInt:count],@"count",
											   messageIn,@"message",nil] 
											repeats:YES];	
			
		} else if ([type caseInsensitiveCompare:@"crash"] == NSOrderedSame) {
            NSMutableArray *help = [[NSMutableArray alloc] init];
            [help addObject:nil];

		} else if ([type caseInsensitiveCompare:@"typing"] == NSOrderedSame) {
			AITypingState typingState;

			if ([[commands objectAtIndex:1] caseInsensitiveCompare:@"on"] == NSOrderedSame) {
				typingState = AITyping;
				
			} else if ([[commands objectAtIndex:1] caseInsensitiveCompare:@"entered"] == NSOrderedSame) {
				typingState = AIEnteredText;
				
			} else {
				typingState = AINotTyping;
				
			}

			[[[adium chatController] chatWithContact:commandContact] setValue:[NSNumber numberWithInt:typingState]
																			  forProperty:KEY_TYPING
																			  notify:NotifyNow];
			
		} else if ([inContentMessage destination] == commandContact) {
            [self echo:[NSString stringWithFormat:@"Unknown command %@",type]];
        }
    }
	
	return YES;
}

- (void)timer_online:(NSTimer *)inTimer
{
    NSMutableDictionary	*userInfo = [inTimer userInfo];
    NSMutableArray		*array = [userInfo objectForKey:@"contacts"];
    AIListContact		*contact = [array lastObject];
	BOOL				silent = [[userInfo objectForKey:@"silent"] boolValue];

	[contact setOnline:YES
				notify:NotifyLater
			  silently:silent];
	
	//Apply any changes
	[contact notifyOfChangedPropertiesSilently:silent];

    [array removeLastObject];
    if ([array count] == 0) {
		if (silent) [[adium contactController] endListObjectNotificationsDelay];

		[inTimer invalidate];
	}
}

- (void)timer_msgin:(NSTimer *)inTimer
{
    NSMutableDictionary *userInfo = [inTimer userInfo];
    NSString		*message = [userInfo objectForKey:@"message"];
    int				i = [[userInfo objectForKey:@"i"] intValue];
    int				count = [[userInfo objectForKey:@"count"] intValue];
    int				spread = [[userInfo objectForKey:@"spread"] intValue];
	
    AIListContact	*contact;
    NSString		*buddyUID = [NSString stringWithFormat:@"Buddy%i",i%spread];
	
    if ((contact = [[adium contactController] contactWithService:service
														account:self
															UID:buddyUID])) {
        AIContentMessage *messageObject;
        messageObject = [AIContentMessage messageInChat:[[adium chatController] chatWithContact:contact]
											 withSource:contact
                                            destination:self
												   date:nil
                                                message:[[[NSAttributedString alloc] initWithString:message
																						 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
											  autoreply:NO];
        [[adium contentController] receiveContentObject:messageObject];
		
    }
	
    i++;
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"i"];
    if (i == count) [inTimer invalidate];
}


- (void)timer_msginout:(NSTimer *)inTimer
{
    NSMutableDictionary *userInfo = [inTimer userInfo];
    NSString		*message = [userInfo objectForKey:@"message"];
    int				i = [[userInfo objectForKey:@"i"] intValue];
    int				count = [[userInfo objectForKey:@"count"] intValue];
    int				spread = [[userInfo objectForKey:@"spread"] intValue];
    BOOL			msgIn = [[userInfo objectForKey:@"in"] boolValue];
    
    AIListContact	*contact;
    NSString		*buddyUID = [NSString stringWithFormat:@"Buddy%i",i%spread];
	
    if ((contact = [[adium contactController] contactWithService:service
														account:self
															UID:buddyUID])) {
        AIContentMessage *messageObject;
        if (msgIn) {
            messageObject = [AIContentMessage messageInChat:[[adium chatController] chatWithContact:contact]
                                                 withSource:self
                                                destination:contact
                                                       date:nil
                                                    message:[[[NSAttributedString alloc] initWithString:message
																							 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
                                                  autoreply:YES];
            [[adium contentController] sendContentObject:messageObject];
        } else {
            messageObject = [AIContentMessage messageInChat:[[adium chatController] chatWithContact:contact]
                                                 withSource:contact
                                                destination:self
                                                       date:nil
                                                    message:[[[NSAttributedString alloc] initWithString:message 
																							 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
                                                  autoreply:NO];
            [[adium contentController] receiveContentObject:messageObject];
        }
		
        [userInfo setObject:[NSNumber numberWithBool:!msgIn] forKey:@"in"];
    }
	
    i++;
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"i"];
    if (i == count) [inTimer invalidate];
}

- (void)timer_groupchat:(NSTimer *)inTimer
{
    NSMutableDictionary *userInfo = [inTimer userInfo];
	NSString		*message = [userInfo objectForKey:@"message"];
    int				i = [[userInfo objectForKey:@"i"] intValue];
    int				count = [[userInfo objectForKey:@"count"] intValue];
	int				j;

	AIContentMessage *messageObject;
	
	//Ensure our contacts and group are created when we get to the first contact
	if ( i == 0 ) {
		for (j = 0; j < count; j++) {
			NSString		*buddyUID = [NSString stringWithFormat:@"Buddy%i",j];
			[listObjectArray addObject:[[adium contactController] contactWithService:service
																			 account:self
																				 UID:buddyUID]];
		}
		
		groupChat = [[[adium chatController] chatWithName:[NSString stringWithFormat:@"%@'s Chat",[[listObjectArray objectAtIndex:0] displayName]]
											   identifier:nil
												onAccount:self
										 chatCreationInfo:nil] retain];
		
	}
	
	[groupChat addObject:[listObjectArray objectAtIndex:i]];
	messageObject = [AIContentMessage messageInChat:groupChat
										 withSource:[listObjectArray objectAtIndex:i]
										destination:nil
											   date:nil
											message:[[[NSAttributedString alloc] initWithString:message
																					 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
										  autoreply:NO];
	[[adium contentController] receiveContentObject:messageObject];
	
	//Increment our object counter, invalidating this timer if we're done sending messages
	i++;
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"i"];
    if (i == count) [inTimer invalidate];
}



//Return YES if we're available for sending the specified content.  If inListObject is NO, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact
{
	if ([inType isEqualToString:CONTENT_MESSAGE_TYPE] ||
		[inType isEqualToString:CONTENT_NOTIFICATION_TYPE]) {
		return YES;
	} else {
		return NO;
	}
}

//Initiate a new chat
- (BOOL)openChat:(AIChat *)chat
{
	AIListObject	*listObject = [chat listObject];
	if (listObject && (listObject == commandContact)) {
		NSMutableString *instructions = [NSMutableString string];
		[instructions appendString:@"Stress Test\r-------------\r"];
		[instructions appendString:@"You must create contacts before using any other commands\r"];
		[instructions appendString:@"Usage:\r"];
		[instructions appendString:@"create <count>\r"];
		[instructions appendString:@"online <count> |silent|\r"];
		[instructions appendString:@"offline <count> |silent|\r"];
		[instructions appendString:@"buddy# [online|offline] <count> |silent| <-- # is replace with a number; set a particular buddy online/offline\r"];
		[instructions appendString:@"msgin <count> <spread> <message>\r"];
		[instructions appendString:@"msginout <count> <spread> <message>\r"];
		[instructions appendString:@"groupchat <count> <message>\r"];
		[instructions appendString:@"crash\r"];
		[instructions appendString:@"typing [on|entered|off]"];

		[self echo:instructions];
	}

    return YES;
}

//Close a chat instance
- (BOOL)closeChat:(AIChat *)chat
{
    return YES;
}


- (void)echo:(NSString *)string
{
    [self performSelector:@selector(_echo:) withObject:string afterDelay:0];
}

- (void)_echo:(NSString *)string
{
    AIContentMessage *messageObject;
    messageObject = [AIContentMessage messageInChat:[[adium chatController] chatWithContact:commandContact]
                                         withSource:commandContact
                                        destination:self
                                               date:nil
                                            message:[[[NSAttributedString alloc] initWithString:string
																					 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
                                          autoreply:NO];
    [[adium contentController] receiveContentObject:messageObject];
}

@end

