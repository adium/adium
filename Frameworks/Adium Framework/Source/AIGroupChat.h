//
//  AIGroupChat.h
//  Adium
//
//  Created by Thijs Alkemade on 21-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import "AIChat.h"

@interface AIGroupChat : AIChat <AIContainingObject> {
	NSString			*topic;
    AIListContact		*topicSetter;
	
	NSMutableDictionary	*participatingContactsFlags;
	NSMutableDictionary	*participatingContactsAliases;
	NSMutableArray		*participatingContacts;
	
	BOOL				hideUserIconAndStatus;
	BOOL				showJoinLeave;
	BOOL				expanded;
    
	NSDate				*lastMessageDate;
}

@property (readwrite, nonatomic) BOOL showJoinLeave;

@property (readwrite, nonatomic) BOOL hideUserIconAndStatus;
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
