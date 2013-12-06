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

#import "AIChatConsolidationPlugin.h"

#import <Adium/AIChat.h>
#import "AIMessageWindowController.h"
#import <Adium/AIMenuControllerProtocol.h>

#import <AIUtilities/AIMenuAdditions.h>

#define CONSOLIDATE_CHATS_MENU_TITLE	AILocalizedString(@"Consolidate Chats",nil)
#define NEW_TAB_MENU_TITLE				AILocalizedString(@"Move Chat to New Window",nil)

@interface AIChatConsolidationPlugin ()
- (void)consolidateChats:(id)sender;
- (void)moveChatToNewWindow:(id)sender;
@end

/*!
 * @class AIChatConsolidationPlugin
 * @brief Component which provides the Conslidate Chats menu item
 *
 * Consolidating chats moves all open chats into a single, tabbed window
 */
@implementation AIChatConsolidationPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	consolidateMenuItem = [[NSMenuItem alloc] initWithTitle:CONSOLIDATE_CHATS_MENU_TITLE
													 target:self 
													 action:@selector(consolidateChats:)
											  keyEquivalent:@"O"];
	[adium.menuController addMenuItem:consolidateMenuItem toLocation:LOC_Window_Commands];

	newWndowMenuItem = [[NSMenuItem alloc] initWithTitle:NEW_TAB_MENU_TITLE
												  target:self 
												  action:@selector(moveChatToNewWindow:)
										   keyEquivalent:@""];
	[adium.menuController addMenuItem:newWndowMenuItem toLocation:LOC_Window_Commands];	
}

/*!
 * @brief Consolidate chats
 *
 *	The interface controller does all the work for us :)
 */
- (void)consolidateChats:(id)sender
{
	[adium.interfaceController consolidateChats];	
}

- (void)moveChatToNewWindow:(id)sender
{
	[adium.interfaceController moveChatToNewContainer:adium.interfaceController.activeChat];
}

/*!
 * @brief Validate menu items
 *
 * Only enable the menu if more than one chat is open
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	BOOL validate;

	if (menuItem == consolidateMenuItem)
		validate = ([adium.interfaceController.openContainerIDs count] > 1);
	else if (menuItem == newWndowMenuItem)
		validate = ([adium.interfaceController.activeChat.chatContainer.windowController.containedChats count] > 1);
	else
		validate = TRUE;

	return validate;
}

@end
