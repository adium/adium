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

#import "AIChat.h"

@interface AIGroupChat : AIChat <AIContainingObject> {
	NSString			*topic;
    AIListContact		*topicSetter;
	
	NSMutableDictionary	*participatingContactsFlags;
	NSMutableDictionary	*participatingContactsAliases;
	NSMutableArray		*participatingContacts;
	
	BOOL				showJoinLeave;
	BOOL				expanded;
    
	NSDate				*lastMessageDate;
}

@property (readwrite, nonatomic) BOOL showJoinLeave;

@property (readonly, nonatomic) BOOL supportsTopic;

- (void)updateTopic:(NSString *)inTopic withSource:(AIListContact *)contact;
- (void)setTopic:(NSString *)inTopic;

@property (readwrite, copy, nonatomic) NSDate *lastMessageDate;

// Group chat participants.
- (NSString *)displayNameForContact:(AIListObject *)contact;
- (AIGroupChatFlags)flagsForContact:(AIListObject *)contact;
- (NSString *)aliasForContact:(AIListObject *)contact;
- (void)setFlags:(AIGroupChatFlags)flags forContact:(AIListObject *)contact;
- (void)setAlias:(NSString *)alias forContact:(AIListObject *)contact;
- (void)removeSavedValuesForContactUID:(NSString *)contactUID;

- (void)addParticipatingListObject:(AIListContact *)inObject notify:(BOOL)notify;
- (void)addParticipatingListObjects:(NSArray *)inObjects notify:(BOOL)notify;
- (void)removeAllParticipatingContactsSilently;
- (void)removeObject:(AIListObject *)inObject;

- (BOOL)inviteListContact:(AIListContact *)inObject withMessage:(NSString *)inviteMessage;

- (void)resortParticipants;

@end
