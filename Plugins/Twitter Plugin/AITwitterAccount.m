//
//  AITwitterAccount.m
//  Adium
//
//  Created by Zachary West on 2009-02-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AITwitterAccount.h"
#import "MGTwitterEngine/MGTwitterEngine.h"
#import <Adium/AIChat.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListBookmark.h>

@interface AITwitterAccount()
- (void)setRequestType:(AITwitterRequestType)type forRequestID:(NSString *)requestID withDictionary:(NSDictionary *)info;
- (AITwitterRequestType)requestTypeForRequestID:(NSString *)requestID;
- (NSDictionary *)dictionaryForRequestID:(NSString *)requestID;
- (void)clearRequestTypeForRequestID:(NSString *)requestID;

- (void)updateTimer:(NSTimer *)timer;
@end

@implementation AITwitterAccount
- (void)initAccount
{
	[super initAccount];
	
	twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
	pendingRequests = [[NSMutableDictionary alloc] init];
}

- (void)dealloc
{
	[twitterEngine release];
	[pendingRequests release];
	
	[super dealloc];
}

#pragma mark AIAccount methods
- (void)connect
{
	[super connect];
	
	[twitterEngine setUsername:self.UID password:self.passwordWhileConnected];
	
	//[twitterEngine getFollowedTimelineFor:self.UID since:nil startingAtPage:0];
	NSString	*requestID = [twitterEngine getRecentlyUpdatedFriendsFor:self.UID startingAtPage:0];
	
	if (requestID) {
		[self setRequestType:AITwitterInitialUserInfo forRequestID:requestID withDictionary:nil];
	} else {
		[self setLastDisconnectionError:AILocalizedString(@"Unable to connect", nil)];
		[self didDisconnect];
	}
	
	updateTimer = [NSTimer scheduledTimerWithTimeInterval:60*TWITTER_UPDATE_INTERVAL_MINUTES
												   target:self
												 selector:@selector(updateTimer:)
												 userInfo:nil
												  repeats:YES];
}

- (void)didConnect
{
	[super didConnect];
	
	AIListContact *listContact = [self contactWithUID:TWITTER_TIMELINE_UID];
	
	// If the user isn't in a group, set them in the Twitter group.
	if(listContact.remoteGroupNames.count == 0) {
		[listContact addRemoteGroupName:TWITTER_REMOTE_GROUP_NAME];
	}
	
	// Grab the Twitter display name and set it as the remote alias.
	if (![[listContact valueForProperty:@"Server Display Name"] isEqualToString:TWITTER_TIMELINE_NAME]) {
		[listContact setServersideAlias:TWITTER_TIMELINE_NAME
							   silently:silentAndDelayed];
	}
	
	// Set the user as available.
	[listContact setStatusWithName:nil
						statusType:AIAvailableStatusType
							notify:NotifyLater];
	
	// Set the user as online.
	[listContact setOnline:YES notify:NotifyNow silently:silentAndDelayed];	
}

- (void)disconnect
{
	NSString *requestID = [twitterEngine endUserSession];
	
	if (requestID) {
		[self setRequestType:AITwitterDisconnect
				forRequestID:requestID
			  withDictionary:nil];
	} else {
		[self didDisconnect];
	}
	
	[updateTimer invalidate];
	
	[super disconnect];
}

- (void)didDisconnect
{
	[pendingRequests removeAllObjects];
	
	[super didDisconnect];
}

- (NSString *)host
{
	return @"twitter.com";
}

- (BOOL)openChat:(AIChat *)chat
{	
	NSLog(@"openChat %@", chat);
	
	if([chat.listObject.UID isEqualToString:TWITTER_TIMELINE_UID]) {
		timelineChat = chat;
			
		[updateTimer fire];
	}
	
	return YES;
}

- (BOOL)closeChat:(AIChat *)inChat
{
	if(inChat == timelineChat) {
		timelineChat = nil;
	}
	
	return YES;
}

