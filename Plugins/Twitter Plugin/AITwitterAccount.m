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
#import "AITwitterReplyWindowController.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIContactObserverManager.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIContentEvent.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import "STTwitterOAuth.h"

@interface AITwitterAccount()
- (void)updateUserIcon:(NSString *)url forContact:(AIListContact *)listContact;

- (void)updateTimelineChat:(AIGroupChat *)timelineChat;

- (NSAttributedString *)parseStatus:(NSDictionary *)inStatus
							tweetID:(NSString *)tweetID
							 userID:(NSString *)userID
					  inReplyToUser:(NSString *)replyUserID
				   inReplyToTweetID:(NSString *)replyTweetID;
- (NSAttributedString *)parseDirectMessage:(NSDictionary *)inMessage
									withID:(NSString *)dmID
								  fromUser:(NSString *)sourceUID;
- (NSAttributedString *)attributedStringWithLinkLabel:(NSString *)label
									  linkDestination:(NSString *)destination
											linkClass:(NSString *)attributeName;

- (void)periodicUpdate;
- (void)displayQueuedUpdatesForRequestType:(AITwitterRequestType)requestType;

- (void)getRateLimitAmount;

- (void)openUserPage:(NSMenuItem *)menuItem;
- (void)enableOrDisableNotifications:(NSMenuItem *)menuItem;
- (void)replyToTweet;
@end

@implementation AITwitterAccount

@synthesize supportsCursors;

