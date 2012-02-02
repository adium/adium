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

#import "AIChatController.h"

#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import "AdiumChatEvents.h"
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>

#import "DCMessageContextDisplayPlugin.h"

#define SHOW_JOIN_LEAVE_TITLE		AILocalizedString(@"Show Join/Leave Messages", nil)

@interface AIChatController ()
- (NSSet *)_informObserversOfChatStatusChange:(AIChat *)inChat withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent;
- (void)chatAttributesChanged:(AIChat *)inChat modifiedKeys:(NSSet *)inModifiedKeys;

- (void)toggleIgnoreOfContact:(id)sender;
- (void)toggleShowJoinLeave:(id)sender;
- (void)didExchangeContent:(NSNotification *)notification;

- (void)adiumWillTerminate:(NSNotification *)inNotification;
@end

/*!
 * @class AIChatController
 * @brief Core controller for chats
 *
 * This is the only class which should vend AIChat objects (via openChat... or chatWith:...).
 * AIChat objects should never be created directly.
 */
@implementation AIChatController

/*!
 * @brief Initialize the controller
 */
- (id)init
{	
	if ((self = [super init])) {
		mostRecentChat = nil;
		chatObserverArray = [[NSMutableArray alloc] init];
		adiumChatEvents = [[AdiumChatEvents alloc] init];

		//Chat tracking
		openChats = [[NSMutableSet alloc] init];
	}
	return self;
}


/*!
 * @brief Controller loaded
 */
- (void)controllerDidLoad
{	
	//Observe content so we can update the most recent chat
    [[NSNotificationCenter defaultCenter] addObserver:self 
								   selector:@selector(didExchangeContent:) 
									   name:CONTENT_MESSAGE_RECEIVED
									 object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self 
								   selector:@selector(didExchangeContent:) 
									   name:CONTENT_MESSAGE_RECEIVED_GROUP
									 object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
								   selector:@selector(didExchangeContent:) 
									   name:CONTENT_MESSAGE_SENT
									 object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(didExchangeContent:)
												 name:CONTENT_MESSAGE_SENT_GROUP
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(adiumWillTerminate:)
									   name:AIAppWillTerminateNotification
									 object:nil];

	//Ignore menu item for contacts in group chats
	menuItem_ignore = [[NSMenuItem alloc] initWithTitle:@""
																		   target:self
																		   action:@selector(toggleIgnoreOfContact:)
																	keyEquivalent:@""];
	[adium.menuController addContextualMenuItem:menuItem_ignore toLocation:Context_Contact_GroupChat_ParticipantAction];
	
	menuItem_joinLeave = [[NSMenuItem alloc] initWithTitle:SHOW_JOIN_LEAVE_TITLE
																				target:self
																			  action:@selector(toggleShowJoinLeave:)
																		 keyEquivalent:@""];
	
	[adium.menuController addMenuItem:menuItem_joinLeave toLocation:LOC_Display_MessageControl];
	[adium.menuController addContextualMenuItem:[menuItem_joinLeave copy] toLocation:Context_GroupChat_Action];

	[adiumChatEvents controllerDidLoad];
}


/*!
 * @brief Controller will close
 */
- (void)controllerWillClose
{
	
}

/*!
 * @brief Adium will terminate
 *
 * Post the Chat_WillClose for each open chat so any closing behavior can be performed
 */
