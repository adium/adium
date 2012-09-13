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

#import "AIAddBookmarkPlugin.h"
#import "AINewBookmarkWindowController.h"
#import "AIMessageWindowController.h"
#import <AIUtilities/AIToolbarUtilities.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListBookmark.h>

#define ADD_BOOKMARKTOOLBAR_ITEM_IDENTIFIER		@"AddBookmark"
#define ADD_BOOKMARK							AILocalizedString(@"Add Group Chat Bookmark", "Add a chat bookmark")
#define ADD_BOOKMARK_CONTEXT_MENU				AILocalizedString(@"Add Bookmark", "Add a chat bookmark (context menu)")

@interface AIAddBookmarkPlugin ()
- (void)addBookmark:(id)sender;
- (void)addBookmarkContext:(id)sender;
@end

@implementation AIAddBookmarkPlugin
/*!
 * @name installPlugin
 * @brief initializes the plugin - installs toolbaritem
 */
- (void)installPlugin
{
	addBookmarkToolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:ADD_BOOKMARKTOOLBAR_ITEM_IDENTIFIER
																		  label:ADD_BOOKMARK
																   paletteLabel:ADD_BOOKMARK
																		toolTip:AILocalizedString(@"Bookmark the current chat", "tooltip text for Add Bookmark")
																  		 target:self
																settingSelector:@selector(setImage:)
																	itemContent:[NSImage imageNamed:@"msg-bookmark-chat" forClass:[self class] loadLazily:YES]
																		 action:@selector(addBookmark:)
																		   menu:nil];
	
	addBookmarkMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_BOOKMARK
																			   target:self
																			   action:@selector(addBookmark:)
																		keyEquivalent:@""];
	
	[adium.menuController addMenuItem:addBookmarkMenuItem toLocation:LOC_Contact_Manage];

	addBookmarkContextMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_BOOKMARK_CONTEXT_MENU
																					  target:self
																					  action:@selector(addBookmarkContext:)
																			   keyEquivalent:@""];

	
	[adium.menuController addContextualMenuItem:addBookmarkContextMenuItem toLocation:Context_GroupChat_Action];
	
	[adium.toolbarController registerToolbarItem:addBookmarkToolbarItem forToolbarType:@"MessageWindow"];
	
}

- (void)uninstallPlugin
{
	[addBookmarkMenuItem release]; 
	[addBookmarkContextMenuItem release];
	
	[adium.toolbarController unregisterToolbarItem:addBookmarkToolbarItem forToolbarType:@"MessageWindow"];
}

/*!
 * @name addBookmark
 * @brief ask delegate to prompt the user with a create bookmark window
 */
- (void)addBookmark:(id)sender
{
	AINewBookmarkWindowController *newBookmarkWindowController = [[AINewBookmarkWindowController alloc] initWithChat:adium.interfaceController.activeChat
																									 notifyingTarget:self];
	[newBookmarkWindowController showOnWindow:[adium.interfaceController.activeChat.chatContainer.windowController window]];
}

/*!
 * @brief Add a bookmark
 *
 * Uses the adium.menuController.currentContextMenuChat as the chat.
 */
- (void)addBookmarkContext:(id)sender
{
	AINewBookmarkWindowController *newBookmarkWindowController = [[AINewBookmarkWindowController alloc] initWithChat:adium.menuController.currentContextMenuChat
																									 notifyingTarget:self];
	[newBookmarkWindowController showOnWindow:[adium.menuController.currentContextMenuChat.chatContainer.windowController window]];
}

// @brief: create a bookmark for the given chat with the given name in the given group
- (void)createBookmarkForChat:(AIChat *)chat withName:(NSString *)name inGroup:(AIListGroup *)group
{
	AIListBookmark *bookmark = [adium.contactController bookmarkForChat:chat inGroup:group];
	[bookmark setDisplayName:name];
}

/*!
 * @brief The chat can be bookmarked if it is a group chat and not already a bookmark.
 */
- (BOOL)validateToolbarItem:(NSToolbarItem *)inToolbarItem
{
	return (adium.interfaceController.activeChat.isGroupChat &&
			![adium.contactController existingBookmarkForChat:adium.interfaceController.activeChat]);
}

/*!
 * @brief The chat can be bookmarked if it is a group chat and not already a bookmark.
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem.title isEqualToString:ADD_BOOKMARK_CONTEXT_MENU]) {
		// WKMV's context menu makes a copy of menu items; check against title.
		return (![adium.contactController existingBookmarkForChat:adium.menuController.currentContextMenuChat]);
	} else {
		return (adium.interfaceController.activeChat.isGroupChat &&
				![adium.contactController existingBookmarkForChat:adium.interfaceController.activeChat]);
	}
}

@end
