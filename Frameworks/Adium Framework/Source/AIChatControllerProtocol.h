/*
 *  AIChatControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

@protocol AIChatController_Private;
@class AIChat, AIAccount, AIListContact;

//Observer which receives notifications of changes in chat status
@protocol AIChatObserver
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
@end

@protocol AIChatController <AIController, AIChatController_Private>
//Chats
- (NSSet *)allChatsWithContact:(AIListContact *)inContact;
- (NSSet *)allGroupChatsContainingContact:(AIListContact *)inContact;
- (AIChat *)openChatWithContact:(AIListContact *)inContact onPreferredAccount:(BOOL)onPreferredAccount;
- (AIChat *)chatWithContact:(AIListContact *)inContact;
- (AIChat *)existingChatWithContact:(AIListContact *)inContact;
- (AIChat *)existingChatWithUniqueChatID:(NSString *)uniqueChatID;
- (AIChat *)chatWithName:(NSString *)inName 
			  identifier:(id)identifier
			   onAccount:(AIAccount *)account
		chatCreationInfo:(NSDictionary *)chatCreationInfo;

- (AIChat *)existingChatWithIdentifier:(id)identifier onAccount:(AIAccount *)account;
- (AIChat *)existingChatWithName:(NSString *)name onAccount:(AIAccount *)account;

- (BOOL)closeChat:(AIChat *)inChat;
- (void)accountDidCloseChat:(AIChat *)inChat;

@property (nonatomic, readonly) NSSet *openChats;
@property (nonatomic, readonly) AIChat *mostRecentUnviewedChat;
@property (nonatomic, readonly) NSUInteger unviewedContentCount;
@property (nonatomic, readonly) NSUInteger unviewedConversationCount;

- (void)switchChat:(AIChat *)chat toAccount:(AIAccount *)newAccount;
- (void)switchChat:(AIChat *)chat toListContact:(AIListContact *)inContact usingContactAccount:(BOOL)useContactAccount;
- (BOOL)contactIsInGroupChat:(AIListContact *)listContact;

	//Status
- (void)registerChatObserver:(id <AIChatObserver>)inObserver;
- (void)unregisterChatObserver:(id <AIChatObserver>)inObserver;
- (void)updateAllChatsForObserver:(id <AIChatObserver>)observer;

	//Addition/removal of contacts to group chats
- (void)chat:(AIChat *)chat addedListContacts:(NSArray *)contacts notify:(BOOL)notify;
- (void)chat:(AIChat *)chat removedListContact:(AIListContact *)inContact;

- (NSString *)defaultInvitationMessageForRoom:(NSString *)room account:(AIAccount *)inAccount;
@end

@protocol AIChatController_Private
- (void)chatStatusChanged:(AIChat *)inChat modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
@end