- (void)adiumWillTerminate:(NSNotification *)inNotification
{
	//Every open chat is about to close. We perform the internal closing here rather than calling on the interface controller since the UI need not change.
	//Also, we don't care for still processing content, the user won't see it anyway, and it can make Adium refuse to quit.
	while ([openChats count] > 0) {
		AIChat *chat = [openChats anyObject];
		
		if (mostRecentChat == chat) {
			mostRecentChat = nil;
		}
		
		//Send out the Chat_WillClose notification
		[[NSNotificationCenter defaultCenter] postNotificationName:Chat_WillClose object:chat userInfo:nil];
		
		[chat.account closeChat:chat];
		[openChats removeObject:chat];
		AILogWithSignature(@"Removed <<%@>> [%@]", chat, openChats);
		
		[chat setIsOpen:NO];
	}
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	openChats = nil;
	chatObserverArray = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
	
/*!
 * @brief Register a chat observer
 *
 * Chat observers are notified when properties are changed on chats
 *
 * @param inObserver An observer, which must conform to AIChatObserver
 */
- (void)registerChatObserver:(id <AIChatObserver>)inObserver
{
	//Add the observer
    [chatObserverArray addObject:[NSValue valueWithNonretainedObject:inObserver]];
	
    //Let the new observer process all existing chats
	[self updateAllChatsForObserver:inObserver];
}

/*!
 * @brief Unregister a chat observer
 */
- (void)unregisterChatObserver:(id <AIChatObserver>)inObserver
{
    [chatObserverArray removeObject:[NSValue valueWithNonretainedObject:inObserver]];
}

/*!
 * @brief Chat status changed
 *
 * Called by AIChat after it changes one or more properties.
 */
- (void)chatStatusChanged:(AIChat *)inChat modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	NSSet			*modifiedAttributeKeys;
	
    //Let all observers know the chat's status has changed before performing any further notifications
	modifiedAttributeKeys = [self _informObserversOfChatStatusChange:inChat withKeys:inModifiedKeys silent:silent];
	
    //Post an attributes changed message (if necessary)
    if ([modifiedAttributeKeys count]) {
		[self chatAttributesChanged:inChat modifiedKeys:modifiedAttributeKeys];
    }	
}

/*!
 * @brief Chat attributes changed
 *
 * Called by -[AIChatController chatStatusChanged:modifiedStatusKeys:silent:] if any observers changed attributes
 */
- (void)chatAttributesChanged:(AIChat *)inChat modifiedKeys:(NSSet *)inModifiedKeys
{
	//Post an attributes changed message
	[[NSNotificationCenter defaultCenter] postNotificationName:Chat_AttributesChanged
											  object:inChat
											userInfo:(inModifiedKeys ? [NSDictionary dictionaryWithObject:inModifiedKeys 
																								   forKey:@"Keys"] : nil)];
}

/*!
 * @brief Send each chat in turn to an observer with a nil modifiedStatusKeys argument
 *
 * This lets an observer use its normal update mechanism to update every chat in some manner
 */
- (void)updateAllChatsForObserver:(id <AIChatObserver>)observer
{	
	for (AIChat *chat in openChats) {
		[self chatStatusChanged:chat modifiedStatusKeys:nil silent:NO];
	}
}

/*!
 * @brief Notify observers of a status change.  Returns the modified attribute keys
 */
- (NSSet *)_informObserversOfChatStatusChange:(AIChat *)inChat withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent
{
	NSMutableSet	*attrChange = nil;
	NSValue			*observerValue;
	
	//Let our observers know
	for (observerValue in chatObserverArray) {
		id <AIChatObserver>	observer;
		NSSet				*newKeys;
		
		observer = [observerValue nonretainedObjectValue];
		if ((newKeys = [observer updateChat:inChat keys:modifiedKeys silent:silent])) {
			if (!attrChange) attrChange = [NSMutableSet set];
			[attrChange unionSet:newKeys];
		}
	}
	
	//Send out the notification for other observers
	[[NSNotificationCenter defaultCenter] postNotificationName:Chat_StatusChanged
											  object:inChat
											userInfo:(modifiedKeys ? [NSDictionary dictionaryWithObject:modifiedKeys 
																								 forKey:@"Keys"] : nil)];
	
	return attrChange;
}

