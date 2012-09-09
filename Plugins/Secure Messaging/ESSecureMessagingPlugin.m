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

#import "ESSecureMessagingPlugin.h"
#import "AdiumOTREncryption.h"

#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>

#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/MVMenuButton.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>

#define	TITLE_MAKE_SECURE		AILocalizedString(@"Initiate Encrypted OTR Chat",nil)
#define	TITLE_MAKE_INSECURE		AILocalizedString(@"Cancel Encrypted Chat",nil)
#define TITLE_SHOW_DETAILS		[AILocalizedString(@"Show Details",nil) stringByAppendingEllipsis]
#define TITLE_VERIFY			[AILocalizedString(@"Verify",nil) stringByAppendingEllipsis]
#define	TITLE_ENCRYPTION_OPTIONS AILocalizedString(@"Encryption Settings",nil)
#define TITLE_ABOUT_ENCRYPTION	[AILocalizedString(@"About Encryption",nil) stringByAppendingEllipsis]

#define TITLE_ENCRYPTION		AILocalizedString(@"Encryption",nil)

#define CHAT_NOW_SECURE				AILocalizedString(@"Encrypted OTR chat initiated.", nil)
#define CHAT_NOW_SECURE_UNVERIFIED	AILocalizedString(@"Encrypted OTR chat initiated. %@'s identity not verified.", nil)
#define CHAT_NO_LONGER_SECURE		AILocalizedString(@"Ended encrypted OTR chat.", nil)

@interface ESSecureMessagingPlugin ()
- (void)configureMenuItems;
- (void)registerToolbarItem;
- (NSMenu *)_secureMessagingMenu;
- (void)_updateToolbarIconOfChat:(AIChat *)inChat inWindow:(NSWindow *)window;
- (void)_updateToolbarItem:(NSToolbarItem *)item forChat:(AIChat *)chat;
- (void) toolbarDidAddItem:(NSToolbarItem *)item;

- (IBAction)toggleSecureMessaging:(id)sender;
- (void)chatDidBecomeVisible:(NSNotification *)notification;
- (void)dummyAction:(id)sender;
@end

@implementation ESSecureMessagingPlugin

- (void)installPlugin
{
	//Muy imporatante: Set OTR as our encryption method
	[adium.contentController setEncryptor:[[AdiumOTREncryption alloc] init]];

	_secureMessagingMenu = nil;
	lockImage_Locked = [NSImage imageNamed:@"lock-locked" forClass:[self class]];
	lockImage_Unlocked = [NSImage imageNamed:@"lock-unlocked" forClass:[self class]];

	[self registerToolbarItem];
	[self configureMenuItems];

	[adium.chatController registerChatObserver:self];
}

- (void)uninstallPlugin
{
	[adium.chatController unregisterChatObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureMenuItems
{
	NSMenu		*menu = [self _secureMessagingMenu];
	
	//Add menu to toolbar item (for text mode)
	menuItem_encryption = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Encryption", nil)
																			   target:self
																			   action:@selector(dummyAction:) 
																		keyEquivalent:@""];
	[menuItem_encryption setSubmenu:menu];
	[menuItem_encryption setTag:AISecureMessagingMenu_Root];

	[adium.menuController addMenuItem:menuItem_encryption
						   toLocation:LOC_Contact_Additions];
	
	menuItem_encryptionContext = [menuItem_encryption copy];

	[adium.menuController addContextualMenuItem:menuItem_encryptionContext
									 toLocation:Context_Contact_ChatAction];
}

- (void)registerToolbarItem
{	
	toolbarItems = [[NSMutableSet alloc] init];

	//Toolbar item registration
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarDidRemoveItem:)
												 name:NSToolbarDidRemoveItemNotification
											   object:nil];

	//Register our toolbar item
	NSToolbarItem	*toolbarItem;
	MVMenuButton	*button;
	button = [[MVMenuButton alloc] initWithFrame:NSMakeRect(0,0,32,32)];
	[button setImage:lockImage_Locked];

    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"Encryption"
														  label:TITLE_ENCRYPTION
												   paletteLabel:AILocalizedString(@"Encrypted Messaging",nil)
														toolTip:AILocalizedString(@"Toggle encrypted messaging. Shows a closed lock when secure and an open lock when insecure.",nil)
														 target:self
												settingSelector:@selector(setView:)
													itemContent:button
														 action:@selector(toggleSecureMessaging:)
														   menu:nil];
	[toolbarItem setMinSize:NSMakeSize(32,32)];
	[toolbarItem setMaxSize:NSMakeSize(32,32)];
	[button setToolbarItem:toolbarItem];

	//Register our toolbar item
	[adium.toolbarController registerToolbarItem:toolbarItem forToolbarType:@"MessageWindow"];
}


