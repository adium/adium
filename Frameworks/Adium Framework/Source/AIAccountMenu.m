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

#import <Adium/AIAccountMenu.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceMenu.h>
#import <Adium/AISocialNetworkingStatusMenu.h>

//Menu titles
#define	ACCOUNT_CONNECT_ACTION_MENU_TITLE			AILocalizedString(@"Connect: %@", "Connect account prefix")
#define	ACCOUNT_DISCONNECT_ACTION_MENU_TITLE		AILocalizedString(@"Disconnect: %@", "Disconnect account prefix")
#define	ACCOUNT_CONNECTING_ACTION_MENU_TITLE		AILocalizedString(@"Cancel: %@", "Cancel current account activity prefix")
#define	ACCOUNT_DISCONNECTING_ACTION_MENU_TITLE		ACCOUNT_CONNECTING_ACTION_MENU_TITLE
#define ACCOUNT_ENABLE_ACTION_MENU_TITLE			AILocalizedString(@"Enable %@", "Enable account prefix")

#define ACCOUNT_CONNECT_PARENS_MENU_TITLE			AILocalizedString(@"%@ (Connecting)", "Account Name (Connecting) - shown for an account while it is connecting")

#define NEW_ACCOUNT_DISPLAY_TEXT			AILocalizedString(@"<New Account>", "Placeholder displayed as the name of a new account")

// XXX Fix those method names! Apple's naming convention don't allow them to start with _

@interface AIAccountMenu ()
- (id)initWithDelegate:(id)inDelegate
		   submenuType:(AIAccountSubmenuType)inSubmenuType
		showTitleVerbs:(BOOL)inShowTitleVerbs;
- (void)_updateMenuItem:(NSMenuItem *)menuItem;
- (NSString *)_titleForAccount:(AIAccount *)account;
- (NSMenu *)actionsMenuForAccount:(AIAccount *)inAccount;
- (void)selectAccountMenuItem:(NSMenuItem *)menuItem;
- (void)menuNeedsUpdate:(NSMenu*)menu;
- (void)rebuildActionsSubmenu:(NSMenu*)actionsSubmenu withAccount:(AIAccount*)account;
- (void)toggleAccountEnabled:(id)sender;
- (void)dummyAction:(id)sender;
- (void)editAccount:(id)sender;
- (void)toggleAccountEnabled:(id)sender;
@end

static NSMenu *socialNetworkingSubmenuForAccount(AIAccount *account, id target, SEL action, id self);

@implementation AIAccountMenu

/*!
 * @brief Create a new account menu
 * @param inDelegate Delegate in charge of adding menu items
 * @param InShowAccountActions YES to show accont actions in a submenu
 * @param inShowTitleVerbs YES to show verbs in the menu titles
 */
+ (id)accountMenuWithDelegate:(id)inDelegate
				  submenuType:(AIAccountSubmenuType)inSubmenuType
			   showTitleVerbs:(BOOL)inShowTitleVerbs
{
	return [[[self alloc] initWithDelegate:inDelegate
							   submenuType:inSubmenuType
							showTitleVerbs:inShowTitleVerbs] autorelease];
}

/*!
 * @brief Init
 * @param inDelegate Delegate in charge of adding menu items
 * @param InShowAccountActions YES to show accont actions in a submenu
 * @param inShowTitleVerbs YES to show verbs in the menu titles
 */
