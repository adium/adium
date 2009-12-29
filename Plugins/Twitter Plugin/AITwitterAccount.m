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
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactObserverManager.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIChat.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIContentEvent.h>

@interface AITwitterAccount()
- (void)updateUserIcon:(NSString *)url forContact:(AIListContact *)listContact;

- (void)updateTimelineChat:(AIChat *)timelineChat;

- (NSAttributedString *)parseMessage:(NSString *)inMessage
							 tweetID:(NSString *)tweetID
							  userID:(NSString *)userID
					   inReplyToUser:(NSString *)replyUserID
					inReplyToTweetID:(NSString *)replyTweetID;
- (NSAttributedString *)parseDirectMessage:(NSString *)inMessage
									withID:(NSString *)dmID
								  fromUser:(NSString *)sourceUID;
- (NSAttributedString *)attributedStringWithLinkLabel:(NSString *)label
									  linkDestination:(NSString *)destination
											linkClass:(NSString *)attributeName;

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
	
	pendingRequests = [[NSMutableDictionary alloc] init];
	queuedUpdates = [[NSMutableArray alloc] init];
	queuedDM = [[NSMutableArray alloc] init];
	queuedOutgoingDM = [[NSMutableArray alloc] init];

	[[NSNotificationCenter defaultCenter] addObserver:self
							     selector:@selector(chatDidOpen:) 
									 name:Chat_DidOpen
								   object:nil];
	
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
												  [NSNumber numberWithInt:TWITTER_UPDATE_INTERVAL_MINUTES], TWITTER_PREFERENCE_UPDATE_INTERVAL,
												  [NSNumber numberWithBool:YES], TWITTER_PREFERENCE_UPDATE_AFTER_SEND,
												  [NSNumber numberWithBool:YES], TWITTER_PREFERENCE_LOAD_CONTACTS, nil]
										forGroup:TWITTER_PREFERENCE_GROUP_UPDATES
										  object:self];

	// If we don't have a server set, set our default (if we have one)
	if (!self.host && self.defaultServer) {
		[self setPreference:self.defaultServer forKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS];
	}

	[adium.preferenceController registerPreferenceObserver:self forGroup:TWITTER_PREFERENCE_GROUP_UPDATES];
	[adium.preferenceController informObserversOfChangedKey:nil inGroup:TWITTER_PREFERENCE_GROUP_UPDATES object:self];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	
	[twitterEngine release];
	[pendingRequests release];
	[queuedUpdates release];
	[queuedDM release];
	[queuedOutgoingDM release];
	
	[super dealloc];
}

/*!
 * @brief Our default server if none is provided.
 */
- (NSString *)defaultServer
{
	return @"twitter.com";
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
	
	[twitterEngine release];
	
	twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
	
	[twitterEngine setClientName:@"Adium"
						 version:[NSApp applicationVersion]
							 URL:@"http://www.adiumx.com"
						   token:self.sourceToken];	
	
	[twitterEngine setAPIDomain:[self.host stringByAppendingPathComponent:self.apiPath]];
	
	[twitterEngine setUsesSecureConnection:self.useSSL];
	
	if (self.useOAuth) {
		if (!self.passwordWhileConnected.length) {
			[self setLastDisconnectionError:TWITTER_OAUTH_NOT_AUTHORIZED];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"AIEditAccount"
																object:self];
			
			[self didDisconnect];
			
			// Don't try and connect.
			return;
			
		} else {
			twitterEngine.useOAuth = YES;
			
			OAToken *token = [[[OAToken alloc] initWithHTTPResponseBody:self.passwordWhileConnected] autorelease];
			OAConsumer *consumer = [[[OAConsumer alloc] initWithKey:self.consumerKey secret:self.secretKey] autorelease];
			
			twitterEngine.accessToken = token;
			twitterEngine.consumer = consumer;
		}
	} else {
		[twitterEngine setUsername:self.UID password:self.passwordWhileConnected];
	}
	
	AILogWithSignature(@"%@ connecting to %@", self, twitterEngine.APIDomain);
	
	NSString *requestID = [twitterEngine checkUserCredentials];
	
	if (requestID) {
		[self setRequestType:AITwitterValidateCredentials forRequestID:requestID withDictionary:nil];
	} else {
		[self setLastDisconnectionError:AILocalizedString(@"Unable to connect to server", nil)];
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
	AIListBookmark *timelineBookmark = [adium.contactController existingBookmarkForChatName:self.timelineChatName
																				  onAccount:self
																		   chatCreationInfo:nil];
	
	if(!timelineBookmark) {
		AIChat *newTimelineChat = [adium.chatController chatWithName:self.timelineChatName
														  identifier:nil
														   onAccount:self 
													chatCreationInfo:nil];
		
		[newTimelineChat setDisplayName:self.timelineChatName];
		
		timelineBookmark = [adium.contactController bookmarkForChat:newTimelineChat inGroup:[adium.contactController groupWithUID:TWITTER_REMOTE_GROUP_NAME]];


		if(!timelineBookmark) {
			AILog(@"%@ Timeline bookmark is nil! Tried checking for existing bookmark for chat name %@, and creating a bookmark for chat %@ in group %@", self.timelineChatName, newTimelineChat, [adium.contactController groupWithUID:TWITTER_REMOTE_GROUP_NAME]);
		}
	}
	
	NSTimeInterval updateInterval = [[self preferenceForKey:TWITTER_PREFERENCE_UPDATE_INTERVAL group:TWITTER_PREFERENCE_GROUP_UPDATES] integerValue] * 60;
	
	if(updateInterval > 0) {
		[updateTimer invalidate];
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval
													   target:self
													 selector:@selector(periodicUpdate)
													 userInfo:nil
													  repeats:YES];
		
		[self periodicUpdate];
	}
}

/*!
 * @brief We've been asked to disconnect.
 *
 * End the session.
 */
- (void)disconnect
{
	[super disconnect];
	
	[twitterEngine release]; twitterEngine = nil;
	[updateTimer invalidate]; updateTimer = nil;
	
	[self didDisconnect];
}

/*!
 * @brief Account will be deleted
 */
