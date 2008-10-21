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

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import "ESBlockingPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIChat.h>

#define BLOCK						AILocalizedString(@"Block","Block Contact menu item")
#define UNBLOCK						AILocalizedString(@"Unblock","Unblock Contact menu item")
#define BLOCK_MENUITEM				[BLOCK stringByAppendingEllipsis]
#define UNBLOCK_MENUITEM			[UNBLOCK stringByAppendingEllipsis]
#define TOOLBAR_ITEM_IDENTIFIER		@"BlockParticipants"
#define TOOLBAR_BLOCK_ICON_KEY		@"Block"
#define TOOLBAR_UNBLOCK_ICON_KEY	@"Unblock"

@interface ESBlockingPlugin()
- (void)_setContact:(AIListContact *)contact isBlocked:(BOOL)isBlocked;
- (void)accountConnected:(NSNotification *)notification;
- (BOOL)areAllGivenContactsBlocked:(NSArray *)contacts;
- (void)setPrivacy:(BOOL)block forContacts:(NSArray *)contacts;
- (IBAction)blockOrUnblockParticipants:(NSToolbarItem *)senderItem;

//protocols
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;

//notifications
- (void)chatDidBecomeVisible:(NSNotification *)notification;
- (void)toolbarWillAddItem:(NSNotification *)notification;
- (void)toolbarDidRemoveItem:(NSNotification *)notification;

//toolbar item methods
- (void)updateToolbarIconOfChat:(AIChat *)inChat inWindow:(NSWindow *)window;
- (void)updateToolbarItem:(NSToolbarItem *)item forChat:(AIChat *)chat;
- (void)updateToolbarItemForObject:(AIListObject *)inObject;
@end

#pragma mark -
@implementation ESBlockingPlugin

- (void)installPlugin
{
	//Install the Block menu items
	blockContactMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_MENUITEM
													  target:self
													  action:@selector(blockContact:)
											   keyEquivalent:@"b"];
	
	[blockContactMenuItem setKeyEquivalentModifierMask:(NSCommandKeyMask|NSAlternateKeyMask)];
	
	[adium.menuController addMenuItem:blockContactMenuItem toLocation:LOC_Contact_NegativeAction];

    //Add our get info contextual menu items
    blockContactContextualMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_MENUITEM
																target:self
																action:@selector(blockContact:)
														 keyEquivalent:@""];
    [adium.menuController addContextualMenuItem:blockContactContextualMenuItem toLocation:Context_Contact_NegativeAction];
	
	//we want to know when an account connects
	[adium.notificationCenter addObserver:self
								   selector:@selector(accountConnected:)
									   name:ACCOUNT_CONNECTED
									 object:nil];
	
	//create the block toolbar item
	chatToolbarItems = [[NSMutableSet alloc] init];
	//cache toolbar icons
	blockedToolbarIcons = [[NSDictionary alloc] initWithObjectsAndKeys:
								[NSImage imageNamed:@"block.png" forClass:[self class]], TOOLBAR_BLOCK_ICON_KEY, 
								[NSImage imageNamed:@"unblock.png" forClass:[self class]], TOOLBAR_UNBLOCK_ICON_KEY, 
								nil];
	NSToolbarItem	*chatItem = [AIToolbarUtilities toolbarItemWithIdentifier:TOOLBAR_ITEM_IDENTIFIER
																		label:BLOCK
																 paletteLabel:BLOCK
																	  toolTip:AILocalizedString(@"Blocking prevents a contact from contacting you or seeing your online status.", nil)
																	   target:self
															  settingSelector:@selector(setImage:)
																  itemContent:[blockedToolbarIcons valueForKey:TOOLBAR_BLOCK_ICON_KEY]
																	   action:@selector(blockOrUnblockParticipants:)
																		 menu:nil];
	
	[adium.toolbarController registerToolbarItem:chatItem forToolbarType:@"MessageWindow"];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarDidRemoveItem:)
												 name:NSToolbarDidRemoveItemNotification
											   object:nil];
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