- (id)initWithDelegate:(id)inDelegate
		   submenuType:(AIAccountSubmenuType)inSubmenuType
		showTitleVerbs:(BOOL)inShowTitleVerbs
{
	if ((self = [super init])) {
		submenuType = inSubmenuType;
		showTitleVerbs = inShowTitleVerbs;

		[self setDelegate:inDelegate];

		if ([self.delegate respondsToSelector:@selector(controlSizeForAccountMenu:)]) {
			controlSize = [self.delegate controlSizeForAccountMenu:self];
			//If the delegate specifes a control size, it's implicitly a control; use the right size for it
			[self setUseSystemFont:YES];

		} else {
			controlSize = NSRegularControlSize;
		}
		
		//Rebuild our account menu when accounts or icon sets change
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(rebuildMenu)
										   name:Account_ListChanged
										 object:nil];

		//Observe our accouts and prepare our state menus
		[[AIContactObserverManager sharedManager] registerListObjectObserver:self];

		if (submenuType == AIAccountStatusSubmenu) {
			statusMenu = [[AIStatusMenu statusMenuWithDelegate:self] retain];
		}

		//Rebuild our menu now
		[self rebuildMenu];
	}
	
	return self;
}

- (void)dealloc
{
	if (submenuType == AIAccountStatusSubmenu) {
		[NSObject cancelPreviousPerformRequestsWithTarget:statusMenu];
		[statusMenu release]; statusMenu = nil;
	}

	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	delegate = nil;

	[super dealloc];
}

/*!
 * @brief Returns the existing menu item for a specific account
 *
 * @param account AIAccount whose menu item to return
 * @return NSMenuItem instance for the account
 */
- (NSMenuItem *)menuItemForAccount:(AIAccount *)account
{
	return [self menuItemWithRepresentedObject:account];
}

//Accessors ------------------------------------------------------------------------------------------------------------
#pragma mark Accessors

- (BOOL) useSystemFont {
	return useSystemFont;
}
- (void) setUseSystemFont:(BOOL)flag {
	useSystemFont = flag;
}

//Delegate -------------------------------------------------------------------------------------------------------------
#pragma mark Delegate
/*!
 * @brief Set our account menu delegate
 */
- (void)setDelegate:(id<AIAccountMenuDelegate>)inDelegate
{
	delegate = inDelegate;
	
	//Ensure the the delegate implements all required selectors and remember which optional selectors it supports.
	if (delegate) NSParameterAssert([delegate respondsToSelector:@selector(accountMenu:didRebuildMenuItems:)]);
	delegateRespondsToDidSelectAccount = [delegate respondsToSelector:@selector(accountMenu:didSelectAccount:)];
	delegateRespondsToShouldIncludeAccount = [delegate respondsToSelector:@selector(accountMenu:shouldIncludeAccount:)];

	includeAddAccountsMenu = ([delegate respondsToSelector:@selector(accountMenuShouldIncludeAddAccountsMenu:)] &&
							  [delegate accountMenuShouldIncludeAddAccountsMenu:self]);

	includeDisabledAccountsMenu = ([delegate respondsToSelector:@selector(accountMenuShouldIncludeDisabledAccountsMenu:)] &&
								   [delegate accountMenuShouldIncludeDisabledAccountsMenu:self]);
	
	delegateRespondsToSpecialMenuItem = [delegate respondsToSelector:@selector(accountMenuSpecialMenuItem:)];
}
- (id<AIAccountMenuDelegate>)delegate
{
	return delegate;
}

/*!
 * @brief Inform our delegate when the menu is rebuilt
 */
- (void)rebuildMenu
{
	[super rebuildMenu];
	[delegate accountMenu:self didRebuildMenuItems:[self menuItems]];
}	

/*!
 * @brief Inform our delegate of menu selections
 */
- (void)selectAccountMenuItem:(NSMenuItem *)menuItem
{
	if(delegateRespondsToDidSelectAccount){
		[delegate accountMenu:self didSelectAccount:[menuItem representedObject]];
	}
}

//Account Menu ---------------------------------------------------------------------------------------------------------
#pragma mark Account Menu
/*!
 * @brief Build our account menu items
 */
