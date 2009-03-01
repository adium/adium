//
//  AITwitterAccount.m
//  Adium
//
//  Created by Zachary West on 2009-02-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AITwitterAccount.h"
#import "MGTwitterEngine/MGTwitterEngine.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContactObserverManager.h>
#import <Adium/AIListContact.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIChat.h>

@interface AITwitterAccount()
- (void)setRequestType:(AITwitterRequestType)type forRequestID:(NSString *)requestID withDictionary:(NSDictionary *)info;
- (AITwitterRequestType)requestTypeForRequestID:(NSString *)requestID;
- (NSDictionary *)dictionaryForRequestID:(NSString *)requestID;
- (void)clearRequestTypeForRequestID:(NSString *)requestID;

- (void)updateTimer:(NSTimer *)timer;
- (void)displayQueuedUpdatesForRequestType:(AITwitterRequestType)requestType;
@end

@implementation AITwitterAccount
- (void)initAccount
{
	[super initAccount];
	
	twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
	pendingRequests = [[NSMutableDictionary alloc] init];
	queuedUpdates = [[NSMutableArray alloc] init];
	queuedDM = [[NSMutableArray alloc] init];
	updateTimer = nil;
	
	[twitterEngine setClientName:@"Adium"
						 version:[NSApp applicationVersion]
							 URL:@"http://www.adiumx.com"
						   token:@""];
}

- (void)dealloc
{
	[twitterEngine release];
	[pendingRequests release];
	[queuedUpdates release];
	[queuedDM release];
	
	[super dealloc];
}

#pragma mark AIAccount methods
/*!
 * @brief We've been asked to connect.
 *
 * Sets our username and password for MGTwitterEngine, and validates credentials.
 */
- (void)connect
{
	[super connect];
	
	[twitterEngine setUsername:self.UID password:self.passwordWhileConnected];
	
	NSString *requestID = [twitterEngine checkUserCredentials];
	
	if (requestID) {
		[self setRequestType:AITwitterValidateCredentials forRequestID:requestID withDictionary:nil];
	} else {
		[self setLastDisconnectionError:AILocalizedString(@"Unable to Connect", nil)];
		[self didDisconnect];
	}
}

/*!
 * @brief Connection successful
 *
 * Our credentials were validated correctly. Set up the timeline chat, and request our friends from the server.
 */
- (void)didConnect
{
	[super didConnect];
	
	//Clear any previous disconnection error
	[self setLastDisconnectionError:nil];
	
	[self silenceAllContactUpdatesForInterval:18.0];
	
	// Creating the fake timeline account.
	{
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
		[listContact setOnline:YES notify:NotifyLater silently:silentAndDelayed];	
		
		[listContact notifyOfChangedPropertiesSilently:silentAndDelayed];
	}
	
	// Grab all of our real updates	
	NSString	*requestID = [twitterEngine getRecentlyUpdatedFriendsFor:self.UID startingAtPage:1];
	
	if (requestID) {
		[self setRequestType:AITwitterInitialUserInfo
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"Page"]];
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

/*!
 * @brief We've been asked to disconnect.
 *
 * End the session.
 */
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
	
	[super disconnect];
}

/*!
 * @brief Session ended
 *
 * Remove all state information.
 */
- (void)didDisconnect
{
	[updateTimer invalidate];
	[pendingRequests removeAllObjects];
	[queuedDM removeAllObjects];
	[queuedUpdates removeAllObjects];
	
	[super didDisconnect];
}

/*!
 * @brief We connect to twitter.com
 *
 * This lets the network accessibility stuff understand where we're going.
 */
- (NSString *)host
{
	return @"twitter.com";
}

/*!
 * @brief Affirm we can open chats.
 */
- (BOOL)openChat:(AIChat *)chat
{	
	if([chat.listObject.UID isEqualToString:TWITTER_TIMELINE_UID]) {
		timelineChat = chat;
			
		[updateTimer fire];
	}
	
	return YES;
}

/*!
 * @brief Allow all chats to close.
 */
- (BOOL)closeChat:(AIChat *)inChat
{
	if(inChat == timelineChat) {
		timelineChat = nil;
	}
	
	return YES;
}