- (void)uninstallPlugin
{
	[adium.notificationCenter removeObserver:self];
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[chatToolbarItems release];
	[blockedToolbarIcons release];
	[blockContactMenuItem release];
	[blockContactContextualMenuItem release];
}

/*!
 * @brief Block or unblock contacts
 *
 * @param block Flag indicating what the operation should achieve: NO for unblock, YES for block.
 * @param contacts The contacts to block or unblock
 */
- (void)setPrivacy:(BOOL)block forContacts:(NSArray *)contacts
{
	AIListContact	*currentContact = nil;
	
	for (currentContact in contacts) {
		if ([currentContact isBlocked] != block) {
			[currentContact setIsBlocked:block updateList:YES];
		}
	}
}

- (IBAction)blockContact:(id)sender
{
	AIListObject	*object;
	
	object = ((sender == blockContactMenuItem) ?
			  adium.interfaceController.selectedListObject :
			  adium.menuController.currentContextMenuObject);
	
	//Don't do groups
	if ([object isKindOfClass:[AIListContact class]]) {
		AIListContact	*contact = (AIListContact *)object;
		BOOL			shouldBlock;
		NSString		*format;

		shouldBlock = [[sender title] isEqualToString:BLOCK_MENUITEM];
		format = (shouldBlock ? 
				  AILocalizedString(@"Are you sure you want to block %@?",nil) :
				  AILocalizedString(@"Are you sure you want to unblock %@?",nil));

		if (NSRunAlertPanel([NSString stringWithFormat:format, [contact displayName]],
							@"",
							(shouldBlock ? BLOCK : UNBLOCK),
							AILocalizedString(@"Cancel", nil),
							nil) == NSAlertDefaultReturn) {
			
			//Handle metas
			if ([object isKindOfClass:[AIMetaContact class]]) {
				AIMetaContact *meta = (AIMetaContact *)object;
									
				//Enumerate over the various list contacts contained
				NSEnumerator *enumerator = [[meta uniqueContainedObjects] objectEnumerator];
				AIListContact *containedContact = nil;
				
				while ((containedContact = [enumerator nextObject])) {
					AIAccount <AIAccount_Privacy> *acct = [containedContact account];
					if ([acct conformsToProtocol:@protocol(AIAccount_Privacy)]) {
						[self _setContact:containedContact isBlocked:shouldBlock];
					} else {
						NSLog(@"Account %@ does not support blocking (contact %@ not blocked on this account)", acct, containedContact);
					}
				}
			} else {
				AIListContact *contact = (AIListContact *)object;
				AIAccount <AIAccount_Privacy> *acct = [contact account];
				if ([acct conformsToProtocol:@protocol(AIAccount_Privacy)]) {
					[self _setContact:contact isBlocked:shouldBlock];
				} else {
					NSLog(@"Account %@ does not support blocking (contact %@ not blocked on this account)", acct, contact);
				}
			}
			
			[adium.notificationCenter postNotificationName:@"AIPrivacySettingsChangedOutsideOfPrivacyWindow"
													  object:nil];		
		}
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	AIListObject *object;
	
	if (menuItem == blockContactMenuItem) {
		object = adium.interfaceController.selectedListObject;
	} else {
		object = adium.menuController.currentContextMenuObject;
	}
	
	//Don't do groups
	if ([object isKindOfClass:[AIListContact class]]) {
		//Handle metas
		if ([object isKindOfClass:[AIMetaContact class]]) {
			AIMetaContact *meta = (AIMetaContact *)object;
								
			//Enumerate over the various list contacts contained
			NSEnumerator	*enumerator = [[meta uniqueContainedObjects] objectEnumerator];
			AIListContact	*contact = nil;
			NSInteger				votesForBlock = 0;
			NSInteger				votesForUnblock = 0;

			while ((contact = [enumerator nextObject])) {
				AIAccount <AIAccount_Privacy> *acct = [contact account];
				if ([acct conformsToProtocol:@protocol(AIAccount_Privacy)]) {
					AIPrivacyType privType = (([acct privacyOptions] == AIPrivacyOptionAllowUsers) ? AIPrivacyTypePermit : AIPrivacyTypeDeny);
					if ([[acct listObjectsOnPrivacyList:privType] containsObject:contact]) {
						switch (privType) {
							case AIPrivacyTypePermit:
								/* He's on a permit list. The action would remove him, blocking him */
								votesForBlock++;
								break;
							case AIPrivacyTypeDeny:
								/* He's on a deny list. The action would remove him, unblocking him */
								votesForUnblock++;
								break;
						}
						
					} else {
						switch (privType) {
							case AIPrivacyTypePermit:
								/* He's not on the permit list. The action would add him, unblocking him */
								votesForUnblock++;
								break;
							case AIPrivacyTypeDeny:
								/* He's not on a deny list. The action would add him, blocking him */
								votesForBlock++;
								break;
						}						
					}
				}
			}

			if (votesForBlock || votesForUnblock) {
				if (votesForBlock >= votesForUnblock) {
					[menuItem setTitle:BLOCK_MENUITEM];
				} else {
					[menuItem setTitle:UNBLOCK_MENUITEM];	
				}
				
				return YES;

			} else {
				return NO;
			}

		} else {
			AIListContact *contact = (AIListContact *)object;
			AIAccount <AIAccount_Privacy> *acct = [contact account];
			if ([acct conformsToProtocol:@protocol(AIAccount_Privacy)]) {
				AIPrivacyType privType = (([acct privacyOptions] == AIPrivacyOptionAllowUsers) ? AIPrivacyTypePermit : AIPrivacyTypeDeny);
				if ([[acct listObjectsOnPrivacyList:privType] containsObject:contact]) {
					switch (privType) {
						case AIPrivacyTypePermit:
							/* He's on a permit list. The action would remove him, blocking him */
							[menuItem setTitle:BLOCK_MENUITEM];
							break;
						case AIPrivacyTypeDeny:
							/* He's on a deny list. The action would remove him, unblocking him */
							[menuItem setTitle:UNBLOCK_MENUITEM];
							break;
					}
					
				} else {
					switch (privType) {
						case AIPrivacyTypePermit:
							/* He's not on the permit list. The action would add him, unblocking him */
							[menuItem setTitle:UNBLOCK_MENUITEM];
							break;
						case AIPrivacyTypeDeny:
							/* He's not on a deny list. The action would add him, blocking him */
							[menuItem setTitle:BLOCK_MENUITEM];
							break;
					}						
				}
				
				return YES;

			} else {
				return NO;
			}
		}
	}
	return NO;
}

#pragma mark -
#pragma mark Private
//Private --------------------------------------------------------------------------------------------------------------

- (void)_setContact:(AIListContact *)contact isBlocked:(BOOL)isBlocked
{
	//We want to block on all accounts with the same service class. If you want someone gone, you want 'em GONE.
	NSEnumerator	*enumerator = [[adium.accountController accountsCompatibleWithService:[contact service]] objectEnumerator];
	AIAccount<AIAccount_Privacy>	*account = nil;
	AIListContact	*sameContact = nil;

	while ((account = [enumerator nextObject])) {
		sameContact = [account contactWithUID:[contact UID]];
		if ([account conformsToProtocol:@protocol(AIAccount_Privacy)]){
			
			if (sameContact){ 
				/* If the account is in AIPrivacyOptionAllowUsers mode, blocking a contact means removing it from the allow list.
				 * Similarly, in allow mode, unblocking a contact means adding it to the allow list.
				 *
				 * In AIPrivacyOptionDenyUsers mode, blocking a contact means adding it to the block list.
				 *
				 * In all other modes, we can't block specific contacts... so we first switch to AIPrivacyOptionDenyUsers, the more lenient
				 * of the two possibilities, then add the contact to the block list.
				 */
				AIPrivacyOption privacyOption = [account privacyOptions];
				if (privacyOption == AIPrivacyOptionAllowUsers) {
					[sameContact setIsAllowed:!isBlocked updateList:YES];

				} else {
					if (privacyOption != AIPrivacyOptionDenyUsers) {
						[account setPrivacyOptions:AIPrivacyOptionDenyUsers];
					}

					[sameContact setIsBlocked:isBlocked updateList:YES];
				}
			}
		}
	}
}

/*!
 * @brief Inform AIListContact instances of the user's intended privacy towards the people they represent
 */
#warning Something similar needs to happen to update when an account privacyOptions change
- (void)accountConnected:(NSNotification *)notification
{
	AIAccount		*account = [notification object];

	if ([account conformsToProtocol:@protocol(AIAccount_Privacy)] &&
		([(AIAccount <AIAccount_Privacy> *)account privacyOptions] == AIPrivacyOptionDenyUsers)) {
		AIListContact	*currentContact;
		NSArray			*blockedContacts = [(AIAccount <AIAccount_Privacy> *)account listObjectsOnPrivacyList:AIPrivacyTypeDeny];
		
		for (currentContact in blockedContacts) {
			[currentContact setIsBlocked:YES updateList:NO];
		}
	}
}

/*!
 * @brief Determine if all the referenced contacts are blocked or unblocked
 *
 * @param contacts The contacts to query
 * @result A flag indicating if all the contacts are blocked or not
 */
- (BOOL)areAllGivenContactsBlocked:(NSArray *)contacts
{
	AIListContact	*currentContact = nil;
	BOOL			areAllGivenContactsBlocked = YES;
	
	//for each contact in the array
	for (currentContact in contacts) {
		
		//if the contact is unblocked, then all the contacts in the array aren't blocked
		if (![currentContact isBlocked]) {
			areAllGivenContactsBlocked = NO;
			break;
		}
	}
	
	return areAllGivenContactsBlocked;
}

/*!
 * @brief Block or unblock participants of the active chat in a chat window
 *
 * If all the participants of the chat are blocked, attempt to unblock each
 * Else, attempt to block those that are not already blocked.
 * Then, Update the item for the chat.
 *
 * We have to do it this way because a user can (un)block participants of 
 * a chat window in the background by command-clicking the toolbar item.
 *
 * @param senderItem The toolbar item that received the event
 */
- (IBAction)blockOrUnblockParticipants:(NSToolbarItem *)senderItem
{
	NSEnumerator	*windowEnumerator = [[NSApp windows] objectEnumerator];
	NSWindow		*currentWindow = nil;
	NSToolbar		*windowToolbar = nil;
	NSToolbar		*senderToolbar = [senderItem toolbar];
	AIChat			*activeChatInWindow = nil;
	NSArray			*participants = nil;
	
	//for each open window
	while ((currentWindow = [windowEnumerator nextObject])) {

		//if it has a toolbar
		if ((windowToolbar = [currentWindow toolbar])) {

			//do the toolbars match?
			if (windowToolbar == senderToolbar) {
				activeChatInWindow = [adium.interfaceController activeChatInWindow:currentWindow];
				participants = [activeChatInWindow containedObjects];
				
				//do the deed
				[self setPrivacy:(![self areAllGivenContactsBlocked:participants]) forContacts:participants];
				[self updateToolbarItem:senderItem forChat:activeChatInWindow];
				break;
			}
		}
	}
}

#pragma mark -
#pragma mark Protocols

/*!
 * @brief Update any chat with the list object
 *
 * If the list object is (un)blocked, update any chats that we my have open with it.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inModifiedKeys containsObject:@"isBlocked"]) {
		[self updateToolbarItemForObject:inObject];
	}
	
	return nil;
}

#pragma mark -
#pragma mark Notifications

/*!
 * @brief Toolbar has added an instance of the chat block toolbar item
 */
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if ([[item itemIdentifier] isEqualToString:TOOLBAR_ITEM_IDENTIFIER]) {
		
		//If this is the first item added, start observing for chats becoming visible so we can update the item
		if ([chatToolbarItems count] == 0) {
			[adium.notificationCenter addObserver:self
										   selector:@selector(chatDidBecomeVisible:)
											   name:@"AIChatDidBecomeVisible"
											 object:nil];
		}
		
		[self updateToolbarItem:item forChat:adium.interfaceController.activeChat];
		[chatToolbarItems addObject:item];
	}
}