- (NSArray *)buildMenuItems
{
	NSMutableArray	*menuItemArray = [NSMutableArray array];
	NSArray			*accounts = adium.accountController.accounts;
	
	if (delegateRespondsToSpecialMenuItem) {
		
		NSMenuItem *specialMenuItem = [delegate accountMenuSpecialMenuItem:self];
		
		if (specialMenuItem) {
			// unless overridden to a different action, just send -accountMenu:didSelectAccount: with nil when selected
			if ([specialMenuItem target] == nil) {
				[specialMenuItem setTarget:self];
				[specialMenuItem setAction:@selector(selectAccountMenuItem:)];
			}
			
			[menuItemArray addObject:specialMenuItem];
			[menuItemArray addObject:[NSMenuItem separatorItem]];
		}
	}
	
	//Add a menuitem for each enabled account or accounts that the delegate allows
	for (AIAccount *account in accounts) {
		if ((account.enabled && !delegateRespondsToShouldIncludeAccount) ||
			(delegateRespondsToShouldIncludeAccount && [delegate accountMenu:self shouldIncludeAccount:account])) {
			NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@""
																						target:self
																						action:@selector(selectAccountMenuItem:)
																				 keyEquivalent:@""
																			 representedObject:account];
			[self _updateMenuItem:menuItem];
			if (submenuType == AIAccountOptionsSubmenu) {
				[menuItem setSubmenu:[self actionsMenuForAccount:account]];
			}
			[menuItemArray addObject:menuItem];
			[menuItem release];
		}
	}
	
	if (includeDisabledAccountsMenu) {
		NSMenu		*disabledAccountMenu = [[NSMenu alloc] init];

		for (AIAccount *account in accounts) {
			if (!account.enabled &&
				(!delegateRespondsToShouldIncludeAccount || [delegate accountMenu:self shouldIncludeAccount:account])) {
				NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@""
																							target:self
																							action:@selector(toggleAccountEnabled:)
																					 keyEquivalent:@""
																				 representedObject:account];
				[self _updateMenuItem:menuItem];
				[disabledAccountMenu addItem:menuItem];
				[menuItem release];
			}
		}

		if (includeAddAccountsMenu || [disabledAccountMenu numberOfItems]) {
			[menuItemArray addObject:[NSMenuItem separatorItem]];
		}

		if (includeAddAccountsMenu) {
			//Build the 'add account' menu of each available service
			NSMenu	*serviceMenu = [AIServiceMenu menuOfServicesWithTarget:self 
														activeServicesOnly:NO
														   longDescription:YES
																	format:AILocalizedString(@"%@",nil)];
			
			
			NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Add Account", nil)
																						target:self
																						action:@selector(dummyAction:)
																				 keyEquivalent:@""
																			 representedObject:nil];
			[menuItemArray addObject:menuItem];
			[menuItem setSubmenu:serviceMenu];
			[menuItem release];
        }

		if ([disabledAccountMenu numberOfItems]) {
			NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Disabled Accounts", nil)
                                                                            target:self
                                                                            action:@selector(dummyAction:)
                                                                     keyEquivalent:@""
                                                                 representedObject:nil];
			[menuItemArray addObject:menuItem];
			[menuItem setSubmenu:disabledAccountMenu];
			[menuItem release];
		}
		
		[disabledAccountMenu release];
	}

	if (submenuType == AIAccountStatusSubmenu) {
		//Update our status submenus once this method returns so that our menuItemArray is set
		[statusMenu performSelector:@selector(rebuildMenu)
						 withObject:nil
						 afterDelay:0];
	}
	
	return menuItemArray;
}

/*!
* @brief Returns a menu image for the account
 */
- (NSImage *)imageForListObject:(AIListObject *)listObject usingUserIcon:(BOOL)useUserIcon
{
	if ([listObject isKindOfClass:[AIAccount class]] &&
		![(AIAccount *)listObject enabled]) {
		return [AIServiceIcons serviceIconForObject:listObject type:AIServiceIconSmall direction:AIIconNormal];	

	} else {
		return [super imageForListObject:listObject usingUserIcon:useUserIcon];
	}
}

/*!
* @brief Update a menu item to reflect its account's current status
 */