//Chats -------------------------------------------------------------------------------------------------
#pragma mark Chats
/*!
 * @brief Opens a chat for communication with the contact, creating if necessary.
 *
 * The interface controller will then be asked to open the UI for the new chat.
 *
 * @param inContact The AIListContact on which to open a chat. If an AIMetaContact, an appropriate contained contact will be selected.
 * @param onPreferredAccount If YES, Adium will determine the account on which the chat should be opened. If NO, inContact.account will be used. Value is treated as YES for AIMetaContacts by the action of -[AIChatController chatWithContact:].
 */
- (AIChat *)openChatWithContact:(AIListContact *)inContact onPreferredAccount:(BOOL)onPreferredAccount
{
	if ([inContact isKindOfClass:[AIListBookmark class]])
		return [(AIListBookmark *)inContact openChat];

	if (onPreferredAccount) {
		inContact = [adium.contactController preferredContactForContentType:CONTENT_MESSAGE_TYPE
															   forListContact:inContact];
	}

	AIChat *chat = [self chatWithContact:inContact];
	if (chat) [adium.interfaceController openChat:chat]; 

	return chat;
}

/*!
 * @brief Creates a chat for communication with the contact, but does not make the chat active
 *
 * No window or tab is opened for the chat.
 * If a chat with this contact already exists, it is returned.
 * If a chat with a contact within the same metaContact at this contact exists, it is switched to this contact
 * and then returned.
 *
 * The passed contact, if an AIListContact, will be used exactly -- that is, inContact.account is the account on which the chat will be opened.
 * If the passed contact is an AIMetaContact, an appropriate contact/account pair will be automatically selected by this method.
 *
 * @param inContact The contact with which to open a chat. See description above.
 */
- (AIChat *)chatWithContact:(AIListContact *)inContact
{
	AIListContact	*targetContact = inContact;
	AIChat			*chat = nil;

	/*
	 If we're dealing with a meta contact, open a chat with the preferred contact for this meta contact
	 It's a good idea for the caller to pick the preferred contact for us, since they know the content type
	 being sent and more information - but we'll do it here as well just to be safe.
	 */
	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		targetContact = [adium.contactController preferredContactForContentType:CONTENT_MESSAGE_TYPE
																   forListContact:inContact];
		
		/*
		 If we have no accounts online, preferredContactForContentType:forListContact will return nil.
		 We'd rather open up the chat window on a useless contact than do nothing, so just pick the 
		 preferredContact from the metaContact.
		 */
		if (!targetContact) {
			targetContact = [(AIMetaContact *)inContact preferredContact];
		}
	}
	
	//If we can't get a contact, we're not going to be able to get a chat... return nil
	if (!targetContact) {
		AILog(@"Warning: -[AIChatController chatWithContact:%@] got a nil targetContact.",inContact);
		NSLog(@"Warning: -[AIChatController chatWithContact:%@] got a nil targetContact.",inContact);
		return nil;
	}

	//Search for an existing chat we can switch instead of replacing
	for (chat in openChats) {
		//If a chat for this object already exists
		if ([chat.uniqueChatID isEqualToString:targetContact.internalObjectID]) {
			if (!(chat.listObject == targetContact)) {
				[self switchChat:chat toAccount:targetContact.account];
			}
			
			break;
		}
		
		//If this object is within a meta contact, and a chat for an object in that meta contact already exists
		if (chat.listObject.parentContact == targetContact.parentContact) {

			//Switch the chat to be on this contact (and its account) now
			[self switchChat:chat toListContact:targetContact usingContactAccount:YES];
			
			break;
		}
	}

	if (!chat) {
		AIAccount	*account = targetContact.account;

		//Create a new chat
		chat = [AIChat chatForAccount:account];
		[chat addParticipatingListObject:targetContact notify:YES];
		[openChats addObject:chat];
		AILog(@"chatWithContact: Added <<%@>> [%@]",chat,openChats);

		//Inform the account of its creation
		if (![targetContact.account openChat:chat]) {
			[openChats removeObject:chat];
			AILog(@"chatWithContact: Immediately removed <<%@>> [%@]",chat,openChats);
			chat = nil;
		}
	}

	return chat;
}