/*!
 * @brief A toolbar item was removed
 */
- (void)toolbarDidRemoveItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	[chatToolbarItems removeObject:item];
	
	if ([chatToolbarItems count] == 0) {
		[adium.notificationCenter removeObserver:self
											  name:@"AIChatDidBecomeVisible"
											object:nil];
	}
}

/*!
 * @brief A chat became visible in a window.
 *
 * Update the window's (un)block toolbar item to reflect the block state of a list object
 *
 * @param notification Notification with an AIChat object and an @"NSWindow" userInfo key
 */
- (void)chatDidBecomeVisible:(NSNotification *)notification
{
	[self updateToolbarIconOfChat:[notification object]
						  inWindow:[[notification userInfo] objectForKey:@"NSWindow"]];
}

#pragma mark -
#pragma mark Toolbar Item Update Methods

/*!
 * @brief Update the toolbar icon in a chat for a particular contact
 *
 * @param inObject The list object we want to update the toolbar item for
 */
- (void)updateToolbarItemForObject:(AIListObject *)inObject
{
	AIChat		*chat = nil;
	NSWindow	*window = nil;
	
	//Update the icon in the toolbar for this contact if a chat is open and we have any toolbar items
	if (([chatToolbarItems count] > 0) &&
		[inObject isKindOfClass:[AIListContact class]] &&
		(chat = [adium.chatController existingChatWithContact:(AIListContact *)inObject]) &&
		(window = [adium.interfaceController windowForChat:chat])) {
		[self updateToolbarIconOfChat:chat
							 inWindow:window];
	}
}