- (void)initAccount
{
	[super initAccount];
	
	pendingRequests = [[NSMutableDictionary alloc] init];
	queuedUpdates = [[NSMutableArray alloc] init];
	queuedDM = [[NSMutableArray alloc] init];
	queuedOutgoingDM = [[NSMutableArray alloc] init];
	supportsCursors = YES;
	
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
	
    /* twitter.com isn't a valid server, but it was stored directly in the past. Clear it. */
    if ([[self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS] isEqualToString:@"twitter.com"])
        [self setPreference:nil
                     forKey:KEY_CONNECT_HOST
                      group:GROUP_ACCOUNT_STATUS];
	
    /* Register the default server if there is one. A subclass may choose to have no default server at all. */
    if (self.defaultServer) {
        [adium.preferenceController registerDefaults:[NSDictionary dictionaryWithObject:self.defaultServer
                                                                                 forKey:KEY_CONNECT_HOST]
                                            forGroup:GROUP_ACCOUNT_STATUS
                                              object:self];
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
	return @"api.twitter.com";
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
	
	if (!self.passwordWhileConnected.length) {
		/* If we weren't able to retrieve the 'password', we can't proceed with oauth - we stored the oauth
		 * http response body in the keychain as the password.
		 *
		 * Note that this can happen not only if Adium isn't authorized but also if it *is* authorized but the
		 * keychain was inaccessible - e.g. keychain access wasn't allowed after an upgrade. Hm.
		 */
		[self setLastDisconnectionError:TWITTER_OAUTH_NOT_AUTHORIZED];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"AIEditAccount"
															object:self];
		
		[self didDisconnect];
		
		// Don't try and connect.
		return;
		
	}
	
	NSDictionary *oauth = [self.passwordWhileConnected parametersDictionary];
	
	NSString *oauthToken = [oauth objectForKey:@"oauth_token"];
	NSString *oauthSecret = [oauth objectForKey:@"oauth_token_secret"];
	
	[twitterEngine release];
	
	twitterEngine = [[STTwitterAPIWrapper twitterAPIWithOAuthConsumerName:@"Adium"
															  consumerKey:self.consumerKey
														   consumerSecret:self.secretKey
															   oauthToken:oauthToken
														 oauthTokenSecret:oauthSecret] retain];
	
	AILogWithSignature(@"%@ connecting to %@", self, twitterEngine.userName);
	
	[twitterEngine getAccountVerifyCredentialsSkipStatus:YES
											successBlock:^(NSDictionary *myInfo) {
		[self userInfoReceived:myInfo forRequest:AITwitterValidateCredentials];
		
		if ([[self preferenceForKey:TWITTER_PREFERENCE_LOAD_CONTACTS group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue]) {
			// If we load our follows as contacts, do so now.
			
			// Delay updates on initial login.
			[self silenceAllContactUpdatesForInterval:18.0];
			// Grab our user list.
			[twitterEngine getFriendsForScreenName:self.UID
									  successBlock:^(NSArray *friends) {
										  [self userInfoReceived:@{ @"friends" : friends } forRequest:AITwitterInitialUserInfo];
										  
										  if ([self boolValueForProperty:@"isConnecting"]) {
											  // Trigger our normal update routine.
											  [self didConnect];
										  }
									  } errorBlock:^(NSError *error) {
										  [self setLastDisconnectionError:AILocalizedString(@"Unable to retrieve user list [fail]", "Message when a (vital) twitter request to retrieve the follow list fails")];
										  [self didDisconnect];
									  }];
		} else {
			// If we don't load follows as contacts, we've finished connecting (fast, wasn't it?)
			[self didConnect];
		}
	} errorBlock:^(NSError *error) {
		[self requestFailed:AITwitterValidateCredentials withError:error userInfo:nil];
	}];
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
	
	// Creating the timeline chat's bookmark.
	AIListBookmark *timelineBookmark = [adium.contactController existingBookmarkForChatName:self.timelineChatName
																				  onAccount:self
																		   chatCreationInfo:nil];
	
	if (timelineBookmark) {
		[timelineBookmark restoreGrouping];
		
	} else {
		AIChat *newTimelineChat = [adium.chatController chatWithName:self.timelineChatName
														  identifier:nil
														   onAccount:self
													chatCreationInfo:nil];
		
		[newTimelineChat setDisplayName:self.timelineChatName];
		
		timelineBookmark = [adium.contactController bookmarkForChat:newTimelineChat
															inGroup:[adium.contactController groupWithUID:self.timelineGroupName]];
		
		
		if(!timelineBookmark) {
			AILog(@"%@ Timeline bookmark is nil! Tried checking for existing bookmark for chat name %@, and creating a bookmark for chat %@ in group %@", self,
				  self.timelineChatName, newTimelineChat,
				  [adium.contactController groupWithUID:self.timelineGroupName]);
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
	return @"/1";
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
 * @brief Returns the maximum number of characters available for a post, or 0 if unlimited.
 *
 * For Twitter, this is hardcoded to 140.
 */
- (int)maxChars
{
	return 140;
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
	return self.online;
}

/*!
 * @brief Affirm we can open chats.
 */
- (BOOL)openChat:(AIChat *)chat
{
	[chat setValue:[NSNumber numberWithBool:YES] forProperty:@"accountJoined" notify:NotifyNow];
	
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
 * @brief Suffix for autocompleted contacts
 */
- (NSString *)suffixForAutocomplete:(AIChat *)inChat forPartialWordRange:(NSRange)charRange
{
	return nil;
}

/*!
 * @brief Prefix for autocompleted contacts
 */
- (NSString *)prefixForAutocomplete:(AIChat *)inChat forPartialWordRange:(NSRange)charRange
{
	return @"@";
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
		[self updateTimelineChat:(AIGroupChat *)chat];
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
- (AIReconnectDelayType)shouldAttemptReconnectAfterDisconnectionError:(NSString * __strong *)disconnectionError
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
- (void)setSocialNetworkingStatusMessage:(NSAttributedString *)inStatusMessage
{
	[self sendUpdate:inStatusMessage.string forChat:nil];
	AILogWithSignature(@"%@ Sending social networking update %@", self, inStatusMessage);
}

/*!
 * @brief Send a tweet
 */
- (void)sendUpdate:(NSString *)inStatusMessage forChat:(AIChat *)chat {
	[twitterEngine postStatusUpdate:inStatusMessage
				  inReplyToStatusID:[chat valueForProperty:@"TweetInReplyToStatusID"]
							placeID:nil
								lat:nil
								lon:nil
					   successBlock:^(NSDictionary *status) {
						   [adium.contentController displayEvent:AILocalizedString(@"Tweet successfully sent.", nil)
														  ofType:@"tweet"
														  inChat:self.timelineChat];
						   
						   [[NSNotificationCenter defaultCenter] postNotificationName:AITwitterNotificationPostedStatus
																			   object:status
																			 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.timelineChat, @"AIChat", nil]];
						   
						   NSDictionary *retweet = [status valueForKey:TWITTER_STATUS_RETWEET];
						   NSString *text = [[status objectForKey:TWITTER_STATUS_TEXT] stringByEscapingForXMLWithEntities:nil];
						   
						   if (retweet && [retweet isKindOfClass:[NSDictionary class]]) {
							   text = [[NSString stringWithFormat:@"RT @%@: %@",
										[[retweet objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_STATUS_UID],
										[retweet objectForKey:TWITTER_STATUS_TEXT]] stringByEscapingForXMLWithEntities:nil];
						   }
						   
						   if ([[self preferenceForKey:TWITTER_PREFERENCE_UPDATE_GLOBAL group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue] &&
							   (![text hasPrefix:@"@"] || [[self preferenceForKey:TWITTER_PREFERENCE_UPDATE_GLOBAL_REPLIES group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue])) {
							   AIStatus *availableStatus = [AIStatus statusOfType:AIAvailableStatusType];
							   
							   availableStatus.statusMessage = [NSAttributedString stringWithString:text];
							   [adium.statusController setActiveStatusState:availableStatus];
						   }
						   
						   if (updateAfterSend)
							   [self performSelector:@selector(periodicUpdate) withObject:nil afterDelay:0.0];
					   } errorBlock:^(NSError *error) {
						   [self requestFailed:AITwitterSendUpdate withError:error userInfo:@{ @"Chat" : chat }];
					   }];
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
	if (inContentMessage.chat.isGroupChat) {
		[self sendUpdate:inContentMessage.encodedMessage forChat:inContentMessage.chat];
		inContentMessage.displayContent = NO;
		
		AILogWithSignature(@"%@ Sending update [in reply to %@]: %@", self, [inContentMessage.chat valueForProperty:@"TweetInReplyToStatusID"], inContentMessage.encodedMessage);
	} else {
		[twitterEngine postDirectMessage:inContentMessage.encodedMessage
									  to:inContentMessage.destination.UID
							successBlock:^(NSDictionary *dm) {
								[queuedOutgoingDM addObject:dm];
								[self displayQueuedUpdatesForRequestType:AITwitterDirectMessageSend];
							} errorBlock:^(NSError *error) {
								[self requestFailed:AITwitterDirectMessageSend withError:error userInfo:@{ @"Chat" : inContentMessage.chat }];
							}];
		
		inContentMessage.displayContent = NO;
		
		AILogWithSignature(@"%@ Sending DM to %@: %@", self, inContentMessage.destination.UID, inContentMessage.encodedMessage);
	}
	
	return YES;
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
	
	[twitterEngine getUserInformationFor:inContact.UID
							successBlock:^(NSDictionary *thisUserInfo) {
								if (thisUserInfo) {
									NSArray *keyNames = [NSArray arrayWithObjects:@"name", @"location", @"description", @"url", @"friends_count", @"followers_count", @"statuses_count", nil];
									NSArray *readableNames = [NSArray arrayWithObjects:AILocalizedString(@"Name", nil), AILocalizedString(@"Location", nil),
															  AILocalizedString(@"Biography", nil), AILocalizedString(@"Website", nil), AILocalizedString(@"Following", nil),
															  AILocalizedString(@"Followers", nil), AILocalizedString(@"Updates", nil), nil];
									
									__block NSMutableArray *profileArray = [[NSMutableArray array] retain];
									
									for (NSUInteger idx = 0; idx < keyNames.count; idx++) {
										NSString			*keyName = [keyNames objectAtIndex:idx];
										id		   unattributedValue = [thisUserInfo objectForKey:keyName];
										NSString		*stringValue = nil;
										if ([unattributedValue isKindOfClass:[NSNumber class]])
											stringValue = [(NSNumber *)unattributedValue stringValue];
										else if ([unattributedValue isKindOfClass:[NSNumber class]])
											stringValue = unattributedValue;
										
										if (stringValue) {
											NSString			*readableName = [readableNames objectAtIndex:idx];
											NSAttributedString	*value;
											
											if([keyName isEqualToString:@"friends_count"]) {
												value = [NSAttributedString attributedStringWithLinkLabel:stringValue
																						  linkDestination:[self addressForLinkType:AITwitterLinkFriends userID:inContact.UID statusID:nil context:nil]];
											} else if ([keyName isEqualToString:@"followers_count"]) {
												value = [NSAttributedString attributedStringWithLinkLabel:stringValue
																						  linkDestination:[self addressForLinkType:AITwitterLinkFollowers userID:inContact.UID statusID:nil context:nil]];
											} else if ([keyName isEqualToString:@"statuses_count"]) {
												value = [NSAttributedString attributedStringWithLinkLabel:stringValue
																						  linkDestination:[self addressForLinkType:AITwitterLinkUserPage userID:inContact.UID statusID:nil context:nil]];
											} else {
												value = [NSAttributedString stringWithString:stringValue];
											}
											
											[profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:readableName, KEY_KEY, value, KEY_VALUE, nil]];
										}
									}
									
									AILogWithSignature(@"%@ Updating profileArray for user %@", self, inContact);
									
									// Grab their statuses.
									[twitterEngine getUserTimelineWithScreenName:inContact.UID
																		   count:TWITTER_UPDATE_USER_INFO_COUNT
																	successBlock:^(NSArray *statuses) {
																		AILogWithSignature(@"%@ Updating statuses for profile, user %@", self, inContact);
																		
																		for (NSDictionary *update in statuses) {
																			NSAttributedString *message = [self parseStatus:update
																													tweetID:[update objectForKey:TWITTER_STATUS_ID]
																													 userID:inContact.UID
																											  inReplyToUser:[update objectForKey:TWITTER_STATUS_REPLY_UID]
																										   inReplyToTweetID:[update objectForKey:TWITTER_STATUS_REPLY_ID]];
																			
																			[profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:message, KEY_VALUE, nil]];
																		}
																		
																		[inContact setProfileArray:profileArray notify:NotifyNow];
																	} errorBlock:^(NSError *error) {
																		[self requestFailed:AITwitterProfileUserInfo withError:error userInfo:@{ @"ListContact" : inContact }];
																	}];
								}
							} errorBlock:^(NSError *error) {
								[self requestFailed:AITwitterProfileUserInfo withError:error userInfo:@{ @"ListContact" : inContact }];
							}];
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
				   url:(NSString *)url
			  location:(NSString *)location
		   description:(NSString *)description
{
	[twitterEngine postUpdateProfile:@{ @"name" : name, @"url" : url, @"location" : location, @"description" : description }
						successBlock:^(NSDictionary *status) {
							[self userInfoReceived:status forRequest:AITwitterProfileSelf];
						} errorBlock:^(NSError *error) {
							[self requestFailed:AITwitterProfileSelf withError:error userInfo:nil];
						}];
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
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:AILocalizedString(@"Open %@'s user page",nil), inContact.UID]
										  target:self
										  action:@selector(openUserPage:)
								   keyEquivalent:@""] autorelease];
	[menuItem setImage:serviceIcon];
	[menuItem setRepresentedObject:inContact];
	[menuItemArray addObject:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:AILocalizedString(@"Enable device notifications for %@", "Enable sending Twitter notifications to your phone (device)"), inContact.UID]
										  target:self
										  action:@selector(enableOrDisableNotifications:)
								   keyEquivalent:@""] autorelease];
	[menuItem setTag:YES];
	[menuItem setImage:serviceIcon];
	[menuItem setRepresentedObject:inContact];
	[menuItemArray addObject:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:AILocalizedString(@"Disable device notifications for %@", "Disable sending Twitter notifications to your phone"), inContact.UID]
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
 * @brief Open the represented object's user page
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
	
	[twitterEngine postUpdateNotifications:enableNotification
							 forScreenName:contact.UID
							  successBlock:^(NSDictionary *relationship) {
								  NSString *status = (enableNotification ?
													  AILocalizedString(@"Notifications Enabled", nil) :
													  AILocalizedString(@"Notifications Disabled", nil));
								  [adium.interfaceController handleMessage:status
														   withDescription:[NSString stringWithFormat:(enableNotification ?
																									   AILocalizedString(@"You will now receive device notifications for %@.", nil) :
																									   AILocalizedString(@"You will no longer receive device notifications for %@.", nil)),
																			contact.UID]
														   withWindowTitle:status];
							  } errorBlock:^(NSError *error) {
								  [self requestFailed:(enableNotification ? AITwitterNotificationEnable : AITwitterNotificationDisable) withError:error userInfo:@{ @"ListContact" : contact }];
							  }];
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
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Update Tweets",nil)
										  target:self
										  action:@selector(periodicUpdate)
								   keyEquivalent:@""] autorelease];
	[menuItem setImage:serviceIcon];
	[menuItemArray addObject:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Reply to a Tweet",nil)
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
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Update Tweets",nil)
										  target:self
										  action:@selector(periodicUpdate)
								   keyEquivalent:@""] autorelease];
	[menuItemArray addObject:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Reply to a Tweet",nil)
										  target:self
										  action:@selector(replyToTweet)
								   keyEquivalent:@""] autorelease];
	[menuItemArray addObject:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Get Rate Limit Amount",nil)
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
	[twitterEngine getRateLimitsForResources:@[ @"users", @"statuses", @"friendships", @"direct_messages" ]
								successBlock:^(NSDictionary *rateLimits) {
									NSMutableString *formattedString = [NSMutableString string];
									[[rateLimits objectForKey:@"resources"] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
										if ([obj isKindOfClass:[NSDictionary class]]) {
											__block BOOL displayedHeader = NO;
											[obj enumerateKeysAndObjectsUsingBlock:^(id subKey, id subObj, BOOL *subStop) {
												NSDate *resetDate = [NSDate dateWithTimeIntervalSince1970:[[subObj objectForKey:TWITTER_RATE_LIMIT_RESET_SECONDS] intValue]];
												
												int limit = [[subObj objectForKey:TWITTER_RATE_LIMIT] intValue];
												int remaining = [[subObj objectForKey:TWITTER_RATE_LIMIT_REMAINING] intValue];
												NSString *resource = [subKey stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/%@/", key]
																									   withString:@""];
												if (remaining < limit) {
													if (!displayedHeader) {
														[formattedString appendFormat:@"%@:\n", key];
														displayedHeader = YES;
													}
													[formattedString appendFormat:@"\t%@: %d/%d for %@\n", resource,
													 remaining, limit,
													 [NSDateFormatter stringForTimeInterval:[resetDate timeIntervalSinceNow]
																			 showingSeconds:YES
																				abbreviated:YES
																			   approximated:NO]];
												}
											}];
										}
									}];
									[[NSAlert alertWithMessageText:AILocalizedString(@"Current Twitter rate limits", "Message in the rate limits status window")
													 defaultButton:nil
												   alternateButton:nil
													   otherButton:nil
										 informativeTextWithFormat:@"%@", formattedString] beginSheetModalForWindow:nil modalDelegate:nil didEndSelector:nil contextInfo:nil];
								} errorBlock:^(NSError *error) {
									[self requestFailed:AITwitterRateLimitStatus withError:error userInfo:nil];
								}];
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
 * @brief The remote group name we'll stuff the timeline into
 */