/*!
 * @brief Return a pre-existing chat with a contact.
 *
 * @result The chat, or nil if no chat with the contact exists
 */
- (AIChat *)existingChatWithContact:(AIListContact *)inContact
{
	AIChat			*chat = nil;

	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		//Search for a chat with any contact within this AIMetaContact
		for (chat in openChats) {
			if (!chat.isGroupChat &&
				[[(AIMetaContact *)inContact containedObjects] containsObjectIdenticalTo:chat.listObject]) break;
		}

	} else {
		//Search for a chat with this AIListContact
		for (chat in openChats) {
			if (!chat.isGroupChat &&
				chat.listObject == inContact) break;
		}
	}
	
	return chat;
}

/*!
 * @brief Open a group chat
 *
 * @param inName The name of the chat; in general, the chat room name
 * @param account The account on which to create the group chat
 * @param chatCreationInfo A dictionary of information which may be used by the account when joining the chat serverside
 * @brief opens a chat with the above parameters. Assigns chatroom info to the created AIChat object.
 */
- (AIChat *)chatWithName:(NSString *)name identifier:(id)identifier onAccount:(AIAccount *)account chatCreationInfo:(NSDictionary *)chatCreationInfo
{
	AIChat			*chat = nil;

	name = [account.service normalizeChatName:name];

 	if (identifier) {
 		chat = [self existingChatWithIdentifier:identifier onAccount:account];

		if (!chat) {
			//See if a chat was made with this name but which doesn't yet have an identifier. If so, take ownership!
			chat = [self existingChatWithName:name onAccount:account];

			if (chat && ![chat identifier])
                [chat setIdentifier:identifier];
            // If existingChatWithName:onAccount: finds a chat, make sure it has the right identifier. 
            else if ([chat identifier] != identifier)
                chat = nil;
		}

	} else {
		//If the caller doesn't care about the identifier, do a search based on name to avoid creating a new chat incorrectly
		chat = [self existingChatWithName:name onAccount:account];
	}

	AILog(@"chatWithName %@ identifier %@ existing --> %@", name, identifier, chat);
	if (!chat) {
		//Create a new chat
		chat = [AIChat chatForAccount:account];
		
		chat.name = [account.service normalizeChatName:name];
		chat.displayName = name;
		chat.identifier = identifier;
		chat.isGroupChat = YES;
		chat.chatCreationDictionary = chatCreationInfo;

		NSArray *lastActivity = [[DCMessageContextDisplayPlugin sharedInstance] contextForChat:chat lines:1 alsoStatus:TRUE];
        
		if (lastActivity.count > 0) {
			chat.lastMessageDate = [[lastActivity objectAtIndex:0] date];
		}

		/* Negative preference so (default == NO) -> showing join/leave messages */
		chat.showJoinLeave = ![[[adium preferenceController] preferenceForKey:[NSString stringWithFormat:@"HideJoinLeave-%@", name]
																	    group:PREF_GROUP_STATUS_PREFERENCES] boolValue];		
		[openChats addObject:chat];
		
		AILog(@"chatWithName:%@ identifier:%@ onAccount:%@ added <<%@>> [%@] [%@]",name,identifier,account,chat,openChats,chatCreationInfo);

		//Inform the account of its creation
		if (![account openChat:chat]) {
			[openChats removeObject:chat];
			AILog(@"chatWithName: Immediately removed <<%@>> [%@]",chat,openChats);
			chat = nil;
		}
	}

	AILog(@"chatWithName %@ created --> %@",name,chat);
	return chat;
}

/*!
* @brief Find an existing group chat
 *
 * @result The group AIChat, or nil if no such chat exists
 */
- (AIChat *)existingChatWithName:(NSString *)name onAccount:(AIAccount *)account
{
	AIChat			*chat = nil;
	
	name = [account.service normalizeChatName:name];
	
	for (chat in openChats) {
		if ((chat.account == account) &&
			([chat.name isEqualToString:name])) {
			break;
		}
	}	
	
	return chat;
}

