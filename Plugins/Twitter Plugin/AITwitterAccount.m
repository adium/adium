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

#import "AITwitterAccount.h"
#import "AITwitterURLParser.h"
#import "MGTwitterEngine/MGTwitterEngine.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
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
#import <Adium/AIUserIcons.h>
#import <Adium/AIService.h>

@interface AITwitterAccount()
- (void)updateUserIcon:(NSString *)url forContact:(AIListContact *)listContact;

- (void)updateTimelineChat:(AIChat *)timelineChat;

- (NSAttributedString *)parseMessage:(NSString *)message;
- (NSAttributedString *)parseMessage:(NSString *)inMessage
							 tweetID:(NSString *)tweetID
							  userID:(NSString *)userID
					inReplyToTweetID:(NSString *)replyTweetID;

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
	
	[adium.notificationCenter addObserver:self
							     selector:@selector(chatDidOpen:) 
									 name:Chat_DidOpen
								   object:nil];
}

- (void)dealloc
{
	[adium.notificationCenter removeObserver:self];
	
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
	if(![adium.contactController existingBookmarkForChatName:self.timelineChatName
												   onAccount:self
											chatCreationInfo:nil]) {	
		AIChat *newTimelineChat = [adium.chatController chatWithName:self.timelineChatName
														  identifier:nil
														   onAccount:self 
													chatCreationInfo:nil];
		
		AIListBookmark *timelineBookmark = [adium.contactController bookmarkForChat:newTimelineChat];
		
		if(timelineBookmark.remoteGroupNames.count == 0) {
			[timelineBookmark addRemoteGroupName:TWITTER_REMOTE_GROUP_NAME];
		}	
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
	[updateTimer invalidate]; updateTimer = nil;
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
 * @brief Returns whether or not this account is connected via an encrypted connection.
 */
- (BOOL)encrypted
{
	return [twitterEngine usesSecureConnection];
}

/*!
 * @brief Affirm we can open chats.
 */
- (BOOL)openChat:(AIChat *)chat
{	
	return YES;
}

/*!
 * @brief Allow all chats to close.
 */
- (BOOL)closeChat:(AIChat *)inChat
{	
	return YES;
}

/*!
 * @brief Rejoin the requested chat.
 */
- (BOOL)rejoinChat:(AIChat *)inChat
{	
	return YES;
}

/*!
 * @brief A chat opened.
 *
 * If this is a group chat which belongs to us, aka a timeline chat, set it up how we want it.
 */
- (void)chatDidOpen:(NSNotification *)notification
{
	AIChat *chat = [notification object];
	
	if(chat.isGroupChat && chat.account == self) {
		[self updateTimelineChat:chat];
	}	
}

/*!
 * @brief We support adding and removing follows.
 */
- (BOOL)contactListEditable
{
    return self.online;
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
	NSString *requestID;
	
	if(inContentMessage.chat.isGroupChat) {
		NSInteger replyID = [[inContentMessage.chat valueForProperty:@"TweetInReplyToStatusID"] integerValue];
		
		requestID = [twitterEngine sendUpdate:inContentMessage.messageString
									inReplyTo:replyID];
		
		AILogWithSignature(@"Sending update [in reply to %d]: %@", replyID, inContentMessage.messageString);
	} else {		
		requestID = [twitterEngine sendDirectMessage:inContentMessage.messageString
												  to:inContentMessage.destination.UID];
		
		AILogWithSignature(@"Sending DM to %@: %@", inContentMessage.destination.UID, inContentMessage.messageString);
	}
	
	if(requestID) {
		[self setRequestType:AITwitterDirectMessageSend
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObject:inContentMessage.chat
														 forKey:@"Chat"]];
		return YES;
	} else {
		AILogWithSignature(@"Message immediate fail.");
		return NO;
	}
}

/*!
 * @brief Trigger an info update
 *
 * This is called when the info inspector wants more information on a contact.
 * Grab the user's profile information, set everything up accordingly in the user info method.
 */
- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{
	if(!self.online) {
		return;
	}
	
	NSString *requestID = [twitterEngine getUserInformationFor:inContact.UID];
	
	if(requestID) {
		[self setRequestType:AITwitterProfileUserInfo
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObject:inContact forKey:@"ListContact"]];
	}
}

