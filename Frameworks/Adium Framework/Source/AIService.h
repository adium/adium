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

#import <Adium/AIServiceIcons.h>

@class AIAccountViewController, DCJoinChatViewController;

//Service importance, used to group and order services
typedef enum {
	AIServicePrimary,
	AIServiceSecondary,
	AIServiceUnsupported
} AIServiceImportance;

@interface AIService : NSObject {

}

/*!
 * @brief Called one time to register this service with Adium
 *
 * This is typically called by the principal class of a service plugin
 */
+ (void)registerService;

//Account Creation
- (id)accountWithUID:(NSString *)inUID internalObjectID:(NSString *)inInternalObjectID;
@property (readonly, nonatomic) Class accountClass;
@property (readonly, nonatomic) AIAccountViewController *accountViewController;
@property (readonly, nonatomic) DCJoinChatViewController *joinChatView;

//Service Description
@property (readonly, nonatomic) NSString *serviceCodeUniqueID;
@property (readonly, nonatomic) NSString *serviceID;
@property (readonly, nonatomic) NSString *serviceClass;
@property (readonly, nonatomic) NSString *shortDescription;
@property (readonly, nonatomic) NSString *longDescription;
@property (readonly, nonatomic) NSString *userNameLabel;
@property (readonly, nonatomic) NSString *contactUserNameLabel;
@property (readonly, nonatomic) NSString *UIDPlaceholder;
@property (readonly, nonatomic) AIServiceImportance serviceImportance;
- (NSImage *)defaultServiceIconOfType:(AIServiceIconType)iconType;

//Service Properties
@property (readonly, nonatomic) NSCharacterSet *allowedCharacters;
@property (readonly, nonatomic) NSCharacterSet *allowedCharactersForUIDs;
@property (readonly, nonatomic) NSCharacterSet *allowedCharactersForAccountName;
@property (readonly, nonatomic) NSCharacterSet *ignoredCharacters;
@property (readonly, nonatomic) NSUInteger allowedLength;
@property (readonly, nonatomic) int allowedLengthForUIDs;
@property (readonly, nonatomic) int allowedLengthForAccountName;
@property (readonly, nonatomic) BOOL caseSensitive;
@property (readonly, nonatomic) BOOL canCreateGroupChats;
@property (readonly, nonatomic) BOOL canRegisterNewAccounts;
@property (readonly, nonatomic) BOOL supportsProxySettings;
@property (readonly, nonatomic) BOOL supportsPassword;
@property (readonly, nonatomic) BOOL requiresPassword;
@property (readonly, nonatomic) BOOL isSocialNetworkingService;
@property (readonly, nonatomic) NSString *defaultUserName;
@property (readonly, nonatomic) BOOL isHidden;

//Utilities
- (NSString *)normalizeUID:(NSString *)inUID removeIgnoredCharacters:(BOOL)removeIgnored;
- (NSString *)normalizeChatName:(NSString *)inChatName;

-(void) registerStatuses;

@end