/*!
 * @brief Find an existing group chat
 *
 * @result The group AIChat, or nil if no such chat exists
 */
- (AIChat *)existingChatWithIdentifier:(id)identifier onAccount:(AIAccount *)account
{
	AIChat			*chat = nil;
	

	for (chat in openChats) {
		if ((chat.account == account) &&
		   ([[chat identifier] isEqual:identifier])) {
			break;
		}
	}	
	
	return chat;
}

/*!
 * @brief Find an existing chat by unique chat ID
 *
 * @result The AIChat, or nil if no such chat exists
 */
- (AIChat *)existingChatWithUniqueChatID:(NSString *)uniqueChatID
{
	AIChat			*chat = nil;
	
	
	for (chat in openChats) {
		if ([chat.uniqueChatID isEqualToString:uniqueChatID]) {
			break;
		}
	}	
	
	return chat;
}

/*!
 * @brief Close a chat
 *
 * This should be called only by the interface controller. To close a chat programatically, use the interface controller's closeChat:.
 *
 * @result YES the chat was removed succesfully; NO if it was not
 */
- (BOOL)closeChat:(AIChat *)inChat
{	
	BOOL	shouldRemove;
	
	/* If we are currently passing a content object for this chat through our content filters, don't remove it from
	 * our openChats set as it will become needed soon. If we were to remove it, and a second message came in which was
	 * also before the first message is done filtering, we would otherwise mistakenly think we needed to create a new
	 * chat, generating a duplicate.
	 */
	shouldRemove = ![adium.contentController chatIsReceivingContent:inChat];

	if (mostRecentChat == inChat) {
		mostRecentChat = nil;
	}
	
	//Send out the Chat_WillClose notification
	[[NSNotificationCenter defaultCenter] postNotificationName:Chat_WillClose object:inChat userInfo:nil];

	//Remove the chat
	if (shouldRemove) {
		/* If we didn't remove the chat because we're waiting for it to reopen, don't cause the account
		 * to close down the chat.
		 */
		[inChat.account closeChat:inChat];
		[openChats removeObject:inChat];
		AILog(@"closeChat: Removed <<%@>> [%@]",inChat, openChats);
	} else {
		AILog(@"closeChat: Did not remove <<%@>> [%@]",inChat, openChats);		
	}
	
	[inChat setIsOpen:NO];

	return shouldRemove;
}

- (void)restoreChat:(AIChat *)inChat
{
	[openChats addObject:inChat];
}

/*!
 * @brief Called by an account to notifiy the chat controller that it left a chat
 *
 * Typically this is called in response to -[AIAccout closeChat:] caled in -[self closeChat:] above.
 * However, if the chat is never opened, accountDidCloseChat: may be called without closeChat: being called first.
 */
- (void)accountDidCloseChat:(AIChat *)inChat
{
	/* If the chat is not open and the account told us that it was closed,
	 * ensure that it's no longer in the open chats list, as the user will have no further
	 * interaction with it. This is poarticularly important if the chat closes before it is
	 * ever opened, such as when an error occurs while joining a group chat.
	 */
	if (![inChat isOpen])
		[openChats removeObject:inChat];
}

/*!
 * @brief Switch a chat from one account to another
 *
 * The target list contact for the chat is changed to be an 'identical' one on the target account; that is, a contact
 * with the same UID but an account and service appropriate for newAccount.
 */
- (void)switchChat:(AIChat *)chat toAccount:(AIAccount *)newAccount
{
	AIAccount	*oldAccount = chat.account;
	if (newAccount != oldAccount) {
		//Close down the chat on account A
		[oldAccount closeChat:chat];

		//Set the account and the listObject
		{
			[chat setAccount:newAccount];

			//We want to keep the same destination for the chat but switch it to a listContact on the desired account.
			AIListContact	*newContact = [adium.contactController contactWithService:newAccount.service
																				account:newAccount
																					UID:chat.listObject.UID];
			[chat setListObject:newContact];
		}

		//Open the chat on account B
		[newAccount openChat:chat];
	}
}