- (BOOL)contactListEditable
{
    return [self online];
}

/*!
 * @brief Update our status
 */
- (void)setSocialNetworkingStatusMessage:(NSAttributedString *)statusMessage
{
	[twitterEngine sendUpdate:[statusMessage string]];
}

/*!
 * @brief Send a message
 *
 * Sends a direct message to the user requested.
 * If it fails to send, i.e. the request fails, an unknown error will occur.
 * This is usually caused by the target not following the user.
 */
- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	NSLog(@"Message to: %@ content: %@", [[inContentMessage destination] UID], [inContentMessage messageString]);
	
	NSString *requestID;
	
	if(inContentMessage.chat == timelineChat) {
		requestID = [twitterEngine sendUpdate:[inContentMessage messageString]];
	} else {		
		requestID = [twitterEngine sendDirectMessage:[inContentMessage messageString]
												  to:[[inContentMessage destination] UID]];
	}
	
	if(requestID) {
		[self setRequestType:AITwitterDirectMessageSend
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObject:[inContentMessage chat]
														 forKey:@"Chat"]];
		return YES;
	} else {
		return NO;
	}
}

#pragma mark Contact handling
- (void)removeContacts:(NSArray *)objects
{	
	for (AIListContact *object in objects) {
		NSString *requestID = [twitterEngine disableUpdatesFor:object.UID];
		
		if(requestID) {
			[self setRequestType:AITwitterRemoveFollow
					forRequestID:requestID
				  withDictionary:[NSDictionary dictionaryWithObject:object forKey:@"ListContact"]];
		}	
	}
}

- (void)addContact:(AIListContact *)contact toGroup:(AIListGroup *)group
{
	NSString	*requestID = [twitterEngine enableUpdatesFor:contact.UID];
	
	if(requestID) {	
		NSString	*updateRequestID = [twitterEngine getUserInformationFor:contact.UID];
		
		if (updateRequestID) {
			[self setRequestType:AITwitterInitialUserInfo forRequestID:updateRequestID withDictionary:nil];
		}
	}
}

#pragma mark Request cataloguing
/*!
 * @brief Set the type and optional dictionary for a request ID
 *
 * Sets the AITwitterRequestType for a particular request ID, so when the request finishes we can identify what it is for.
 * Optionally sets a dictionary which can be retrieved in association with the request type.
 */
- (void)setRequestType:(AITwitterRequestType)type forRequestID:(NSString *)requestID withDictionary:(NSDictionary *)info
{
	[pendingRequests setObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:type], @"Type",
								info, @"Info", nil]
						forKey:requestID];
}

/*!
 * @brief Get the request type for a request ID
 */
- (AITwitterRequestType)requestTypeForRequestID:(NSString *)requestID
{
	return [(NSNumber *)[[pendingRequests objectForKey:requestID] objectForKey:@"Type"] intValue];
}

/*!
 * @brief Get the dictionary associated with a request ID
 */
- (NSDictionary *)dictionaryForRequestID:(NSString *)requestID
{
	return (NSDictionary *)[[pendingRequests objectForKey:requestID] objectForKey:@"Info"];
}

/*!
 * @brief Remove a request ID's saved information.
 */
- (void)clearRequestTypeForRequestID:(NSString *)requestID
{
	[pendingRequests removeObjectForKey:requestID];
}

#pragma mark Periodic update scheduler
/*!
 * @brief Trigger our periodic updates
 */
