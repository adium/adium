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

#import <Adium/AIAccount.h>
#import <Adium/AIGroupChat.h>
#import "STTwitterAPIWrapper.h"

typedef enum {
	AITwitterUnknownType = 0,
	
	AITwitterValidateCredentials,
	AITwitterDisconnect,
	
	AITwitterRateLimitStatus,
	
	AITwitterInitialUserInfo,
	AITwitterAddFollow,
	AITwitterRemoveFollow,
	
	AITwitterProfileSelf,
	AITwitterSelfUserIconPull,
	
	AITwitterProfileUserInfo,
	AITwitterProfileStatusUpdates,
	AITwitterUserIconPull,
	
	AITwitterDirectMessageSend,
	AITwitterSendUpdate,
	
	AITwitterUpdateDirectMessage,
	AITwitterUpdateFollowedTimeline,
	AITwitterUpdateReplies,
	
	AITwitterFavoriteYes,
	AITwitterFavoriteNo,
	
	AITwitterNotificationEnable,
	AITwitterNotificationDisable,
	
	AITwitterDestroyStatus,
	AITwitterDestroyDM
} AITwitterRequestType;

typedef enum {
	AITwitterLinkReply = 0,
	AITwitterLinkRetweet,
	AITwitterLinkQuote,
	AITwitterLinkFavorite,
	AITwitterLinkStatus,
	AITwitterLinkFriends,
	AITwitterLinkFollowers,
	AITwitterLinkUserPage,
	AITwitterLinkSearchHash,
	AITwitterLinkGroup,
	AITwitterLinkDestroyStatus,
	AITwitterLinkDestroyDM
} AITwitterLinkType;

// HTML class names
#define AITwitterInReplyToClassName		@"twitter_inReplyTo"
#define AITwitterQuoteClassName			@"twitter_quote"
#define AITwitterRetweetClassName		@"twitter_reTweet"
#define AITwitterReplyClassName			@"twitter_reply"
#define AITwitterDeleteClassName		@"twitter_delete"
#define AITwitterFavoriteClassName		@"twitter_favorite"
#define AITwitterStatusLinkClassName	@"twitter_status"

#define AITwitterActionLinksAttributeName	@"AITwitterActionLinks"

#define TWITTER_UPDATE_INTERVAL_MINUTES		10 // Used as the default Preferences

#define TWITTER_UPDATE_TIMELINE_COUNT_FIRST_RUN		50

#define TWITTER_UPDATE_TIMELINE_COUNT		200
#define TWITTER_UPDATE_DM_COUNT				20
#define TWITTER_UPDATE_REPLIES_COUNT		20
#define TWITTER_UPDATE_USER_INFO_COUNT		10

#define TWITTER_INCORRECT_PASSWORD_MESSAGE	AILocalizedString(@"Incorrect username or password","Error message displayed when the server reports username or password as being incorrect.")
#define TWITTER_OAUTH_NOT_AUTHORIZED		AILocalizedString(@"Adium isn't allowed access to your account.", "Error message displayed when the server reports that our access has been revoked or invalid.")

#define TWITTER_REMOTE_GROUP_NAME			@"Twitter"
#define TWITTER_TIMELINE_NAME				@"Timeline (%@)"

#define TWITTER_PROPERTY_REQUESTED_USER_ICON	@"Twitter Requested User Icon"

#define TWITTER_PREFERENCE_UPDATE_AFTER_SEND		@"Update After Send"
#define TWITTER_PREFERENCE_UPDATE_GLOBAL			@"Update Global Status"
#define TWITTER_PREFERENCE_UPDATE_GLOBAL_REPLIES	@"Update Global Status Includes Replies"
#define TWITTER_PREFERENCE_LOAD_CONTACTS			@"Load Follows as Contacts"

#define TWITTER_PREFERENCE_EVER_LOADED_TIMELINE	@"Ever Loaded Timeline"
#define TWITTER_PREFERENCE_UPDATE_INTERVAL		@"Update Interval In Minutes"
#define TWITTER_PREFERENCE_DM_LAST_ID			@"Direct Messages Last ID"
#define TWITTER_PREFERENCE_TIMELINE_LAST_ID		@"Followed Timeline Last ID 2.0"
#define TWITTER_PREFERENCE_REPLIES_LAST_ID		@"Replies Last ID 2.0"
#define TWITTER_PREFERENCE_GROUP_UPDATES		@"Twitter Preferences"