/*!
 * @brief We support adding and removing follows.
 */
- (BOOL)contactListEditable
{
    return [self online];
}

/*!
 * @brief Immediately retry for an incorrect password.
 */
- (AIReconnectDelayType)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	AIReconnectDelayType reconnectDelayType = [super shouldAttemptReconnectAfterDisconnectionError:disconnectionError];
	
	if ([*disconnectionError isEqualToString:TWITTER_INCORRECT_PASSWORD_MESSAGE]) {
		reconnectDelayType = AIReconnectImmediately;
	}
	
	return reconnectDelayType;
}

/*!
 * @brief Don't allow OTR encryption.
 */
- (BOOL)allowSecureMessagingTogglingForChat:(AIChat *)inChat
{
	return NO;
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
	NSLog(@"Sending message to: %@ content: %@", [[inContentMessage destination] UID], [inContentMessage messageString]);
	
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

#pragma mark Menu Items
/*!
 * @brief Menu items for the account's actions
 *
 * Returns an array of menu items for account-specific actions.  This is the best place to add protocol-specific
 * actions that aren't otherwise supported by Adium.  It will only be queried if the account is online.
 * @return NSArray of NSMenuItem instances for this account
 */
- (NSArray *)accountActionMenuItems
{
	NSMutableArray *menuItemArray = [NSMutableArray array];
	
	NSMenuItem *menuItem;
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Force Refresh",nil)
																	target:self
																	action:@selector(forceUpdate:)
															 keyEquivalent:@""] autorelease];
	[menuItemArray addObject:menuItem];
	
	return menuItemArray;	
}

/*!
 * @brief Forces our periodic updates to fire.
 */
- (void)forceUpdate:(NSMenuItem *)menuItem
{
	[updateTimer fire];
}

#pragma mark Contact handling
/*!
 * @brief Unfollow the requested contacts.
 */
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

/*!
 * @brief Follow the requested contact, trigger an information pull for them.
 */
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
	NSString	*requestID;
	NSDate		*lastPull;
	NSDate		*requestDate = [NSDate date];
	
	// We haven't completed the timeline nor replies.
	// This state information helps us know how many pages to pull.
	followedTimelineCompleted = repliesCompleted = NO;
	
	// We'll update the date preferences for last pulled times when the response is received.
	// We use the current date, not the date when received, just in case a request is received in-between.
	
	// Pull direct messages	
	lastPull = [self preferenceForKey:TWITTER_PREFERENCE_DATE_DM
								group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	requestID = [twitterEngine getDirectMessagesSince:lastPull startingAtPage:1];
	
	if (requestID) {
		[self setRequestType:AITwitterUpdateDirectMessage
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"Page",
							  requestDate, @"Date", nil]];
	}

	// Pull followed timeline
	lastPull = [self preferenceForKey:TWITTER_PREFERENCE_DATE_TIMELINE
								group:TWITTER_PREFERENCE_GROUP_UPDATES];

	requestID = [twitterEngine getFollowedTimelineFor:self.UID
												since:lastPull
									   startingAtPage:1
												count:TWITTER_UPDATE_TIMELINE_COUNT];
	
	if (requestID) {
		[self setRequestType:AITwitterUpdateFollowedTimeline
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"Page",
							  requestDate, @"Date", nil]];
	}
	
	// Pull the replies feed	
	requestID = [twitterEngine getRepliesStartingAtPage:1];
	
	if (requestID) {
		[self setRequestType:AITwitterUpdateReplies
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"Page",
							  requestDate, @"Date", nil]];
	}
}

/*!
 * @brief Sort status updates
 */
NSInteger queuedUpdatesSort(id update1, id update2, void *context)
{
	return [[update1 objectForKey:TWITTER_STATUS_CREATED] compare:[update2 objectForKey:TWITTER_STATUS_CREATED]];
}

/*!
 * @brief Sort direct messages
 */
NSInteger queuedDMSort(id dm1, id dm2, void *context)
{
	return [[dm1 objectForKey:TWITTER_DM_CREATED] compare:[dm2 objectForKey:TWITTER_DM_CREATED]];	
}