- (void)_updateMenuItem:(NSMenuItem *)menuItem
{
	AIAccount	*account = [menuItem representedObject];
	
	if (account) {
		[[menuItem menu] setMenuChangedMessagesEnabled:NO];

		[menuItem setImage:[self imageForListObject:account usingUserIcon:NO]];

		/* The default font size for menu items in the main menu seems to be 1 pt larger than the font size produced by [NSFont menuFontOfSize:0.0f]:
		 * specifically, as of Mac OS X 10.4.10, it is 14 pt. This seems to be an AppKit bug.
		 */
		NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont menuFontOfSize:(useSystemFont ? [NSFont systemFontSizeForControlSize:controlSize] : 14.0f)], NSFontAttributeName,
			[NSParagraphStyle styleWithAlignment:NSLeftTextAlignment
								   lineBreakMode:NSLineBreakByTruncatingTail], NSParagraphStyleAttributeName,
			nil];	

		NSAttributedString *plainTitle = [[NSAttributedString alloc] initWithString:[self _titleForAccount:account]
																		 attributes:titleAttributes];

		//Add an SSL icon if the account is encrypted.
		if ([account encrypted]) {
			NSBundle *securityInterfaceFramework = [NSBundle bundleWithIdentifier:@"com.apple.securityinterface"];
			if (!securityInterfaceFramework) securityInterfaceFramework = [NSBundle bundleWithPath:@"/System/Library/Frameworks/SecurityInterface.framework"];

			NSString					*path = [securityInterfaceFramework pathForImageResource:@"CertSmallStd"];
			NSFileWrapper				*fileWrapper = nil;
			NSTextAttachment			*textAttachment = nil;
			NSMutableAttributedString	*title = nil;
			
			fileWrapper = [[NSFileWrapper alloc] initWithPath:path];
			textAttachment = [[NSTextAttachment alloc] initWithFileWrapper:fileWrapper];

			title = [plainTitle mutableCopy];

			//Put a space between the title and the SSL icon.
			[[title mutableString] appendString:@" "];

			NSMutableAttributedString *SSLIconText = [[NSAttributedString attributedStringWithAttachment:textAttachment] mutableCopy];
			//Shift the image down a little bit; otherwise, it rides too high.
			[SSLIconText addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-3.0f] range:NSMakeRange(0, [SSLIconText length])];

			[title appendAttributedString:SSLIconText];
			[SSLIconText release];

			[menuItem setAttributedTitle:title];
			
			[title release];
			[textAttachment release];
			[fileWrapper release];
		} else {
			[menuItem setAttributedTitle:plainTitle];
		}
		
		[plainTitle release];

		[account accountMenuDidUpdate:menuItem];

		[[menuItem menu] setMenuChangedMessagesEnabled:YES];
	}
}

/*!
* @brief Returns the menu title for an account
 */
- (NSString *)_titleForAccount:(AIAccount *)account
{
	NSString	*accountTitle = [account explicitFormattedUID];
	NSString	*titleFormat = nil;
	
	//If the account doesn't have a name, give it a generic one
	if (!accountTitle || ![accountTitle length]) accountTitle = NEW_ACCOUNT_DISPLAY_TEXT;
	
	if (account.enabled) {
		if (showTitleVerbs) {
			if ([account boolValueForProperty:@"isConnecting"] || [account valueForProperty:@"waitingToReconnect"]) {
				titleFormat = ACCOUNT_CONNECTING_ACTION_MENU_TITLE;
			} else if ([account boolValueForProperty:@"isDisconnecting"]) {
				titleFormat = ACCOUNT_DISCONNECTING_ACTION_MENU_TITLE;
			} else {
				//Display 'connect' or 'disconnect' before the account name
				titleFormat = (account.online ? ACCOUNT_DISCONNECT_ACTION_MENU_TITLE : ACCOUNT_CONNECT_ACTION_MENU_TITLE);
			}
			
		} else {
			if ([account boolValueForProperty:@"isConnecting"]) {
				titleFormat = ACCOUNT_CONNECT_PARENS_MENU_TITLE;
			}
		}
	} else {
		if (showTitleVerbs) {
			titleFormat = ACCOUNT_ENABLE_ACTION_MENU_TITLE;
		}
	}
		
	return (titleFormat ? [NSString stringWithFormat:titleFormat, accountTitle] : accountTitle);
}