/*!
 * @brief Switch the list contact of a chat
 *
 * @param chat The chat
 * @param inContact The contact with which the chat will now take place
 * @param useContactAccount If YES, the chat is also set to inContact.account as its account. If NO, the account and service of chat are unchanged.
 */
- (void)switchChat:(AIChat *)chat toListContact:(AIListContact *)inContact usingContactAccount:(BOOL)useContactAccount
{
	AIAccount		*newAccount = (useContactAccount ? inContact.account : chat.account);

	//Switch the inContact over to a contact on the new account so we send messages to the right place.
	AIListContact	*newContact = [adium.contactController contactWithService:newAccount.service
																		account:newAccount
																			UID:inContact.UID];
	if (newContact != chat.listObject) {
		//Close down the chat on the account, as the account may need to perform actions such as closing a connection
		[chat.account closeChat:chat];
		
		//Set to the new listContact and account as needed
		[chat setListObject:newContact];
		if (useContactAccount || ![inContact.service.serviceClass isEqualToString:chat.account.service.serviceClass])
			[chat setAccount:newAccount];

		//Reopen the chat on the account
		[chat.account openChat:chat];
	}
}

/*!
 * @brief Find all open chats with a contact
 *
 * @param inContact The contact. If inContact is an AIMetaContact, all chats with all contacts within the metaContact will be returned.
 * @result An NSSet with all chats with the contact.  In general, will contain 0 or 1 AIChat objects, though it may contain more.
 */
- (NSSet *)allChatsWithContact:(AIListContact *)inContact
{
    NSMutableSet	*foundChats = [NSMutableSet set];
	
	//Scan the objects participating in each chat, looking for the requested object
	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		if ([openChats count]) {
			for (AIListContact *listContact in ((AIMetaContact *)inContact).uniqueContainedObjects) {
				[foundChats unionSet:[self allChatsWithContact:listContact]];
			}
		}
		
	} else {
		for (AIChat *chat in openChats) {
			if (!chat.isGroupChat &&
				[chat.listObject.internalObjectID isEqualToString:inContact.internalObjectID] &&
				chat.isOpen) {
				[foundChats addObject:chat];
			}
		}
	}

    return foundChats;
}

/*!
 * @brief Find all open chats with a contact
 *
 * @param inContact The contact. If inContact is an AIMetaContact, all chats with all contacts within the metaContact will be returned.
 * @result An NSSet with all chats with the contact.
 */
- (NSSet *)allGroupChatsContainingContact:(AIListContact *)inContact
{
	NSMutableSet *groupChats = [NSMutableSet set];
	
	//Search for a chat containing this AIListContact
	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		//Search for a chat with any contact within this AIMetaContact
		for (AIChat *chat in openChats) {
			if (!chat.isGroupChat)
				continue;
			
			for (AIListContact *contact in (AIMetaContact *)inContact) {
				if([chat containsObject:contact]) {
					[groupChats addObject:chat];
					break;
				}
			}
		}
		
	} else {
		//Search for a chat with this AIListContact
		for (AIChat *chat in openChats) {
			if (chat.isGroupChat && [chat containsObject:inContact] && chat.account.shouldBeOnline) {
				[groupChats addObject:chat];
			}
		}
	}
	
	return groupChats;
}

/*!
 * @brief All open chats
 *
 * Open chats from the chatController may include chats which are not currently displayed by the interface.
 */
- (NSSet *)openChats
{
    return [openChats copy];
}

/*!
 * @brief Find the chat which most recently received content which has not yet been seen
 *
 * @result An AIChat with unviewed content, or nil if no chats current have unviewed content
 */
