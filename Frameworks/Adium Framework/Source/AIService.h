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
- (Class)accountClass;
- (AIAccountViewController *)accountViewController;
- (DCJoinChatViewController *)joinChatView;

//Service Description
- (NSString *)serviceCodeUniqueID;
- (NSString *)serviceID;
- (NSString *)serviceClass;
- (NSString *)shortDescription;
- (NSString *)longDescription;
- (NSString *)userNameLabel;
- (NSString *)contactUserNameLabel;
- (NSString *)UIDPlaceholder;
- (AIServiceImportance)serviceImportance;
- (NSImage *)defaultServiceIconOfType:(AIServiceIconType)iconType;

//Service Properties
- (NSCharacterSet *)allowedCharacters;
- (NSCharacterSet *)allowedCharactersForUIDs;
- (NSCharacterSet *)allowedCharactersForAccountName;
- (NSCharacterSet *)ignoredCharacters;
- (int)allowedLength;
- (int)allowedLengthForUIDs;
- (int)allowedLengthForAccountName;
- (BOOL)caseSensitive;
- (BOOL)canCreateGroupChats;
- (BOOL)canRegisterNewAccounts;
- (BOOL)supportsProxySettings;
- (BOOL)supportsPassword;
- (BOOL)requiresPassword;
- (void)registerStatuses;
- (BOOL)isSocialNetworkingService;
- (NSString *)defaultUserName;
- (BOOL)isHidden;

//Utilities
- (NSString *)normalizeUID:(NSString *)inUID removeIgnoredCharacters:(BOOL)removeIgnored;
- (NSString *)normalizeChatName:(NSString *)inChatName;

@end
