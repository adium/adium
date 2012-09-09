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

#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import "ESUserIconHandlingPlugin.h"
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageButton.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIServiceIcons.h>

#define	TOOLBAR_ITEM_TAG	-999

@interface ESUserIconHandlingPlugin ()
- (void)registerToolbarItem;
- (void)_updateToolbarIconOfChat:(AIChat *)inChat inWindow:(NSWindow *)window;
- (void)_updateToolbarItem:(NSToolbarItem *)item forChat:(AIChat *)chat;
- (void)updateToolbarItemForObject:(AIListObject *)inObject;
- (void)toolbarDidAddItem:(NSToolbarItem *)item;

- (void)chatDidBecomeVisible:(NSNotification *)notification;

- (void)listObjectAttributesChanged:(NSNotification *)notification;
- (IBAction)dummyAction:(id)sender;
@end

/*!
 * @class ESUserIconHandlingPlugin
 * @brief User icon handling component
 *
 * This component manages the Adium user icon cache.  It also provides a toolbar icon which shows the user icon
 * or service icon of the current chat in its window.
 */
@implementation ESUserIconHandlingPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	//Register our observers
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(listObjectAttributesChanged:)
									   name:ListObject_AttributesChanged
									 object:nil];

	[self registerToolbarItem];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
}

//Needs some 		[self updateToolbarItemForObject:inObject];

/*!
 * @brief List object attributes changes
 *
 * A plugin, or this plugin, modified the display array for the object; ensure our cache is up to date.
 */
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
	AIListObject	*inObject = [notification object];
	NSSet			*keys = [[notification userInfo] objectForKey:@"Keys"];
	
	if ([keys containsObject:KEY_USER_ICON]) {
		if (inObject) {
			[self updateToolbarItemForObject:inObject];
		} else {
			for (AIChat *chat in adium.interfaceController.openChats) {
				NSWindow *window = [adium.interfaceController windowForChat:chat];
				if (window) {
					[self _updateToolbarIconOfChat:chat
										  inWindow:window];
				}
			}
		}
			
	}
}

#pragma mark Toolbar Item

/*!
 * @brief Register our toolbar item
 *
 * Our toolbar item shows an image for the current chat, displaying it full size/animating if clicked.
 */
- (void)registerToolbarItem
{
	AIImageButton	*button;
	NSToolbarItem	*toolbarItem;

	toolbarItems = [[NSMutableSet alloc] init];
	validatedItems = [[NSMutableSet alloc] init];

	//Toolbar item registration
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarDidRemoveItem:)
												 name:NSToolbarDidRemoveItemNotification
											   object:nil];

	button = [[AIImageButton alloc] initWithFrame:NSMakeRect(0,0,32,32)];
	
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"UserIcon"
														  label:AILocalizedString(@"Icon",nil)
												   paletteLabel:AILocalizedString(@"Contact Icon",nil)
														toolTip:AILocalizedString(@"Show this contact's icon",nil)
														 target:self
												settingSelector:@selector(setView:)
													itemContent:button
														 action:@selector(dummyAction:)
														   menu:nil];

	[toolbarItem setMinSize:NSMakeSize(32,32)];
	[toolbarItem setMaxSize:NSMakeSize(32,32)];
	
	[button setCornerRadius:3.0f];
	[button setToolbarItem:toolbarItem];
	[button setImage:[NSImage imageNamed:@"default-icon" forClass:[self class] loadLazily:YES]];

	//Register our toolbar item
	[adium.toolbarController registerToolbarItem:toolbarItem forToolbarType:@"MessageWindow"];
}