- (NSString *)timelineGroupName
{
	return TWITTER_REMOTE_GROUP_NAME;
}

/*!
 * @brief Our timeline chat
 *
 * If the timeline chat is not already active, it is created.
 */
- (AIGroupChat *)timelineChat
{
	AIGroupChat *timelineChat = [adium.chatController existingChatWithName:self.timelineChatName
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
- (void)updateTimelineChat:(AIGroupChat *)timelineChat
{
	// Disable the user list on the chat.
	if (timelineChat.chatContainer.chatViewController.userListVisible) {
		[timelineChat.chatContainer.chatViewController toggleUserList];
	}
	
	// Update the participant list.
	for (AIListContact *contact in self.contacts) {
		[timelineChat addParticipatingNick:contact.UID notify:NotifyNow];
		[timelineChat setContact:contact forNick:contact.UID];
	}
	
	NSNumber *max = nil;
	if (self.maxChars > 0) {
		max = [NSNumber numberWithInt:self.maxChars];
	}
	[timelineChat setValue:max forProperty:@"Character Counter Max" notify:NotifyNow];
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
	if(![listContact boolValueForProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON]) {
		[listContact setValue:[NSNumber numberWithBool:YES] forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
		
		// Grab the user icon and set it as their serverside icon.
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSString *imageURL = [url stringByReplacingOccurrencesOfString:@"_normal." withString:@"_bigger."];
			NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURL]];
			NSError *error = nil;
			NSData *data = [NSURLConnection sendSynchronousRequest:imageRequest returningResponse:nil error:&error];
			NSImage *image = [[[NSImage alloc] initWithData:data] autorelease];
			
			if (image) {
				dispatch_async(dispatch_get_main_queue(), ^{
					AILogWithSignature(@"%@ Updated user icon for %@", self, listContact);
					[listContact setServersideIconData:[image TIFFRepresentation]
												notify:NotifyLater];
					
					[listContact setValue:nil forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
				});
			} else {
				[self requestFailed:AITwitterUserIconPull withError:error userInfo:@{ @"ListContact" : listContact }];
			}
		});
	}
}