/*!
 * @brief Should an autoreply be sent to this message?
 */
- (BOOL)shouldSendAutoreplyToMessage:(AIContentMessage *)message
{
	return NO;
}

#pragma mark Menu Items
/*!
 * @brief Menu items for chat
 *
 * Returns an array of menu items for a chat on this account.  This is the best place to add protocol-specific
 * actions that aren't otherwise supported by Adium.
 * @param inChat AIChat for menu items
 * @return NSArray of NSMenuItem instances for the passed contact
 */
- (NSArray *)menuItemsForChat:(AIChat *)inChat
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
 * @brief The name of our timeline chat
 */
- (NSString *)timelineChatName
{
	return [NSString stringWithFormat:TWITTER_TIMELINE_NAME, self.UID];
}

/*!
 * @brief Update the timeline chat
 * 
 * Remove the userlist
 */
- (void)updateTimelineChat:(AIChat *)timelineChat
{
	// Disable the user list on the chat.
	if (timelineChat.chatContainer.chatViewController.userListVisible) {
		[timelineChat.chatContainer.chatViewController toggleUserList]; 
	}	
	
	// Update the participant list.
	for (AIListContact *listContact in self.contacts) {
		[timelineChat addParticipatingListObject:listContact notify:NotifyNow];
	}
	
	[timelineChat setValue:[NSNumber numberWithInt:140] forProperty:@"Character Counter Max" notify:NotifyNow];
}

/*!
 * @brief Update a user icon from a URL if necessary
 */
