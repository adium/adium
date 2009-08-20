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
#import <Adium/AIMenuControllerProtocol.h>
#import "DCJoinChatPanelPlugin.h"
#import "DCJoinChatWindowController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#define JOIN_CHAT_MENU_ITEM		[AILocalizedString(@"Join Group Chat",nil) stringByAppendingEllipsis]

/*!
 * @class DCJoinChatPanelPlugin
 * @brief Component to manage the Join Group Chat menu item
 */
@implementation DCJoinChatPanelPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	joinChatMenuItem = [[NSMenuItem alloc] initWithTitle:JOIN_CHAT_MENU_ITEM
													target:self 
													action:@selector(joinChat:)
											 keyEquivalent:@"J"];
	[adium.menuController addMenuItem:joinChatMenuItem toLocation:LOC_File_New];
}	

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[joinChatMenuItem release];

	[super dealloc];
}

/*!
 * @brief Show the join group chat window
 */
- (IBAction)joinChat:(id)sender
{	
	[DCJoinChatWindowController showJoinChatWindow];
}

/*!
 * @brief Validate menu item
 *
 * Disable the menu item if no online accounts could make use of it
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem == joinChatMenuItem) {
		for (AIAccount *account in adium.accountController.accounts) {
			if (account.online && account.service.canCreateGroupChats) return YES;
		}
		
		return NO;
	}
	
	return YES;
}

@end