/*!
 * @brief Update menu when an account's status changes
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		NSMenuItem	*menuItem = [self menuItemForAccount:(AIAccount *)inObject];
		BOOL		rebuilt = NO;
		
		if ([inModifiedKeys containsObject:@"Enabled"]) {
			//Rebuild the menu when the enabled state changes
			[self rebuildMenu];
			rebuilt = YES;

		} else if ([inModifiedKeys containsObject:@"isOnline"] ||
				   [inModifiedKeys containsObject:@"isConnecting"] ||
				   [inModifiedKeys containsObject:@"waitingToReconnect"] ||
				   [inModifiedKeys containsObject:@"isDisconnecting"] ||
				   [inModifiedKeys containsObject:@"idleSince"] ||
				   [inModifiedKeys containsObject:@"accountStatus"]) {
			//Update menu items to reflect status changes

			//Update the changed menu item (or rebuild the entire menu if this item should be removed or added)
			if (delegateRespondsToShouldIncludeAccount) {
				BOOL shouldIncludeAccount = [delegate accountMenu:self shouldIncludeAccount:(AIAccount *)inObject];
				BOOL menuItemExists		  = (menuItem != nil);
				//If we disagree on item inclusion and existence, rebuild the menu.
				if (shouldIncludeAccount != menuItemExists) {
					[self rebuildMenu];
					rebuilt = YES;
				} else { 
					[self _updateMenuItem:menuItem];
				}
			} else {
				[self _updateMenuItem:menuItem];
			}
		}

		if ((submenuType == AIAccountOptionsSubmenu) && [inModifiedKeys containsObject:@"isOnline"]) {
			if (rebuilt) menuItem = [self menuItemForAccount:(AIAccount *)inObject];

			//Append the account actions menu
			if (menuItem && [(AIAccount *)inObject enabled]) {
				[menuItem setSubmenu:[self actionsMenuForAccount:(AIAccount *)inObject]];
			}
		}
		
		if ((submenuType == AIAccountStatusSubmenu) && [inObject.service isSocialNetworkingService] && [inModifiedKeys containsObject:@"isOnline"]) {
			menuItem = [self menuItemForAccount:(AIAccount *)inObject];
			
			if (menuItem) {
				[menuItem setSubmenu:socialNetworkingSubmenuForAccount((AIAccount *)inObject, [menuItem target], [menuItem action], self)];
			}
		}
	}

    return nil;
}

- (IBAction)selectServiceType:(id)sender
{
	AIService	*service = [sender representedObject];
	AIAccount	*account = [adium.accountController createAccountWithService:service
																		   UID:[service defaultUserName]];
	[adium.accountController editAccount:account
								  onWindow:nil
						   notifyingTarget:self];
}

/*!
* @brief Editing of an account completed
 */
- (void)editAccountSheetDidEndForAccount:(AIAccount *)inAccount withSuccess:(BOOL)successful
{
	if (successful) {
		//New accounts need to be added to our account list once they're configured
		[adium.accountController addAccount:inAccount];
        
		//Put new accounts online by default
		[inAccount setPreference:[NSNumber numberWithBool:YES] forKey:@"isOnline" group:GROUP_ACCOUNT_STATUS];
	}
}

//Account Action Submenu -----------------------------------------------------------------------------------------------
#pragma mark Account Action Submenu
/*!
 * @brief Returns an action menu for the passed account
 *
 * If the account is online, it is queried for account actions.
 * If it is offline, this menu has only "Edit Account" and "Disable."
 */