- (void)updateUserIcon:(NSString *)url forContact:(AIListContact *)listContact;
{
	// If we don't already have an icon for the user...
	if(![AIUserIcons userIconSourceForObject:listContact] && ![[listContact valueForProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON] boolValue]) {
		// Grab the user icon and set it as their serverside icon.
		NSString *requestID = [twitterEngine getImageAtURL:url];
		
		if(requestID) {
			[self setRequestType:AITwitterUserIconPull
					forRequestID:requestID
				  withDictionary:[NSDictionary dictionaryWithObject:listContact forKey:@"ListContact"]];
		}
		
		[listContact setValue:[NSNumber numberWithBool:YES] forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
	}
}

/*!
 * @brief Unfollow the requested contacts.
 */
- (void)removeContacts:(NSArray *)objects
{	
	for (AIListContact *object in objects) {
		NSString *requestID = [twitterEngine disableUpdatesFor:object.UID];
		
		AILogWithSignature(@"Requesting unfollow for: %@", object.UID);
		
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
	
	AILogWithSignature(@"Requesting follow for: %@", contact.UID);
	
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
	
	[queuedUpdates removeAllObjects];
	[queuedDM removeAllObjects];
	
	// We'll update the date preferences for last pulled times when the response is received.
	// We use the current date, not the date when received, just in case a request is received in-between.
	
	AILogWithSignature(@"Periodic update fire");
	
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

#pragma mark Message Display
/*!
 * @brief Parses a Twitter message into an attributed string
 *
 * This is a shortcut method if no additional information is provided
 */
- (NSAttributedString *)parseMessage:(NSString *)inMessage
{
	return [self parseMessage:inMessage
					  tweetID:nil
					   userID:nil
			 inReplyToTweetID:nil];
}

/*!
 * @brief Parses a Twitter message into an attributed string
 */
- (NSAttributedString *)parseMessage:(NSString *)inMessage
							 tweetID:(NSString *)tweetID
							  userID:(NSString *)userID
					inReplyToTweetID:(NSString *)replyTweetID
{
	NSAttributedString *message;
	
	message = [NSAttributedString stringWithString:[inMessage stringByUnescapingFromXMLWithEntities:nil]];
	
	message = [AITwitterURLParser linkifiedAttributedStringFromString:message];
	
	BOOL replyTweet = ([replyTweetID length]);
	BOOL tweetLink = ([tweetID length] && [userID length]);
	
	if (replyTweet || tweetLink) {
		NSMutableAttributedString *mutableMessage = [[message mutableCopy] autorelease];
		
		[mutableMessage appendString:@"  (" withAttributes:nil];
	
		// Append a link to the tweet this is in reply to
		if (replyTweet) {
			// Parse out the user this is in reply to. I really wish Twitter provided it on its own.
			NSString *replyUsername = [inMessage substringFromIndex:1];
			NSRange usernameRange = [replyUsername rangeOfCharacterFromSet:[self.service.allowedCharacters invertedSet]];
			
			if(usernameRange.location == NSNotFound) {
				usernameRange = NSMakeRange([replyUsername length], 0);
			}
			
			replyUsername = [replyUsername substringToIndex:usernameRange.location];
			
			NSString *linkAddress = [NSString stringWithFormat:@"https://twitter.com/%@/status/%@", replyUsername, replyTweetID];
			
			[mutableMessage appendString:AILocalizedString(@"original", "Link appended which goes to the permanent location of the status this tweet is in reply to")
						  withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:linkAddress, NSLinkAttributeName, nil]];
		}
		
		// Append a link to reply to this tweet
		if (tweetLink) {
			NSString *linkAddress = [NSString stringWithFormat:@"twitterreply://%@@%@?status=%@", self.UID, userID, tweetID];
			
			if(replyTweet) {
				[mutableMessage appendString:@", " withAttributes:nil];
			}
			
			[mutableMessage appendString:AILocalizedString(@"reply", "Link appended to tweets to reply to *this* tweet")
						  withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:linkAddress, NSLinkAttributeName, nil]];
			
			linkAddress = [NSString stringWithFormat:@"https://twitter.com/%@/status/%@", userID, tweetID];
			
			[mutableMessage appendString:@", " withAttributes:nil];
			
			[mutableMessage appendString:AILocalizedString(@"link", "Link appended which goes to the permanent location of this tweet")
						  withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:linkAddress, NSLinkAttributeName, nil]];			

		}
	
		[mutableMessage appendString:@")" withAttributes:nil];
	
		return mutableMessage;
	} else {
		return message;
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
		if([queuedUpdates count] == 0) {
			return;
		}
		
		AILogWithSignature(@"Displaying %d updates", [queuedUpdates count]);
		
		// Sort the queued updates (since we're intermingling pages of data from different souces)
		NSArray *sortedQueuedUpdates = [queuedUpdates sortedArrayUsingFunction:queuedUpdatesSort context:nil];
		
		AIChat *timelineChat = [adium.chatController existingChatWithName:self.timelineChatName
																onAccount:self];
		
		if (!timelineChat) {
			timelineChat = [adium.chatController chatWithName:self.timelineChatName
												   identifier:nil
													onAccount:self
											 chatCreationInfo:nil];
		}
		
		for (NSDictionary *status in sortedQueuedUpdates) {
			NSDate			*date = [status objectForKey:TWITTER_STATUS_CREATED];
			NSString		*text = [status objectForKey:TWITTER_STATUS_TEXT];
			AIListContact	*listContact = [self contactWithUID:[[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_STATUS_UID]];
			
			if (![listContact.UID isEqualToString:self.UID]) {
				// Update the user's status message
				[listContact setStatusMessage:[NSAttributedString stringWithString:[text stringByUnescapingFromXMLWithEntities:nil]]
									   notify:NotifyNow];
				
				[self updateUserIcon:[[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_INFO_ICON] forContact:listContact];
				
				[timelineChat addParticipatingListObject:listContact notify:NotifyNow];
				
				NSAttributedString *message = [self parseMessage:text
														 tweetID:[status objectForKey:TWITTER_STATUS_ID]
														  userID:listContact.UID
												inReplyToTweetID:[status objectForKey:TWITTER_STATUS_REPLY_ID]];
				
				AIContentMessage *contentMessage = [AIContentMessage messageInChat:timelineChat
																		withSource:listContact
																	   destination:self
																			  date:date
																		   message:message
																		 autoreply:NO];
				
				[adium.contentController receiveContentObject:contentMessage];
			}
		}
		
		[queuedUpdates removeAllObjects];
	} else if (requestType == AITwitterUpdateDirectMessage) {
		if([queuedDM count] == 0) {
			return;
		}
		
		AILogWithSignature(@"Displaying %d DMs", [queuedDM count]);
		
		NSArray *sortedQueuedDM = [queuedDM sortedArrayUsingFunction:queuedDMSort context:nil];
		
		for (NSDictionary *message in sortedQueuedDM) {
			NSDate			*date = [message objectForKey:TWITTER_DM_CREATED];
			NSString		*text = [message objectForKey:TWITTER_DM_TEXT];
			AIListContact	*listContact = [self contactWithUID:[message objectForKey:TWITTER_DM_SENDER_UID]];
			AIChat			*chat = [adium.chatController chatWithContact:listContact];
			
			if(chat) {
				AIContentMessage *contentMessage = [AIContentMessage messageInChat:chat
																		withSource:listContact
																	   destination:self
																			  date:date
																		   message:[self parseMessage:text]
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
		
		AILogWithSignature(@"Chat send error on %@", chat);
		
	} else if ([self requestTypeForRequestID:identifier] == AITwitterDisconnect) {
		[self didDisconnect];
	} else if ([self requestTypeForRequestID:identifier] == AITwitterValidateCredentials) {
		// Error code 401 is an invalid password.
		if([error code] == 401) {
			[self setLastDisconnectionError:TWITTER_INCORRECT_PASSWORD_MESSAGE];
			[self serverReportedInvalidPassword];
		} else {
			[self setLastDisconnectionError:AILocalizedString(@"Unable to Connect", nil)];
		}
		[self didDisconnect];
	} else if ([self requestTypeForRequestID:identifier] == AITwitterInitialUserInfo) {
		[self setLastDisconnectionError:AILocalizedString(@"Unable to retrieve user list", "Message when a (vital) twitter request to retrieve the follow list fails")];
		[self didDisconnect];
	} else if([self requestTypeForRequestID:identifier] == AITwitterUserIconPull) {
		AIListContact *listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
		
		// Image pull failed, flag ourselves as needing to try again.
		[listContact setValue:nil forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
	}
	
	AILogWithSignature(@"Request failed (%@ - %d) - %@", identifier, [self requestTypeForRequestID:identifier], error);
	
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
		// If there's nothing in this set of statuses, then there's no need to get another page.
		BOOL nextPageNecessary = (lastPull != nil && [statuses count] != 0);
		
		// The order doesn't matter since we'll sort later, but for the sake of updating statuses, let's go backwards.
		for (NSDictionary *status in [statuses reverseObjectEnumerator]) {
			NSDate			*date = [status objectForKey:TWITTER_STATUS_CREATED];
			
			if ([date compare:lastPull] == NSOrderedAscending) {
				nextPageNecessary = NO;
			} else {
				[queuedUpdates addObject:status];
			}
		}
		
		AILogWithSignature(@"Last Pull: %@ Next Page Necessary: %d", lastPull, nextPageNecessary);
		
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
				
				AILogWithSignature(@"Pulling additional timeline page %d", nextPage);
				
				if (requestID) {
					[self setRequestType:AITwitterUpdateFollowedTimeline
							forRequestID:requestID
						  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:nextPage], @"Page",
										  requestDate, @"Date", nil]];
				} else {
					// Gracefully fail: remove all stored objects.
					AILogWithSignature(@"Immediate timeline fail");
					[queuedUpdates removeAllObjects];
				}
				
			} else if ([self requestTypeForRequestID:identifier] == AITwitterUpdateReplies) {
				requestID = [twitterEngine getRepliesStartingAtPage:nextPage];
				
				AILogWithSignature(@"Pulling additional replies page %d", nextPage);
				
				if (requestID) {
					[self setRequestType:AITwitterUpdateReplies
							forRequestID:requestID
						  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:nextPage], @"Page",
										  requestDate, @"Date", nil]];
				} else {
					// Gracefully fail: remove all stored objects.
					AILogWithSignature(@"Immediate reply fail");
					[queuedUpdates removeAllObjects];
				}
			}
		} else {
			if([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline) {
				followedTimelineCompleted = YES;
			} else if ([self requestTypeForRequestID:identifier] == AITwitterUpdateReplies) {
				repliesCompleted = YES;
			}
			
			AILogWithSignature(@"Followed completed: %d Replies completed: %d", followedTimelineCompleted, repliesCompleted);
			
			if (followedTimelineCompleted && repliesCompleted && [queuedUpdates count] > 0) {
				// Set the "last pulled" for the timeline, since we've completed both replies and the timeline.
				[self setPreference:[[self dictionaryForRequestID:identifier] objectForKey:@"Date"]
							 forKey:TWITTER_PREFERENCE_DATE_TIMELINE
							  group:TWITTER_PREFERENCE_GROUP_UPDATES];
				
				[self displayQueuedUpdatesForRequestType:[self requestTypeForRequestID:identifier]];
			}
		}
	} else if ([self requestTypeForRequestID:identifier] == AITwitterProfileStatusUpdates) {
		AIListContact *listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];

		NSMutableArray *profileArray = [[listContact profileArray] mutableCopy];
		
		AILogWithSignature(@"Updating statuses for profile, user %@", listContact);
		
		for (NSDictionary *update in statuses) {
			NSAttributedString *message = [self parseMessage:[update objectForKey:TWITTER_STATUS_TEXT]];
			
			[profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:message, KEY_VALUE, nil]];
		}
		
		[listContact setProfileArray:profileArray notify:NotifyNow];
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
		
		BOOL nextPageNecessary = (lastPull != nil && [messages count] != 0);
		
		for (NSDictionary *message in messages)  {
			NSDate			*date = [message objectForKey:TWITTER_DM_CREATED];
					
			if ([date compare:lastPull] == NSOrderedAscending) {
				nextPageNecessary = NO;
			} else {
				[queuedDM addObject:message];
			}
		}
		
		AILogWithSignature(@"Last pull: %@ Next page necessary: %d", lastPull, nextPageNecessary);
		
		if(nextPageNecessary) {
			NSInteger	nextPage = [[[self dictionaryForRequestID:identifier] objectForKey:@"Page"] intValue] + 1;
			NSDate		*requestDate = [[self dictionaryForRequestID:identifier] objectForKey:@"Date"];
			
			NSString	*requestID = [twitterEngine getDirectMessagesSince:lastPull startingAtPage:nextPage];
			
			AILogWithSignature(@"Pulling additional DM page %d", nextPage);
			
			if(requestID) {
				[self setRequestType:AITwitterUpdateDirectMessage
						forRequestID:requestID
					  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:nextPage], @"Page",
									  requestDate, @"Date", nil]];
			} else {
				// Gracefully fail: remove all stored objects.
				AILogWithSignature(@"Immediate DM pull fail");
				[queuedDM removeAllObjects];
			}
		} else if([queuedDM count] > 0) {
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
		
		// The current amount of friends per page is 100. Use >= just in case this changes.
		BOOL nextPageNecessary = ([userInfo count] >= 100);
		
		AILogWithSignature(@"Initial user info pull, Next page necessary: %d Count: %d", nextPageNecessary, [userInfo count]);
		
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
			[self updateUserIcon:[info objectForKey:TWITTER_INFO_ICON] forContact:listContact];
			
			// Set the user as available.
			[listContact setStatusWithName:nil
								statusType:AIAvailableStatusType
									notify:NotifyLater];
			
			// Set the user's status message to their current twitter status text
			[listContact setStatusMessage:[NSAttributedString stringWithString:[[[info objectForKey:TWITTER_INFO_STATUS] objectForKey:TWITTER_INFO_STATUS_TEXT] stringByUnescapingFromXMLWithEntities:nil]]
								   notify:NotifyLater];
		
			// Set the user as online.
			[listContact setOnline:YES notify:NotifyLater silently:silentAndDelayed];
			
			[listContact notifyOfChangedPropertiesSilently:silentAndDelayed];
		}
		
		[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
		
		if (nextPageNecessary) {
			NSInteger	nextPage = [[[self dictionaryForRequestID:identifier] objectForKey:@"Page"] intValue] + 1;
			NSString	*requestID = [twitterEngine getRecentlyUpdatedFriendsFor:self.UID startingAtPage:nextPage];
			
			AILogWithSignature(@"Pulling additional user info page %d", nextPage);
			
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
	} else if ([self requestTypeForRequestID:identifier] == AITwitterProfileUserInfo) {
		NSDictionary *thisUserInfo = [userInfo objectAtIndex:0];
		
		if (thisUserInfo) {	
			NSArray *keyNames = [NSArray arrayWithObjects:@"screen_name", @"name", @"location", @"description", @"url", @"friends_count", @"followers_count", @"statuses_count", nil];
			NSArray *readableNames = [NSArray arrayWithObjects:AILocalizedString(@"User name", nil), AILocalizedString(@"Name", nil), AILocalizedString(@"Location", nil),
									  AILocalizedString(@"Biography", nil), AILocalizedString(@"Website", nil), AILocalizedString(@"Following", nil),
									  AILocalizedString(@"Followers", nil), AILocalizedString(@"Updates", nil), nil];
			
			NSMutableArray *profileArray = [NSMutableArray array];
			
			for (NSUInteger index = 0; index < [keyNames count]; index++) {
				NSString			*unattributedValue = [thisUserInfo objectForKey:[keyNames objectAtIndex:index]];
				
				if(![unattributedValue isEqualToString:@""]) {
					NSString			*readableName = [readableNames objectAtIndex:index];
					NSAttributedString	*value = [NSAttributedString stringWithString:unattributedValue];
					
					[profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:readableName, KEY_KEY, value, KEY_VALUE, nil]];
				}
			}
			
			AIListContact	*listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
			
			AILogWithSignature(@"Updating profileArray for user %@", listContact);
			
			[listContact setProfileArray:profileArray notify:NotifyNow];
			
			// Grab their statuses.
			NSString *requestID = [twitterEngine getUserTimelineFor:listContact.UID since:nil startingAtPage:0 count:TWITTER_UPDATE_USER_INFO_COUNT];
			
			if (requestID) {
				[self setRequestType:AITwitterProfileStatusUpdates
						forRequestID:requestID
					  withDictionary:[NSDictionary dictionaryWithObject:listContact forKey:@"ListContact"]];
			}
		}
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

/*!
 * @brief Miscellaneous information received
 */
- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)identifier
{
	AILogWithSignature(@"Got misc info: %@", miscInfo);
}

/*!
 * @brief Requested image received
 */
- (void)imageReceived:(NSImage *)image forRequest:(NSString *)identifier
{
	if([self requestTypeForRequestID:identifier] == AITwitterUserIconPull) {
		AIListContact		*listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
		
		AILogWithSignature(@"Updated user icon for %@", listContact);
		
		[listContact setServersideIconData:[image TIFFRepresentation]
									notify:NotifyLater];
		
		[listContact setValue:nil forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

@end
