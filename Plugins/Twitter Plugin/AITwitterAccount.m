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
#import "AITwitterReplyWindowController.h"
#import "MGTwitterEngine/MGTwitterEngine.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIContactObserverManager.h>
#import <Adium/AIListContact.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIChat.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>

@interface AITwitterAccount()
- (void)updateUserIcon:(NSString *)url forContact:(AIListContact *)listContact;

- (void)updateTimelineChat:(AIChat *)timelineChat;

- (NSAttributedString *)parseMessage:(NSString *)message;
- (NSAttributedString *)parseMessage:(NSString *)inMessage
							 tweetID:(NSString *)tweetID
							  userID:(NSString *)userID
					   inReplyToUser:(NSString *)replyUserID
					inReplyToTweetID:(NSString *)replyTweetID;

- (void)setRequestType:(AITwitterRequestType)type forRequestID:(NSString *)requestID withDictionary:(NSDictionary *)info;
- (AITwitterRequestType)requestTypeForRequestID:(NSString *)requestID;
- (NSDictionary *)dictionaryForRequestID:(NSString *)requestID;
- (void)clearRequestTypeForRequestID:(NSString *)requestID;

- (void)periodicUpdate;
- (void)displayQueuedUpdatesForRequestType:(AITwitterRequestType)requestType;

- (void)getRateLimitAmount;
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
	
	futureTimelineLastID = futureRepliesLastID = nil;
	
	[twitterEngine setClientName:@"Adium"
						 version:[NSApp applicationVersion]
							 URL:@"http://www.adiumx.com"
						   token:@"adiumofficial"];

	[adium.notificationCenter addObserver:self
							     selector:@selector(chatDidOpen:) 
									 name:Chat_DidOpen
								   object:nil];
	
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
												  [NSNumber numberWithInt:TWITTER_UPDATE_INTERVAL_MINUTES], TWITTER_PREFERENCE_UPDATE_INTERVAL,
												  [NSNumber numberWithBool:YES], TWITTER_PREFERENCE_UPDATE_AFTER_SEND, nil]
										forGroup:TWITTER_PREFERENCE_GROUP_UPDATES
										  object:self];
	
	updateAfterSend = [[self preferenceForKey:TWITTER_PREFERENCE_UPDATE_AFTER_SEND group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue];
	
	[adium.preferenceController registerPreferenceObserver:self forGroup:TWITTER_PREFERENCE_GROUP_UPDATES];
}

- (void)dealloc
{
	[adium.notificationCenter removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	
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
 *
 * Our connection procedure:
 * 1. Validate credentials
 * 2. Retrieve friends
 * 3. Trigger "periodic" update - DM, replies, timeline
 */
- (void)connect
{
	[super connect];
	
	[twitterEngine setAPIDomain:[self.host stringByAppendingPathComponent:self.apiPath]];
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
	
	// Creating the fake timeline account.
	if(![adium.contactController existingBookmarkForChatName:self.timelineChatName
												   onAccount:self
											chatCreationInfo:nil]) {	
		AIChat *newTimelineChat = [adium.chatController chatWithName:self.timelineChatName
														  identifier:nil
														   onAccount:self 
													chatCreationInfo:nil];
		
		AIListBookmark *timelineBookmark = [adium.contactController bookmarkForChat:newTimelineChat];
		
		[adium.contactController moveContact:timelineBookmark intoGroups:[NSSet setWithObject:[adium.contactController groupWithUID:TWITTER_REMOTE_GROUP_NAME]]];
	}
	
	NSTimeInterval updateInterval = [[self preferenceForKey:TWITTER_PREFERENCE_UPDATE_INTERVAL group:TWITTER_PREFERENCE_GROUP_UPDATES] intValue] * 60;
	
	if(updateInterval > 0) {
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval
													   target:self
													 selector:@selector(periodicUpdate)
													 userInfo:nil
													  repeats:YES];
	}
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
 * @brief API path
 *
 * The API path extension for the given host.
 */
- (NSString *)apiPath
{
	return nil;
}

/*!
 * @brief Returns whether or not this account is connected via an encrypted connection.
 */
- (BOOL)encrypted
{
	return (self.online && [twitterEngine usesSecureConnection]);
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
	[self displayYouHaveConnectedInChat:inChat];
	
	return YES;
}

/*!
 * @brief We always want to autocomplete the UID.
 */
- (BOOL)chatShouldAutocompleteUID:(AIChat *)inChat
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
 * @brief Move contacts
 *
 * Move existing contacts to a specific group on this account.  The passed contacts should already exist somewhere on
 * this account.
 * @param objects NSArray of AIListContact objects to remove
 * @param group AIListGroup destination for contacts
 */
- (void)moveListObjects:(NSArray *)objects toGroups:(NSSet *)groups
{
	// XXX do twitter grouping
}

/*!
 * @brief Rename a group
 *
 * Rename a group on this account.
 * @param group AIListGroup to rename
 * @param newName NSString name for the group
 */
- (void)renameGroup:(AIListGroup *)group to:(NSString *)newName
{
	// XXX do twitter grouping
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
	NSString *requestID = [twitterEngine sendUpdate:[statusMessage string]];

	if(requestID) {
		[self setRequestType:AITwitterSendUpdate
				forRequestID:requestID
			  withDictionary:nil];
	}
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
		
		if(requestID) {
			[self setRequestType:AITwitterSendUpdate
					forRequestID:requestID
				  withDictionary:[NSDictionary dictionaryWithObject:inContentMessage.chat
															 forKey:@"Chat"]];
			
			AILogWithSignature(@"%@ Sending update [in reply to %d]: %@", self, replyID, inContentMessage.messageString);
		}
		
		inContentMessage.displayContent = NO;
	} else {		
		requestID = [twitterEngine sendDirectMessage:inContentMessage.messageString
												  to:inContentMessage.destination.UID];
		
		if(requestID) {
			[self setRequestType:AITwitterDirectMessageSend
					forRequestID:requestID
				  withDictionary:[NSDictionary dictionaryWithObject:inContentMessage.chat
															 forKey:@"Chat"]];
			
			AILogWithSignature(@"%@ Sending DM to %@: %@", self, inContentMessage.destination.UID, inContentMessage.messageString);
		}
	}
	
	if (!requestID) {
		AILogWithSignature(@"%@ Message immediate fail.", self);
	}
	
	return (requestID != nil);
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
	
	if ([inContact isKindOfClass:[AIListBookmark class]]) {
		[inContact setProfileArray:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"", KEY_VALUE, nil]] notify:NotifyNow];
	} else {
		NSString *requestID = [twitterEngine getUserInformationFor:inContact.UID];
		
		if(requestID) {
			[self setRequestType:AITwitterProfileUserInfo
					forRequestID:requestID
				  withDictionary:[NSDictionary dictionaryWithObject:inContact forKey:@"ListContact"]];
		}
	}
}