- (void)willBeDeleted
{
	[updateTimer invalidate]; updateTimer = nil;
	
	[super willBeDeleted];
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
	[queuedOutgoingDM removeAllObjects];
	[queuedUpdates removeAllObjects];
	
	[super didDisconnect];
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
 * @brief Our source token
 *
 * On Twitter, our given source token is "adiumofficial".
 */
- (NSString *)sourceToken
{
	return @"adiumofficial";
}

/*!
 * @brief Returns whether or not to connect to Twitter API over HTTPS.
 */
- (BOOL)useSSL
{
	return YES;
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
	[chat setValue:[NSNumber numberWithBool:YES] forProperty:@"Account Joined" notify:NotifyNow];
	
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
- (void)moveListObjects:(NSArray *)objects oldGroups:(NSSet *)oldGroups toGroups:(NSSet *)groups
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
 * @brief For an invalid password, fail but don't try and reconnect or report it. We do it ourself.
 */
- (AIReconnectDelayType)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	AIReconnectDelayType reconnectDelayType = [super shouldAttemptReconnectAfterDisconnectionError:disconnectionError];
	
	if ([*disconnectionError isEqualToString:TWITTER_INCORRECT_PASSWORD_MESSAGE]) {
		reconnectDelayType = AIReconnectImmediately;
	} else if ([*disconnectionError isEqualToString:TWITTER_OAUTH_NOT_AUTHORIZED]) {
		reconnectDelayType = AIReconnectNeverNoMessage;
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

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return [[inAttributedString attributedStringByConvertingLinksToURLStrings] string];
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
		requestID = [twitterEngine sendUpdate:inContentMessage.encodedMessage
									inReplyTo:[inContentMessage.chat valueForProperty:@"TweetInReplyToStatusID"]];
		
		if(requestID) {
			[self setRequestType:AITwitterSendUpdate
					forRequestID:requestID
				  withDictionary:[NSDictionary dictionaryWithObject:inContentMessage.chat
															 forKey:@"Chat"]];
			
			inContentMessage.displayContent = NO;
			
			AILogWithSignature(@"%@ Sending update [in reply to %@]: %@", self, [inContentMessage.chat valueForProperty:@"TweetInReplyToStatusID"], inContentMessage.encodedMessage);
		}

	} else {		
		requestID = [twitterEngine sendDirectMessage:inContentMessage.encodedMessage
												  to:inContentMessage.destination.UID];
		
		if(requestID) {
			[self setRequestType:AITwitterDirectMessageSend
					forRequestID:requestID
				  withDictionary:[NSDictionary dictionaryWithObject:inContentMessage.chat
															 forKey:@"Chat"]];
			
			inContentMessage.displayContent = NO;
			
			AILogWithSignature(@"%@ Sending DM to %@: %@", self, inContentMessage.destination.UID, inContentMessage.encodedMessage);
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

#pragma mark OAuth
/*!
 * @brief Should we store our password based on internal object ID?
 *
 * We only need to if we're using OAuth.
 */
- (BOOL)useInternalObjectIDForPasswordName
{
	return self.useOAuth;
}

/*!
 * @brief Should we connect using OAuth?
 *
 * If enabled, the account view will display the OAuth setup. Basic authentication will not be used.
 */
- (BOOL)useOAuth
{
	return YES;
}

/*!
 * @brief OAuth consumer key
 */
- (NSString *)consumerKey
{
	return @"amjYVOrzKpKkkHAsdEaClA";
}

/*!
 * @brief OAuth secret key
 */
- (NSString *)secretKey
{
	return @"kvqM2CQsUO3J6NHctJVhTOzlKZ0k7FsTaR5NwakYU";
}

/*!
 * @brief Token request URL
 */
- (NSString *)tokenRequestURL
{
	return @"https://twitter.com/oauth/request_token";
}

/*!
 * @brief Token access URL
 */
- (NSString *)tokenAccessURL
{
	return @"https://twitter.com/oauth/access_token";	
}

/*!
 * @brief Token authorize URL
 */
- (NSString *)tokenAuthorizeURL
{
	return @"https://twitter.com/oauth/authorize";
}

#pragma mark Menu Items
/*!
 * @brief Menu items for contact
 *
 * Returns an array of menu items for a contact on this account.  This is the best place to add protocol-specific
 * actions that aren't otherwise supported by Adium.
 * @param inContact AIListContact for menu items
 * @return NSArray of NSMenuItem instances for the passed contact
 */
- (NSArray *)menuItemsForContact:(AIListContact *)inContact
{
	NSMutableArray *menuItemArray = [NSMutableArray array];
	
	NSMenuItem *menuItem;
	
	NSImage	*serviceIcon = [AIServiceIcons serviceIconForService:self.service
															type:AIServiceIconSmall
													   direction:AIIconNormal];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:AILocalizedString(@"Open %@'s user page",nil), inContact.UID]
																	 target:self
																	 action:@selector(openUserPage:)
															  keyEquivalent:@""] autorelease];
	[menuItem setImage:serviceIcon];
	[menuItem setRepresentedObject:inContact];
	[menuItemArray addObject:menuItem];	

	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:AILocalizedString(@"Enable device notifications for %@", "Enable sending Twitter notifications to your phone (device)"), inContact.UID]
																	 target:self
																	 action:@selector(enableOrDisableNotifications:)
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:YES];
	[menuItem setImage:serviceIcon];
	[menuItem setRepresentedObject:inContact];
	[menuItemArray addObject:menuItem];

	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:AILocalizedString(@"Disable device notifications for %@", "Disable sending Twitter notifications to your phone"), inContact.UID]
																	 target:self
																	 action:@selector(enableOrDisableNotifications:)
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:NO];
	[menuItem setImage:serviceIcon];
	[menuItem setRepresentedObject:inContact];
	[menuItemArray addObject:menuItem];
	
	return menuItemArray;	
}

/*!
 * @brief Open the represented objec'ts user page
 */
- (void)openUserPage:(NSMenuItem *)menuItem
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self addressForLinkType:AITwitterLinkUserPage
																				  userID:((AIListContact *)menuItem.representedObject).UID
																				statusID:nil
																				 context:nil]]];
}

/*!
 * @brief Enable or disable notifications for a contact.
 *
 * If the menuItem's tag is YES, we're adding. Otherwise we're removing.
 */
- (void)enableOrDisableNotifications:(NSMenuItem *)menuItem
{
	if(![menuItem.representedObject isKindOfClass:[AIListContact class]]) {
		return;
	}

	BOOL enableNotification = menuItem.tag;
	AIListContact *contact = menuItem.representedObject;
	
	NSString *requestID = nil;
	
	BOOL initialFailure = NO;
	
	if (enableNotification) {
		requestID = [twitterEngine enableNotificationsFor:contact.UID];

		if (requestID) {
			[self setRequestType:AITwitterNotificationEnable
					forRequestID:requestID
				  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:contact, @"ListContact", nil]];
		} else {
			initialFailure = YES;
		}
	
	} else {
		requestID = [twitterEngine disableNotificationsFor:contact.UID];
		
		if (requestID) {
			[self setRequestType:AITwitterNotificationDisable
					forRequestID:requestID
				  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:contact, @"ListContact", nil]];
		} else {
			initialFailure = YES;
		}
	}
	
	if (initialFailure) {
		[adium.interfaceController handleErrorMessage:(enableNotification ?
														AILocalizedString(@"Unable to Enable Notifications", nil) :
														AILocalizedString(@"Unable to Disable Notifications", nil))
									  withDescription:AILocalizedString(@"Unable to connect to the Twitter server.", nil)];
	}
}

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
	
	NSImage	*serviceIcon = [AIServiceIcons serviceIconForService:self.service
															type:AIServiceIconSmall
													   direction:AIIconNormal];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Update Tweets",nil)
																	 target:self
																	 action:@selector(periodicUpdate)
															  keyEquivalent:@""] autorelease];
	[menuItem setImage:serviceIcon];
	[menuItemArray addObject:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Reply to a Tweet",nil)
																	 target:self
																	 action:@selector(replyToTweet)
															  keyEquivalent:@""] autorelease];
	[menuItem setImage:serviceIcon];
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
 * @brief Our timeline chat
 *
 * If the timeline chat is not already active, it is created.
 */
- (AIChat *)timelineChat
{
	AIChat *timelineChat = [adium.chatController existingChatWithName:self.timelineChatName
							onAccount:self];
	
	if (!timelineChat) {
		timelineChat = [adium.chatController chatWithName:self.timelineChatName
						identifier:nil
						onAccount:self
						chatCreationInfo:nil];
	}

	return timelineChat;	
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
	[timelineChat addParticipatingListObjects:self.contacts notify:NotifyNow];
	
	[timelineChat setValue:[NSNumber numberWithInt:140] forProperty:@"Character Counter Max" notify:NotifyNow];
}

