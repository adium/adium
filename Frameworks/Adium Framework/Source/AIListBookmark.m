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

#import "AIListBookmark.h"
#import <Adium/AIListGroup.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIService.h>
#import <Adium/AIContactList.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

#define	KEY_CONTAINING_OBJECT_UID	@"ContainingObjectUID"

#define KEY_ACCOUNT_INTERNAL_ID		@"AccountInternalObjectID"

@interface AIListBookmark ()
- (BOOL)chatIsOurs:(AIChat *)chat;
- (AIChat *)openChatWithoutActivating;
- (void)restoreGrouping;

- (void)claimChatIfOurs:(AIChat *)chat;

- (void)_updateUnreadMessagesStatusForChat:(AIChat *)inChat;
@end

@implementation AIListBookmark

@synthesize name, password, chatCreationDictionary;

- (id)initWithUID:(NSString *)inUID
		  account:(AIAccount *)inAccount
		  service:(AIService *)inService
	   dictionary:(NSDictionary *)inChatCreationDictionary
			 name:(NSString *)inName
{
	if ((self = [super initWithUID:inUID
						   account:inAccount
						   service:inService])) {
		chatCreationDictionary = [inChatCreationDictionary copy];
		name = [inName copy];
		
		[adium.chatController registerChatObserver:self];
		
		[self.account addObserver:self
					   forKeyPath:@"isOnline"
						  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
						  context:NULL];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
									 selector:@selector(chatDidOpen:) 
										 name:Chat_DidOpen
									   object:nil];
		
		// Scan all open chats to claim them, if we loaded after they were available.
		for (AIChat *chat in adium.interfaceController.openChats) {
			[self claimChatIfOurs:chat];
		}
		
		AILog(@"Created %@", self);
		
	}
	
	return self;
}

-(id)initWithChat:(AIChat *)inChat
{
	if ((self = [self initWithUID:[NSString stringWithFormat:@"Bookmark:%@", inChat.uniqueChatID]
						  account:inChat.account
						  service:inChat.account.service
					   dictionary:inChat.chatCreationDictionary
							 name:inChat.name])) {
		[self setDisplayName:inChat.displayName];
		
		if ([inChat valueForProperty:KEY_TOPIC]) {
			[self setStatusMessage:[NSAttributedString stringWithString:[inChat valueForProperty:KEY_TOPIC]] notify:NotifyNow];
		}
		
		[self _updateUnreadMessagesStatusForChat:inChat];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	AIAccount *myAccount = [adium.accountController accountWithInternalObjectID:[decoder decodeObjectForKey:KEY_ACCOUNT_INTERNAL_ID]];
	
	if (!myAccount) {
		return nil;
	}
	
	if ((self = [self initWithUID:[decoder decodeObjectForKey:@"UID"]
						  account:myAccount
						  service:[adium.accountController firstServiceWithServiceID:[decoder decodeObjectForKey:@"ServiceID"]]
					   dictionary:[decoder decodeObjectForKey:@"chatCreationDictionary"]
							 name:[decoder decodeObjectForKey:@"name"]])) {
		[self restoreGrouping];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.chatController unregisterChatObserver:self];
	[self.account removeObserver:self forKeyPath:@"isOnline"];
}

/*!
 * @brief Remove ourself
 *
 * We've been asked to be removed. Ask the contact controller to do so.
 */
- (void)removeFromGroup:(AIListObject <AIContainingObject> *)group
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
 * @brief Internal ID for this object
 *
 * An object ID generated by Adium that is shared by all objects which are, to most intents and purposes, identical to
 * this object.  Ths ID is composed of the service ID and UID, so any object with identical services and object IDs
 * will have the same value here.
 */
- (NSString *)internalObjectID
{
	if (!internalObjectID) {
		NSAssert(self.account != nil, @"Null list bookmark account - make sure you didn't try to touch the internalObjectID before it was loaded.");
		
		// We're not like any other bookmarks by the same name.
		internalObjectID = [NSString stringWithFormat:@"%@.%@.%@", self.service.serviceID, self.UID, self.account.UID];
	}
	
	return internalObjectID;
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
 * @brief For a newly created bookmark, set the group that -restoreGrouping will move us to. This is saved, so has no use on existing bookmarks
 */
- (void)setInitialGroup:(AIListGroup *)inGroup
{
	[self setPreference:inGroup.UID
				 forKey:KEY_CONTAINING_OBJECT_UID
				  group:PREF_GROUP_OBJECT_STATUS_CACHE];	
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
	NSString *savedGroupUID = [self preferenceForKey:KEY_CONTAINING_OBJECT_UID group:PREF_GROUP_OBJECT_STATUS_CACHE];
	
	if((!savedGroupUID || ![groupUID isEqualToString:savedGroupUID]) &&
		(inGroup != adium.contactController.contactList)) {
		// We either don't have a group, or this is a new, non-root-list group. Set our preference.
		
		[self setPreference:groupUID
					 forKey:KEY_CONTAINING_OBJECT_UID
					  group:PREF_GROUP_OBJECT_STATUS_CACHE];
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
	NSSet *targetGroup = nil;
	// In reality, it's extremely unlikely the saved group would be lost.
	NSString *savedGroupUID = [self preferenceForKey:KEY_CONTAINING_OBJECT_UID group:PREF_GROUP_OBJECT_STATUS_CACHE] ?: AILocalizedString(@"Bookmarks", nil);

	if (adium.contactController.useContactListGroups) {
		targetGroup = [NSSet setWithObject:[adium.contactController groupWithUID:savedGroupUID]];
	} else {
		targetGroup = [NSSet setWithObject:adium.contactController.contactList];
	}

	[adium.contactController moveContact:self fromGroups:self.groups intoGroups:targetGroup];
}

/*!
 * @brief Open our chat
 *
 * @return A chat for the bookmark
 *
 * This is called when we are double-clicked in the contact list.
 * Either find or create a chat appropriately, and activate it.
 */
- (AIChat *)openChat
{
	AIChat *chat = [self openChatWithoutActivating];
	
	if (!chat) {
		return nil;
	}
	
	if(!chat.isOpen) {
		[adium.interfaceController openChat:chat];
	}
	
	[adium.interfaceController setActiveChat:chat];
	
	return chat;
}

/*!
 * @brief Open our chat without activating it
 *
 * This is called when joining automatically on connect, and within the
 * method which opens on double click.
 */
- (AIChat *)openChatWithoutActivating
{
	if (self.account.joiningGroupChatRequiresCreationDictionary && !self.chatCreationDictionary) {
		if (NSRunAlertPanel(AILocalizedString(@"Unable to join bookmarked chat", nil),
                            AILocalizedString(@"The bookmark %@ does not contain enough information and can not be used. Please recreate it next time you join the chat.\nWould you like to remove this bookmark?", nil),
                            AILocalizedStringFromTable(@"Delete", @"Buttons", nil), 
                            AILocalizedStringFromTable(@"Cancel", @"Buttons", nil), 
                            nil,
                            [self displayName]) == NSAlertDefaultReturn) {
			AILogWithSignature(@"Removing %@", self);
			[adium.contactController removeBookmark:self];
		}
		return nil;
	}
	
	AIChat *chat = [adium.chatController existingChatWithName:self.name
					onAccount:self.account];
	
	if (![self chatIsOurs:chat]) {
		//Open a new group chat (bookmarked chat)
		chat = [adium.chatController chatWithName:self.name
				identifier:NULL 
				onAccount:self.account 
				chatCreationInfo:self.chatCreationDictionary];
	}
	
	return chat;
}

/*!
 * @brief A chat opened
 *
 * If this chat is our representation, set it up appropriately with our settings.
 */
- (void)chatDidOpen:(NSNotification *)notification
{
	AIChat *chat = [notification object];

	[self claimChatIfOurs:chat];
}

/*!
 * @brief Claim a chat
 *
 * Has no effect if the chat is not ours.
 *
 * Establishes any defaults we wish for our chats to have. Called when they are created.
 */
- (void)claimChatIfOurs:(AIChat *)chat
{
	if ([self chatIsOurs:chat]) {
		chat.displayName = self.displayName;
		[self setStatusMessage:[NSAttributedString stringWithString:([chat valueForProperty:KEY_TOPIC] ?: @"")] notify:NotifyNow];
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
			[chat.name isEqualToString:[self.account.service normalizeChatName:self.name]] &&
			chat.account == self.account &&
			((!chat.chatCreationDictionary && !self.chatCreationDictionary) ||
			 ([chat.chatCreationDictionary isEqualToDictionary:self.chatCreationDictionary])));
}

#pragma mark -
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"isOnline"] && object == self.account) {
		// If an account is just initially signing on, a -setOnline:notify:silently will still broadcast an event for the contact.
		// The initial delay an account (usually) sets is done after they're set as online, so these bookmarks would always fire.
		// Thus, we have to use the secondary, silent notification so that the online gets propogated without the events.
		[self setOnline:self.account.online notify:NotifyLater silently:YES];
		[self notifyOfChangedPropertiesSilently:YES];
		
		if (self.account.online && [[self preferenceForKey:KEY_AUTO_JOIN group:GROUP_LIST_BOOKMARK] boolValue]) {
			[self openChatWithoutActivating];
		}
	}
}

- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([self chatIsOurs:inChat]) {
		
		if ([inModifiedKeys containsObject:KEY_TOPIC]) {
			[self setStatusMessage:[NSAttributedString stringWithString:([inChat valueForProperty:KEY_TOPIC] ?: @"")] notify:NotifyNow];
		}
	
		if ([inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT] || [inModifiedKeys containsObject:KEY_UNVIEWED_MENTION]) {
			[self _updateUnreadMessagesStatusForChat:inChat];
		}
	}
	
	return nil;
}

- (void)_updateUnreadMessagesStatusForChat:(AIChat *)inChat
{
	NSString *statusMessage = nil;
	
	if (inChat.unviewedMentionCount) {
		// We contain mentions; display both this and the content count.
		if (inChat.unviewedMentionCount > 1) {
			statusMessage = [NSString stringWithFormat:AILocalizedString(@"%d mentions, %d messages", "Status message for a bookmark (>1 mention, >1 messages)"),
							 inChat.unviewedMentionCount, inChat.unviewedContentCount];
		} else if (inChat.unviewedContentCount > 1) {
			statusMessage = [NSString stringWithFormat:AILocalizedString(@"1 mention, %d messages", "Status message for a bookmark (1 mention, >1 messages)"),
							 inChat.unviewedContentCount];
		} else {
			statusMessage = AILocalizedString(@"1 mention, 1 message", "Status message for a bookmark (1 mention, 1 message)");
		}
	} else if (inChat.unviewedContentCount) {
		// We don't contain mentions; display the content count.
		if (inChat.unviewedContentCount > 1) {
			statusMessage = [NSString stringWithFormat:AILocalizedString(@"%d messages", "Status message for a bookmark (>1 messages)"),
							 inChat.unviewedContentCount];
		} else {
			statusMessage = AILocalizedString(@"1 message", "Status message for a bookmark (1 message)");
		}
	}
	
	[self setValue:statusMessage forProperty:KEY_UNREAD_STATUS notify:NotifyNow];
}

#pragma mark -
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p %@ - %@ on %@ in %@>",NSStringFromClass([self class]), self, self.formattedUID, [self chatCreationDictionary], self.account, self.remoteGroups];
}

@end
