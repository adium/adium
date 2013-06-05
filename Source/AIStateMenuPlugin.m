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

#import "AIStateMenuPlugin.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIEditStateWindowController.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AISocialNetworkingStatusMenu.h>
#import <AIUtilities/AIMenuAdditions.h>

@interface AIStateMenuPlugin ()
- (void)updateKeyEquivalents;
- (void)adiumFinishedLaunching:(NSNotification *)notification;
- (void)stateMenuSelectionsChanged:(NSNotification *)notification;
- (void)dummyAction:(id)sender;
@end

/*!
 * @class AIStateMenuPlugin
 * @brief Implements a list of preset states in the status menu
 *
 * This plugin places a list of preset states in the status menu, allowing the user to easily view and change the
 * active state.  It also manages a list of accounts in the status menu with associate statuses for setting account
 * statuses individually.
 */
@implementation AIStateMenuPlugin

/*!
 * @brief Initialize the state menu plugin
 *
 * Initialize the state menu, registering this class as a state menu plugin.  The status controller will then instruct
 * us to add and remove state menu items and handle all other details on its own.
 */
- (void)installPlugin
{
	//Wait for Adium to finish launching before we perform further actions
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:AIApplicationDidFinishLoadingNotification
									 object:nil];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	accountMenu = [AIAccountMenu accountMenuWithDelegate:self submenuType:AIAccountStatusSubmenu showTitleVerbs:NO];

	dockStatusMenuRoot = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Status",nil)
																			  target:self
																			  action:@selector(dummyAction:)
																	   keyEquivalent:@""];
	[adium.menuController addMenuItem:dockStatusMenuRoot toLocation:LOC_Dock_Status];

	statusMenu = [AIStatusMenu statusMenuWithDelegate:self];

	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(stateMenuSelectionsChanged:)
									   name:AIStatusActiveStateChangedNotification
									 object:nil];
	
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

- (void)uninstallPlugin
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[adium.menuController removeMenuItem:dockStatusMenuRoot];

	accountMenu = nil;
	statusMenu = nil;
	dockStatusMenuRoot = nil;
	currentMenuItemArray = nil;
	installedMenuItems = nil;
	socialNetworkingMenuItem = nil;
}

/*!
 * @brief Add state menu items to our location
 *
 * Implemented as required by the StateMenuPlugin protocol.  Also assigns key equivalents to appropriate
 * menu items depending on the current status.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be added to the menu
 */
- (void)statusMenu:(AIStatusMenu *)inStatusMenu didRebuildStatusMenuItems:(NSArray *)menuItemArray
{
	NSMenuItem		*menuItem;
	NSMenu			*dockStatusMenu = [[NSMenu alloc] init];

    for (menuItem in menuItemArray) {
		NSMenuItem	*dockMenuItem;

		[adium.menuController addMenuItem:menuItem toLocation:LOC_Status_State];
		
		dockMenuItem = [menuItem copy];
		[dockStatusMenu addItem:dockMenuItem];
    }
	
	[dockStatusMenuRoot setSubmenu:dockStatusMenu];

	//Tell the status controller to update these items as necessary
	[statusMenu delegateCreatedMenuItems:[dockStatusMenu itemArray]];
	
	if (currentMenuItemArray != menuItemArray) {
		currentMenuItemArray = menuItemArray;
	}

	[self updateKeyEquivalents];
}

- (void)statusMenu:(AIStatusMenu *)inStatusMenu willRemoveStatusMenuItems:(NSArray *)inMenuItems
{
	if ([inMenuItems count]) {
		NSMenuItem		*menuItem;
		
		NSMenu			*menubarMenu = [(NSMenuItem *)[inMenuItems objectAtIndex:0] menu];
		[menubarMenu setMenuChangedMessagesEnabled:NO];
		
		for (menuItem in inMenuItems) {
			[adium.menuController removeMenuItem:menuItem];
		}
		
		[menubarMenu setMenuChangedMessagesEnabled:YES];
	}
}