/*!
 * @brief Update serverside icon
 *
 * This is called by AIUserIcons when it needs an icon update for a contact.
 * If we already have an icon set (even a cached icon), ignore it.
 * Otherwise return the Twitter service icon.
 *
 * This is so that when an unknown contact appears, it has an actual image
 * to replace in the WKMV when an actual icon update is returned.
 *
 * This service icon will not remain saved very long, I see no harm in using it.
 * This only occurs for "strangers".
 */
- (NSData *)serversideIconDataForContact:(AIListContact *)listContact
{
	if (![AIUserIcons userIconSourceForObject:listContact] &&
		![AIUserIcons cachedUserIconExistsForObject:listContact]) {
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
		NSString *fileName = [[url lastPathComponent] stringByReplacingOccurrencesOfString:@"_normal." withString:@"_bigger."];
		
		url = [[url stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
		
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
- (void)removeContacts:(NSArray *)objects fromGroups:(NSArray *)groups
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
	if ([contact.UID isCaseInsensitivelyEqualToString:self.UID]) {
		AILogWithSignature(@"Not adding contact %@ to group %@, it's me!", contact.UID, group.UID);
		return;
	}
	
	NSString	*requestID = [twitterEngine enableUpdatesFor:contact.UID];
	
	AILogWithSignature(@"%@ Requesting follow for: %@", self, contact.UID);
	
	if(requestID) {	
		NSString	*updateRequestID = [twitterEngine getUserInformationFor:contact.UID];
		
		if (updateRequestID) {
			[self setRequestType:AITwitterAddFollow
					forRequestID:updateRequestID
				  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:contact.UID, @"UID", nil]];
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
			
			if (timeInterval != newTimeInterval && self.online) {
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
		
		updateAfterSend = [[prefDict objectForKey:TWITTER_PREFERENCE_UPDATE_AFTER_SEND] boolValue];
		retweetLink = [[prefDict objectForKey:TWITTER_PREFERENCE_RETWEET_SPAM] boolValue];
		
		if ([key isEqualToString:TWITTER_PREFERENCE_LOAD_CONTACTS] && self.online) {
			if ([[prefDict objectForKey:TWITTER_PREFERENCE_LOAD_CONTACTS] boolValue]) {
				// Delay updates when loading our contacts list.
				[self silenceAllContactUpdatesForInterval:18.0];
				// Grab our user list.
				NSString	*requestID = [twitterEngine getRecentlyUpdatedFriendsFor:self.UID startingAtPage:1];
				
				if (requestID) {
					[self setRequestType:AITwitterInitialUserInfo
							forRequestID:requestID
						  withDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"Page"]];
				}
			} else {
				[self removeAllContacts];
			}
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
	NSString	*lastID;
	
	// We haven't completed the timeline nor replies. This lets us know if we should display statuses.
	followedTimelineCompleted = repliesCompleted = NO;
	futureTimelineLastID = futureRepliesLastID = nil;
	
	// Prevent triggering this update routine multiple times.
	pendingUpdateCount = 3;
	
	// We haven't printed error messages for this set.
	timelineErrorMessagePrinted = NO;
	
	[queuedUpdates removeAllObjects];
	[queuedDM removeAllObjects];
	
	AILogWithSignature(@"%@ Periodic update fire", self);
	
	// Pull direct messages	
	lastID = [self preferenceForKey:TWITTER_PREFERENCE_DM_LAST_ID
							  group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	requestID = [twitterEngine getDirectMessagesSinceID:lastID startingAtPage:1];
	
	if (requestID) {
		[self setRequestType:AITwitterUpdateDirectMessage
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"Page", nil]];
	} else {
		--pendingUpdateCount;
	}

	// Pull followed timeline
	lastID = [self preferenceForKey:TWITTER_PREFERENCE_TIMELINE_LAST_ID
							  group:TWITTER_PREFERENCE_GROUP_UPDATES];

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
	lastID = [self preferenceForKey:TWITTER_PREFERENCE_REPLIES_LAST_ID
							  group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
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
 * @brief Returns a user-readable message for an error code.
 */
- (NSString *)errorMessageForError:(NSError *)error
{
	switch (error.code) {
		case 400:
			// Bad Request: your request is invalid, and we'll return an error message that tells you why.
			// This is the status code returned if you've exceeded the rate limit. 
			return AILocalizedString(@"You've exceeded the rate limit.", nil);
			break;
			
		case 401:
			// Not Authorized: either you need to provide authentication credentials, or the credentials provided aren't valid.
			return AILocalizedString(@"Your credentials do not allow you access.", nil);
			break;
			
		case 403:
			// Forbidden: we understand your request, but are refusing to fulfill it.  An accompanying error message should explain why.
			return AILocalizedString(@"Request refused by the server.", nil);
			break;
			
		case 404:
			// Not Found: either you're requesting an invalid URI or the resource in question doesn't exist (ex: no such user). 
			return AILocalizedString(@"Requested resource not found.", nil);
			break;
			
		case 500:
			// Internal Server Error: we did something wrong.  Please post to the group about it and the Twitter team will investigate.
			return AILocalizedString(@"The server reported an internal error.", nil);
			break;
			
		case 502:
			// Bad Gateway: returned if Twitter is down or being upgraded.
			return AILocalizedString(@"The server is currently down.", nil);
			break;
			
		case -1001:
			// Timeout
		case 503:
			// Service Unavailable: the Twitter servers are up, but are overloaded with requests.  Try again later.
			return AILocalizedString(@"The server is overloaded with requests.", nil);
			break;
			
	}
	
	return [NSString stringWithFormat:AILocalizedString(@"Unknown error: code %d, %@", nil), error.code, error.localizedDescription];
}

/*!
 * @brief Returns the link URL for a specific type of link
 */
- (NSString *)addressForLinkType:(AITwitterLinkType)linkType
						  userID:(NSString *)userID
						statusID:(NSString *)statusID
						 context:(NSString *)context
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
	} else if (linkType == AITwitterLinkSearchHash) {
		address = [NSString stringWithFormat:@"http://search.twitter.com/search?q=%%23%@", context];
	} else if (linkType == AITwitterLinkReply) {
		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=reply&status=%@", self.internalObjectID, userID, statusID];
	} else if (linkType == AITwitterLinkRetweet) {
		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=retweet&status=%@", self.internalObjectID, userID, statusID];
	} else if (linkType == AITwitterLinkFavorite) {
		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=favorite&status=%@", self.internalObjectID, userID, statusID];
	} else if (linkType == AITwitterLinkDestroyStatus) {
		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=destroy&status=%@&message=%@", self.internalObjectID, userID, statusID, context];
	} else if (linkType == AITwitterLinkDestroyDM) {
		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=destroy&dm=%@&message=%@", self.internalObjectID, userID, statusID, context];		
	} else if (linkType == AITwitterLinkQuote) {
		address = [NSString stringWithFormat:@"twitterreply://%@@%@?action=quote&message=%@", self.internalObjectID, userID, context];
	}
	
	return address;
}

/*!
 * @brief Retweet the selected tweet.
 *
 * Attempts to retweet a tweet.
 * Prints a status message in the chat on success/failure, behaves identical to sending a new tweet.
 *
 * @returns YES if the account could send a retweet message, NO if the account doesn't support it.
 */
- (BOOL)retweetTweet:(NSString *)tweetID
{
	NSString *requestID = [twitterEngine retweetUpdate:tweetID];
	
	if (requestID) {
		[self setRequestType:AITwitterSendUpdate
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:tweetID, @"tweetID", nil]];
	} else {
		[self.timelineChat receivedError:[NSNumber numberWithInt:AIChatMessageSendingConnectionError]];
	}
	
	return YES;
}

/*!
 * @brief Toggle the favorite status for a tweet.
 *
 * Attempts to favorite a tweet. If that fails, it removes favorite status.
 * Prints a status message in the chat on success/failure, since it's otherwise not obvious.
 */
- (void)toggleFavoriteTweet:(NSString *)tweetID
{
	NSString *requestID = [twitterEngine markUpdate:tweetID asFavorite:YES];
	
	if (requestID) {
		[self setRequestType:AITwitterFavoriteYes
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:tweetID, @"tweetID", nil]];
	} else {
		AIChat *timelineChat = self.timelineChat;
		
		[adium.contentController displayEvent:AILocalizedString(@"Attempt to favorite tweet failed to connect.", nil)
									   ofType:@"favorite"
									   inChat:timelineChat];
	}
}

/*!
 * @brief Destroy the tweet.
 *
 * The user has already confirmed they want to destroy it; send the message.
 */
- (void)destroyTweet:(NSString *)tweetID
{
	NSString *requestID = [twitterEngine deleteUpdate:tweetID];
	
	if(requestID) {
		[self setRequestType:AITwitterDestroyStatus
				forRequestID:requestID
			  withDictionary:nil];
	} else {
		AIChat *timelineChat = self.timelineChat;
		
		[adium.contentController displayEvent:AILocalizedString(@"Attempt to delete tweet failed to connect.", nil)
									   ofType:@"delete"
									   inChat:timelineChat];
	}
}

/*!
 * @brief Destroy the DM.
 *
 * The user has already confirmed they want to destroy it; send the message.
 */
- (void)destroyDirectMessage:(NSString *)messageID
					 forUser:(NSString *)userID
{
	NSString *requestID = [twitterEngine deleteDirectMessage:messageID];
	AIListContact *contact = [self contactWithUID:userID];
	
	if(requestID) {
		[self setRequestType:AITwitterDestroyDM
				forRequestID:requestID
			  withDictionary:[NSDictionary dictionaryWithObject:contact forKey:@"ListContact"]];
	} else {
		AIChat *chat = [adium.chatController chatWithContact:contact];
		
		[adium.contentController displayEvent:AILocalizedString(@"Attempt to delete tweet failed to connect.", nil)
									   ofType:@"delete"
									   inChat:chat];
	}	
}

/*!
 * @brief Convert a link URL and name into an attributed link
 *
 * @param label The text to display for the link.
 * @param destination The destination address for the link.
 * @param attributeName The name of the twitter link attribute for HTML processing.
 */
- (NSAttributedString *)attributedStringWithLinkLabel:(NSString *)label
									  linkDestination:(NSString *)destination
											linkClass:(NSString *)className
{
	NSURL *url = [NSURL URLWithString:destination];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								url, NSLinkAttributeName,
								className, AIElementClassAttributeName, nil];
	
	return [[[NSAttributedString alloc] initWithString:label attributes:attributes] autorelease];
}

/*!
 * @brief Parse an attributed string into a linkified version.
 */
- (NSAttributedString *)linkifiedAttributedStringFromString:(NSAttributedString *)inString
{	
	NSAttributedString *attributedString;
	
	static NSCharacterSet *usernameCharacters = nil;
	static NSCharacterSet *hashCharacters = nil;
	
	if (!usernameCharacters) {
		usernameCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"] retain];
	}
	
	if (!hashCharacters) {
		NSMutableCharacterSet	*disallowedCharacters = [[NSCharacterSet punctuationCharacterSet] mutableCopy];
		[disallowedCharacters formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
		[disallowedCharacters removeCharactersInString:@"_"];
		
		hashCharacters = [[disallowedCharacters invertedSet] retain];
		
		[disallowedCharacters release];
	}
	
	attributedString = [AITwitterURLParser linkifiedStringFromAttributedString:inString
															forPrefixCharacter:@"@"
																   forLinkType:AITwitterLinkUserPage
																	forAccount:self
															 validCharacterSet:usernameCharacters];
	
	attributedString = [AITwitterURLParser linkifiedStringFromAttributedString:attributedString
															forPrefixCharacter:@"#"
																   forLinkType:AITwitterLinkSearchHash
																	forAccount:self
															 validCharacterSet:hashCharacters];
	
	return attributedString;
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
	
	message = [self linkifiedAttributedStringFromString:message];
	
	BOOL replyTweet = (replyTweetID.length);
	BOOL tweetLink = (tweetID.length && userID.length);
	
	if (replyTweet || tweetLink) {
		NSMutableAttributedString *mutableMessage = [[message mutableCopy] autorelease];
		
		NSUInteger startIndex = message.length;
		
		[mutableMessage appendString:@"  (" withAttributes:nil];
	
		BOOL commaNeeded = NO;
		
		// Append a link to the tweet this is in reply to
		if (replyTweet) {
			NSString *linkAddress = [self addressForLinkType:AITwitterLinkStatus
													  userID:replyUserID
													statusID:replyTweetID
													 context:nil];

			if([inMessage hasPrefix:@"@"] &&
			   inMessage.length >= replyUserID.length + 1 &&
			   [replyUserID isCaseInsensitivelyEqualToString:[inMessage substringWithRange:NSMakeRange(1, replyUserID.length)]]) {
				// If the message has a "@" prefix, it's a proper in_reply_to_status_id if the usernames match. Set a link appropriately.
				[mutableMessage setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:linkAddress, NSLinkAttributeName, nil]
										range:NSMakeRange(0, replyUserID.length + 1)];
			} else {
				// This happens for mentions which are in_reply_to_status_id but the @target isn't the first part of the message.
				
				[mutableMessage appendAttributedString:[self attributedStringWithLinkLabel:AILocalizedString(@"IRT", "An abbreviation for 'in reply to' - placed at the beginning of the tweet tools for those which are directly in reply to another")
																		   linkDestination:linkAddress
																				 linkClass:AITwitterInReplyToClassName]];
				
				commaNeeded = YES;	
			}
		}
		
		// Append a link to reply to this tweet
		if (tweetLink) {
			NSString *linkAddress;
			
			if(![self.UID isCaseInsensitivelyEqualToString:userID]) {
				// A message from someone other than ourselves. RT and @ is permissible.
				if (retweetLink) {				
					if(commaNeeded) {
						[mutableMessage appendString:@", " withAttributes:nil];
					}
					
					linkAddress = [self addressForLinkType:AITwitterLinkRetweet
													userID:userID
												  statusID:tweetID
												   context:nil];
					
					// If the account doesn't support retweets, it returns nil.
					if (linkAddress) {
						[mutableMessage appendAttributedString:[self attributedStringWithLinkLabel:@"RT"
																				   linkDestination:linkAddress
																						 linkClass:AITwitterRetweetClassName]];
						
						[mutableMessage appendString:@", " withAttributes:nil];
					}
									
					linkAddress = [self addressForLinkType:AITwitterLinkQuote
													userID:userID
												  statusID:tweetID
												   context:[inMessage stringByAddingPercentEscapesForAllCharacters]];
					
#define PILCROW_SIGN @"\u00B6"
					
					[mutableMessage appendAttributedString:[self attributedStringWithLinkLabel:PILCROW_SIGN
																			   linkDestination:linkAddress
																					 linkClass:AITwitterQuoteClassName]];					
					
					commaNeeded = YES;
				}
				
				if (commaNeeded) {
					[mutableMessage appendString:@", " withAttributes:nil];
				}			
				
				linkAddress = [self addressForLinkType:AITwitterLinkReply
												userID:userID
											  statusID:tweetID
											   context:nil];
				
				[mutableMessage appendAttributedString:[self attributedStringWithLinkLabel:@"@"
																		   linkDestination:linkAddress
																				 linkClass:AITwitterReplyClassName]];
			} else {
				if(commaNeeded) {
					[mutableMessage appendString:@", " withAttributes:nil];
				}
				
				// Our own message. Display a destroy link.
				linkAddress = [self addressForLinkType:AITwitterLinkDestroyStatus
												userID:userID
											  statusID:tweetID
											   context:[inMessage stringByAddingPercentEscapesForAllCharacters]];
				
				[mutableMessage appendAttributedString:[self attributedStringWithLinkLabel:@"\u232B"
																		   linkDestination:linkAddress
																				 linkClass:AITwitterDeleteClassName]];
			}
			
			[mutableMessage appendString:@", " withAttributes:nil];

			linkAddress = [self addressForLinkType:AITwitterLinkFavorite
											userID:userID
										  statusID:tweetID
										   context:nil];

			[mutableMessage appendAttributedString:[self attributedStringWithLinkLabel:@"\u2606"
																	   linkDestination:linkAddress
																			 linkClass:AITwitterFavoriteClassName]];

			[mutableMessage appendString:@", " withAttributes:nil];
			
			linkAddress = [self addressForLinkType:AITwitterLinkStatus
											userID:userID
										  statusID:tweetID
										   context:nil];
			
			[mutableMessage appendAttributedString:[self attributedStringWithLinkLabel:@"#"
																	   linkDestination:linkAddress
																			 linkClass:AITwitterStatusLinkClassName]];

		}
	
		[mutableMessage appendString:@")" withAttributes:nil];
		
		[mutableMessage addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithBool:YES], AITwitterActionLinksAttributeName,
									   [NSNumber numberWithBool:YES], AIHiddenMessagePartAttributeName, nil]
								range:NSMakeRange(startIndex, mutableMessage.length - startIndex)];
	
		return mutableMessage;
	} else {
		return message;
	}
}