/*!
 * @brief After the toolbar has added the item we can set up the submenus
 */
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];

	if ([[item itemIdentifier] isEqualToString:@"UserIcon"]) {

		[item setEnabled:YES];

		//Add menu to toolbar item (for text mode)
		NSMenuItem	*menuFormRepresentation, *blankMenuItem;
		NSMenu		*menu;

		menuFormRepresentation = [[NSMenuItem alloc] init];

		menu = [[NSMenu alloc] init];
		[menu setDelegate:self];
		[menu setAutoenablesItems:NO];

		blankMenuItem = [[NSMenuItem alloc] initWithTitle:@""
												   target:self
												   action:@selector(dummyAction:)
											keyEquivalent:@""];
		[blankMenuItem setRepresentedObject:item];
		[blankMenuItem setEnabled:YES];
		[menu addItem:blankMenuItem];

		[menuFormRepresentation setSubmenu:menu];
		[menuFormRepresentation setTitle:[item label]];
		[item setMenuFormRepresentation:menuFormRepresentation];

		//If this is the first item added, start observing for chats becoming visible so we can update the icon
		if ([toolbarItems count] == 0) {
			[[NSNotificationCenter defaultCenter] addObserver:self
										   selector:@selector(chatDidBecomeVisible:)
											   name:@"AIChatDidBecomeVisible"
											 object:nil];
		}

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

/*!
 * @brief Toolbar removed an item.
 *
 * If the item is one of ours, stop tracking it.
 *
 * @param notification Notification with an @"item" userInfo key for an NSToolbarItem.
 */
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

/*!
 * @brief A chat became visible in a window.
 *
 * Update the item with the @"UserIcon" identifier if necessary
 *
 * @param notification Notification with an AIChat object and an @"NSWindow" userInfo key
 */
- (void)chatDidBecomeVisible:(NSNotification *)notification
{
	[self _updateToolbarIconOfChat:[notification object]
						  inWindow:[[notification userInfo] objectForKey:@"NSWindow"]];
}

- (void)updateToolbarItemForObject:(AIListObject *)inObject
{
	AIChat		*chat;
	NSWindow	*window;

	//Update the icon in the toolbar for this contact if a chat is open and we have any toolbar items
	if (([toolbarItems count] > 0) &&
		[inObject isKindOfClass:[AIListContact class]] &&
		(chat = [adium.chatController existingChatWithContact:(AIListContact *)inObject]) &&
		(window = [adium.interfaceController windowForChat:chat])) {
		[self _updateToolbarIconOfChat:chat
							  inWindow:window];
	}
}

- (void)_updateToolbarItem:(NSToolbarItem *)item forChat:(AIChat *)chat
{
	AIListContact	*listContact;
	NSImage			*image;
	
    if (chat.isGroupChat) {
        listContact = (AIListContact *)[adium.contactController existingBookmarkForChat:chat];
    } else {
        listContact = chat.listObject.parentContact;
    }
    
	if (listContact) {
		image = [listContact userIcon];
		
		//Use the serviceIcon if no image can be found
		if (!image) image = [AIServiceIcons serviceIconForObject:listContact
															type:AIServiceIconLarge
													   direction:AIIconNormal];
	} else {
		//If we have no listObject or we have a name, we are a group chat and
		//should use the account's service icon
		image = [AIServiceIcons serviceIconForObject:chat.account
												type:AIServiceIconLarge
										   direction:AIIconNormal];
	}
	
	[(AIImageButton *)[item view] setImage:image];
	
	[validatedItems addObject:item];
}

/*!
 * @brief Update the user image toolbar icon in a chat
 *
 * @param chat The chat for which to retrieve an image
 * @param window The window in which the chat resides
 */
- (void)_updateToolbarIconOfChat:(AIChat *)chat inWindow:(NSWindow *)window
{
	for (NSToolbarItem *item in window.toolbar.items) {
		if ([[item itemIdentifier] isEqualToString:@"UserIcon"]) {
			[self _updateToolbarItem:item forChat:chat];
			break;
		}
	}
}

/*!
 * @brief Empty action for menu item validation purposes
 */
- (IBAction)dummyAction:(id)sender{};

/*!
 * @brief Menu needs update
 *
 * Should only be called for a menu off one of our toolbar items in text-only mode, and only when that menu is about
 * to be displayed.
 */
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSMenuItem *menuItem = [menu itemAtIndex:0];
	NSToolbarItem	*toolbarItem = [menuItem representedObject];

	[menuItem setImage:[[(AIImageButton *)[toolbarItem view] image] copy]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	return YES;
}

@end
