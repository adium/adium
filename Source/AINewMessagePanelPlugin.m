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

#import "AINewMessagePanelPlugin.h"
#import "AINewMessagePromptController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIListObject.h>
#import <Adium/AIAccount.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@interface AINewMessagePanelPlugin ()
- (void)contextualOpenChat:(id)sender;
@end

/*!
 * @class AINewMessagePanelPlugin
 * @brief Component to provide the New Message window, which allows messaging an arbitrary contact.
 *
 * Also provides a New Chat contextual menu item for contacts in situations which don't have immediate access
 * to opening a chat window.
 */
@implementation AINewMessagePanelPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	NSMenuItem *newMessageMenuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"New Chat",nil) stringByAppendingEllipsis]
																 target:self 
																 action:@selector(newMessage:)
														  keyEquivalent:@"n"];
	[adium.menuController addMenuItem:newMessageMenuItem toLocation:LOC_File_New];
	
	NSMenuItem *openChatMenuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Open Chat",nil)
																  target:self 
																  action:@selector(contextualOpenChat:)
														   keyEquivalent:@""]; 
	[adium.menuController addContextualMenuItem:openChatMenuItem toLocation:Context_Contact_Message];
	
}	

/*!
 * @brief Show the prompt
 */
- (void)newMessage:(id)sender
{
	[AINewMessagePromptController showPrompt];
}

- (BOOL)validateMenuItem:(id)menuItem
{
	if ([menuItem action] == @selector(newMessage:)) {
		return [adium.accountController oneOrMoreConnectedAccounts];

	} else if ([menuItem action] == @selector(contextualOpenChat:)) {
		BOOL enable = NO;

		for (AIAccount *account in [adium.accountController accountsCompatibleWithService:adium.menuController.currentContextMenuObject.service]) {
			if (account.online) {
				enable = YES;
				break;
			}
		}

		return enable;
	}
	
	return YES;
}

- (void)contextualOpenChat:(id)sender
{
	//Open a new message with the contact
	[adium.interfaceController setActiveChat:[adium.chatController openChatWithContact:(AIListContact *)adium.menuController.currentContextMenuObject
																		onPreferredAccount:YES]];
}

@end
