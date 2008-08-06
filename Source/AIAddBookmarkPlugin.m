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
#import <Adium/AIListBookmark.h>

#define ADD_BOOKMARKTOOLBAR_ITEM_IDENTIFIER		@"AddBookmark"
#define ADD_BOOKMARK							AILocalizedString(@"Add Group Chat Bookmark", "Add a chat bookmark")

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
																	itemContent:[NSImage imageNamed:@"AddressBook" forClass:[self class] loadLazily:YES]
																		 action:@selector(addBookmark:)
																		   menu:nil];
	
	addBookmarkMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_BOOKMARK
																			   target:self
																			   action:@selector(addBookmark:)
																		keyEquivalent:@""];
	
	[[adium menuController] addMenuItem:addBookmarkMenuItem
							 toLocation:LOC_Contact_Manage];
	
	[[adium toolbarController] registerToolbarItem:addBookmarkToolbarItem forToolbarType:@"MessageWindow"];
	
}

- (void)uninstallPlugin
{
	[addBookmarkMenuItem release];
	[[adium toolbarController] unregisterToolbarItem:addBookmarkToolbarItem forToolbarType:@"MessageWindow"];
	[[adium menuController] removeMenuItem:addBookmarkMenuItem];
}

/*!
 * @name addBookmark
 * @brief ask delegate to prompt the user with a create bookmark window
 */
- (void)addBookmark:(id)sender
{
	[AINewBookmarkWindowController promptForNewBookmarkForChat:[[adium interfaceController] activeChat]
													  onWindow:[[[[[adium interfaceController] activeChat] chatContainer] windowController] window]
												notifyingTarget:self];
}
// @brief: create a bookmark for the given chat with the given name in the given group
- (void)createBookmarkForChat:(AIChat *)chat withName:(NSString *)name inGroup:(AIListGroup *)group
{
	AIListBookmark *bookmark = [[adium contactController] bookmarkForChat:chat];
	[bookmark setDisplayName:name];
	
	[[adium contactController] moveContact:bookmark
								intoObject:group];
	[bookmark setVisible:YES];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)inToolbarItem
{
	return [[[adium interfaceController] activeChat] isGroupChat];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	return [[[adium interfaceController] activeChat] isGroupChat];	
}

@end