/*!
 * @brief Parse a direct message
 */
- (NSAttributedString *)parseDirectMessage:(NSString *)inMessage
									withID:(NSString *)dmID
								  fromUser:(NSString *)sourceUID
{
	NSAttributedString *message;
	
	message = [NSAttributedString stringWithString:[inMessage stringByUnescapingFromXMLWithEntities:nil]];
	
	message = [self linkifiedAttributedStringFromString:message];
	
	NSMutableAttributedString *mutableMessage = [[message mutableCopy] autorelease];
	
	NSUInteger startIndex = message.length;
	
	[mutableMessage appendString:@"  (" withAttributes:nil];
	
	NSString *linkAddress = [self addressForLinkType:AITwitterLinkDestroyDM
											  userID:sourceUID
											statusID:dmID
											 context:[inMessage stringByAddingPercentEscapesForAllCharacters]];
	
	[mutableMessage appendAttributedString:[self attributedStringWithLinkLabel:@"\u232B"
															   linkDestination:linkAddress
																	 linkClass:AITwitterDeleteClassName]];
	
	[mutableMessage appendString:@")" withAttributes:nil];
	
	[mutableMessage addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithBool:YES], AITwitterActionLinksAttributeName,
								   [NSNumber numberWithBool:YES], AIHiddenMessagePartAttributeName, nil]
							range:NSMakeRange(startIndex, mutableMessage.length - startIndex)];
	
	return mutableMessage;
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
	for(NSUInteger idx = 1; idx < inArray.count; idx++)
	{
		status = [inArray objectAtIndex:idx];
		previousStatus = [inArray objectAtIndex:idx-1];
		
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
		
		BOOL trackContent = [[self preferenceForKey:TWITTER_PREFERENCE_EVER_LOADED_TIMELINE group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue];
		
		AIChat *timelineChat = self.timelineChat;
		
		[[AIContactObserverManager sharedManager] delayListObjectNotifications];
		
		for (NSDictionary *status in sortedQueuedUpdates) {
			NSDate			*date = [status objectForKey:TWITTER_STATUS_CREATED];
			NSString		*text = [status objectForKey:TWITTER_STATUS_TEXT];
			
			NSString *contactUID = [[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_STATUS_UID];
			
			id fromObject = nil;
			
			if(![self.UID isCaseInsensitivelyEqualToString:contactUID]) {
				AIListContact *listContact = [self contactWithUID:contactUID];
				
				// Update the user's status message
				[listContact setStatusMessage:[NSAttributedString stringWithString:[text stringByUnescapingFromXMLWithEntities:nil]]
									   notify:NotifyNow];
				
				[self updateUserIcon:[[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_INFO_ICON] forContact:listContact];
				
				[timelineChat addParticipatingListObject:listContact notify:NotifyNow];
				
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
			
			contentMessage.trackContent = trackContent;
			
			[adium.contentController receiveContentObject:contentMessage];
		}
		
		[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
		
		[queuedUpdates removeAllObjects];
	} else if (requestType == AITwitterUpdateDirectMessage || requestType == AITwitterDirectMessageSend) {
		NSMutableArray **unsortedArray = (requestType == AITwitterUpdateDirectMessage) ? &queuedDM : &queuedOutgoingDM;
		
		if (!(*unsortedArray).count) {
			return;
		}
		
		AILogWithSignature(@"%@ Displaying %d DMs", self, queuedDM.count);
		
		NSArray *sortedQueuedDM = [*unsortedArray sortedArrayUsingFunction:queuedDMSort context:nil];
		
		for (NSDictionary *message in sortedQueuedDM) {
			NSDate			*date = [message objectForKey:TWITTER_DM_CREATED];
			NSString		*text = [message objectForKey:TWITTER_DM_TEXT];
			NSString		*fromUID = [message objectForKey:TWITTER_DM_SENDER_UID];
			NSString		*toUID = [message objectForKey:TWITTER_DM_RECIPIENT_UID];
			
			AIListObject *source = nil, *destination = nil;
			AIChat *chat = nil;
			
			if([self.UID isCaseInsensitivelyEqualToString:fromUID]) {
				// This is a message we sent; display as coming from us.
				source = self;
				destination = [self contactWithUID:toUID];
				chat = [adium.chatController chatWithContact:(AIListContact *)destination];
			} else {
				source = [self contactWithUID:fromUID];
				destination = self;
				chat = [adium.chatController chatWithContact:(AIListContact *)source];
			}
			
			if(chat && source && destination) {
				AIContentMessage *contentMessage = [AIContentMessage messageInChat:chat
																		withSource:source
																	   destination:destination
																			  date:date
																		   message:[self parseDirectMessage:text
																									 withID:[message objectForKey:TWITTER_DM_ID]
																								   fromUser:chat.listObject.UID]
																		 autoreply:NO];
				
				[adium.contentController receiveContentObject:contentMessage];
			}
		}
		
		[*unsortedArray removeAllObjects];
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
	} else if ([self requestTypeForRequestID:identifier] == AITwitterRemoveFollow) {
		AIListContact *listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
		
		for (NSString *groupName in listContact.remoteGroupNames) {
			[listContact removeRemoteGroupName:groupName];
		}
	} else if ([self requestTypeForRequestID:identifier] == AITwitterDestroyStatus) {
		AIChat *timelineChat = self.timelineChat;
		
		[adium.contentController displayEvent:AILocalizedString(@"Your tweet has been successfully deleted.", nil)
									  ofType:@"delete"
									  inChat:timelineChat];
	} else if ([self requestTypeForRequestID:identifier] == AITwitterDestroyDM) {
		AIListContact *contact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
		AIChat *chat = [adium.chatController chatWithContact:contact];
		
		[adium.contentController displayEvent:AILocalizedString(@"The direct message has been successfully deleted.", nil)
									   ofType:@"delete"
									   inChat:chat];		
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
	switch ([self requestTypeForRequestID:identifier]) {
		case AITwitterDirectMessageSend:
		case AITwitterSendUpdate:
		{
			AIChat	*chat = [[self dictionaryForRequestID:identifier] objectForKey:@"Chat"];
			
			if (chat) {
				[chat receivedError:[NSNumber numberWithInt:AIChatMessageSendingConnectionError]];
				
				AILogWithSignature(@"%@ Chat send error on %@", self, chat);
			}
			break;
		}
			
		case AITwitterDisconnect:
			[self didDisconnect];
			break;
			
		case AITwitterInitialUserInfo:
			[self setLastDisconnectionError:AILocalizedString(@"Unable to retrieve user list [fail]", "Message when a (vital) twitter request to retrieve the follow list fails")];
			[self didDisconnect];
			break;
			
		case AITwitterUserIconPull:
		{
			AIListContact *listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
			
			// Image pull failed, flag ourselves as needing to try again.
			[listContact setValue:nil forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
			break;
		}
			
		case AITwitterUpdateFollowedTimeline:
		case AITwitterUpdateReplies:
		{
			AIChat *timelineChat = [adium.chatController existingChatWithName:self.timelineChatName
																	onAccount:self];
			
			// Only print an error if the user already has the timeline open. Beyond annoying if we pop it open just to say "lol error"
			if (timelineChat && !timelineErrorMessagePrinted) {
				AIContentEvent *content = [AIContentEvent eventInChat:timelineChat
														   withSource:nil
														  destination:self
																 date:[NSDate date]
															  message:[NSAttributedString stringWithString:[NSString stringWithFormat:AILocalizedString(@"Unable to update timeline: %@", nil),
																											[self errorMessageForError:error]]]
															 withType:@"error"];
				
				content.postProcessContent = NO;
				content.coalescingKey = @"error";
				
				[adium.contentController receiveContentObject:content];
				
				// This gets reset to NO the next a periodic update fires.
				timelineErrorMessagePrinted = YES;
			}
			
			--pendingUpdateCount;
			break;
		}
			
		case AITwitterUpdateDirectMessage:
			--pendingUpdateCount;
			break;
			
		case AITwitterAddFollow:
			if(error.code == 404) {
				[adium.interfaceController handleErrorMessage:AILocalizedString(@"Unable to Add Contact", nil)
											  withDescription:[NSString stringWithFormat:AILocalizedString(@"Unable to add %@ to account %@, the user does not exist.", nil),
															   [[self dictionaryForRequestID:identifier] objectForKey:@"UID"],
															   self.explicitFormattedUID]];
			} else {
				[adium.interfaceController handleErrorMessage:AILocalizedString(@"Unable to Add Contact", nil)
											  withDescription:[NSString stringWithFormat:AILocalizedString(@"Unable to add %@ to account %@. %@",nil),
															   [[self dictionaryForRequestID:identifier] objectForKey:@"UID"],
															   self.explicitFormattedUID,
															   [self errorMessageForError:error]]];
			}
			break;
			
		case AITwitterRemoveFollow:
			[adium.interfaceController handleErrorMessage:AILocalizedString(@"Unable to Remove Contact", nil)
										  withDescription:[NSString stringWithFormat:AILocalizedString(@"Unable to remove %@ on account %@. %@", nil),
														   ((AIListContact *)[[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"]).UID,
														   self.explicitFormattedUID,
														   [self errorMessageForError:error]]];
			break;
			
		case AITwitterValidateCredentials:
			if(error.code == 401) {	
				if(self.useOAuth) {
					[self setPasswordTemporarily:nil];
					[self setLastDisconnectionError:TWITTER_OAUTH_NOT_AUTHORIZED];
					
					[[NSNotificationCenter defaultCenter] postNotificationName:@"AIEditAccount"
																		object:self];
					
				} else {
					[self setLastDisconnectionError:TWITTER_INCORRECT_PASSWORD_MESSAGE];
					[self serverReportedInvalidPassword];
				}
				
				[self didDisconnect];
			} else {
				[self setLastDisconnectionError:AILocalizedString(@"Unable to validate credentials", nil)];
				[self didDisconnect];
			}
			break;
			
		case AITwitterFavoriteYes:
		case AITwitterFavoriteNo:
		{
			AIChat *timelineChat = self.timelineChat;

			if (error.code == 403) {
				// We've attempted to add or remove when we already have it marked as such. Try the opposite.
				BOOL addAsFavorite = ([self requestTypeForRequestID:identifier] == AITwitterFavoriteNo);
				NSString *tweetID = [[self dictionaryForRequestID:identifier] objectForKey:@"tweetID"];
				
				NSString *requestID = [twitterEngine markUpdate:tweetID
													 asFavorite:addAsFavorite];
				
				if (requestID) {
					[self setRequestType:(addAsFavorite ? AITwitterFavoriteYes : AITwitterFavoriteNo)
							forRequestID:requestID
						  withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:tweetID, @"tweetID", nil]];
				} else {
					[adium.contentController displayEvent:AILocalizedString(@"Attempt to favorite tweet failed to connect.", nil)
												   ofType:@"favorite"
												   inChat:timelineChat];
				}
			} else {
				[adium.contentController displayEvent:[NSString stringWithFormat:AILocalizedString(@"Attempt to favorite tweet failed. %@", nil), [self errorMessageForError:error]]
											   ofType:@"favorite"
											   inChat:timelineChat];				
			}
			
			break;
		}
			
		case AITwitterNotificationEnable:
		case AITwitterNotificationDisable:
		{
			BOOL			enableNotification = ([self requestTypeForRequestID:identifier] == AITwitterNotificationEnable);
			AIListContact	*listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
			
			[adium.interfaceController handleErrorMessage:(enableNotification ?
														   AILocalizedString(@"Unable to Enable Notifications", nil) :
														   AILocalizedString(@"Unable to Disable Notifications", nil))
										  withDescription:[NSString stringWithFormat:AILocalizedString(@"Cannot change notification setting for %@. %@", nil), listContact.UID, [self errorMessageForError:error]]];
			break;
		}
			
		case AITwitterDestroyStatus:
		{
			AIChat *timelineChat = self.timelineChat;
			
			[adium.contentController displayEvent:[NSString stringWithFormat:AILocalizedString(@"Your tweet failed to delete. %@", nil), [self errorMessageForError:error]]
										   ofType:@"delete"
										   inChat:timelineChat];
			break;
		}
			
		case AITwitterDestroyDM:
		{
				AIListContact *contact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
				AIChat *chat = [adium.chatController chatWithContact:contact];
				
				[adium.contentController displayEvent:[NSString stringWithFormat:AILocalizedString(@"The direct message failed to delete. %@", nil), [self errorMessageForError:error]]
											   ofType:@"delete"
											   inChat:chat];	
			break;
		}
			
		case AITwitterUnknownType:
		case AITwitterRateLimitStatus:
		case AITwitterProfileSelf:
		case AITwitterSelfUserIconPull:
		case AITwitterProfileUserInfo:
		case AITwitterProfileStatusUpdates:
			// While we don't handle the errors, it's a good idea to not have a "default" just to prevent accidentally letting something
			// we should really handle slip through.
			break;

	}
	
	AILogWithSignature(@"%@ Request failed (%@ - %u) - %@", self, identifier, [self requestTypeForRequestID:identifier], error);
	
	[self clearRequestTypeForRequestID:identifier];
}

/*!
 * @brief Status updates received
 */
- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier
{
	if([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline ||
	   [self requestTypeForRequestID:identifier] == AITwitterUpdateReplies) {
		NSString *lastID;
		
		BOOL nextPageNecessary = NO;
		
		if([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline) {
			lastID = [self preferenceForKey:TWITTER_PREFERENCE_TIMELINE_LAST_ID
									  group:TWITTER_PREFERENCE_GROUP_UPDATES];
			
			nextPageNecessary = (lastID && statuses.count >= TWITTER_UPDATE_TIMELINE_COUNT - 5);
		} else {
			lastID = [self preferenceForKey:TWITTER_PREFERENCE_REPLIES_LAST_ID
									  group:TWITTER_PREFERENCE_GROUP_UPDATES];
			
			nextPageNecessary = (lastID && statuses.count >= TWITTER_UPDATE_REPLIES_COUNT - 5);
		}
		
		// Store the largest tweet ID we find; this will be our "last ID" the next time we run.
		NSString *largestTweet = [[self dictionaryForRequestID:identifier] objectForKey:@"LargestTweet"];
		
		// The largest ID is first, compare.
		if (statuses.count) {
			NSString *tweetID = [[statuses objectAtIndex:0] objectForKey:TWITTER_STATUS_ID];
			if (!largestTweet || [largestTweet compare:tweetID options:NSNumericSearch] == NSOrderedAscending) {
				largestTweet = tweetID;
			}
		}
		
		[queuedUpdates addObjectsFromArray:statuses];
		
		AILogWithSignature(@"%@ Last ID: %@ Largest Tweet: %@ Next Page Necessary: %d", self, lastID, largestTweet, nextPageNecessary);
		
		// See if we need to pull more updates.
		if (nextPageNecessary) {
			int	nextPage = [[[self dictionaryForRequestID:identifier] objectForKey:@"Page"] intValue] + 1;
			NSString	*requestID;
			
			if ([self requestTypeForRequestID:identifier] == AITwitterUpdateFollowedTimeline) {
				requestID = [twitterEngine getFollowedTimelineFor:nil
														  sinceID:lastID
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
				requestID = [twitterEngine getRepliesSinceID:lastID startingAtPage:nextPage];
				
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
			
			if (followedTimelineCompleted && repliesCompleted) {
				if (queuedUpdates.count) {
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

				if (![self preferenceForKey:TWITTER_PREFERENCE_EVER_LOADED_TIMELINE group:TWITTER_PREFERENCE_GROUP_UPDATES]) {
					[self setPreference:[NSNumber numberWithBool:YES]
								 forKey:TWITTER_PREFERENCE_EVER_LOADED_TIMELINE
								  group:TWITTER_PREFERENCE_GROUP_UPDATES];
				}
			}
		}
	} else if ([self requestTypeForRequestID:identifier] == AITwitterProfileStatusUpdates) {
		AIListContact *listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];

		NSMutableArray *profileArray = [[[listContact profileArray] mutableCopy] autorelease];
		
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
	} else if ([self requestTypeForRequestID:identifier] == AITwitterSendUpdate) {
		if (updateAfterSend) {
			[self periodicUpdate];
		}
		
		if (statuses.count) {
			[adium.contentController displayEvent:AILocalizedString(@"Tweet successfully sent.", nil)
										   ofType:@"tweet"
										  inChat:self.timelineChat];
		}
				
		for(NSDictionary *update in statuses) {
			[[NSNotificationCenter defaultCenter] postNotificationName:AITwitterNotificationPostedStatus
																object:update
															  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.timelineChat, @"AIChat", nil]];
			
			NSString *text = [[update objectForKey:TWITTER_STATUS_TEXT] stringByUnescapingFromXMLWithEntities:nil];
			
			if([[self preferenceForKey:TWITTER_PREFERENCE_UPDATE_GLOBAL group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue] &&
			   (![text hasPrefix:@"@"] || [[self preferenceForKey:TWITTER_PREFERENCE_UPDATE_GLOBAL_REPLIES group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue])) {
				AIStatus *availableStatus = [AIStatus statusOfType:AIAvailableStatusType];
				
				availableStatus.statusMessage = [NSAttributedString stringWithString:text];
				[adium.statusController setActiveStatusState:availableStatus];
			}
		}
	} else if ([self requestTypeForRequestID:identifier] == AITwitterFavoriteYes ||
			   [self requestTypeForRequestID:identifier] == AITwitterFavoriteNo) {
		AIChat *timelineChat = self.timelineChat;

		for (NSDictionary *status in statuses) {
			NSString *message;
			
			// Use HTML for the status message since it's just easier to localize that way.
			
			if ([self requestTypeForRequestID:identifier] == AITwitterFavoriteYes) {
				message = AILocalizedString(@"The <a href=\"%@\">requested tweet</a> by <a href=\"%@\">%@</a> is now a favorite.", nil);
			} else {
				message = AILocalizedString(@"The <a href=\"%@\">requested tweet</a> by <a href=\"%@\">%@</a> is no longer a favorite.", nil);
			}

			NSString *userID = [[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_STATUS_UID];
			
			
			message = [NSString stringWithFormat:message,
					   [self addressForLinkType:AITwitterLinkStatus
										 userID:userID
									   statusID:[status objectForKey:TWITTER_STATUS_ID]
										context:nil],
					   [self addressForLinkType:AITwitterLinkUserPage
										 userID:userID
									   statusID:nil
										context:nil],
					   userID];
			
			NSAttributedString *attributedMessage = [[AIHTMLDecoder decoder] decodeHTML:message withDefaultAttributes:nil];
			
			AIContentEvent *content = [AIContentEvent eventInChat:timelineChat
													   withSource:nil
													  destination:self
															 date:[NSDate date]
														  message:attributedMessage
														 withType:@"favorite"];
			
			content.postProcessContent = NO;
			content.coalescingKey = @"favorite";

			[adium.contentController receiveContentObject:content];
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
		NSString *lastID = [self preferenceForKey:TWITTER_PREFERENCE_DM_LAST_ID
											group:TWITTER_PREFERENCE_GROUP_UPDATES];
		
		BOOL nextPageNecessary = (lastID && messages.count >= TWITTER_UPDATE_DM_COUNT);
		
		// Store the largest tweet ID we find; this will be our "last ID" the next time we run.
		NSString *largestTweet = [[self dictionaryForRequestID:identifier] objectForKey:@"LargestTweet"];
		
		// The largest ID is first, compare.
		if (messages.count) {
			NSString *tweetID = [[messages objectAtIndex:0] objectForKey:TWITTER_DM_ID];
			if (!largestTweet || [largestTweet compare:tweetID] == NSOrderedAscending) {
				largestTweet = tweetID;
			}
		}
		
		[queuedDM addObjectsFromArray:messages];
		
		AILogWithSignature(@"%@ Last ID: %@ Largest Tweet: %@ Next Page Necessary: %d", self, lastID, largestTweet, nextPageNecessary);
		
		if(nextPageNecessary) {
			int	nextPage = [[[self dictionaryForRequestID:identifier] objectForKey:@"Page"] intValue] + 1;
			
			NSString	*requestID = [twitterEngine getDirectMessagesSinceID:lastID
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
	} else if ([self requestTypeForRequestID:identifier] == AITwitterDirectMessageSend) {
		[queuedOutgoingDM addObjectsFromArray:messages];
		[self displayQueuedUpdatesForRequestType:AITwitterDirectMessageSend];
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

/*!
 * @brief User information received
 */
- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)identifier
{	
	if (([self requestTypeForRequestID:identifier] == AITwitterInitialUserInfo ||
		 [self requestTypeForRequestID:identifier] == AITwitterAddFollow) &&
		[[self preferenceForKey:TWITTER_PREFERENCE_LOAD_CONTACTS group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue]) {
		[[AIContactObserverManager sharedManager] delayListObjectNotifications];
		
		// The current amount of friends per page is 100. Use >= just in case this changes.
		BOOL nextPageNecessary = (userInfo.count >= 100);
		
		AILogWithSignature(@"%@ User info pull, Next page necessary: %d Count: %d", self, nextPageNecessary, userInfo.count);
		
		for (NSDictionary *info in userInfo) {
			AIListContact *listContact = [self contactWithUID:[info objectForKey:TWITTER_INFO_UID]];
			
			// If the user isn't in a group, set them in the Twitter group.
			if(listContact.countOfRemoteGroupNames == 0) {
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
			NSString *statusText = [[info objectForKey:TWITTER_INFO_STATUS] objectForKey:TWITTER_INFO_STATUS_TEXT];
			if (!statusText) //nil if they've never tweeted
				statusText = @"";
			[listContact setStatusMessage:[NSAttributedString stringWithString:[statusText stringByUnescapingFromXMLWithEntities:nil]] notify:NotifyLater];
			
			// Set the user as online.
			[listContact setOnline:YES notify:NotifyLater silently:silentAndDelayed];
			
			[listContact notifyOfChangedPropertiesSilently:silentAndDelayed];
		}
		
		[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
		
		if (nextPageNecessary) {
			int	nextPage = [[[self dictionaryForRequestID:identifier] objectForKey:@"Page"] intValue] + 1;
			NSString	*requestID = [twitterEngine getRecentlyUpdatedFriendsFor:self.UID startingAtPage:nextPage];
			
			AILogWithSignature(@"%@ Pulling additional user info page %d", self, nextPage);
			
			if(requestID) {
				[self setRequestType:AITwitterInitialUserInfo
						forRequestID:requestID
					  withDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:nextPage]
																 forKey:@"Page"]];
			} else { 
				[self setLastDisconnectionError:AILocalizedString(@"Unable to retrieve user list [additional fail]", "Message when a (vital) twitter request to retrieve the follow list fails")];
				[self didDisconnect];
			}
			
		} else if ([self valueForProperty:@"Connecting"]) {			
			// Trigger our normal update routine.
			[self didConnect];
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
			
			for (NSUInteger idx = 0; idx < keyNames.count; idx++) {
				NSString			*keyName = [keyNames objectAtIndex:idx];
				NSString			*unattributedValue = [thisUserInfo objectForKey:keyName];
				
				if(![unattributedValue isEqualToString:@""]) {
					NSString			*readableName = [readableNames objectAtIndex:idx];
					NSAttributedString	*value;
					
					if([keyName isEqualToString:@"friends_count"]) {
						value = [NSAttributedString attributedStringWithLinkLabel:unattributedValue
																  linkDestination:[self addressForLinkType:AITwitterLinkFriends userID:listContact.UID statusID:nil context:nil]];
					} else if ([keyName isEqualToString:@"followers_count"]) {
						value = [NSAttributedString attributedStringWithLinkLabel:unattributedValue
																  linkDestination:[self addressForLinkType:AITwitterLinkFollowers userID:listContact.UID statusID:nil context:nil]];
					} else if ([keyName isEqualToString:@"statuses_count"]) {
						value = [NSAttributedString attributedStringWithLinkLabel:unattributedValue
																  linkDestination:[self addressForLinkType:AITwitterLinkUserPage userID:listContact.UID statusID:nil context:nil]];
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

			[self filterAndSetUID:[info objectForKey:TWITTER_INFO_UID]];
			
			if ([info objectForKey:@"name"]) {
				[self setPreference:[[NSAttributedString stringWithString:[info objectForKey:@"name"]] dataRepresentation]
								forKey:KEY_ACCOUNT_DISPLAY_NAME
								 group:GROUP_ACCOUNT_STATUS];		
			}
			
			[self setValue:[info objectForKey:@"name"] forProperty:@"Profile Name" notify:NotifyLater];
			[self setValue:[info objectForKey:@"url"] forProperty:@"Profile URL" notify:NotifyLater];
			[self setValue:[info objectForKey:@"location"] forProperty:@"Profile Location" notify:NotifyLater];
			[self setValue:[info objectForKey:@"description"] forProperty:@"Profile Description" notify:NotifyLater];
			[self notifyOfChangedPropertiesSilently:NO];
		}
		
		
		if([self requestTypeForRequestID:identifier] == AITwitterValidateCredentials) {
			// Our UID is definitely set; grab our friends.
			
			if ([[self preferenceForKey:TWITTER_PREFERENCE_LOAD_CONTACTS group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue]) {
				// If we load our follows as contacts, do so now.
				
				// Delay updates on initial login.
				[self silenceAllContactUpdatesForInterval:18.0];
				// Grab our user list.
				NSString	*requestID = [twitterEngine getRecentlyUpdatedFriendsFor:self.UID startingAtPage:1];
				
				if (requestID) {
					[self setRequestType:AITwitterInitialUserInfo
							forRequestID:requestID
						  withDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"Page"]];
				} else {
					[self setLastDisconnectionError:AILocalizedString(@"Unable to retrieve user list", nil)];
					[self didDisconnect];
				}
			} else {
				// If we don't load follows as contacts, we've finished connecting (fast, wasn't it?)
				[self didConnect];
			}
		}
	} else if ([self requestTypeForRequestID:identifier] == AITwitterNotificationEnable ||
			   [self requestTypeForRequestID:identifier] == AITwitterNotificationDisable) {
		BOOL			enableNotification = ([self requestTypeForRequestID:identifier] == AITwitterNotificationEnable);
		AIListContact	*listContact = [[self dictionaryForRequestID:identifier] objectForKey:@"ListContact"];
		
		for (NSDictionary *info in userInfo) {		
			[adium.interfaceController handleMessage:(enableNotification ?
													  AILocalizedString(@"Notifications Enabled", nil) :
													  AILocalizedString(@"Notifications Disabled", nil))
									 withDescription:[NSString stringWithFormat:(enableNotification ?
																				 AILocalizedString(@"You will now receive device notifications for %@.", nil) :
																				 AILocalizedString(@"You will no longer receive device notifications for %@.", nil)),
													  listContact.UID]
									 withWindowTitle:(enableNotification ?
													  AILocalizedString(@"Notifications Enabled", nil) :
													  AILocalizedString(@"Notifications Disabled", nil))];
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
		
		[self setPreference:[NSNumber numberWithBool:YES]
					 forKey:KEY_USE_USER_ICON
					  group:GROUP_ACCOUNT_STATUS];
		
		
		[self setPreference:[image TIFFRepresentation]
					 forKey:KEY_USER_ICON
					  group:GROUP_ACCOUNT_STATUS];
	}
	
	[self clearRequestTypeForRequestID:identifier];
}

@end