- (AIChat *)mostRecentUnviewedChat
{
	BOOL onlyMentions = [[adium.preferenceController preferenceForKey:KEY_STATUS_MENTION_COUNT
																group:PREF_GROUP_STATUS_PREFERENCES] boolValue];
	
	if (mostRecentChat && mostRecentChat.unviewedContentCount && (!mostRecentChat.isGroupChat || !onlyMentions || mostRecentChat.unviewedMentionCount)) {
		//First choice: switch to the chat which received chat most recently if it has unviewed content
		return mostRecentChat;
		
	} else {
		//Second choice: switch to the first chat we can find which has unviewed content
		for (AIChat *chat in openChats) {
			if (chat.unviewedContentCount && (!chat.isGroupChat || !onlyMentions || chat.unviewedMentionCount))
				return chat;
		}
	}
	
	return nil;
}

/*!
 * @brief Gets the total number of unviewed messages
 * 
 * @result The number of unviewed messages
 */
- (NSUInteger)unviewedContentCount
{
	NSUInteger	count = 0;

	for (AIChat *chat in openChats) {
		if (chat.isGroupChat &&
			[[adium.preferenceController preferenceForKey:KEY_STATUS_MENTION_COUNT
													group:PREF_GROUP_STATUS_PREFERENCES] boolValue]) {
			count += [chat unviewedMentionCount];
		} else {
			count += [chat unviewedContentCount];
		}
	}
	return count;
}

/*!
 * @brief Gets the total number of conversations with unviewed messages
 * 
 * @result The number of conversations with unviewed messages
 */
- (NSUInteger)unviewedConversationCount
{
	NSUInteger count = 0;

	for (AIChat *chat in openChats) {
		if (chat.isGroupChat &&
			[[adium.preferenceController preferenceForKey:KEY_STATUS_MENTION_COUNT
													group:PREF_GROUP_STATUS_PREFERENCES] boolValue]) {
			if (chat.unviewedMentionCount) {
				count++;
			}
		} else if (chat.unviewedContentCount) {
			count++;
		}
	}
	return count;
}

/*!
 * @brief Is the passed contact in a group chat?
 *
 * @result YES if the contact is in an open group chat; NO if not.
 */
- (BOOL)contactIsInGroupChat:(AIListContact *)listContact
{
	BOOL			contactIsInGroupChat = NO;
	
	for (AIChat *chat in openChats) {
		if (chat.isGroupChat &&
			[chat containsObject:listContact]) {
			
			contactIsInGroupChat = YES;
			break;
		}
	}
	
	return contactIsInGroupChat;
}

/*!
 * @brief Called when content is sent or received
 *
 * Update the most recent chat
 */
- (void)didExchangeContent:(NSNotification *)notification
{
	AIContentObject	*contentObject = [[notification userInfo] objectForKey:@"AIContentObject"];

	//Update our most recent chat
	if (contentObject.trackContent) {
		AIChat	*chat = contentObject.chat;
		
		if (chat != mostRecentChat) {
			mostRecentChat = chat;
		}
	}
}

#pragma mark Menu Items
/*!
 * @brief Toggle ignoring of a contact
 *
 * Must be called from the contextual menu for the contact within a chat
 */
- (void)toggleIgnoreOfContact:(id)sender
{
	AIListObject	*listObject = adium.menuController.currentContextMenuObject;
	AIChat			*chat = [adium.menuController currentContextMenuChat];
	
	if ([listObject isKindOfClass:[AIListContact class]]) {
		BOOL			isIgnored = [chat isListContactIgnored:(AIListContact *)listObject];
		[chat setListContact:(AIListContact *)listObject isIgnored:!isIgnored];
	}
}

/*!
 * @brief Toggle displaying of show/part messages for a chat
 *
 * Effects the currently active chat.
 */