/*!
 * @brief Should an autoreply be sent to this message?
 */
- (BOOL)shouldSendAutoreplyToMessage:(AIContentMessage *)message
{
	return NO;
}

/*!
 * @brief Update the Twitter profile
 */
- (void)setProfileName:(NSString *)name
				   url:(NSString*)url
			  location:(NSString *)location
		   description:(NSString *)description
{
	NSString *requestID = [twitterEngine updateProfileName:name
													 email:nil
													   url:url
												  location:location
											   description:description];
	
	if (requestID) {
		[self setRequestType:AITwitterProfileSelf
				forRequestID:requestID
			  withDictionary:nil];
	}
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
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Update Tweets",nil)
																	 target:self
																	 action:@selector(periodicUpdate)
															  keyEquivalent:@""] autorelease];
	[menuItemArray addObject:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Reply to a Tweet",nil)
																	 target:self
																	 action:@selector(replyToTweet)
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
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Update Tweets",nil)
																	target:self
																	action:@selector(periodicUpdate)
															 keyEquivalent:@""] autorelease];
	[menuItemArray addObject:menuItem];

	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Reply to a Tweet",nil)
																	 target:self
																	 action:@selector(replyToTweet)
															  keyEquivalent:@""] autorelease];
	[menuItemArray addObject:menuItem];

	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Get Rate Limit Amount",nil)
																	 target:self
																	 action:@selector(getRateLimitAmount)
															  keyEquivalent:@""] autorelease];
	[menuItemArray addObject:menuItem];
	
	return menuItemArray;	
}

/*!
 * @brief Open the reply to tweet window
 *
 * Opens a window in which the user can create a reply featuring in_reply_to_status_id being set.
 */
- (void)replyToTweet
{
	[AITwitterReplyWindowController showReplyWindowForAccount:self];
}

/*!
 * @brief Gets the current rate limit amount.
 */
- (void)getRateLimitAmount
{
	NSString *requestID = [twitterEngine getRateLimitStatus];
	
	if (requestID) {
		[self setRequestType:AITwitterRateLimitStatus
				forRequestID:requestID
			  withDictionary:nil];
	}
	
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
	[timelineChat addParticipatingListObjects:self.contacts notify:NotifyLater];
	
	[timelineChat setValue:[NSNumber numberWithInt:140] forProperty:@"Character Counter Max" notify:NotifyNow];
}

/*!
 * @brief Update serverside icon
 *
 * This is called by AIUserIcons when it needs an icon update for a contact.
 * If we already have an icon set, ignore it. Otherwise return the Twitter service icon.
 * This is so that when an unknown contact appears, it has an actual image
 * to replace in the WKMV when an actual icon update is returned.
 *
 * This service icon will not remain saved very long, I see no harm in using it.
 * This only occurs for "strangers".
 */