/*!
 * @brief Unfollow the requested contacts.
 */
- (void)removeContacts:(NSArray *)objects fromGroups:(NSArray *)groups
{
	for (AIListContact *object in objects) {
		AILogWithSignature(@"%@ Requesting unfollow for: %@", self, object.UID);
		[twitterEngine postUnfollow:object.UID
					   successBlock:^(NSDictionary *user) {
						   for (NSString *groupName in object.remoteGroupNames) {
							   [object removeRemoteGroupName:groupName];
						   }
					   } errorBlock:^(NSError *error) {
						   [self requestFailed:AITwitterRemoveFollow withError:error userInfo:@{ @"ListContact" : UID }];
					   }];
	}
}

/*!
 * @brief How should deletion of a particular group be handled?
 *
 * If the account returns AIAccountGroupDeletionShouldRemoveContacts, then each contact will be removed from the contact list
 * If instead AIAccountGroupDeletionShouldIgnoreContacts is returned, the group is removed from the contact list's display
 *   but contacts are not affected.  In this case, the account should take action to avoid redisplaying the group in
 *   the future. This is used for, for example, the Twitter timeline; a deletion is unlikely to mean the user actually
 *   wanted to stop following all contained contacts.
 */
- (AIAccountGroupDeletionResponse)willDeleteGroup:(AIListGroup *)group
{
	if ([group.UID isEqualToString:self.timelineGroupName]) {
		/* Hide the group by no longer loading Twitter contacts */
		[self setPreference:[NSNumber numberWithBool:NO]
					 forKey:TWITTER_PREFERENCE_LOAD_CONTACTS
					  group:TWITTER_PREFERENCE_GROUP_UPDATES];
		return AIAccountGroupDeletionShouldIgnoreContacts;
		
	} else {
		return AIAccountGroupDeletionShouldRemoveContacts;
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
	
	AILogWithSignature(@"%@ Requesting follow for: %@", self, contact.UID);
	[twitterEngine postFollow:contact.UID
				 successBlock:^(NSDictionary *friend) {
					 [self userInfoReceived:@{ @"friends" : friend } forRequest:AITwitterAddFollow];
				 } errorBlock:^(NSError *error) {
					 [self requestFailed:AITwitterAddFollow withError:error userInfo:@{ @"UID" : contact.UID }];
				 }];
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
				AILogWithSignature(@"%@ Pushing self icon update", self);
				[twitterEngine postUpdateProfileImage:[prefDict objectForKey:KEY_USER_ICON]
										 successBlock:^(NSDictionary *myInfo) {
											 [self userInfoReceived:myInfo forRequest:AITwitterProfileSelf];
										 } errorBlock:^(NSError *error) {
											 [self requestFailed:AITwitterProfileSelf withError:error userInfo:nil];
										 }];
				[self setValue:nil forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
			}
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
		
		if ([key isEqualToString:TWITTER_PREFERENCE_LOAD_CONTACTS] && self.online) {
			if ([[prefDict objectForKey:TWITTER_PREFERENCE_LOAD_CONTACTS] boolValue]) {
				// Delay updates when loading our contacts list.
				[self silenceAllContactUpdatesForInterval:18.0];
				// Grab our user list.
				[twitterEngine getFriendsForScreenName:self.UID
										  successBlock:^(NSArray *friends) {
											  [self userInfoReceived:@{ @"friends" : friends } forRequest:AITwitterInitialUserInfo];
										  } errorBlock:^(NSError *error) {
											  [self requestFailed:AITwitterInitialUserInfo withError:error userInfo:nil];
										  }];
			} else {
				[[self timelineChat] removeAllParticipatingContactsSilently];
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
		AILogWithSignature(@"%@ Update already in progress. Count = %ld", self, pendingUpdateCount);
		return;
	}
	
	// Prevent triggering this update routine multiple times.
	pendingUpdateCount = 3;
	
	// We haven't printed error messages for this set.
	timelineErrorMessagePrinted = NO;
	
	[queuedUpdates removeAllObjects];
	[queuedDM removeAllObjects];
	
	AILogWithSignature(@"%@ Periodic update fire", self);
	
	NSString	*lastID;
	
	// Pull direct messages
	lastID = [self preferenceForKey:TWITTER_PREFERENCE_DM_LAST_ID
							  group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	[twitterEngine getDirectMessagesSinceID:lastID
									  count:TWITTER_UPDATE_DM_COUNT
							   successBlock:^(NSArray *statuses) {
								   [self directMessagesReceived:statuses forRequest:AITwitterUpdateDirectMessage];
							   } errorBlock:^(NSError *error) {
								   [self requestFailed:AITwitterUpdateDirectMessage withError:error userInfo:nil];
							   }];
	
	// We haven't completed the timeline nor replies. This lets us know if we should display statuses.
	followedTimelineCompleted = repliesCompleted = NO;
	futureTimelineLastID = futureRepliesLastID = nil;
	
	// Pull followed timeline
	lastID = [self preferenceForKey:TWITTER_PREFERENCE_TIMELINE_LAST_ID
							  group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	[twitterEngine getHomeTimelineSinceID:lastID
									count:TWITTER_UPDATE_TIMELINE_COUNT
							 successBlock:^(NSArray *statuses) {
								 [self statusesReceived:statuses forRequest:AITwitterUpdateFollowedTimeline];
							 } errorBlock:^(NSError *error) {
								 [self requestFailed:AITwitterUpdateFollowedTimeline withError:error userInfo:nil];
							 }];
	
	// Pull the replies feed
	lastID = [self preferenceForKey:TWITTER_PREFERENCE_REPLIES_LAST_ID
							  group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	[twitterEngine getMentionsTimelineSinceID:lastID
										count:TWITTER_UPDATE_REPLIES_COUNT
								 successBlock:^(NSArray *statuses) {
									 [self statusesReceived:statuses forRequest:AITwitterUpdateReplies];
								 } errorBlock:^(NSError *error) {
									 [self requestFailed:AITwitterUpdateReplies withError:error userInfo:nil];
								 }];
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
			return AILocalizedString(@"The request is invalid.", nil);
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
			
		case 429:
			// This is the status code returned if you've exceeded the rate limit.
			return AILocalizedString(@"You've exceeded the rate limit.", nil);
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
		address = [NSString stringWithFormat:@"http://twitter.com/search?q=%%23%@", context];
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
	[twitterEngine postStatusRetweetWithID:tweetID
							  successBlock:^(NSDictionary *status) {
								  [self statusesReceived:@[status] forRequest:AITwitterSendUpdate];
							  } errorBlock:^(NSError *error) {
								  [self requestFailed:AITwitterSendUpdate withError:error userInfo:@{ @"Chat" : self.timelineChat }];
							  }];
	
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
	[self markTweet:tweetID asFavorite:YES];
}

- (void)markTweet:(NSString *)tweetID asFavorite:(BOOL)favorite
{
	[twitterEngine postFavoriteState:favorite
						 forStatusID:tweetID
						successBlock:^(NSDictionary *status) {
							AIChat *timelineChat = self.timelineChat;
							NSString *message;
							
							// Use HTML for the status message since it's just easier to localize that way.
							if (favorite) {
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
						} errorBlock:^(NSError *error) {
							if (error.code == 403) {
								// We've attempted to add or remove when we already have it marked as such. Try the opposite.
								[self markTweet:tweetID asFavorite:!favorite];
							} else {
								[self requestFailed:(favorite ? AITwitterFavoriteYes : AITwitterFavoriteNo) withError:error userInfo:nil];
							}
						}];
}

/*!
 * @brief Destroy the tweet.
 *
 * The user has already confirmed they want to destroy it; send the message.
 */
- (void)destroyTweet:(NSString *)tweetID
{
	[twitterEngine postDestroyStatusWithID:tweetID
							  successBlock:^(NSDictionary *status) {
								  [adium.contentController displayEvent:AILocalizedString(@"Your tweet has been successfully deleted.", nil)
																 ofType:@"delete"
																 inChat:self.timelineChat];
							  } errorBlock:^(NSError *error) {
								  [adium.contentController displayEvent:[NSString stringWithFormat:AILocalizedString(@"Your tweet failed to delete. %@", nil), [self errorMessageForError:error]]
																 ofType:@"delete"
																 inChat:self.timelineChat];
							  }];
}

/*!
 * @brief Destroy the DM.
 *
 * The user has already confirmed they want to destroy it; send the message.
 */
- (void)destroyDirectMessage:(NSString *)messageID
					 forUser:(NSString *)userID
{
	[twitterEngine postDestroyDirectMessageWithID:messageID
									 successBlock:^(NSDictionary *dm) {
										 AIListContact *contact = [self contactWithUID:userID];
										 AIChat *chat = [adium.chatController chatWithContact:contact];
										 
										 [adium.contentController displayEvent:AILocalizedString(@"The direct message has been successfully deleted.", nil)
																		ofType:@"delete"
																		inChat:chat];
									 } errorBlock:^(NSError *error) {
										 AIListContact *contact = [self contactWithUID:userID];
										 AIChat *chat = [adium.chatController chatWithContact:contact];
										 
										 [adium.contentController displayEvent:[NSString stringWithFormat:AILocalizedString(@"The direct message failed to delete. %@", nil), [self errorMessageForError:error]]
																		ofType:@"delete"
																		inChat:chat];
									 }];
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
- (void)linkifyEntities:(NSArray *)entities inString:(NSMutableAttributedString **)inString forLinkType:(AITwitterLinkType)linkType {
	[entities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *text = @"";
		NSString *userID = nil;
		NSString *context = nil;
		if (linkType == AITwitterLinkUserPage) {
			userID = [obj objectForKey:@"screen_name"];
			text = [NSString stringWithFormat:@"@%@", userID];
		} else if (linkType == AITwitterLinkSearchHash) {
			context = [obj objectForKey:@"text"];
			text = [NSString stringWithFormat:@"#%@", context];
		}
		
		NSString *linkURL = [self addressForLinkType:linkType
											  userID:userID
											statusID:nil
											 context:context];
		
		[*inString replaceOccurrencesOfString:text
								   withString:text
								   attributes:@{ NSLinkAttributeName : linkURL }
									  options:NSCaseInsensitiveSearch
										range:NSMakeRange(0, [*inString length])];
	}];
}

/*!
 * @brief Parses a Twitter message into an attributed string
 */
- (NSAttributedString *)parseStatus:(NSDictionary *)inStatus
							tweetID:(NSString *)tweetID
							 userID:(NSString *)userID
					  inReplyToUser:(NSString *)replyUserID
				   inReplyToTweetID:(NSString *)replyTweetID
{
	NSMutableAttributedString *mutableMessage;
	NSDictionary    *retweet = [inStatus objectForKey:TWITTER_STATUS_RETWEET];
	
	if (retweet && [retweet isKindOfClass:[NSDictionary class]]) {
		NSString *text = [[retweet objectForKey:TWITTER_STATUS_TEXT] stringByUnescapingFromXMLWithEntities:nil];
		mutableMessage = [[NSMutableAttributedString alloc] initWithString:text];
		[mutableMessage replaceCharactersInRange:NSMakeRange(0, 0)
									  withString:[NSString stringWithFormat:@"RT @%@: ",
										[[retweet objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_STATUS_UID]]];
	} else {
		NSString *text = [[inStatus objectForKey:TWITTER_STATUS_TEXT] stringByUnescapingFromXMLWithEntities:nil];
		mutableMessage = [[NSMutableAttributedString alloc] initWithString:text];
	}
	
	//Extract hashtags, users, and URLs
	NSDictionary *entities = [inStatus objectForKey:@"entities"];
	NSArray *hashtags = [entities objectForKey:@"hashtags"];
	NSArray *urls = [entities objectForKey:@"urls"];
	NSArray *users = [entities objectForKey:@"user_mentions"];
	NSArray *media = [entities objectForKey:@"media"];

	[self linkifyEntities:users inString:&mutableMessage forLinkType:AITwitterLinkUserPage];
	[self linkifyEntities:hashtags inString:&mutableMessage forLinkType:AITwitterLinkSearchHash];
	[urls enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *linkURL = [obj objectForKey:@"url"];
		NSString *expandedURL = [obj objectForKey:@"expanded_url"];
		[mutableMessage replaceOccurrencesOfString:linkURL
										withString:expandedURL
										attributes:@{ NSLinkAttributeName : linkURL }
										   options:NSLiteralSearch
											 range:NSMakeRange(0, mutableMessage.length)];
	}];
	[media enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *linkURL = [obj objectForKey:@"url"];
		NSString *displayURL = [obj objectForKey:@"display_url"];
		[mutableMessage replaceOccurrencesOfString:linkURL
										withString:displayURL
										attributes:@{ NSLinkAttributeName : linkURL }
										   options:NSLiteralSearch
											 range:NSMakeRange(0, mutableMessage.length)];
	}];
	
	NSString *message = [mutableMessage string];
	
	BOOL replyTweet = (replyTweetID.length > 0);
	BOOL tweetLink = (tweetID.length && userID.length);
	
	if (replyTweet || tweetLink) {
		NSUInteger startIndex = message.length;
		
		[mutableMessage appendString:@"  (" withAttributes:nil];
		
		BOOL commaNeeded = NO;
		
		// Append a link to the tweet this is in reply to
		if (replyTweet) {
			NSString *linkAddress = [self addressForLinkType:AITwitterLinkStatus
													  userID:replyUserID
													statusID:replyTweetID
													 context:nil];
			
			if([message hasPrefix:@"@"] &&
			   message.length >= replyUserID.length + 1 &&
			   [replyUserID isCaseInsensitivelyEqualToString:[message substringWithRange:NSMakeRange(1, replyUserID.length)]]) {
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
				
				/* Add the retweet link, if the account supports retweets */
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
					commaNeeded = YES;
				}
				
				/* Next add the quote link */
				if(commaNeeded) {
					[mutableMessage appendString:@", " withAttributes:nil];
				}
				
				linkAddress = [self addressForLinkType:AITwitterLinkQuote
												userID:userID
											  statusID:tweetID
											   context:[message stringByAddingPercentEscapesForAllCharacters]];
				
#define PILCROW_SIGN @"\u00B6"
				
				[mutableMessage appendAttributedString:[self attributedStringWithLinkLabel:PILCROW_SIGN
																		   linkDestination:linkAddress
																				 linkClass:AITwitterQuoteClassName]];
				
				commaNeeded = YES;
				
				/* Now add the reply link */
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
											   context:[message stringByAddingPercentEscapesForAllCharacters]];
				
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
		
		return [mutableMessage autorelease];
	} else {
		return [[[NSAttributedString alloc] initWithString:message] autorelease];
	}
}

/*!
 * @brief Parse a direct message
 */
- (NSAttributedString *)parseDirectMessage:(NSDictionary *)inMessage
									withID:(NSString *)dmID
								  fromUser:(NSString *)sourceUID
{
	NSString *message = [[inMessage objectForKey:TWITTER_DM_TEXT] stringByUnescapingFromXMLWithEntities:nil];
	NSMutableAttributedString *mutableMessage = [[NSMutableAttributedString alloc] initWithString:message];
	
	NSDictionary *entities = [inMessage objectForKey:@"entities"];
	NSArray *hashtags = [entities objectForKey:@"hashtags"];
	NSArray *users = [entities objectForKey:@"user_mentions"];
	[self linkifyEntities:users inString:&mutableMessage forLinkType:AITwitterLinkUserPage];
	[self linkifyEntities:hashtags inString:&mutableMessage forLinkType:AITwitterLinkSearchHash];
	
	NSUInteger startIndex = message.length;
	
	[mutableMessage appendString:@"  (" withAttributes:nil];
	
	NSString *linkAddress = [self addressForLinkType:AITwitterLinkDestroyDM
											  userID:sourceUID
											statusID:dmID
											 context:[message stringByAddingPercentEscapesForAllCharacters]];
	
	[mutableMessage appendAttributedString:[self attributedStringWithLinkLabel:@"\u232B"
															   linkDestination:linkAddress
																	 linkClass:AITwitterDeleteClassName]];
	
	[mutableMessage appendString:@")" withAttributes:nil];
	
	[mutableMessage addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithBool:YES], AITwitterActionLinksAttributeName,
								   [NSNumber numberWithBool:YES], AIHiddenMessagePartAttributeName, nil]
							range:NSMakeRange(startIndex, mutableMessage.length - startIndex)];
	
	return [mutableMessage autorelease];
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
		
		AILogWithSignature(@"%@ Displaying %ld updates", self, queuedUpdates.count);
		
		// Sort the queued updates (since we're intermingling pages of data from different souces)
		NSArray *sortedQueuedUpdates = [queuedUpdates sortedArrayUsingFunction:queuedUpdatesSort context:nil];
		
		sortedQueuedUpdates = [self arrayWithDuplicateTweetsRemoved:sortedQueuedUpdates];
		
		BOOL trackContent = [[self preferenceForKey:TWITTER_PREFERENCE_EVER_LOADED_TIMELINE group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue];
		
		AIGroupChat *timelineChat = self.timelineChat;
		
		[[AIContactObserverManager sharedManager] delayListObjectNotifications];
		
		for (NSDictionary *status in sortedQueuedUpdates) {
			NSString *contactUID = [[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_STATUS_UID];
			NSAttributedString *message = [self parseStatus:status
													tweetID:[status objectForKey:TWITTER_STATUS_ID]
													 userID:contactUID
											  inReplyToUser:[status objectForKey:TWITTER_STATUS_REPLY_UID]
										   inReplyToTweetID:[status objectForKey:TWITTER_STATUS_REPLY_ID]];
			
			NSDate			*date = [status objectForKey:TWITTER_STATUS_CREATED];
			
			AIListObject *fromObject = nil;
			
			if (![self.UID isCaseInsensitivelyEqualToString:contactUID]) {
				AIListContact *listContact = [self contactWithUID:contactUID];
				
				// Update the user's status message
				[listContact setStatusMessage:message
									   notify:NotifyNow];
				
				[self updateUserIcon:[[status objectForKey:TWITTER_STATUS_USER] objectForKey:TWITTER_INFO_ICON] forContact:listContact];
				
				[timelineChat addParticipatingNick:listContact.UID notify:NotifyNow];
				[timelineChat setContact:listContact forNick:listContact.UID];
				
				fromObject = listContact;
			} else {
				fromObject = self;
			}
			
			AIContentMessage *contentMessage = [AIContentMessage messageInChat:timelineChat
																	withSource:fromObject
																	sourceNick:fromObject.displayName
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
		
		AILogWithSignature(@"%@ Displaying %ld DMs", self, queuedDM.count);
		
		NSArray *sortedQueuedDM = [*unsortedArray sortedArrayUsingFunction:queuedDMSort context:nil];
		
		for (NSDictionary *message in sortedQueuedDM) {
			NSDate			*date = [NSDate dateWithNaturalLanguageString:[message objectForKey:TWITTER_DM_CREATED]];
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
																		sourceNick:source.displayName
																	   destination:destination
																			  date:date
																		   message:[self parseDirectMessage:message
																									 withID:[message objectForKey:TWITTER_DM_ID]
																								   fromUser:chat.listObject.UID]
																		 autoreply:NO];
				
				[adium.contentController receiveContentObject:contentMessage];
			}
		}
		
		[*unsortedArray removeAllObjects];
	}
}

#pragma mark Response Handling
/*!
 * @brief A request failed
 *
 * If it's a fatal error, we need to kill the session and retry. Otherwise, twitter's reliability is
 * pretty terrible, so let's ignore errors for the most part.
 */
- (void)requestFailed:(AITwitterRequestType)identifier withError:(NSError *)error userInfo:(NSDictionary *)userInfo
{
	switch (identifier) {
		case AITwitterDirectMessageSend:
		case AITwitterSendUpdate:
		{
			AIChat	*chat = [userInfo objectForKey:@"Chat"];
			
			if (chat) {
				[chat receivedError:[NSNumber numberWithInt:AIChatMessageSendingConnectionError]];
				
				AILogWithSignature(@"%@ Chat send error on %@", self, chat);
			}
			break;
		}
			
		case AITwitterDisconnect:
			[self didDisconnect];
			break;
			
		case AITwitterUserIconPull:
		{
			AIListContact *listContact = [userInfo objectForKey:@"ListContact"];
			
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
															   [userInfo objectForKey:@"UID"],
															   self.explicitFormattedUID]];
			} else {
				[adium.interfaceController handleErrorMessage:AILocalizedString(@"Unable to Add Contact", nil)
											  withDescription:[NSString stringWithFormat:AILocalizedString(@"Unable to add %@ to account %@. %@",nil),
															   [userInfo objectForKey:@"UID"],
															   self.explicitFormattedUID,
															   [self errorMessageForError:error]]];
			}
			break;
			
		case AITwitterRemoveFollow:
			[adium.interfaceController handleErrorMessage:AILocalizedString(@"Unable to Remove Contact", nil)
										  withDescription:[NSString stringWithFormat:AILocalizedString(@"Unable to remove %@ on account %@. %@", nil),
														   ((AIListContact *)[userInfo objectForKey:@"ListContact"]).UID,
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
			[adium.contentController displayEvent:[NSString stringWithFormat:AILocalizedString(@"Attempt to favorite tweet failed. %@", nil), [self errorMessageForError:error]]
										   ofType:@"favorite"
										   inChat:timelineChat];
			
			break;
		}
			
		case AITwitterNotificationEnable:
		case AITwitterNotificationDisable:
		{
			BOOL			enableNotification = (identifier == AITwitterNotificationEnable);
			AIListContact	*listContact = [userInfo objectForKey:@"ListContact"];
			
			[adium.interfaceController handleErrorMessage:(enableNotification ?
														   AILocalizedString(@"Unable to Enable Notifications", nil) :
														   AILocalizedString(@"Unable to Disable Notifications", nil))
										  withDescription:[NSString stringWithFormat:AILocalizedString(@"Cannot change notification setting for %@. %@", nil), listContact.UID, [self errorMessageForError:error]]];
			break;
		}
		case AITwitterDestroyStatus:
		case AITwitterDestroyDM:
		case AITwitterUnknownType:
		case AITwitterRateLimitStatus:
		case AITwitterProfileSelf:
		case AITwitterSelfUserIconPull:
		case AITwitterProfileUserInfo:
		case AITwitterProfileStatusUpdates:
		case AITwitterInitialUserInfo:
			// While we don't handle the errors, it's a good idea to not have a "default" just to prevent accidentally letting something
			// we should really handle slip through.
			break;
	}
	
	AILogWithSignature(@"%@ Request failed (%u) - %@", self, identifier, error);
}

/*!
 * @brief Status updates received
 */
- (void)statusesReceived:(NSArray *)statuses forRequest:(AITwitterRequestType)identifier
{
	if(identifier == AITwitterUpdateFollowedTimeline ||
	   identifier == AITwitterUpdateReplies) {
		NSString *lastID;
		
		if(identifier == AITwitterUpdateFollowedTimeline) {
			lastID = [self preferenceForKey:TWITTER_PREFERENCE_TIMELINE_LAST_ID
									  group:TWITTER_PREFERENCE_GROUP_UPDATES];
		} else {
			lastID = [self preferenceForKey:TWITTER_PREFERENCE_REPLIES_LAST_ID
									  group:TWITTER_PREFERENCE_GROUP_UPDATES];
		}
		
		// Store the largest tweet ID we find; this will be our "last ID" the next time we run.
		NSString *largestTweet = nil;
		
		if (statuses.count)
			largestTweet = [[statuses objectAtIndex:0] objectForKey:TWITTER_STATUS_ID];
		
		//Convert the TWITTER_STATUS_CREATED datestrings to NSDates
		NSMutableArray *ms = CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFArrayRef)statuses, kCFPropertyListMutableContainers);
		[ms enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			[obj setObject:[NSDate dateWithNaturalLanguageString:[obj objectForKey:TWITTER_STATUS_CREATED]]
					forKey:TWITTER_STATUS_CREATED];
		}];
		
		[queuedUpdates addObjectsFromArray:ms];
		
		AILogWithSignature(@"%@ Last ID: %@ Largest Tweet: %@", self, lastID, largestTweet);
		
		if (identifier == AITwitterUpdateFollowedTimeline) {
			followedTimelineCompleted = YES;
			futureTimelineLastID = [largestTweet retain];
		} else if (identifier == AITwitterUpdateReplies) {
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
				
				[self displayQueuedUpdatesForRequestType:identifier];
			}
			
			if (![self preferenceForKey:TWITTER_PREFERENCE_EVER_LOADED_TIMELINE group:TWITTER_PREFERENCE_GROUP_UPDATES]) {
				[self setPreference:[NSNumber numberWithBool:YES]
							 forKey:TWITTER_PREFERENCE_EVER_LOADED_TIMELINE
							  group:TWITTER_PREFERENCE_GROUP_UPDATES];
			}
		}
	}
}