- (NSMenu *)actionsMenuForAccount:(AIAccount *)inAccount
{
	NSMenu		*actionsSubmenu = [[[NSMenu allocWithZone:[NSMenu zone]] init] autorelease];
	
	[actionsSubmenu setDelegate:self];

	[self rebuildActionsSubmenu:actionsSubmenu withAccount:inAccount];
	
	return actionsSubmenu;
}

/*!
 * @brief NSMenu delegate method to to update the account menu
 *
 * @param actionsSubmenu The menu to refresh
 */
- (void)menuNeedsUpdate:(NSMenu *)actionsSubmenu {
	if ([actionsSubmenu numberOfItems] == 0)
		return;

	// assume that the first item is "Edit Account" with the AIAccount object as the representedObject
	NSMenuItem *editAccountMenuItem = [actionsSubmenu itemAtIndex:0];
	AIAccount *account = [editAccountMenuItem representedObject];
	if(!account || ![account isKindOfClass:[AIAccount class]]) // safety checks (should never fail)
		return;
	
	// clean menu
	[actionsSubmenu setMenuChangedMessagesEnabled:NO];
	while([actionsSubmenu numberOfItems] > 0) {
		[actionsSubmenu removeItemAtIndex:0];
	}
	
	[self rebuildActionsSubmenu:actionsSubmenu withAccount:account];
	[actionsSubmenu setMenuChangedMessagesEnabled:YES];
}

/*!
* @brief Insert all action menu items into the given menu object
 *
 * @param actionsSubmenu The menu to build
 * @param inAccount The account this menu belongs to
 */
- (void)rebuildActionsSubmenu:(NSMenu*)actionsSubmenu withAccount:(AIAccount*)inAccount {
	NSArray		*accountActionMenuItems = (inAccount.online ? [inAccount accountActionMenuItems] : nil);
	NSMenuItem	*menuItem;
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Edit Account", nil)
																	target:self
																	action:@selector(editAccount:)
															 keyEquivalent:@""
														 representedObject:inAccount];
	[actionsSubmenu addItem:menuItem];
	[menuItem release];
	
	[actionsSubmenu addItem:[NSMenuItem separatorItem]];
	
	//Only build a menu if we have items
	if (accountActionMenuItems && [accountActionMenuItems count]) {
		//Build a menu containing all the items
		for (menuItem in accountActionMenuItems) {
			NSMenuItem	*newMenuItem = [menuItem copy];
			[actionsSubmenu addItem:newMenuItem];
			[newMenuItem release];
		}
		
		//Separate the actions from our final menu items which apply to all accounts
		[actionsSubmenu addItem:[NSMenuItem separatorItem]];
	}
	
	if ([inAccount enabled]) {
		menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Disable", nil)
																	target:self
																	action:@selector(toggleAccountEnabled:)
															 keyEquivalent:@""
														 representedObject:inAccount];
	} else {
		menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Enable", nil)
																		target:self
																		action:@selector(toggleAccountEnabled:)
																 keyEquivalent:@""
															 representedObject:inAccount];
	}
	[actionsSubmenu addItem:menuItem];
	[menuItem release];
}

/*!
 * @brief Edit an account
 *
 * @param sender An NSMenuItem whose representedObject is an AIAccount
 */
- (void)editAccount:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIEditAccount"
											  object:[sender representedObject]];
}

/*!
 * @brief Disable an account
 *
 * @param sender An NSMenuItem whose representedObject is an AIAccount
 */
- (void)toggleAccountEnabled:(id)sender
{
	AIAccount	*account = [sender representedObject];
	[account setEnabled:!account.enabled];
}