- (void)updateTimer:(NSTimer *)timer
{
	NSDate		*lastDirectMessagePull = [self preferenceForKey:TWITTER_PREFERENCE_DATE_DM
														  group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	NSString *requestID;
	
	// We'll update the date preferences for last pulled times when the response is received.
	// We use the current date, not the date when received, just in case a request is received in-between.
	
	// Pull direct messages
	requestID = [twitterEngine getDirectMessagesSince:lastDirectMessagePull startingAtPage:0];
	
	if (requestID) {
		[self setRequestType:AITwitterUpdateDirectMessage
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObject:[NSDate date] forKey:@"Date"]];
	}
	
	NSLog(@"Requested DMs since %d", [lastDirectMessagePull timeIntervalSince1970]);
	
	NSDate		*lastFollowedTimelinePull = [self preferenceForKey:TWITTER_PREFERENCE_DATE_TIMELINE
														 group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	// Pull followed timeline
	requestID = [twitterEngine getFollowedTimelineFor:self.UID
												since:lastFollowedTimelinePull
									   startingAtPage:0];
	
	if (requestID) {
		[self setRequestType:AITwitterUpdateFollowedTimeline
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObject:[NSDate date] forKey:@"Date"]];
	}	
	
	NSLog(@"Requested timeline since %@", lastFollowedTimelinePull);
}

#pragma mark MGTwitterEngine Delegate Methods
- (void)requestSucceeded:(NSString *)identifier
{
	// If a request succeeds and we think we're offline, call ourselves online.
	if ([self requestTypeForRequestID:identifier] == AITwitterDisconnect) {
		[self didDisconnect];
	} else if (!self.online) {
		[self didConnect];
	}
	
	if ([self requestTypeForRequestID:identifier] == AITwitterRemoveFollow) {
		AIListContact *listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
		
		for (NSString *groupName in [[listContact.remoteGroupNames copy] autorelease]) {
			[listContact removeRemoteGroupName:groupName];
		}
	}
	
    NSLog(@"Request succeeded (%@)", identifier);
}

