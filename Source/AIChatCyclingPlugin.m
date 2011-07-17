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

#import "AIChatCyclingPlugin.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import "ESGeneralPreferencesPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>

#define PREVIOUS_MESSAGE_MENU_TITLE		AILocalizedString(@"Select Previous Chat",nil)
#define NEXT_MESSAGE_MENU_TITLE			AILocalizedString(@"Select Next Chat",nil)

/*!
 * @class AIChatCyclingPlugin
 * @brief Component to manage the chat cycling menu items
 *
 * Adium supports several different key combinations for switching tabs, configuring via the General Preferences.
 */
@implementation AIChatCyclingPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	id<AIMenuController>	menuController = adium.menuController;
	NSMenuItem				*nextChatMenuItem, *previousChatMenuItem;

	//Cycling menu items
	nextChatMenuItem = [[NSMenuItem alloc] initWithTitle:NEXT_MESSAGE_MENU_TITLE 
												  target:self
												  action:@selector(nextChat:)
										   keyEquivalent:@"\t"];
	[nextChatMenuItem setKeyEquivalentModifierMask:NSControlKeyMask];
	[menuController addMenuItem:nextChatMenuItem toLocation:LOC_Window_Commands];
	
	previousChatMenuItem = [[NSMenuItem alloc] initWithTitle:PREVIOUS_MESSAGE_MENU_TITLE
													  target:self 
													  action:@selector(previousChat:)
											   keyEquivalent:@"\t"];
	[previousChatMenuItem setKeyEquivalentModifierMask:(NSControlKeyMask | NSShiftKeyMask)];
	[menuController addMenuItem:previousChatMenuItem toLocation:LOC_Window_Commands];
}

- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
}

/*!
 * @brief Menu item validation
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (!adium.interfaceController.activeChat) return NO;
	
	NSString *containerID = [adium.interfaceController containerIDForChat:adium.interfaceController.activeChat];
	
	return ([adium.interfaceController openChatsInContainerWithID:containerID].count > 0);
}

/*!
 * @brief Select the next chat
 */
- (IBAction)nextChat:(id)sender
{
	[adium.interfaceController nextChat:nil];
}

/*!
 * @brief Select the previous chat
 */
- (IBAction)previousChat:(id)sender
{
	[adium.interfaceController previousChat:nil];
}	

@end