/*!
 * @brief Direct messages received
 */
- (void)directMessagesReceived:(NSArray *)messages forRequest:(AITwitterRequestType)identifier
{
	if (identifier == AITwitterUpdateDirectMessage) {
		NSString *lastID = [self preferenceForKey:TWITTER_PREFERENCE_DM_LAST_ID
											group:TWITTER_PREFERENCE_GROUP_UPDATES];
		
		// Store the largest tweet ID we find; this will be our "last ID" the next time we run.
		NSString *largestTweet = nil;
		
		if (messages.count)
			largestTweet = [[messages objectAtIndex:0] objectForKey:TWITTER_DM_ID];
		
		[queuedDM addObjectsFromArray:messages];
		
		AILogWithSignature(@"%@ Last ID: %@ Largest Tweet: %@", self, lastID, largestTweet);
		
		--pendingUpdateCount;
		
		if (largestTweet) {
			AILogWithSignature(@"%@ Largest DM pulled = %@", self, largestTweet);
			
			[self setPreference:largestTweet
						 forKey:TWITTER_PREFERENCE_DM_LAST_ID
						  group:TWITTER_PREFERENCE_GROUP_UPDATES];
		}
		
		// On first load, don't display any direct messages. Just ge the largest ID.
		if (queuedDM.count && lastID) {
			[self displayQueuedUpdatesForRequestType:identifier];
		} else {
			[queuedDM removeAllObjects];
		}
	}
}