- (void)toggleShowJoinLeave:(id)sender
{
	AIChat *chat = nil;
	
	if (sender == menuItem_joinLeave) {
		chat = adium.interfaceController.activeChat;
	} else {
		chat = adium.menuController.currentContextMenuChat;
	}

	chat.showJoinLeave = !chat.showJoinLeave;

	[[adium preferenceController] setPreference:[NSNumber numberWithBool:!chat.showJoinLeave]
										 forKey:[NSString stringWithFormat:@"HideJoinLeave-%@", chat.name]
										  group:PREF_GROUP_STATUS_PREFERENCES];
}

/*!
 * @brief Menu item validation
 *
 * When asked to validate our ignore menu item, set its title to ignore/un-ignore as appropriate for the contact
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem == menuItem_ignore) {
		AIListObject	*listObject = adium.menuController.currentContextMenuObject;
		AIChat			*chat = [adium.menuController currentContextMenuChat];
		
		if ([listObject isKindOfClass:[AIListContact class]]) {
			if ([chat isListContactIgnored:(AIListContact *)listObject]) {
				[menuItem setTitle:AILocalizedString(@"Un-ignore","Un-ignore means begin receiving messages from this contact again in a chat")];
				
			} else {
				[menuItem setTitle:AILocalizedString(@"Ignore","Ignore means no longer receive messages from this contact in a chat")];
			}
		} else {
			[menuItem setTitle:AILocalizedString(@"Ignore","Ignore means no longer receive messages from this contact in a chat")];
			return NO;
		}
	} else if ([menuItem.title isEqualToString:SHOW_JOIN_LEAVE_TITLE]) {
		// We're using multiple menu items for the same goal, and WKMV makes a copy of the contextual ones.
		// Validate based on the title.
		AIChat *chat = nil;
		if (menuItem == menuItem_joinLeave) {
			chat = adium.interfaceController.activeChat;
		} else {
			chat = adium.menuController.currentContextMenuChat;
		}
			
		if (chat.isGroupChat) {
			[menuItem setState:chat.showJoinLeave];
			return YES;
		}
		
		return NO;		
	}
	
	return YES;
}

#pragma mark Chat contact addition and removal

/*!
 * @brief A chat added a listContact to its participatants list
 *
 * @param chat The chat
 * @param inContact The contact
 * @param notify If YES, trigger the contact joined event if this is a group chat.  Ignored if this is not a group chat.
 */
- (void)chat:(AIChat *)chat addedListContacts:(NSArray *)inObjects notify:(BOOL)notify
{
	if (notify && chat.isGroupChat) {
		/* Prevent triggering of the event when we are informed that the chat's own account entered the chat
		 * If the UID of a contact in a chat differs from a normal UID, such as is the case with Jabber where a chat
		 * contact has the form "roomname@conferenceserver/handle" this will fail, but it's better than nothing.
		 */
		for (AIListContact *inContact in inObjects) {
			if (![inContact.account.UID isEqualToString:inContact.UID]) {
				[adiumChatEvents chat:chat addedListContact:inContact];
			}
		}
	}

	//Always notify Adium that the list changed so it can be updated, caches can be modified, etc.
	[[NSNotificationCenter defaultCenter] postNotificationName:Chat_ParticipatingListObjectsChanged
											  object:chat];
}

/*!
 * @brief A chat removed a listContact from its participants list
 *
 * @param chat The chat
 * @param inContact The contact
 */
- (void)chat:(AIChat *)chat removedListContact:(AIListContact *)inContact
{
	if (chat.isGroupChat) {
		[adiumChatEvents chat:chat removedListContact:inContact];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:Chat_ParticipatingListObjectsChanged
											  object:chat];
}

- (NSString *)defaultInvitationMessageForRoom:(NSString *)room account:(AIAccount *)inAccount
{
	return [NSString stringWithFormat:AILocalizedString(@"%@ invites you to join the chat \"%@\"", nil), inAccount.formattedUID, room];
}

@end

/*
 * These strings were used previously; we may want them again. Keeping the translations around for now.
  AILocalizedString("%@ joined the chat", nil);
  AILocalizedString("%@ left the chat", nil);
 */