//Account Status Submenu -----------------------------------------------------------------------------------------------
#pragma mark Account Status Submenu
void updateRepresentedObjectForSubmenusOfMenuItem(NSMenuItem *menuItem, AIAccount *account)
{
	NSMenu *submenu;
	if ((submenu = [menuItem submenu])) {
		NSEnumerator *enumerator = [[submenu itemArray] objectEnumerator];
		NSMenuItem *submenuItem;
		
		while ((submenuItem = [enumerator nextObject])) {
			AIStatus	 *status;
			NSDictionary *newRepresentedObject;

			//Set the represented object to indicate both the right status and the right account
			if ((status = [[submenuItem representedObject] objectForKey:@"AIStatus"])) {
				newRepresentedObject = [[NSDictionary alloc] initWithObjectsAndKeys:
					status, @"AIStatus",
					account, @"AIAccount",
					nil];
			} else {
				//Custom status items don't have an associated AIStatus.
				newRepresentedObject = [[NSDictionary alloc] initWithObjectsAndKeys:
																	 account, @"AIAccount",
																	 nil];
			}
			
			[submenuItem setRepresentedObject:newRepresentedObject];
			[newRepresentedObject release];

			//Recurse into any submenu on this menu item
			updateRepresentedObjectForSubmenusOfMenuItem(submenuItem, account);
		}
	}
}

static NSMenu *socialNetworkingSubmenuForAccount(AIAccount *account, id target, SEL action, id self)
{
	NSMenuItem *onlineOfflineItem;
	NSMenu *accountSubmenu;
	accountSubmenu = [AISocialNetworkingStatusMenu socialNetworkingSubmenuForAccount:account];
	
	/* Put a connect/disconnect menu item at the top, since we skip the status items
	 * By copying the accountMenuItem's target and action, it gains the action of toggling conncectivity,
	 * which is exactly what we want.
	 */
	onlineOfflineItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:(account.online ?
																					 AILocalizedString(@"Disconnect", nil) :
																					 AILocalizedString(@"Connect", nil))
																			 target:target
																			 action:action
																	  keyEquivalent:@""
																  representedObject:account];
	
	[accountSubmenu insertItem:onlineOfflineItem atIndex:0];
	[accountSubmenu insertItem:[NSMenuItem separatorItem] atIndex:1];
	[onlineOfflineItem release];	
	
	return accountSubmenu;
}

NSMenu *statusMenuForAccountMenuItem(NSArray *menuItemArray, NSMenuItem *accountMenuItem, BOOL addOriginalItems, id self)
{
	AIAccount			*account = [accountMenuItem representedObject];
	NSMenu				*accountSubmenu;
	NSMenuItem			*statusMenuItem;
	
	if ([account.service isSocialNetworkingService]) {		
		accountSubmenu = socialNetworkingSubmenuForAccount(account, [accountMenuItem target], [accountMenuItem action], self);
		[accountSubmenu setMenuChangedMessagesEnabled:NO];
		
	} else {
		accountSubmenu = [[[NSMenu allocWithZone:[NSMenu zone]] init] autorelease];
		[accountSubmenu setMenuChangedMessagesEnabled:NO];

		//Enumerate all the menu items we were originally passed
		for (statusMenuItem in menuItemArray) {
			AIStatus		*status;
			NSDictionary	*newRepresentedObject;
			NSMenuItem		*actualMenuItem;
			
			//Set the represented object to indicate both the right status and the right account
			if ((status = [[statusMenuItem representedObject] objectForKey:@"AIStatus"])) {
				newRepresentedObject = [[NSDictionary alloc] initWithObjectsAndKeys:
										status, @"AIStatus",
										account, @"AIAccount",
										nil];
			} else {
				//Custom status items don't have an associated AIStatus.
				newRepresentedObject = [[NSDictionary alloc] initWithObjectsAndKeys:
										account, @"AIAccount",
										nil];
			}
			
			if (addOriginalItems) {
				//The last time, we can use the original menu item rather than creating a copy
				actualMenuItem = statusMenuItem;
				[accountSubmenu addItem:statusMenuItem];
				
			} else {
				/* Create a copy of the item for this account and add it to our status menu
				 * (which retains it, so we can release and continue to use the variable)
				 */
				NSMenuItem *newItem = [statusMenuItem copy];
				actualMenuItem = newItem;
				[accountSubmenu addItem:newItem];
				[newItem release];				
			}
			
			[actualMenuItem setRepresentedObject:newRepresentedObject];
			[newRepresentedObject release];
			
			updateRepresentedObjectForSubmenusOfMenuItem(actualMenuItem, account);
		}
	}
	
	NSMenuItem *enableDisableItem;
	
	if (account.enabled) {
		enableDisableItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Disable", nil)
																						target:self
																						action:@selector(toggleAccountEnabled:)
																				 keyEquivalent:@""
																			 representedObject:account];
	} else {
		enableDisableItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Enable", nil)
																						target:self
																						action:@selector(toggleAccountEnabled:)
																				 keyEquivalent:@""
																			 representedObject:account];
	}
	
	[accountSubmenu addItem:[NSMenuItem separatorItem]];
	[accountSubmenu addItem:enableDisableItem];
	[enableDisableItem release];
	
	[accountSubmenu setMenuChangedMessagesEnabled:YES];
	
	return accountSubmenu;
}