- (NSData *)serversideIconDataForContact:(AIListContact *)listContact
{
	if (![AIUserIcons userIconSourceForObject:listContact] && [listContact isStranger]) {
		return [[self.service defaultServiceIconOfType:AIServiceIconLarge] TIFFRepresentation];
	} else {
		return nil;
	}
}

/*!
 * @brief Update a user icon from a URL if necessary
 */
- (void)updateUserIcon:(NSString *)url forContact:(AIListContact *)listContact;
{
	// If we don't already have an icon for the user...
	if(![[listContact valueForProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON] boolValue]) {
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
		
		AILogWithSignature(@"%@ Requesting unfollow for: %@", self, object.UID);
		
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
	
	AILogWithSignature(@"%@ Requesting follow for: %@", self, contact.UID);
	
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

#pragma mark Preference updating
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];
	
	// We only care about our changes.
	if (object != self) {
		return;
	}
	
	if([group isEqualToString:GROUP_ACCOUNT_STATUS]) {
		if([key isEqualToString:KEY_USER_ICON]) {
			// Avoid pushing an icon update which we just downloaded.
			if(![self boolValueForProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON]) {
				NSString *requestID = [twitterEngine updateProfileImage:[prefDict objectForKey:KEY_USER_ICON]];
			
				if(requestID) {
					AILogWithSignature(@"%@ Pushing self icon update", self);
					
					[self setRequestType:AITwitterProfileSelf
							forRequestID:requestID
						  withDictionary:nil];
				}
			}
			
			[self setValue:nil forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
		}
	}
	
	if([group isEqualToString:TWITTER_PREFERENCE_GROUP_UPDATES]) {
		if(!firstTime && [key isEqualToString:TWITTER_PREFERENCE_UPDATE_INTERVAL]) {
			NSTimeInterval timeInterval = [updateTimer timeInterval];
			NSTimeInterval newTimeInterval = [[prefDict objectForKey:TWITTER_PREFERENCE_UPDATE_INTERVAL] intValue] * 60;
			
			if (timeInterval != newTimeInterval) {
				[updateTimer invalidate]; updateTimer = nil;
				
				if(newTimeInterval > 0) {
					updateTimer = [NSTimer scheduledTimerWithTimeInterval:newTimeInterval
																   target:self
																 selector:@selector(periodicUpdate)
																 userInfo:nil
																  repeats:YES];
				}
			}
		}
		
		if ([key isEqualToString:TWITTER_PREFERENCE_UPDATE_AFTER_SEND]) {		
			updateAfterSend = [[prefDict objectForKey:TWITTER_PREFERENCE_UPDATE_AFTER_SEND] boolValue];
		}
	}	
}

#pragma mark Periodic update scheduler
/*!
 * @brief Trigger our periodic updates
 */
- (void)periodicUpdate
{
	if (pendingUpdateCount) {
		AILogWithSignature(@"%@ Update already in progress. Count = %d", self, pendingUpdateCount);
		return;
	}
	
	NSString	*requestID;
	NSUInteger	lastID;
	
	// We haven't completed the timeline nor replies. This lets us know if we should display statuses.
	followedTimelineCompleted = repliesCompleted = NO;
	
	// Prevent triggering this update routine multiple times.
	pendingUpdateCount = 3;
	
	[queuedUpdates removeAllObjects];
	[queuedDM removeAllObjects];
	
	AILogWithSignature(@"%@ Periodic update fire", self);
	
	// Pull direct messages	
	lastID = [[self preferenceForKey:TWITTER_PREFERENCE_DM_LAST_ID
								group:TWITTER_PREFERENCE_GROUP_UPDATES] intValue];
	
	requestID = [twitterEngine getDirectMessagesSinceID:lastID startingAtPage:1];
	
	if (requestID) {
		[self setRequestType:AITwitterUpdateDirectMessage
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"Page", nil]];
	} else {
		--pendingUpdateCount;
	}

	// Pull followed timeline
	lastID = [[self preferenceForKey:TWITTER_PREFERENCE_TIMELINE_LAST_ID
								group:TWITTER_PREFERENCE_GROUP_UPDATES] intValue];

	requestID = [twitterEngine getFollowedTimelineFor:nil
											  sinceID:lastID
									   startingAtPage:1
												count:(lastID ? TWITTER_UPDATE_TIMELINE_COUNT : TWITTER_UPDATE_TIMELINE_COUNT_FIRST_RUN)];
	
	if (requestID) {
		[self setRequestType:AITwitterUpdateFollowedTimeline
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"Page", nil]];
	} else {
		--pendingUpdateCount;
	}
	
	// Pull the replies feed	
	lastID = [[self preferenceForKey:TWITTER_PREFERENCE_REPLIES_LAST_ID
							   group:TWITTER_PREFERENCE_GROUP_UPDATES] intValue];
	
	requestID = [twitterEngine getRepliesSinceID:lastID startingAtPage:1];
	
	if (requestID) {
		[self setRequestType:AITwitterUpdateReplies
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"Page", nil]];
	} else {
		--pendingUpdateCount;
	}
}

