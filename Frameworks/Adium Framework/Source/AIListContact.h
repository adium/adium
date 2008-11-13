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

#import <Adium/AIListObject.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListGroup.h>

typedef enum
{
		AIGroupChatNone						= 0x0000, /**< No flags                     */
		AIGroupChatVoice						= 0x0001, /**< Voiced user or "Participant" */
		AIGroupChatHalfOp					= 0x0002, /**< Half-op                      */
		AIGroupChatOp								= 0x0004, /**< Channel Op or Moderator      */
		AIGroupChatFounder				= 0x0008, /**< Channel Founder              */
		AIGroupChatTyping					= 0x0010, /**< Currently typing             */
} AIGroupChatFlags;

#define KEY_AB_UNIQUE_ID		@"AB Unique ID"

@class ABPerson;

@interface AIListContact : AIListObject {
	AIAccount	*account;
	NSString		*remoteGroupName;
	NSString		*internalUniqueObjectID;
	AIGroupChatFlags groupChatFlags;
}

- (id)initWithUID:(NSString *)inUID account:(AIAccount *)inAccount service:(AIService *)inService;
- (id)initWithUID:(NSString *)inUID service:(AIService *)inService;
@property (readwrite, nonatomic, retain) NSString *remoteGroupName;
- (void)setUID:(NSString *)inUID;
@property (readonly, nonatomic) AIAccount *account;
- (NSString *)internalUniqueObjectID;
+ (NSString *)internalUniqueObjectIDForService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID;
- (void)restoreGrouping;

@property (readonly, nonatomic) AIListGroup *parentGroup;
@property (readonly, nonatomic) AIListContact *parentContact;

@property (readonly, nonatomic) NSString *ownDisplayName;
@property (readonly, nonatomic) NSString *ownPhoneticName;
@property (readonly, nonatomic) NSString *serversideDisplayName;

@property (readwrite, nonatomic) AIGroupChatFlags groupChatFlags;

@property (readonly, nonatomic) BOOL canJoinMetaContacts;

@property (readonly, nonatomic) BOOL isIntentionallyNotAStranger;

- (void)setIsMobile:(BOOL)isMobile notify:(NotifyTiming)notify;
- (void)setOnline:(BOOL)online notify:(NotifyTiming)notify silently:(BOOL)silent;
- (void)setSignonDate:(NSDate *)signonDate notify:(NotifyTiming)notify;
- (NSDate *)signonDate;
- (void)setIsBlocked:(BOOL)yesOrNo updateList:(BOOL)addToPrivacyLists;
- (void)setIsAllowed:(BOOL)yesOrNo updateList:(BOOL)addToPrivacyLists;
- (void)setIsOnPrivacyList:(BOOL)yesOrNo updateList:(BOOL)addToPrivacyLists privacyType:(AIPrivacyType)privType;

- (void)setIdle:(BOOL)isIdle sinceDate:(NSDate *)idleSinceDate notify:(NotifyTiming)notify;
- (void)setServersideIconData:(NSData *)iconData notify:(NotifyTiming)notify;

- (void)setWarningLevel:(int)warningLevel notify:(NotifyTiming)notify;
- (int)warningLevel;

- (void)setProfileArray:(NSArray *)array notify:(NotifyTiming)notify;
- (void)setProfile:(NSAttributedString *)profile notify:(NotifyTiming)notify;
- (NSArray *)profileArray;
- (NSAttributedString *)profile;

- (void)setServersideAlias:(NSString *)alias 
				  silently:(BOOL)silent;

- (NSAttributedString *)contactListStatusMessage;

- (NSWritingDirection)baseWritingDirection;
- (void)setBaseWritingDirection:(NSWritingDirection)direction;

- (ABPerson *)addressBookPerson;
- (void)setAddressBookPerson:(ABPerson *)inPerson;

@end