#define AITwitterNotificationPostedStatus		@"AITwitterNotificationPostedStatus"

// Status Updates
#define TWITTER_STATUS_ID					@"id_str"
#define TWITTER_STATUS_REPLY_UID			@"in_reply_to_screen_name"
#define TWITTER_STATUS_REPLY_ID				@"in_reply_to_status_id_str"
#define TWITTER_STATUS_CREATED				@"created_at"
#define TWITTER_STATUS_USER					@"user"
#define TWITTER_STATUS_UID					@"screen_name"
#define TWITTER_STATUS_TEXT					@"text"
#define TWITTER_STATUS_RETWEET				@"retweeted_status"

// Direct Messages
#define TWITTER_DM_ID						@"id"
#define TWITTER_DM_CREATED					@"created_at"
#define TWITTER_DM_SENDER_UID				@"sender_screen_name"
#define TWITTER_DM_RECIPIENT_UID			@"recipient_screen_name"
#define TWITTER_DM_TEXT						@"text"

// User Info
#define TWITTER_INFO_STATUS					@"status"
#define TWITTER_INFO_STATUS_TEXT			@"text"
#define TWITTER_INFO_DISPLAY_NAME			@"name"
#define TWITTER_INFO_UID					@"screen_name"
#define TWITTER_INFO_ICON					@"profile_image_url"

// Rate Limit
#define TWITTER_RATE_LIMIT					@"limit"
#define TWITTER_RATE_LIMIT_REMAINING		@"remaining"
#define TWITTER_RATE_LIMIT_RESET_SECONDS	@"reset"

@interface AITwitterAccount : AIAccount {
	STTwitterAPIWrapper	*twitterEngine;
	NSTimer				*updateTimer;
	
	BOOL				updateAfterSend;
	
	BOOL				timelineErrorMessagePrinted;
	NSUInteger			pendingUpdateCount;
	
	BOOL				followedTimelineCompleted;
	BOOL				repliesCompleted;
	BOOL				supportsCursors;
	NSMutableArray		*queuedUpdates;
	NSMutableArray		*queuedDM;
	NSMutableArray		*queuedOutgoingDM;
	
	NSString			*futureTimelineLastID;
	NSString			*futureRepliesLastID;
	
	NSMutableDictionary	*pendingRequests;
}

@property (weak, readonly, nonatomic) NSString *timelineChatName;
@property (weak, readonly, nonatomic) NSString *timelineGroupName;
@property (weak, readonly, nonatomic) NSString *apiPath;
@property (weak, readonly, nonatomic) NSString *sourceToken;
@property (weak, readonly, nonatomic) NSString *defaultServer;

@property (readonly, nonatomic) int maxChars;
@property (readonly, nonatomic) BOOL useSSL;
@property (readonly, nonatomic) BOOL useOAuth;
@property (readonly, nonatomic) BOOL supportsCursors;
@property (weak, readonly, nonatomic) NSString *consumerKey;
@property (weak, readonly, nonatomic) NSString *secretKey;
@property (weak, readonly, nonatomic) NSString *tokenRequestURL;
@property (weak, readonly, nonatomic) NSString *tokenAccessURL;
@property (weak, readonly, nonatomic) NSString *tokenAuthorizeURL;

@property (weak, readonly, nonatomic) AIGroupChat *timelineChat;

- (NSString *)errorMessageForError:(NSError *)error;

- (void)setProfileName:(NSString *)name
				   url:(NSString*)url
			  location:(NSString *)location
		   description:(NSString *)description;

- (BOOL)retweetTweet:(NSString *)tweetID;
- (void)toggleFavoriteTweet:(NSString *)tweetID;
- (void)destroyTweet:(NSString *)tweetID;
- (void)destroyDirectMessage:(NSString *)messageID
					 forUser:(NSString *)userID;

- (void)linkifyEntities:(NSArray *)entities inString:(NSMutableAttributedString **)inString forLinkType:(AITwitterLinkType)linkType;

- (NSString *)addressForLinkType:(AITwitterLinkType)linkType
						  userID:(NSString *)userID
						statusID:(NSString *)statusID
						 context:(NSString *)context;

- (void)updateTimelineChat:(AIGroupChat *)timelineChat;

@end