- (void)requestFailed:(NSString *)identifier withError:(NSError *)error
{		
	if([self requestTypeForRequestID:identifier] == AITwitterDirectMessageSend) {
		AIChat	*chat = [[self dictionaryForRequestID:identifier] objectForKey:@"Chat"];
		
		[chat receivedError:[NSNumber numberWithInt:AIChatUnknownError]];
		
		NSLog(@"Chat message error - %@ %@", chat, identifier);
	} else if ([self requestTypeForRequestID:identifier] == AITwitterDisconnect) {
		[self didDisconnect];
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier
{	
	if([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline) {
		NSDate		*lastFollowedTimelinePull = [self preferenceForKey:TWITTER_PREFERENCE_DATE_TIMELINE
																group:TWITTER_PREFERENCE_GROUP_UPDATES];
		
		for (NSDictionary *status in [statuses reverseObjectEnumerator]) {
			NSDate			*date = [status objectForKey:TWITTER_STATUS_CREATED];
			NSString		*text = [status objectForKey:TWITTER_STATUS_TEXT];
			AIListContact	*listContact = [self contactWithUID:[[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_STATUS_UID]];
			
			// Update the user's status message if necessary.
			if(![[listContact.statusMessage string] isEqualToString:text]) {
				[listContact setStatusMessage:[NSAttributedString stringWithString:text]
									   notify:NotifyLater];
			}
			
			if(timelineChat && [date compare:lastFollowedTimelinePull] != NSOrderedAscending) {
				AIContentMessage *contentMessage = [AIContentMessage messageInChat:timelineChat
																		withSource:listContact
																	   destination:self
																			  date:date
																		   message:[NSAttributedString stringWithString:text]
																		 autoreply:NO];
				
				[adium.contentController receiveContentObject:contentMessage];
			}
		}
		
		if (timelineChat) {
			// Set the "last pulled" date for Direct Messages, only if we've pushed content to the timeline.
			[self setPreference:[[self dictionaryForRequestID:identifier] objectForKey:@"Date"]
						 forKey:TWITTER_PREFERENCE_DATE_TIMELINE
						  group:TWITTER_PREFERENCE_GROUP_UPDATES];
		}
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)identifier
{	
	if ([self requestTypeForRequestID:identifier] == AITwitterUpdateDirectMessage) {		
		NSDate		*lastDirectMessagePull = [self preferenceForKey:TWITTER_PREFERENCE_DATE_DM
														  group:TWITTER_PREFERENCE_GROUP_UPDATES];
		
		for (NSDictionary *message in [messages reverseObjectEnumerator])  {
			NSDate			*receivedDate = [message objectForKey:TWITTER_DM_CREATED];
			NSString		*text = [message objectForKey:TWITTER_DM_TEXT];
			AIListContact	*listContact = [self contactWithUID:[message objectForKey:TWITTER_DM_SENDER_UID]];
					
			// We appear to continue to receive DMs even earlier than our requested date; explicitly check.
			if (listContact && text && receivedDate && [receivedDate compare:lastDirectMessagePull] != NSOrderedAscending) {
				AIChat	*chat = [adium.chatController chatWithContact:listContact];
			
				NSLog(@"Received DM: %@ %@ %@", receivedDate, text, listContact);
				
				AIContentMessage *contentMessage = [AIContentMessage messageInChat:chat
																		withSource:listContact
																	   destination:self
																			  date:receivedDate
																		   message:[NSAttributedString stringWithString:text]
																		 autoreply:NO];
				
				[adium.contentController receiveContentObject:contentMessage];
			}
		}
		
		// Set the "last pulled" date for Direct Messages
		[self setPreference:[[self dictionaryForRequestID:identifier] objectForKey:@"Date"]
					 forKey:TWITTER_PREFERENCE_DATE_DM
					  group:TWITTER_PREFERENCE_GROUP_UPDATES];
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)identifier
{	
	if ([self requestTypeForRequestID:identifier] == AITwitterInitialUserInfo) {			
		for (NSDictionary *info in userInfo) {
			AIListContact *listContact = [self contactWithUID:[info objectForKey:TWITTER_INFO_UID]];
			
			// If the user isn't in a group, set them in the Twitter group.
			if(listContact.remoteGroupNames.count == 0) {
				[listContact addRemoteGroupName:TWITTER_REMOTE_GROUP_NAME];
			}
		
			// Grab the Twitter display name and set it as the remote alias.
			if (![[listContact valueForProperty:@"Server Display Name"] isEqualToString:[info objectForKey:TWITTER_INFO_DISPLAY_NAME]]) {
				[listContact setServersideAlias:[info objectForKey:TWITTER_INFO_DISPLAY_NAME]
									   silently:silentAndDelayed];
			}
			
			// Grab the user icon and set it as their serverside icon.
			NSString *requestID = [twitterEngine getImageAtURL:[info objectForKey:TWITTER_INFO_ICON]];
			
			if(requestID) {
				[self setRequestType:AITwitterUserIconPull
						forRequestID:requestID
					  withDictionary:[NSDictionary dictionaryWithObject:listContact forKey:@"ListContact"]];
			}
			
			// Set the user as available.
			[listContact setStatusWithName:nil
								statusType:AIAvailableStatusType
									notify:NotifyLater];
			
			// Set the user's status message to their current twitter status text
			[listContact setStatusMessage:[NSAttributedString stringWithString:[[info objectForKey:TWITTER_INFO_STATUS] objectForKey:TWITTER_INFO_STATUS_TEXT]]
								   notify:NotifyLater];
		
			// Set the user as online.
			[listContact setOnline:YES notify:NotifyNow silently:silentAndDelayed];
		}
		
		// Trigger our normal update routine.
		[updateTimer fire];
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)identifier
{
	NSLog(@"Got misc info:\r%@", miscInfo);
}

- (void)imageReceived:(NSImage *)image forRequest:(NSString *)identifier
{
	if([self requestTypeForRequestID:identifier] == AITwitterUserIconPull) {
		AIListContact		*listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
		
		[listContact setServersideIconData:[image TIFFRepresentation]
									notify:NotifyLater];
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

@end