//After the toolbar has added the item we can set up the submenus
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	if ([[item itemIdentifier] isEqualToString:@"Encryption"]) {
		[item setEnabled:YES];
		
		//If this is the first item added, start observing for chats becoming visible so we can update the icon
		if ([toolbarItems count] == 0) {
			[[NSNotificationCenter defaultCenter] addObserver:self
										   selector:@selector(chatDidBecomeVisible:)
											   name:@"AIChatDidBecomeVisible"
											 object:nil];
		}
		
		NSMenu		*menu = [self _secureMessagingMenu];
		
		//Add menu to view
		[[item view] setMenu:menu];
		
		//Add menu to toolbar item (for text mode)
		NSMenuItem	*mItem = [[NSMenuItem alloc] init];
		[mItem setSubmenu:menu];
		[mItem setTitle:[menu title]];
		[item setMenuFormRepresentation:mItem];

		[toolbarItems addObject:item];
		
		[self performSelector:@selector(toolbarDidAddItem:)
				   withObject:item
				   afterDelay:0];
	}
}

- (void)toolbarDidAddItem:(NSToolbarItem *)item
{
	/* Only need to take action if we haven't already validated the initial state of this item.
	 * This will only be true when the toolbar is revealed for the first time having been hidden when window opened.
	 */
	if (![validatedItems containsObject:item]) {
		NSWindow	 *window;
		NSToolbar	 *thisItemsToolbar = [item toolbar];
		
		//Look at each window to find the toolbar we are in
		for (window in [NSApp windows]) {
			if ([window toolbar] == thisItemsToolbar) break;
		}
		
		if (window) {
			[self _updateToolbarItem:item
							 forChat:[adium.interfaceController activeChatInWindow:window]];
		}
	}
}

- (void)toolbarDidRemoveItem: (NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	if ([toolbarItems containsObject:item]) {
		[item setView:nil];
		[toolbarItems removeObject:item];
		[validatedItems removeObject:item];

		if ([toolbarItems count] == 0) {
			[[NSNotificationCenter defaultCenter] removeObserver:self
												  name:@"AIChatDidBecomeVisible"
												object:nil];
		}
	}
}

//A chat became visible in a window.  Update the item with the @"Encryption" identifier to show the IsSecure state for this chat
- (void)chatDidBecomeVisible:(NSNotification *)notification
{
	[self _updateToolbarIconOfChat:[notification object]
						  inWindow:[[notification userInfo] objectForKey:@"NSWindow"]];
}

//When the IsSecure key of a chat changes, update the @"Encryption" item immediately
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    if ([inModifiedKeys containsObject:@"securityDetails"]) {
		[self _updateToolbarIconOfChat:inChat
							  inWindow:[adium.interfaceController windowForChat:inChat]];
		
		/* Add a status message to the chat */
		BOOL		chatIsSecure = [inChat isSecure];
		if (chatIsSecure != [inChat boolValueForProperty:@"secureMessagingLastEncryptedState"]) {
			NSString	*message;
			NSString	*type;

			[inChat setValue:[NSNumber numberWithBool:chatIsSecure]
							 forProperty:@"secureMessagingLastEncryptedState"
							 notify:NotifyNever];

			if (chatIsSecure) {
				if ([inChat encryptionStatus] == EncryptionStatus_Unverified) {
					AIListObject	*listObject = [inChat listObject];
					NSString		*displayName = (listObject ?
													listObject.formattedUID :
													inChat.displayName);

					message = [NSString stringWithFormat:CHAT_NOW_SECURE_UNVERIFIED, displayName];
					type = @"encryptionStartedUnverified";

				} else {
					message = CHAT_NOW_SECURE;
					type = @"encryptionStarted";
				}

			} else {
				message = CHAT_NO_LONGER_SECURE;
				type = @"encryptionEnded";
			}

			if ([inChat isOpen]) {
				[adium.contentController displayEvent:message
												 ofType:type
												 inChat:inChat];
			}
		}
	}

	return nil;
}

