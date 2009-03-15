//
//  AIListBookmark.m
//  Adium
//
//  Created by Erik Beerepoot on 19/07/07.
//  Copyright 2007 Adium Team. All rights reserved.
//

#import "AIListBookmark.h"
#import <Adium/AIAccount.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIService.h>
#import <Adium/AIChat.h>
#import <Adium/AIContactList.h>

#define	KEY_CONTAINING_OBJECT_UID	@"ContainingObjectUID"
#define	OBJECT_STATUS_CACHE			@"Object Status Cache"

#define KEY_ACCOUNT_INTERNAL_ID		@"AccountInternalObjectID"

@interface AIListObject ()
- (void)setContainingObject:(AIListGroup *)inGroup;
@end

@interface AIListBookmark ()
- (BOOL)chatIsOurs:(AIChat *)chat;
- (void)restoreGrouping;
@end

@implementation AIListBookmark

@synthesize name, password, chatCreationDictionary;

- (void)_initListBookmark
{
	[self restoreGrouping];
	
	[self.account addObserver:self
					 forKeyPath:@"Online"
						options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
						context:NULL];
	
	[adium.notificationCenter addObserver:self
								 selector:@selector(chatDidOpen:) 
									 name:Chat_DidOpen
								   object:nil];
}

-(id)initWithChat:(AIChat *)inChat
{
	if ((self = [self initWithUID:[NSString stringWithFormat:@"Bookmark:%@", inChat.uniqueChatID]
						   account:inChat.account
						   service:inChat.account.service])) {
		chatCreationDictionary = [inChat.chatCreationDictionary copy];
		name = [inChat.name copy];
		[self _initListBookmark];
		AILog(@"Created AIListBookmark %@", self);
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	AIAccount *myAccount = [adium.accountController accountWithInternalObjectID:[decoder decodeObjectForKey:KEY_ACCOUNT_INTERNAL_ID]];
	if (!myAccount) {
		[self release];
		return nil;
	}

	if ((self = [self initWithUID:[decoder decodeObjectForKey:@"UID"]
						  account:myAccount
						  service:[adium.accountController firstServiceWithServiceID:[decoder decodeObjectForKey:@"ServiceID"]]])) {
		chatCreationDictionary = [[decoder decodeObjectForKey:@"chatCreationDictionary"] retain];
		name = [[decoder decodeObjectForKey:@"name"] retain];
		[self _initListBookmark];
		AILog(@"Created AIListBookmark from coder with dict %@",chatCreationDictionary);
		
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:self.UID forKey:@"UID"];
	[encoder encodeObject:self.account.internalObjectID forKey:KEY_ACCOUNT_INTERNAL_ID];
	[encoder encodeObject:self.service.serviceID forKey:@"ServiceID"];
	[encoder encodeObject:self.chatCreationDictionary forKey:@"chatCreationDictionary"];
	[encoder encodeObject:name forKey:@"name"];
}

- (void)dealloc
{
	[adium.notificationCenter removeObserver:self];
	[self.account removeObserver:self forKeyPath:@"Online"];

	[super dealloc];
}

/*!
 * @brief Remove ourself
 *
 * We've been asked to be removed. Ask the contact controller to do so.
 */
- (void)removeFromList
{
	[adium.contactController removeBookmark:self];
}

/*!
 * @brief Our formatted UID
 *
 * If we're in an active chat, returns the name of the chat; otherwise, our UID.
 */
- (NSString *)formattedUID
{
	AIChat *chat = [adium.chatController existingChatWithName:[self name]
													onAccount:self.account];
	
	if ([self chatIsOurs:chat]) {
		return chat.name;
	} else {
		return self.name;
	}
}

- (BOOL) existsServerside
{
	return NO; //TODO: protocols where this can be yes, like XMPP
}

/*!
 * @brief Set our display name
 *
 * Update the display name of our chat if our display name changes.
 */
- (void)setDisplayName:(NSString *)inDisplayName
{
	[super setDisplayName:inDisplayName];
	
	AIChat *chat = [adium.chatController existingChatWithName:[self name]
					onAccount:self.account];
	
	if ([self chatIsOurs:chat]) {
		chat.displayName = self.displayName;
	}
}

/*!
 * @brief Add a containing group
 *
 * When adding a containing group, save the group's UID so that we can rejoin the group next time.
 */
- (void)addContainingGroup:(AIListGroup *)inGroup
{
	[super addContainingGroup:inGroup];
	
	NSString *groupUID = inGroup.UID;
	NSString *savedGroupUID = [self preferenceForKey:KEY_CONTAINING_OBJECT_UID group:OBJECT_STATUS_CACHE];
	
	if((!savedGroupUID || ![groupUID isEqualToString:savedGroupUID]) &&
		(inGroup != adium.contactController.contactList)) {
		// We either don't have a group, or this is a new, non-root-list group. Set our preference.
		
		[self setPreference:groupUID
					 forKey:KEY_CONTAINING_OBJECT_UID
					  group:OBJECT_STATUS_CACHE];
	}
}

/*!
 * @brief Restore grouping
 *
 * When asked to restore grouping, move ourselves to the appropriate AIListGroup:
 * - The root contact list if contact list groups are disabled, or
 * - The last saved group. If the last saved group is missing for some reason, we move to "Bookmarks".
 */
- (void)restoreGrouping
{
	AIListGroup		*targetGroup = nil;

	// In reality, it's extremely unlikely the saved group would be lost.
	NSString *savedGroupUID = [self preferenceForKey:KEY_CONTAINING_OBJECT_UID group:OBJECT_STATUS_CACHE] ?: AILocalizedString(@"Bookmarks", nil);

	if (adium.contactController.useContactListGroups) {
		targetGroup = [adium.contactController groupWithUID:savedGroupUID];
	} else {
		targetGroup = adium.contactController.contactList;
	}

	[adium.contactController moveContact:self intoGroups:targetGroup ? [NSSet setWithObject:targetGroup] : [NSSet set]];
}

/*!
 * @brief Open our chat
 *
 * This is called when we are double-clicked in the contact list.
 * Either find or create a chat appropriately, and activate it.
 */
- (void)openChat
{
	AIChat *chat = [adium.chatController existingChatWithName:self.name
													onAccount:self.account];
	
	if (![self chatIsOurs:chat]) {
		//Open a new group chat (bookmarked chat)
		chat = [adium.chatController chatWithName:self.name
									   identifier:NULL 
								        onAccount:self.account 
							     chatCreationInfo:self.chatCreationDictionary];
	}	
	
	if(!chat.isOpen) {
		[adium.interfaceController openChat:chat];
	}
	
	[adium.interfaceController setActiveChat:chat];
}

/*!
 * @brief A chat opened
 *
 * If this chat is our representation, set it up appropriately with our settings.
 */
- (void)chatDidOpen:(NSNotification *)notification
{
	AIChat *chat = [notification object];
	
	// If this is our chat, we should set it up appropriately.
	if ([self chatIsOurs:chat]) {
		chat.displayName = self.displayName;
	}
}

/*!
 * @brief Can this object be part of a metacontact?
 *
 * Bookmarks cannot join meta contacts.
 */
- (BOOL)canJoinMetaContacts
{
	return NO;
}

/*!
 * @brief Is this chat ours?
 *
 * If the chat's name, account, and creation dictionary matches ours, it should be considered ours.
 */
- (BOOL)chatIsOurs:(AIChat *)chat
{
	return (chat &&
			[chat.name isEqualToString:self.name] &&
			chat.account == self.account &&
			((!chat.chatCreationDictionary && !self.chatCreationDictionary) ||
			 ([chat.chatCreationDictionary isEqualToDictionary:self.chatCreationDictionary])));
}

#pragma mark -
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"Online"] && object == self.account) {
		// If an account is just initially signing on, a -setOnline:notify:silently will still broadcast an event for the contact.
		// The initial delay an account (usually) sets is done after they're set as online, so these bookmarks would always fire.
		// Thus, we have to use the secondary, silent notification so that the online gets propogated without the events.
		[self setOnline:self.account.online notify:NotifyLater silently:YES];
		[self notifyOfChangedPropertiesSilently:YES];
	}
}

#pragma mark -
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%x %@ - %@ on %@>",NSStringFromClass([self class]), self, self.formattedUID, [self chatCreationDictionary], self.account];
}

@end
