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
#import "AIAccountMenuAccessPlugin.h"
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>

#import "AIGuestAccountWindowController.h"

@interface AIAccountMenuAccessPlugin ()
- (void)showGuestAccountWindow:(id)sender;
- (void)connectAllAccounts:(NSMenuItem *)menuItem;
@end

/*!
 * @class AIAccountMenuAccessPlugin
 * @brief Provide menu access to account connection/disconnect
 */
@implementation AIAccountMenuAccessPlugin

/*!
 * @brief Install the plugin
 */
- (void)installPlugin
{
	accountMenu = [[AIAccountMenu accountMenuWithDelegate:self submenuType:AIAccountOptionsSubmenu showTitleVerbs:YES] retain];
	
	NSMenuItem	*menuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Connect a Guest Account", "Menu item title which opens the window for adding and connecting a guest (temporary) account") stringByAppendingEllipsis]
													   target:self
													   action:@selector(showGuestAccountWindow:)
												keyEquivalent:@""];
	[adium.menuController addMenuItem:menuItem toLocation:LOC_File_Additions];
	[menuItem release];
}

/*!
 * @brief Uninstall Plugin
 */
- (void)uninstallPlugin
{
	[accountMenu release];
}

/*!
 * @brief Add account menu items to our location
 *
 * Implemented as required by the AccountMenuPlugin protocol.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be added to the menu
 */
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems
{
	NSMenuItem		*menuItem;

	//Remove any existing menu items
    for (menuItem in installedMenuItems) { 
		[adium.menuController removeMenuItem:menuItem];
    }
	
	//Add the new menu items
    for (menuItem in menuItems) {
		[adium.menuController addMenuItem:menuItem toLocation:LOC_File_Accounts];
    }
	
	//Remember the installed items so we can remove them later
	[installedMenuItems release]; 
	installedMenuItems = [menuItems retain];
}
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount {
	[inAccount toggleOnline];
}

- (BOOL)accountMenuShouldIncludeAddAccountsMenu:(AIAccountMenu *)inAccountMenu
{
	return YES;
}

- (BOOL)accountMenuShouldIncludeDisabledAccountsMenu:(AIAccountMenu *)inAccountMenu
{
	return YES;
}

- (NSMenuItem *)accountMenuSpecialMenuItem:(AIAccountMenu *)inAccountMenu
{
	NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Connect All Accounts",nil)
																				target:self
																				action:@selector(connectAllAccounts:)
																		 keyEquivalent:@"R"];
	[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
	return [menuItem autorelease];
}

/*!
 * @brief Connects all offline, enabled acounts
 */
- (void)connectAllAccounts:(NSMenuItem *)menuItem
{
	for (AIAccount *account in adium.accountController.accounts) {
		if (account.enabled && !account.online)
			[account setShouldBeOnline:YES];
	}
}

#pragma mark Guest account access
- (void)showGuestAccountWindow:(id)sender
{
	[AIGuestAccountWindowController showGuestAccountWindow];
}

@end