- (void)dummyAction:(id)sender {};

/*!
 * @brief Update key equivalents for our main status menu
 *
 * When available, cmd-y is mapped to custom away.
 * When away, cmd-y is mapped to available and cmd-option-y is always mapped to custom away.
 */
- (void)updateKeyEquivalents
{
	NSMenuItem		*menuItem;

	AIStatusType	activeStatusType = [adium.statusController activeStatusTypeTreatingInvisibleAsAway:YES];
	AIStatusType	targetStatusType = AIAvailableStatusType;
	AIStatus		*targetStatusState = nil;
	BOOL			assignCmdOptionY;
	
	if (activeStatusType == AIAvailableStatusType) {
		//If currently available, set an equivalent for the base away
		targetStatusType = AIAwayStatusType;
		targetStatusState = nil;
		assignCmdOptionY = NO;

	} else {
		//If away, invisible, or offline, set an equivalent for the available state
		targetStatusType = AIAvailableStatusType;		
		targetStatusState = [adium.statusController defaultInitialStatusState];
		assignCmdOptionY = YES;
	}

    for (menuItem in currentMenuItemArray) {
		AIStatus	*representedStatus = [[menuItem representedObject] objectForKey:@"AIStatus"];

		NSInteger			tag = [menuItem tag];
		if ((tag == targetStatusType) && 
		   (representedStatus == targetStatusState)) {			
			[menuItem setKeyEquivalent:@"y"];
			[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask];

		} else if (assignCmdOptionY && ((tag == AIAwayStatusType) && (representedStatus == nil))) {
			[menuItem setKeyEquivalent:@"y"];
			[menuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
			
		} else if ((tag == AIAvailableStatusType) && (representedStatus == nil)) {
			[menuItem setKeyEquivalent:@"Y"];
			[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
			
		} else {
			[menuItem setKeyEquivalent:@""];
			
		}
	}
}

/*!
 * @brief State menu selections changed
 */
- (void)stateMenuSelectionsChanged:(NSNotification *)notification
{
	[self updateKeyEquivalents];
}

#pragma mark Social networking
- (void)updateSocialNetworkingMenuItems
{
	BOOL oneOrMoreSocialNetworkingAccountsOnline = NO;
	for (AIAccount *account in adium.accountController.accounts) {
		if (account.online && [account.service isSocialNetworkingService]) {
			oneOrMoreSocialNetworkingAccountsOnline = YES;
			break;
		}
	}
	
	if (oneOrMoreSocialNetworkingAccountsOnline) {
		if (!socialNetworkingMenuItem) {
			socialNetworkingMenuItem = [AISocialNetworkingStatusMenu socialNetworkingSubmenuItem];
			[adium.menuController addMenuItem:socialNetworkingMenuItem toLocation:LOC_Status_SocialNetworking];
		}
	} else {
		if (socialNetworkingMenuItem) {
			[adium.menuController removeMenuItem:socialNetworkingMenuItem];
			socialNetworkingMenuItem = nil;
		}
	}
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]] && [[(AIAccount *)inObject service] isSocialNetworkingService] &&
		[inModifiedKeys containsObject:@"isOnline"]) {
		[self updateSocialNetworkingMenuItems];
	}
	
	return nil;
}

#pragma mark Account menu items

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
		[adium.menuController addMenuItem:menuItem toLocation:LOC_Status_Accounts];
    }
	
	//Remember the installed items so we can remove them later
	if (installedMenuItems != menuItems) {
		installedMenuItems = menuItems;
	}
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount {
	[inAccount toggleOnline];
}

- (BOOL)accountMenuShouldIncludeAddAccountsMenu:(AIAccountMenu *)inAccountMenu
{
	return NO;
}

- (BOOL)accountMenuShouldIncludeDisabledAccountsMenu:(AIAccountMenu *)inAccountMenu
{
	return YES;
}

@end