#pragma mark Message Display
/*!
 * @brief Returns the link URL for a specific type of link
 */
- (NSString *)addressForLinkType:(AITwitterLinkType)linkType
						  userID:(NSString *)userID
						statusID:(NSString *)statusID
{
	NSString *address = nil;
	
	if (linkType == AITwitterLinkStatus) {
		address = [NSString stringWithFormat:@"https://twitter.com/%@/status/%@", userID, statusID];
	} else if (linkType == AITwitterLinkFriends) {
		address = [NSString stringWithFormat:@"https://twitter.com/%@/friends", userID];
	} else if (linkType == AITwitterLinkFollowers) {
		address = [NSString stringWithFormat:@"https://twitter.com/%@/followers", userID]; 
	} else if (linkType == AITwitterLinkUserPage) {
		address = [NSString stringWithFormat:@"https://twitter.com/%@", userID]; 
	}
	
	return address;
}

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
				inReplyToUser:nil
			 inReplyToTweetID:nil];
}

/*!
 * @brief Parses a Twitter message into an attributed string
 */
- (NSAttributedString *)parseMessage:(NSString *)inMessage
							 tweetID:(NSString *)tweetID
							  userID:(NSString *)userID
					   inReplyToUser:(NSString *)replyUserID
					inReplyToTweetID:(NSString *)replyTweetID
{
	NSAttributedString *message;
	
	message = [NSAttributedString stringWithString:[inMessage stringByUnescapingFromXMLWithEntities:nil]];
	
	message = [AITwitterURLParser linkifiedAttributedStringFromString:message];
	
	BOOL replyTweet = (replyTweetID.length);
	BOOL tweetLink = (tweetID.length && userID.length);
	
	if (replyTweet || tweetLink) {
		NSMutableAttributedString *mutableMessage = [[message mutableCopy] autorelease];
		
		[mutableMessage appendString:@"  (" withAttributes:nil];
	
		// Append a link to the tweet this is in reply to
		if (replyTweet) {			
			NSString *linkAddress = [self addressForLinkType:AITwitterLinkStatus
													  userID:replyUserID
													statusID:replyTweetID];
			
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
			
			linkAddress = [self addressForLinkType:AITwitterLinkStatus
											userID:userID
										  statusID:tweetID];
			
			[mutableMessage appendString:@", " withAttributes:nil];
			
			[mutableMessage appendString:AILocalizedString(@"view", "Link appended which goes to the permanent location of this tweet")
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
 * @brief Remove duplicate status updates.
 *
 * If we're following someone who replies to us, we'll receive a status update in both the
 * timeline and the reply feed.
 *
 * @param inArray The sorted array of Tweets
 */
- (NSArray *)arrayWithDuplicateTweetsRemoved:(NSArray *)inArray
{
	NSMutableArray *mutableArray = [inArray mutableCopy];
	
	NSDictionary *status = nil, *previousStatus = nil;
	
	// Starting at index 1, checking backwards. We'll never exceed bounds this way.
	for(NSUInteger index = 1; index < inArray.count; index++)
	{
		status = [inArray objectAtIndex:index];
		previousStatus = [inArray objectAtIndex:index-1];
		
		if([[status objectForKey:TWITTER_STATUS_ID] isEqualToString:[previousStatus objectForKey:TWITTER_STATUS_ID]]) {
			[mutableArray removeObject:status];
		}
	}
	
	return [mutableArray autorelease];
}

/*!
 * @brief Display queued updates or direct messages
 *
 * This could potentially be simplified since both DMs and updates have the same format.
 */
- (void)displayQueuedUpdatesForRequestType:(AITwitterRequestType)requestType
{
	if(requestType == AITwitterUpdateReplies || requestType == AITwitterUpdateFollowedTimeline) {
		if(!queuedUpdates.count) {
			return;
		}
		
		AILogWithSignature(@"%@ Displaying %d updates", self, queuedUpdates.count);
		
		// Sort the queued updates (since we're intermingling pages of data from different souces)
		NSArray *sortedQueuedUpdates = [queuedUpdates sortedArrayUsingFunction:queuedUpdatesSort context:nil];
		
		sortedQueuedUpdates = [self arrayWithDuplicateTweetsRemoved:sortedQueuedUpdates];
		
		AIChat *timelineChat = [adium.chatController existingChatWithName:self.timelineChatName
																onAccount:self];
		
		if (!timelineChat) {
			timelineChat = [adium.chatController chatWithName:self.timelineChatName
												   identifier:nil
													onAccount:self
											 chatCreationInfo:nil];
		}
		
		[[AIContactObserverManager sharedManager] delayListObjectNotifications];
		
		for (NSDictionary *status in sortedQueuedUpdates) {
			NSDate			*date = [status objectForKey:TWITTER_STATUS_CREATED];
			NSString		*text = [status objectForKey:TWITTER_STATUS_TEXT];
			
			NSString *contactUID = [[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_STATUS_UID];
			
			id fromObject = nil;
			
			if(![contactUID isEqualToString:self.UID]) {
				AIListContact *listContact = [self contactWithUID:contactUID];
				
				// Update the user's status message
				[listContact setStatusMessage:[NSAttributedString stringWithString:[text stringByUnescapingFromXMLWithEntities:nil]]
									   notify:NotifyNow];
				
				[self updateUserIcon:[[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_INFO_ICON] forContact:listContact];
				
				[timelineChat addParticipatingListObject:listContact notify:NotifyLater];
				
				fromObject = (id)listContact;
			} else {
				fromObject = (id)self;
			}

			NSAttributedString *message = [self parseMessage:text
													 tweetID:[status objectForKey:TWITTER_STATUS_ID]
													  userID:contactUID
											   inReplyToUser:[status objectForKey:TWITTER_STATUS_REPLY_UID]
											inReplyToTweetID:[status objectForKey:TWITTER_STATUS_REPLY_ID]];
			
			AIContentMessage *contentMessage = [AIContentMessage messageInChat:timelineChat
																	withSource:fromObject
																   destination:self
																		  date:date
																	   message:message
																	 autoreply:NO];
			
			[adium.contentController receiveContentObject:contentMessage];
		}
		
		[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
		
		[queuedUpdates removeAllObjects];
	} else if (requestType == AITwitterUpdateDirectMessage) {
		if(!queuedDM.count) {
			return;
		}
		
		AILogWithSignature(@"%@ Displaying %d DMs", self, queuedDM.count);
		
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
		// Delay updates on initial login.
		[self silenceAllContactUpdatesForInterval:18.0];
		// Grab our user list.
		NSString	*requestID = [twitterEngine getRecentlyUpdatedFriendsFor:self.UID startingAtPage:1];
		
		if (requestID) {
			[self setRequestType:AITwitterInitialUserInfo
					forRequestID:requestID
				  withDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"Page"]];
		} else {
			[self setLastDisconnectionError:AILocalizedString(@"Unable to connect", nil)];
			[self didDisconnect];
		}
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
	if([self requestTypeForRequestID:identifier] == AITwitterDirectMessageSend || [self requestTypeForRequestID:identifier] == AITwitterSendUpdate) {
		AIChat	*chat = [[self dictionaryForRequestID:identifier] objectForKey:@"Chat"];
		
		if (chat) {
			[chat receivedError:[NSNumber numberWithInt:AIChatUnknownError]];
			
			AILogWithSignature(@"%@ Chat send error on %@", self, chat);
		}
		
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
	} else if ([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline || 
			   [self requestTypeForRequestID:identifier] == AITwitterUpdateReplies ||
			   [self requestTypeForRequestID:identifier] == AITwitterUpdateDirectMessage) {
		--pendingUpdateCount;
	}
	
	AILogWithSignature(@"%@ Request failed (%@ - %d) - %@", self, identifier, [self requestTypeForRequestID:identifier], error);
	
	[self clearRequestTypeForRequestID:identifier];
}

/*!
 * @brief Status updates received
 */
- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier
{		
	if([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline ||
	   [self requestTypeForRequestID:identifier] == AITwitterUpdateReplies) {
		NSNumber *lastID;
		
		BOOL nextPageNecessary = NO;
		
		if([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline) {
			lastID = [self preferenceForKey:TWITTER_PREFERENCE_TIMELINE_LAST_ID
									  group:TWITTER_PREFERENCE_GROUP_UPDATES];
			
			nextPageNecessary = (lastID && statuses.count >= TWITTER_UPDATE_TIMELINE_COUNT);
		} else {
			lastID = [self preferenceForKey:TWITTER_PREFERENCE_REPLIES_LAST_ID
									  group:TWITTER_PREFERENCE_GROUP_UPDATES];
			
			nextPageNecessary = (lastID && statuses.count >= TWITTER_UPDATE_REPLIES_COUNT);
		}
		
		// Store the largest tweet ID we find; this will be our "last ID" the next time we run.
		NSNumber *largestTweet = [[self dictionaryForRequestID:identifier] objectForKey:@"LargestTweet"];
		
		// The largest ID is first, compare.
		if (statuses.count) {
			NSNumber *tweetID = [[statuses objectAtIndex:0] objectForKey:TWITTER_STATUS_ID];
			if (!largestTweet || [largestTweet compare:tweetID] == NSOrderedAscending) {
				largestTweet = tweetID;
			}
		}
		
		[queuedUpdates addObjectsFromArray:statuses];
		
		AILogWithSignature(@"%@ Last ID: %@ Largest Tweet: %@ Next Page Necessary: %d", self, lastID, largestTweet, nextPageNecessary);
		
		// See if we need to pull more updates.
		if (nextPageNecessary) {
			NSInteger	nextPage = [[[self dictionaryForRequestID:identifier] objectForKey:@"Page"] intValue] + 1;
			NSString	*requestID;
			
			if ([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline) {
				requestID = [twitterEngine getFollowedTimelineFor:nil
														  sinceID:[lastID intValue]
												   startingAtPage:nextPage
															count:TWITTER_UPDATE_TIMELINE_COUNT];
				
				AILogWithSignature(@"%@ Pulling additional timeline page %d", self, nextPage);
				
				if (requestID) {
					[self setRequestType:AITwitterUpdateFollowedTimeline
							forRequestID:requestID
						  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:nextPage], @"Page", 
										  largestTweet, @"LargestTweet", nil]];
				} else {
					// Gracefully fail: remove all stored objects.
					AILogWithSignature(@"%@ Immediate timeline fail", self);
					--pendingUpdateCount;
					[queuedUpdates removeAllObjects];
				}
				
			} else if ([self requestTypeForRequestID:identifier] == AITwitterUpdateReplies) {
				requestID = [twitterEngine getRepliesSinceID:[lastID intValue] startingAtPage:nextPage];
				
				AILogWithSignature(@"%@ Pulling additional replies page %d", self, nextPage);
				
				if (requestID) {
					[self setRequestType:AITwitterUpdateReplies
							forRequestID:requestID
						  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:nextPage], @"Page",
										  largestTweet, @"LargestTweet", nil]];
				} else {
					// Gracefully fail: remove all stored objects.
					AILogWithSignature(@"%@ Immediate reply fail", self);
					--pendingUpdateCount;
					[queuedUpdates removeAllObjects];
				}
			}
		} else {
			if([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline) {
				followedTimelineCompleted = YES;
				futureTimelineLastID = [largestTweet retain];
			} else if ([self requestTypeForRequestID:identifier] == AITwitterUpdateReplies) {
				repliesCompleted = YES;
				futureRepliesLastID = [largestTweet retain];
			}
			
			--pendingUpdateCount;
			
			AILogWithSignature(@"%@ Followed completed: %d Replies completed: %d", self, followedTimelineCompleted, repliesCompleted);
			
			if (followedTimelineCompleted && repliesCompleted && queuedUpdates.count) {
				// Set the "last pulled" for the timeline and replies, since we've completed both.
				if(futureRepliesLastID) {
					AILogWithSignature(@"%@ futureRepliesLastID = %@", self, futureRepliesLastID);
					
					[self setPreference:futureRepliesLastID
								 forKey:TWITTER_PREFERENCE_REPLIES_LAST_ID
								  group:TWITTER_PREFERENCE_GROUP_UPDATES];
					
					[futureRepliesLastID release]; futureRepliesLastID = nil;
				}
				
				if(futureTimelineLastID) {
					AILogWithSignature(@"%@ futureTimelineLastID = %@", self, futureTimelineLastID);
					
					[self setPreference:futureTimelineLastID
								 forKey:TWITTER_PREFERENCE_TIMELINE_LAST_ID
								  group:TWITTER_PREFERENCE_GROUP_UPDATES];
					
					[futureTimelineLastID release]; futureTimelineLastID = nil;
				}
				
				[self displayQueuedUpdatesForRequestType:[self requestTypeForRequestID:identifier]];
			}
		}
	} else if ([self requestTypeForRequestID:identifier] == AITwitterProfileStatusUpdates) {
		AIListContact *listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];

		NSMutableArray *profileArray = [[listContact profileArray] mutableCopy];
		
		AILogWithSignature(@"%@ Updating statuses for profile, user %@", self, listContact);
		
		for (NSDictionary *update in statuses) {
			NSAttributedString *message = [self parseMessage:[update objectForKey:TWITTER_STATUS_TEXT]
													 tweetID:[update objectForKey:TWITTER_STATUS_ID]
													  userID:listContact.UID
											   inReplyToUser:[update objectForKey:TWITTER_STATUS_REPLY_UID]
											inReplyToTweetID:[update objectForKey:TWITTER_STATUS_REPLY_ID]];
			
			[profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:message, KEY_VALUE, nil]];
		}
		
		[listContact setProfileArray:profileArray notify:NotifyNow];
	} else if ([self requestTypeForRequestID:identifier] == AITwitterSendUpdate && updateAfterSend) {
		[self periodicUpdate];
		
		if ([[self preferenceForKey:TWITTER_PREFERENCE_UPDATE_GLOBAL group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue]) {
			for(NSDictionary *update in statuses) {
				NSString *text = [[update objectForKey:TWITTER_STATUS_TEXT] stringByUnescapingFromXMLWithEntities:nil];
				
				if(![text hasPrefix:@"@"] ||
				   [[self preferenceForKey:TWITTER_PREFERENCE_UPDATE_GLOBAL_REPLIES group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue]) {
					AIStatus *availableStatus = [AIStatus statusOfType:AIAvailableStatusType];
					
					availableStatus.statusMessage = [NSAttributedString stringWithString:text];
					[adium.statusController setActiveStatusState:availableStatus];
				}
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
		NSNumber *lastID = [self preferenceForKey:TWITTER_PREFERENCE_DM_LAST_ID
											group:TWITTER_PREFERENCE_GROUP_UPDATES];
		
		BOOL nextPageNecessary = (lastID && messages.count >= TWITTER_UPDATE_DM_COUNT);
		
		// Store the largest tweet ID we find; this will be our "last ID" the next time we run.
		NSNumber *largestTweet = [[self dictionaryForRequestID:identifier] objectForKey:@"LargestTweet"];
		
		// The largest ID is first, compare.
		if (messages.count) {
			NSNumber *tweetID = [[messages objectAtIndex:0] objectForKey:TWITTER_DM_ID];
			if (!largestTweet || [largestTweet compare:tweetID] == NSOrderedAscending) {
				largestTweet = tweetID;
			}
		}
		
		[queuedDM addObjectsFromArray:messages];
		
		AILogWithSignature(@"%@ Last ID: %@ Largest Tweet: %@ Next Page Necessary: %d", self, lastID, largestTweet, nextPageNecessary);
		
		if(nextPageNecessary) {
			NSInteger	nextPage = [[[self dictionaryForRequestID:identifier] objectForKey:@"Page"] intValue] + 1;
			
			NSString	*requestID = [twitterEngine getDirectMessagesSinceID:[lastID intValue] 
														      startingAtPage:nextPage];
			
			AILogWithSignature(@"%@ Pulling additional DM page %d", self, nextPage);
			
			if(requestID) {
				[self setRequestType:AITwitterUpdateDirectMessage
						forRequestID:requestID
					  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:nextPage], @"Page",
									  largestTweet, @"LargestTweet", nil]];
			} else {
				// Gracefully fail: remove all stored objects.
				AILogWithSignature(@"%@ Immediate DM pull fail", self);
				--pendingUpdateCount;
				[queuedDM removeAllObjects];
			}
		} else {		
			--pendingUpdateCount;
			
			if (largestTweet) {
				AILogWithSignature(@"%@ Largest DM pulled = %@", self, largestTweet);
				
				[self setPreference:largestTweet
							 forKey:TWITTER_PREFERENCE_DM_LAST_ID
							  group:TWITTER_PREFERENCE_GROUP_UPDATES];
			}
		
			// On first load, don't display any direct messages. Just ge the largest ID.
			if (queuedDM.count && lastID) {
				[self displayQueuedUpdatesForRequestType:[self requestTypeForRequestID:identifier]];
			} else {
				[queuedDM removeAllObjects];		
			}
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
		BOOL nextPageNecessary = (userInfo.count >= 100);
		
		AILogWithSignature(@"%@ Initial user info pull, Next page necessary: %d Count: %d", self, nextPageNecessary, userInfo.count);
		
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
			
			AILogWithSignature(@"%@ Pulling additional user info page %d", self, nextPage);
			
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
			[self didConnect];
			[self periodicUpdate];
		}
	} else if ([self requestTypeForRequestID:identifier] == AITwitterProfileUserInfo) {
		NSDictionary *thisUserInfo = [userInfo objectAtIndex:0];
		
		if (thisUserInfo) {	
			AIListContact	*listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
			
			NSArray *keyNames = [NSArray arrayWithObjects:@"name", @"location", @"description", @"url", @"friends_count", @"followers_count", @"statuses_count", nil];
			NSArray *readableNames = [NSArray arrayWithObjects:AILocalizedString(@"Name", nil), AILocalizedString(@"Location", nil),
									  AILocalizedString(@"Biography", nil), AILocalizedString(@"Website", nil), AILocalizedString(@"Following", nil),
									  AILocalizedString(@"Followers", nil), AILocalizedString(@"Updates", nil), nil];
			
			NSMutableArray *profileArray = [NSMutableArray array];
			
			for (NSUInteger index = 0; index < keyNames.count; index++) {
				NSString			*keyName = [keyNames objectAtIndex:index];
				NSString			*unattributedValue = [thisUserInfo objectForKey:keyName];
				
				if(![unattributedValue isEqualToString:@""]) {
					NSString			*readableName = [readableNames objectAtIndex:index];
					NSAttributedString	*value;
					
					if([keyName isEqualToString:@"friends_count"]) {
						value = [NSAttributedString attributedStringWithLinkLabel:unattributedValue
																  linkDestination:[self addressForLinkType:AITwitterLinkFriends userID:listContact.UID statusID:nil]];
					} else if ([keyName isEqualToString:@"followers_count"]) {
						value = [NSAttributedString attributedStringWithLinkLabel:unattributedValue
																  linkDestination:[self addressForLinkType:AITwitterLinkFollowers userID:listContact.UID statusID:nil]];
					} else if ([keyName isEqualToString:@"statuses_count"]) {
						value = [NSAttributedString attributedStringWithLinkLabel:unattributedValue
																  linkDestination:[self addressForLinkType:AITwitterLinkUserPage userID:listContact.UID statusID:nil]];
					} else {
						value = [NSAttributedString stringWithString:unattributedValue];
					}
						
					[profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:readableName, KEY_KEY, value, KEY_VALUE, nil]];
				}
			}
			
			AILogWithSignature(@"%@ Updating profileArray for user %@", self, listContact);
			
			[listContact setProfileArray:profileArray notify:NotifyNow];
			
			// Grab their statuses.
			NSString *requestID = [twitterEngine getUserTimelineFor:listContact.UID since:nil startingAtPage:0 count:TWITTER_UPDATE_USER_INFO_COUNT];
			
			if (requestID) {
				[self setRequestType:AITwitterProfileStatusUpdates
						forRequestID:requestID
					  withDictionary:[NSDictionary dictionaryWithObject:listContact forKey:@"ListContact"]];
			}
		}
	} else if ([self requestTypeForRequestID:identifier] == AITwitterValidateCredentials ||
			   [self requestTypeForRequestID:identifier] == AITwitterProfileSelf) {
		for (NSDictionary *info in userInfo) {
			NSString *requestID = [twitterEngine getImageAtURL:[info objectForKey:TWITTER_INFO_ICON]];
			
			if (requestID) {
				[self setRequestType:AITwitterSelfUserIconPull
						forRequestID:requestID
					  withDictionary:nil];
			}
			
			[self setValue:[info objectForKey:@"name"] forProperty:@"Profile Name" notify:NotifyLater];
			[self setValue:[info objectForKey:@"url"] forProperty:@"Profile URL" notify:NotifyLater];
			[self setValue:[info objectForKey:@"location"] forProperty:@"Profile Location" notify:NotifyLater];
			[self setValue:[info objectForKey:@"description"] forProperty:@"Profile Description" notify:NotifyLater];
			[self notifyOfChangedPropertiesSilently:NO];
		}
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

/*!
 * @brief Miscellaneous information received
 */
- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)identifier
{
	if([self requestTypeForRequestID:identifier] == AITwitterRateLimitStatus) {
		NSDictionary *rateLimit = [miscInfo objectAtIndex:0];
		NSDate *resetDate = [NSDate dateWithTimeIntervalSince1970:[[rateLimit objectForKey:TWITTER_RATE_LIMIT_RESET_SECONDS] intValue]];
		
		[adium.interfaceController handleMessage:AILocalizedString(@"Current Twitter rate limit", "Message in the rate limit status window")
								 withDescription:[NSString stringWithFormat:AILocalizedString(@"You have %d/%d more requests for %@.", "The first %d is the number of requests, the second is the total number of requests per hour. The %@ is the duration of time until the count resets."),
													[[rateLimit objectForKey:TWITTER_RATE_LIMIT_REMAINING] intValue],
													[[rateLimit objectForKey:TWITTER_RATE_LIMIT_HOURLY_LIMIT] intValue],
													[NSDateFormatter stringForTimeInterval:[resetDate timeIntervalSinceNow]
																			showingSeconds:YES
																			   abbreviated:YES
																			  approximated:NO]]
								 withWindowTitle:AILocalizedString(@"Rate Limit Status", nil)];
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

/*!
 * @brief Requested image received
 */
- (void)imageReceived:(NSImage *)image forRequest:(NSString *)identifier
{
	if([self requestTypeForRequestID:identifier] == AITwitterUserIconPull) {
		AIListContact		*listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
		
		AILogWithSignature(@"%@ Updated user icon for %@", self, listContact);
		
		[listContact setServersideIconData:[image TIFFRepresentation]
									notify:NotifyLater];
		
		[listContact setValue:nil forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
	} else if([self requestTypeForRequestID:identifier] == AITwitterSelfUserIconPull) {
		AILogWithSignature(@"Updated self icon for %@", self);

		// Set a property so we don't re-send thie image we're just now downloading.
		[self setValue:[NSNumber numberWithBool:YES] forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
		
		[self setPreference:[image TIFFRepresentation]
					 forKey:KEY_USER_ICON
					  group:GROUP_ACCOUNT_STATUS];
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

@end