- (void)_updateToolbarItem:(NSToolbarItem *)item forChat:(AIChat *)chat
{
	NSImage			*image;
	
	if ([chat isSecure]) {
		image = lockImage_Locked;
	} else {
		image = lockImage_Unlocked;				
	}
	
	[item setEnabled:[chat supportsSecureMessagingToggling]];
	[(MVMenuButton *)[item view] setImage:image];
	[validatedItems addObject:item];
}

- (void)_updateToolbarIconOfChat:(AIChat *)chat inWindow:(NSWindow *)window
{
	for (NSToolbarItem *item in window.toolbar.items) {
		if ([[item itemIdentifier] isEqualToString:@"Encryption"]) {
			[self _updateToolbarItem:item forChat:chat];
			break;
		}
	}	
}

- (IBAction)toggleSecureMessaging:(id)sender
{
	AIChat	*chat = adium.interfaceController.activeChat;

	[chat.account requestSecureMessaging:!chat.isSecure
									inChat:chat];
}

- (IBAction)showDetails:(id)sender
{
	NSRunInformationalAlertPanel(AILocalizedString(@"Details",nil),
								 [[adium.interfaceController.activeChat securityDetails] objectForKey:@"Description"],
								 AILocalizedString(@"OK",nil),
								 nil,
								 nil);
}

- (IBAction)verify:(id)sender
{
	AIChat	*chat = adium.interfaceController.activeChat;
	
	[chat.account promptToVerifyEncryptionIdentityInChat:chat];	
}

- (IBAction)showAbout:(id)sender
{
	NSString	*aboutEncryption;
	
	aboutEncryption = adium.interfaceController.activeChat.account.aboutEncryption;
	
	if (aboutEncryption) {
		NSRunInformationalAlertPanel(AILocalizedString(@"About Encryption",nil),
									 aboutEncryption,
									 AILocalizedString(@"OK",nil),
									 nil,
									 nil);
	}
}

- (IBAction)selectedEncryptionPreference:(id)sender
{
	AIListContact	*listContact = adium.interfaceController.activeChat.listObject.parentContact;
	
	[listContact setPreference:[NSNumber numberWithInteger:[sender tag]]
						forKey:KEY_ENCRYPTED_CHAT_PREFERENCE
						 group:GROUP_ENCRYPTION];
}

