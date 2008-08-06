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

#import <Adium/AIAbstractListObjectMenu.h>
#import <Adium/AIContactControllerProtocol.h>

@class AIAccount, AIStatusMenu;

typedef enum {
	AIAccountNoSubmenu = 0,
	AIAccountStatusSubmenu,
	AIAccountOptionsSubmenu
} AIAccountSubmenuType;

@interface AIAccountMenu : AIAbstractListObjectMenu <AIListObjectObserver> {
	id				delegate;
	BOOL			delegateRespondsToDidSelectAccount;
	BOOL			delegateRespondsToShouldIncludeAccount;	

	BOOL			useSystemFont;
	BOOL			submenuType;
	BOOL			showTitleVerbs;
	BOOL			includeDisabledAccountsMenu;
	BOOL			includeAddAccountsMenu;
	BOOL			includeConnectAllMenuItem;

	NSControlSize	controlSize;

	AIStatusMenu	*statusMenu;
}

+ (id)accountMenuWithDelegate:(id)inDelegate
				  submenuType:(AIAccountSubmenuType)inSubmenuType
			   showTitleVerbs:(BOOL)inShowTitleVerbs;

/*!	@brief	Whether to use the system font instead of the menu font.
 *
 *	@par	By default, menu items in the account menu use the menu font, but a client can request them with the system font instead.
 *
 *	@return	\c NO if the menu font should be used (the default); \c YES if the system font should be used instead.
 */
- (BOOL) useSystemFont;
/*!	@brief	Change whether to use the system font instead of the menu font.
 *
 *	@par	By default, menu items in the account menu use the menu font, but a client can request them with the system font instead.
 *
 *	@par	One situation in which it's appropriate to use the system font instead of the menu font is in the case of an NSPopUpButton, in which case the menu font is too big.
 *
 *	@param	flag	\c NO if the menu font should be used (the default); \c YES if the system font should be used instead.
 */
- (void) setUseSystemFont:(BOOL)flag;

- (void)setDelegate:(id)inDelegate;
- (id)delegate;

- (NSMenuItem *)menuItemForAccount:(AIAccount *)account;

@end

@interface NSObject (AIAccountMenuDelegate)
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems;
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount; 	//Optional
- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount; //Optional

/*!
 * @brief At what size will this menu be used?
 *
 * If not implemented, the default is NSRegularControlSize. NSMiniControlSize is not supported.
 */
- (NSControlSize)controlSizeForAccountMenu:(AIAccountMenu *)inAccountMenu; //Optional

//Should the account menu include a submenu of services for adding accounts?
- (BOOL)accountMenuShouldIncludeAddAccountsMenu:(AIAccountMenu *)inAccountMenu;			//Optional

//Should the account menu include a "connect all" menu item?
- (BOOL)accountMenuShouldIncludeConnectAllMenuItem:(AIAccountMenu *)inAccountMenu;			//Optional

//Should the account menu include a submenu of 'disabled accounts'?
- (BOOL)accountMenuShouldIncludeDisabledAccountsMenu:(AIAccountMenu *)inAccountMenu;			//Optional
@end