/*!
 * @brief Add the passed state menu items to each of our account menu items
 */
- (void)statusMenu:(AIStatusMenu *)inStatusMenu didRebuildStatusMenuItems:(NSArray *)menuItemArray
{
	NSMutableArray		*newMenuItems = [NSMutableArray array];
	NSArray				*accountMenuItems = [self menuItems];
	NSUInteger		accountMenuItemsCount = [accountMenuItems count];
	NSUInteger		i;
	
	//Add status items only if we have more than one account
	if (accountMenuItemsCount <= 1) return;

	for (i = 0; i < accountMenuItemsCount; i++) {
		/* Add the original items the last time; all other times, add copies of the items.
		 * An NSMenuItem can only be in one menu, so we have to make copies for all but one; without this specifier, we'd create one more copy
		 * than necessary, which is	inefficient.
		 */
		BOOL		addOriginalItems = (i == (accountMenuItemsCount - 1));
		NSMenuItem	*menuItem = [accountMenuItems objectAtIndex:i];
		NSMenu		*accountSubmenu = nil;

		if ([[menuItem representedObject] isKindOfClass:[AIAccount class]]) {
			//The menu item is for an AIAccount directly.  Get its status menu
			accountSubmenu = statusMenuForAccountMenuItem(menuItemArray, menuItem, addOriginalItems, self);
			
			if (!addOriginalItems) {
				[newMenuItems addObjectsFromArray:[accountSubmenu itemArray]];
			}
			
			//Add the status menu to our account menu item
			[menuItem setSubmenu:accountSubmenu];
			
		} else {
			//The menu item is not for an AIAccount directly. If it has a submenu of AIAccount-representing NSMenuItems, handle those.
			NSMenu			*thisItemSubmenu;

			if ((thisItemSubmenu = [menuItem submenu])) {
				NSUInteger	thisItemSubmenuCount = [thisItemSubmenu numberOfItems];
				NSUInteger	j;
				
				for (j = 0; j < thisItemSubmenuCount; j++) {
					menuItem = [thisItemSubmenu itemAtIndex:j];

					if ([[menuItem representedObject] isKindOfClass:[AIAccount class]]) {
						BOOL		reallyAddOriginalItems = (addOriginalItems && (j == (thisItemSubmenuCount - 1)));
						accountSubmenu = statusMenuForAccountMenuItem(menuItemArray, menuItem, reallyAddOriginalItems, self);
						
						if (!reallyAddOriginalItems) {
							[newMenuItems addObjectsFromArray:[accountSubmenu itemArray]];
						}
						
						//Add the status menu to our account menu item
						[menuItem setSubmenu:accountSubmenu];
					}
				}
			}
		}
	}
	
	/* Let the statusMenu know about the menuItems we created based on the menuItemArray
	 * we were passed. This will allow it to manage the proper checkboxes.
	 */
	 [statusMenu delegateCreatedMenuItems:newMenuItems];
}

- (void)dummyAction:(id)sender
{
}

@end