/*!
 * @brief Update the toolbar item for the particpants of a particular chat
 *
 * @param item The toolbar item to modify
 * @param chat The chat for which the participants are participating in
 */
- (void)updateToolbarItem:(NSToolbarItem *)item forChat:(AIChat *)chat
{
	if ([self areAllGivenContactsBlocked:[chat containedObjects]]) {
		//assume unblock appearance
		[item setLabel:UNBLOCK];
		[item setPaletteLabel:UNBLOCK];
		[item setImage:[blockedToolbarIcons valueForKey:TOOLBAR_UNBLOCK_ICON_KEY]];
	} else {
		//assume block appearance
		[item setLabel:BLOCK];
		[item setPaletteLabel:BLOCK];
		[item setImage:[blockedToolbarIcons valueForKey:TOOLBAR_BLOCK_ICON_KEY]];
	}
}

/*!
 * @brief Update the (un)block toolbar icon in a chat
 *
 * @param chat The chat with the participants
 * @param window The window in which the chat resides
 */
- (void)updateToolbarIconOfChat:(AIChat *)chat inWindow:(NSWindow *)window
{
	NSToolbar		*toolbar = [window toolbar];
	NSEnumerator	*enumerator = [[toolbar items] objectEnumerator];
	NSToolbarItem	*item;
	
	while ((item = [enumerator nextObject])) {
		if ([[item itemIdentifier] isEqualToString:TOOLBAR_ITEM_IDENTIFIER]) {
			[self updateToolbarItem:item forChat:chat];
			break;
		}
	}
}

@end