/*!
 * @brief User information received
 */
- (void)userInfoReceived:(NSDictionary *)userInfo forRequest:(AITwitterRequestType)identifier
{
	if (identifier == AITwitterInitialUserInfo ||
		identifier == AITwitterAddFollow) {
		[[AIContactObserverManager sharedManager] delayListObjectNotifications];
		
		NSArray *users = [userInfo objectForKey:@"friends"];
		AILogWithSignature(@"%@ User info pull, Users count: %ld", self, users.count);
		for (NSDictionary *user in users) {
			// Iterate users
			NSString *twitterInfoUID = [user objectForKey:TWITTER_INFO_UID];
			
			if (twitterInfoUID) {
				
				AIListContact *listContact = [self contactWithUID:twitterInfoUID];
				
				// If the user isn't in a group, set them in the Twitter group.
				if (listContact.countOfRemoteGroupNames == 0) {
					[listContact addRemoteGroupName:self.timelineGroupName];
				}
				
				// Grab the Twitter display name and set it as the remote alias.
				if (![[listContact valueForProperty:@"serverDisplayName"] isEqualToString:[user objectForKey:TWITTER_INFO_DISPLAY_NAME]]) {
					[listContact setServersideAlias:[user objectForKey:TWITTER_INFO_DISPLAY_NAME]
										   silently:silentAndDelayed];
				}
				
				// Grab the user icon and set it as their serverside icon.
				[self updateUserIcon:[user objectForKey:TWITTER_INFO_ICON] forContact:listContact];
				
				// Set the user as available.
				[listContact setStatusWithName:nil
									statusType:AIAvailableStatusType
										notify:NotifyLater];
				
				// Set the user's status message to their current twitter status text
				NSString *statusText = [[user objectForKey:TWITTER_INFO_STATUS] objectForKey:TWITTER_INFO_STATUS_TEXT];
				if (!statusText) //nil if they've never tweeted
					statusText = @"";
				[listContact setStatusMessage:[NSAttributedString stringWithString:[statusText stringByUnescapingFromXMLWithEntities:nil]] notify:NotifyLater];
				
				// Set the user as online.
				[listContact setOnline:YES notify:NotifyLater silently:silentAndDelayed];
				
				[listContact notifyOfChangedPropertiesSilently:silentAndDelayed];
			}
		}
		
		[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
	} else if (identifier == AITwitterValidateCredentials ||
			   identifier == AITwitterProfileSelf) {
		[self filterAndSetUID:[userInfo objectForKey:TWITTER_INFO_UID]];
		
		if ([userInfo objectForKey:@"name"]) {
			[self setPreference:[[NSAttributedString stringWithString:[userInfo objectForKey:@"name"]] dataRepresentation]
						 forKey:KEY_ACCOUNT_DISPLAY_NAME
						  group:GROUP_ACCOUNT_STATUS];
		}
		
		[self setValue:[userInfo objectForKey:@"name"] forProperty:@"Profile Name" notify:NotifyLater];
		[self setValue:[userInfo objectForKey:@"url"] forProperty:@"Profile URL" notify:NotifyLater];
		[self setValue:[userInfo objectForKey:@"location"] forProperty:@"Profile Location" notify:NotifyLater];
		[self setValue:[userInfo objectForKey:@"description"] forProperty:@"Profile Description" notify:NotifyLater];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSString *imageURL = [userInfo objectForKey:TWITTER_INFO_ICON];
			NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURL]];
			NSError *error = nil;
			NSData *data = [NSURLConnection sendSynchronousRequest:imageRequest returningResponse:nil error:&error];
			NSImage *image = [[[NSImage alloc] initWithData:data] autorelease];
			
			if (image) {
				dispatch_async(dispatch_get_main_queue(), ^{
					AILogWithSignature(@"Updated self icon for %@", self);
					
					// Set a property so that we don't re-send the image we're just now downloading.
					[self setValue:[NSNumber numberWithBool:YES] forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
					
					[self setPreference:[NSNumber numberWithBool:YES]
								 forKey:KEY_USE_USER_ICON
								  group:GROUP_ACCOUNT_STATUS];
					
					[self setPreference:[image TIFFRepresentation]
								 forKey:KEY_USER_ICON
								  group:GROUP_ACCOUNT_STATUS];
					
					[self notifyOfChangedPropertiesSilently:NO];
					
					[self setValue:nil forProperty:TWITTER_PROPERTY_REQUESTED_USER_ICON notify:NotifyNever];
				});
			} else {
				[self requestFailed:AITwitterSelfUserIconPull withError:error userInfo:nil];
			}
		});
	}
}

@end
