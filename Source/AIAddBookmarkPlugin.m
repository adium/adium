//
//  AIAddBookmarkPlugin.m
//  Adium
//
//  Created by Erik Beerepoot on 30/07/07.
//  Copyright 2007 Adium. Licensed under the GNU GPL.
//

#import "AIAddBookmarkPlugin.h"
#import "AINewBookmarkWindowController.h"
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
																	itemContent:[NSImage imageNamed:@"bookmark_chat" forClass:[self class] loadLazily:YES]
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
	[AINewBookmarkWindowController promptForNewBookmarkForChat:adium.interfaceController.activeChat
													  onWindow:[adium.interfaceController.activeChat.chatContainer.windowController window]
												notifyingTarget:self];
}

/*!
 * @brief Add a bookmark
 *
 * Uses the adium.menuController.currentContextMenuChat as the chat.
 */
- (void)addBookmarkContext:(id)sender
{
	[AINewBookmarkWindowController promptForNewBookmarkForChat:adium.menuController.currentContextMenuChat
													  onWindow:[adium.menuController.currentContextMenuChat.chatContainer.windowController window]
											   notifyingTarget:self];
}

// @brief: create a bookmark for the given chat with the given name in the given group
- (void)createBookmarkForChat:(AIChat *)chat withName:(NSString *)name inGroup:(AIListGroup *)group
{
	AIListBookmark *bookmark = [adium.contactController bookmarkForChat:chat];
	[bookmark setDisplayName:name];
	
	[adium.contactController moveContact:bookmark fromGroups:[NSSet set] intoGroups:[NSSet setWithObject:group]];
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