//Disable the insertion if a text field is not active
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	AIChat *chat;
	
	if (menuItem == menuItem_encryptionContext) {
		chat = adium.menuController.currentContextMenuChat;
	} else {
		chat = adium.interfaceController.activeChat;
	}

	if (!chat) return NO;

	if ([[[menuItem menu] title] isEqualToString:ENCRYPTION_MENU_TITLE]) {
		/* Options submenu */
		AIEncryptedChatPreference tag = (AIEncryptedChatPreference)[menuItem tag];
		
		AIListContact	*listContact = chat.listObject.parentContact;
		
		AIEncryptedChatPreference userPreference = [[listContact preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE
																			group:GROUP_ENCRYPTION] intValue];
		
		switch (tag) {
			case EncryptedChat_Default:
			{
				if (listContact) {
					//Set the state (checked or unchecked) as appropriate. Default = no pref or the actual 'default' value.
					[menuItem setState:(tag == userPreference || ![listContact preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE
																						  group:GROUP_ENCRYPTION])];
				}
				return YES;
				break;
			}
			case EncryptedChat_Never:
			case EncryptedChat_Manually:
			case EncryptedChat_Automatically:
			case EncryptedChat_RejectUnencryptedMessages:
			{
				if (listContact) {
					//Set the state (checked or unchecked) as appropriate
					[menuItem setState:(tag == userPreference)];
				}
				return YES;
				break;
			}
		}
	} else {
		/* Items on the main menu */
		AISecureMessagingMenuTag tag = (AISecureMessagingMenuTag)[menuItem tag];
		
		switch (tag) {
			case AISecureMessagingMenu_Root:
				return  [chat supportsSecureMessagingToggling];
				break;

			case AISecureMessagingMenu_Toggle:
				// The menu item should indicate what will happen if it is selected.. the opposite of our secure state
				if ([chat isSecure]) {
					[menuItem setTitle:TITLE_MAKE_INSECURE];
				} else {
					[menuItem setTitle:TITLE_MAKE_SECURE];
				
					AIListContact *listContact = chat.listObject.parentContact;
					AIEncryptedChatPreference userPreference = [[listContact preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE
																						group:GROUP_ENCRYPTION] intValue];
					
					// Disable 'Initiate Encrypted OTR Chat' menu item if chat encryption is disabled
					if (userPreference == EncryptedChat_Never) {
                    	return NO;
                    }
				}

				return YES;
				break;
				
			case AISecureMessagingMenu_ShowDetails:
			case AISecureMessagingMenu_Verify:
				//Only enable show details if the chat is secure
				return [chat isSecure];
				break;
				
			case AISecureMessagingMenu_Options:
				//Only enable options if the chat is with a single person 
				return ([chat supportsSecureMessagingToggling] && chat.listObject && !chat.isGroupChat);
				break;
				
			case AISecureMessagingMenu_ShowAbout:
				return [chat supportsSecureMessagingToggling];
				break;
		}
	}

	return YES;
}

- (NSMenu *)_secureMessagingMenu
{
	if (!_secureMessagingMenu) {
		NSMenuItem	*item;

		_secureMessagingMenu = [[NSMenu alloc] init];
		[_secureMessagingMenu setTitle:TITLE_ENCRYPTION];

		item = [[NSMenuItem alloc] initWithTitle:TITLE_MAKE_SECURE
										   target:self
										   action:@selector(toggleSecureMessaging:)
									keyEquivalent:@""];
		[item setTag:AISecureMessagingMenu_Toggle];
		[_secureMessagingMenu addItem:item];
		
		item = [[NSMenuItem alloc] initWithTitle:TITLE_SHOW_DETAILS
										   target:self
										   action:@selector(showDetails:)
									keyEquivalent:@""];
		[item setTag:AISecureMessagingMenu_ShowDetails];
		[_secureMessagingMenu addItem:item];

		item = [[NSMenuItem alloc] initWithTitle:TITLE_VERIFY
										   target:self
										   action:@selector(verify:)
									keyEquivalent:@""];
		[item setTag:AISecureMessagingMenu_Verify];
		[_secureMessagingMenu addItem:item];
		
		item = [[NSMenuItem alloc] initWithTitle:TITLE_ENCRYPTION_OPTIONS
										   target:nil
										   action:nil
									keyEquivalent:@""];
		[item setTag:AISecureMessagingMenu_Options];
		[item setSubmenu:[adium.contentController encryptionMenuNotifyingTarget:self
																	  withDefault:YES]];
		[_secureMessagingMenu addItem:item];		

		[_secureMessagingMenu addItem:[NSMenuItem separatorItem]];
		item = [[NSMenuItem alloc] initWithTitle:TITLE_ABOUT_ENCRYPTION
										   target:self
										   action:@selector(showAbout:)
									keyEquivalent:@""];
		[item setTag:AISecureMessagingMenu_ShowAbout];
		[_secureMessagingMenu addItem:item];
	}
	
	return [_secureMessagingMenu copy];
}

- (void)dummyAction:(id)sender {};

@end
