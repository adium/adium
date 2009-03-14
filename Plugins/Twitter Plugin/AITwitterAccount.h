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
#import "MGTwitterEngine/MGTwitterEngine.h"

typedef enum {
	AITwitterUnknownType = 0,
	
	AITwitterValidateCredentials,
	AITwitterDisconnect,
	
	AITwitterRateLimitStatus,
	
	AITwitterInitialUserInfo,
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
	AITwitterUpdateReplies
} AITwitterRequestType;

typedef enum {
	AITwitterLinkStatus,
	AITwitterLinkFriends,
	AITwitterLinkFollowers,
	AITwitterLinkUserPage
} AITwitterLinkType;

#define TWITTER_UPDATE_INTERVAL_MINUTES		10 // Used as the default Preferences

#define TWITTER_UPDATE_TIMELINE_COUNT_FIRST_RUN		50

#define TWITTER_UPDATE_TIMELINE_COUNT		200
#define TWITTER_UPDATE_DM_COUNT				20
#define TWITTER_UPDATE_REPLIES_COUNT		20
#define TWITTER_UPDATE_USER_INFO_COUNT		10

#define TWITTER_INCORRECT_PASSWORD_MESSAGE	AILocalizedString(@"Incorrect username or password","Error message displayed when the server reports username or password as being incorrect.")

#define TWITTER_REMOTE_GROUP_NAME			@"Twitter"
#define TWITTER_TIMELINE_NAME				AILocalizedString(@"Timeline (%@)", "Twitter timeline chat name, where %@ is the name of the account")

#define TWITTER_PROPERTY_REQUESTED_USER_ICON	@"Twitter Requested User Icon"

#define TWITTER_PREFERENCE_UPDATE_AFTER_SEND		@"Update After Send"
#define TWITTER_PREFERENCE_UPDATE_GLOBAL			@"Update Global Status"
#define TWITTER_PREFERENCE_UPDATE_GLOBAL_REPLIES	@"Update Global Status Includes Replies"

#define TWITTER_PREFERENCE_UPDATE_INTERVAL		@"Update Interval In Minutes"
#define TWITTER_PREFERENCE_DM_LAST_ID			@"Direct Messages Last ID"
#define TWITTER_PREFERENCE_TIMELINE_LAST_ID		@"Followed Timeline Last ID"
#define TWITTER_PREFERENCE_REPLIES_LAST_ID		@"Replies Last ID"
#define TWITTER_PREFERENCE_GROUP_UPDATES		@"Twitter Preferences"

// Status Updates
#define TWITTER_STATUS_ID					@"id"
#define TWITTER_STATUS_REPLY_UID			@"in_reply_to_screen_name"
#define TWITTER_STATUS_REPLY_ID				@"in_reply_to_status_id"
#define TWITTER_STATUS_CREATED				@"created_at"
#define TWITTER_STATUS_USER					@"user"
#define TWITTER_STATUS_UID					@"screen_name"
#define TWITTER_STATUS_TEXT					@"text"

// Direct Messages
#define TWITTER_DM_ID						@"id"
#define TWITTER_DM_CREATED					@"created_at"
#define TWITTER_DM_SENDER					@"sender"
#define TWITTER_DM_SENDER_UID				@"sender_screen_name"
#define TWITTER_DM_TEXT						@"text"

// User Info
#define TWITTER_INFO_STATUS					@"status"
#define TWITTER_INFO_STATUS_TEXT			@"text"
#define TWITTER_INFO_DISPLAY_NAME			@"name"
#define TWITTER_INFO_UID					@"screen_name"
#define TWITTER_INFO_ICON					@"profile_image_url"

// Rate Limit
#define TWITTER_RATE_LIMIT_HOURLY_LIMIT		@"hourly-limit"
#define TWITTER_RATE_LIMIT_REMAINING		@"remaining-hits"
#define TWITTER_RATE_LIMIT_RESET_SECONDS	@"reset-time-in-seconds"

@interface AITwitterAccount : AIAccount <MGTwitterEngineDelegate> {
	MGTwitterEngine		*twitterEngine;
	NSTimer				*updateTimer;
	
	BOOL				updateAfterSend;
	
	NSUInteger			pendingUpdateCount;
	
	BOOL				followedTimelineCompleted;
	BOOL				repliesCompleted;
	NSMutableArray		*queuedUpdates;
	NSMutableArray		*queuedDM;
	
	NSNumber			*futureTimelineLastID;
	NSNumber			*futureRepliesLastID;
	
	NSMutableDictionary	*pendingRequests;
}

@property (readonly) NSString *timelineChatName;

- (NSString *)apiPath;

- (void)setProfileName:(NSString *)name
				   url:(NSString*)url
			  location:(NSString *)location
		   description:(NSString *)description;

- (NSString *)addressForLinkType:(AITwitterLinkType)linkType
						  userID:(NSString *)userID
						statusID:(NSString *)statusID;

@end