/*!
 * @brief Display queued updates or direct messages
 *
 * This could potentially be simplified since both DMs and updates have the same format.
 */
- (void)displayQueuedUpdatesForRequestType:(AITwitterRequestType)requestType
{
	if(requestType == AITwitterUpdateReplies || requestType == AITwitterUpdateFollowedTimeline) {
		// Sort the queued updates (since we're intermingling pages of data from different souces)
		NSArray *sortedQueuedUpdates = [queuedUpdates sortedArrayUsingFunction:queuedUpdatesSort context:nil];
		
		for (NSDictionary *status in sortedQueuedUpdates) {
			NSDate			*date = [status objectForKey:TWITTER_STATUS_CREATED];
			NSString		*text = [status objectForKey:TWITTER_STATUS_TEXT];
			AIListContact	*listContact = [self contactWithUID:[[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_STATUS_UID]];
			
			// Update the user's status message
			[listContact setStatusMessage:[NSAttributedString stringWithString:text]
								   notify:NotifyNow];
			
			AIContentMessage *contentMessage = [AIContentMessage messageInChat:timelineChat
																	withSource:listContact
																   destination:self
																		  date:date
																	   message:[NSAttributedString stringWithString:text]
																	 autoreply:NO];
			
			[adium.contentController receiveContentObject:contentMessage];
		}
		
		[queuedUpdates removeAllObjects];
	} else if (requestType == AITwitterUpdateDirectMessage) {
		NSArray *sortedQueuedDM = [queuedDM sortedArrayUsingFunction:queuedDMSort context:nil];
		
		for (NSDictionary *message in sortedQueuedDM) {
			NSDate			*date = [message objectForKey:TWITTER_DM_CREATED];
			NSString		*text = [message objectForKey:TWITTER_DM_TEXT];
			AIListContact	*listContact = [self contactWithUID:[message objectForKey:TWITTER_DM_SENDER_UID]];
			AIChat			*chat = [adium.chatController chatWithContact:listContact];
			
			NSLog(@"Received DM: %@ %@ %@", date, text, listContact);
			
			if(chat) {
				AIContentMessage *contentMessage = [AIContentMessage messageInChat:chat
																		withSource:listContact
																	   destination:self
																			  date:date
																		   message:[NSAttributedString stringWithString:text]
																		 autoreply:NO];
				
				[adium.contentController receiveContentObject:contentMessage];
			}
		}
		
		[queuedDM removeAllObjects];
	}
}

#pragma mark MGTwitterEngine Delegate Methods
/*!
 * @brief A request was successful
 *
 * We only care about requests succeeding if they aren't specifically handled in another location.
 */
- (void)requestSucceeded:(NSString *)identifier
{
	// If a request succeeds and we think we're offline, call ourselves online.
	if ([self requestTypeForRequestID:identifier] == AITwitterDisconnect) {
		[self didDisconnect];
	} else if ([self requestTypeForRequestID:identifier] == AITwitterValidateCredentials) {
		[self didConnect];
	} else if ([self requestTypeForRequestID:identifier] == AITwitterRemoveFollow) {
		AIListContact *listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
		
		for (NSString *groupName in [[listContact.remoteGroupNames copy] autorelease]) {
			[listContact removeRemoteGroupName:groupName];
		}
	}
}

/*!
 * @brief A request failed
 *
 * If it's a fatal error, we need to kill the session and retry. Otherwise, twitter's reliability is
 * pretty terrible, so let's ignore errors for the most part.
 */
- (void)requestFailed:(NSString *)identifier withError:(NSError *)error
{		
	if([self requestTypeForRequestID:identifier] == AITwitterDirectMessageSend) {
		AIChat	*chat = [[self dictionaryForRequestID:identifier] objectForKey:@"Chat"];
		[chat receivedError:[NSNumber numberWithInt:AIChatUnknownError]];
	} else if ([self requestTypeForRequestID:identifier] == AITwitterDisconnect) {
		[self didDisconnect];
	} else if ([self requestTypeForRequestID:identifier] == AITwitterValidateCredentials) {
		// XXX check HTTP error code, make sure it's really a 401
		[self setLastDisconnectionError:TWITTER_INCORRECT_PASSWORD_MESSAGE];
		[self serverReportedInvalidPassword];
		[self didDisconnect];
	} else if ([self requestTypeForRequestID:identifier] == AITwitterInitialUserInfo) {
		[self setLastDisconnectionError:AILocalizedString(@"Unable to retrieve user list", "Message when a (vital) twitter request to retrieve the follow list fails")];
		[self didDisconnect];
	}
	
	NSLog(@"Request failed (%@) - %@", identifier, error);
	
	[self clearRequestTypeForRequestID:identifier];
}

/*!
 * @brief Status updates received
 */
- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier
{		
	if([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline ||
	   [self requestTypeForRequestID:identifier] == AITwitterUpdateReplies) {
		NSDate		*lastPull = [self preferenceForKey:TWITTER_PREFERENCE_DATE_TIMELINE
												 group:TWITTER_PREFERENCE_GROUP_UPDATES];
		
		// If we've never pulled anything before, we shall default to only pulling 1 page.
		// We only need to traverse more if we're pulling for the timeline chat.
		// If there's nothing in this set of statuses, then there's no need to get another page.
		BOOL nextPageNecessary = (timelineChat && lastPull != nil && [statuses count] != 0);
		
		NSLog(@"Type: %d", [self requestTypeForRequestID:identifier]);
		NSLog(@"Initial nPN: %d", nextPageNecessary);
		
		// The order doesn't matter since we'll sort later, but for the sake of updating statuses, let's go backwards.
		for (NSDictionary *status in [statuses reverseObjectEnumerator]) {
			NSDate			*date = [status objectForKey:TWITTER_STATUS_CREATED];
			
			if ([date compare:lastPull] == NSOrderedAscending) {
				nextPageNecessary = NO;
			} else if (timelineChat) {
				[queuedUpdates addObject:status];
			} else {
				// Only update status here if we're not pulling for a timeline.
				AIListContact	*listContact = [self contactWithUID:[[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_STATUS_UID]];
				NSString		*text = [status objectForKey:TWITTER_STATUS_TEXT];
				
				[listContact setStatusMessage:[NSAttributedString stringWithString:text]
									   notify:NotifyNow];
			}
		}
		
		NSLog(@"nPN after: %d", nextPageNecessary);
		
		// See if we need to pull more updates.
		if (nextPageNecessary) {
			NSInteger	nextPage = [[[self dictionaryForRequestID:identifier] objectForKey:@"Page"] intValue] + 1;
			NSDate		*requestDate = [[self dictionaryForRequestID:identifier] objectForKey:@"Date"];
			NSString	*requestID;
			
			if ([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline) {
				requestID = [twitterEngine getFollowedTimelineFor:self.UID
															since:lastPull
												   startingAtPage:nextPage
															count:TWITTER_UPDATE_TIMELINE_COUNT];
				
				NSLog(@"Pulling timeline page %d", nextPage);
				
				if (requestID) {
					[self setRequestType:AITwitterUpdateFollowedTimeline
							forRequestID:requestID
						  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:nextPage], @"Page",
										  requestDate, @"Date", nil]];
				} else {
					// Gracefully fail: remove all stored objects.
					[queuedUpdates removeAllObjects];
				}
				
			} else if ([self requestTypeForRequestID:identifier] == AITwitterUpdateReplies) {
				requestID = [twitterEngine getRepliesStartingAtPage:nextPage];
				
				NSLog(@"Pulling replies page %d", nextPage);
				
				if (requestID) {
					[self setRequestType:AITwitterUpdateReplies
							forRequestID:requestID
						  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:nextPage], @"Page",
										  requestDate, @"Date", nil]];
				} else {
					// Gracefully fail: remove all stored objects.
					[queuedUpdates removeAllObjects];
				}
			}
		} else 	if (timelineChat) {
			if([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline) {
				followedTimelineCompleted = YES;
			} else if ([self requestTypeForRequestID:identifier] == AITwitterUpdateReplies) {
				repliesCompleted = YES;
			}
			
			NSLog(@"fTC: %d rC: %d", followedTimelineCompleted, repliesCompleted);
			
			if (followedTimelineCompleted && repliesCompleted) {
				// Set the "last pulled" for the timeline, since we've completed both replies and the timeline.
				[self setPreference:[[self dictionaryForRequestID:identifier] objectForKey:@"Date"]
							 forKey:TWITTER_PREFERENCE_DATE_TIMELINE
							  group:TWITTER_PREFERENCE_GROUP_UPDATES];
				
				[self displayQueuedUpdatesForRequestType:[self requestTypeForRequestID:identifier]];
			}
		}
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

/*!
 * @brief Direct messages received
 */
- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)identifier
{	
	if ([self requestTypeForRequestID:identifier] == AITwitterUpdateDirectMessage) {		
		NSDate		*lastPull = [self preferenceForKey:TWITTER_PREFERENCE_DATE_DM
												 group:TWITTER_PREFERENCE_GROUP_UPDATES];
		
		BOOL nextPageNecessary = ([messages count] != 0);
		
		NSLog(@"---- Page: %d", [[[self dictionaryForRequestID:identifier] objectForKey:@"Page"] intValue]);
		
		for (NSDictionary *message in messages)  {
			NSDate			*date = [message objectForKey:TWITTER_DM_CREATED];
			
			NSLog(@"Message: %@", date);
					
			if ([date compare:lastPull] == NSOrderedAscending) {
				nextPageNecessary = NO;
			} else {
				[queuedDM addObject:message];
			}
		}
		
		if(nextPageNecessary) {
			NSInteger	nextPage = [[[self dictionaryForRequestID:identifier] objectForKey:@"Page"] intValue] + 1;
			NSDate		*requestDate = [[self dictionaryForRequestID:identifier] objectForKey:@"Date"];
			
			NSString	*requestID = [twitterEngine getDirectMessagesSince:lastPull startingAtPage:nextPage];
			
			if(requestID) {
				[self setRequestType:AITwitterUpdateDirectMessage
						forRequestID:requestID
					  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:nextPage], @"Page",
									  requestDate, @"Date", nil]];
			} else {
				// Gracefully fail: remove all stored objects.
				[queuedDM removeAllObjects];
			}
		} else {
			[self setPreference:[[self dictionaryForRequestID:identifier] objectForKey:@"Date"]
						 forKey:TWITTER_PREFERENCE_DATE_DM
						  group:TWITTER_PREFERENCE_GROUP_UPDATES];
			
			[self displayQueuedUpdatesForRequestType:[self requestTypeForRequestID:identifier]];
		}
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

/*!
 * @brief User information received
 */
- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)identifier
{	
	if ([self requestTypeForRequestID:identifier] == AITwitterInitialUserInfo) {	
		[[AIContactObserverManager sharedManager] delayListObjectNotifications];
		
		BOOL nextPageNecessary = ([userInfo count] != 0);
		
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
			[listContact setOnline:YES notify:NotifyLater silently:silentAndDelayed];
			
			[listContact notifyOfChangedPropertiesSilently:silentAndDelayed];
		}
		
		[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
		
		if (nextPageNecessary) {
			NSInteger	nextPage = [[[self dictionaryForRequestID:identifier] objectForKey:@"Page"] intValue] + 1;
			NSString	*requestID = [twitterEngine getRecentlyUpdatedFriendsFor:self.UID startingAtPage:nextPage];
			
			if(requestID) {
				[self setRequestType:AITwitterInitialUserInfo
						forRequestID:requestID
					  withDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:nextPage]
																 forKey:@"Page"]];
			} else { 
				[self setLastDisconnectionError:AILocalizedString(@"Unable to retrieve user list", "Message when a (vital) twitter request to retrieve the follow list fails")];
				[self didDisconnect];
			}
			
		} else {	
			// Trigger our normal update routine.
			[updateTimer fire];
		}
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

/*!
 * @brief Miscellaneous information received
 */
- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)identifier
{
	NSLog(@"Got misc info:\r%@", miscInfo);
}

/*!
 * @brief Requested image received
 */
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
