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

#import "RAFBlockEditorWindowController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <AIUtilities/AICompletingTextField.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIService.h>

@interface RAFBlockEditorWindowController ()
- (NSMenu *)privacyOptionsMenu;
- (AIAccount<AIAccount_Privacy> *)selectedAccount;
- (void)configureTextField;
- (NSSet *)contactsFromTextField;
- (AIPrivacyOption)selectedPrivacyOption;
- (void)privacySettingsChangedExternally:(NSNotification *)inNotification;
- (void)runBlockSheet;
- (void)removeSelection;
@end

@implementation RAFBlockEditorWindowController

static RAFBlockEditorWindowController *sharedInstance = nil;

+ (void)showWindow
{	
	if (!sharedInstance) {
		sharedInstance = [[self alloc] initWithWindowNibName:@"BlockEditorWindow"];
	}

	[sharedInstance showWindow:nil];
	[[sharedInstance window] makeKeyAndOrderFront:nil];
}

- (void)windowDidLoad
{
	[[self window] setTitle:AILocalizedString(@"Privacy Settings", nil)];
	[cancelButton setLocalizedString:AILocalizedString(@"Cancel","Cancel button for Privacy Settings")];
	[blockButton setLocalizedString:AILocalizedString(@"Add","Add button for Privacy Settings")];
	[[buddyCol headerCell] setTitle:AILocalizedString(@"Contact","Title of column containing user IDs of blocked contacts")];
	[[accountCol headerCell] setTitle:AILocalizedString(@"Account","Title of column containing blocking accounts")];
	[accountText setLocalizedString:AILocalizedString(@"Account:",nil)];

	{
		//Let the min X margin be resizeable while label_account and label_privacyLevel localize in case the window moves
		[stateChooser setAutoresizingMask:(NSViewMinYMargin | NSViewMinXMargin)];
		[popUp_accounts setAutoresizingMask:(NSViewMinYMargin | NSViewMinXMargin)];

		//Keep label_privacyLevel in place, too, while label_account potentially resizes the window
		[label_privacyLevel setAutoresizingMask:(NSViewMinYMargin | NSViewMinXMargin)];
		[label_account setLocalizedString:AILocalizedString(@"Account:",nil)];
		[label_privacyLevel setAutoresizingMask:(NSViewMinYMargin | NSViewMaxXMargin)];
		//Account is in place; popUp_accounts can width-resize again
		[popUp_accounts setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];

		[label_privacyLevel setLocalizedString:AILocalizedString(@"Privacy level:", nil)];		
		[stateChooser setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
	}

	accountColumnsVisible = YES;
	[accountCol retain];

	listContents = [[NSMutableArray alloc] init];

	[stateChooser setMenu:[self privacyOptionsMenu]];

	[[table tableColumnWithIdentifier:@"icon"] setDataCell:[[[NSImageCell alloc] init] autorelease]];
	
	accountMenu = [[AIAccountMenu accountMenuWithDelegate:self
											  submenuType:AIAccountNoSubmenu
										   showTitleVerbs:NO] retain];
	[table registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListObject", @"AIListObjectUniqueIDs",nil]];

	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(privacySettingsChangedExternally:)
									   name:@"AIPrivacySettingsChangedOutsideOfPrivacyWindow"
									 object:nil];

	// Force an update, so the window will resize properly.
	[self accountMenu:accountMenu didSelectAccount:[self selectedAccount]];	
	
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];

	[super windowDidLoad];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[sharedInstance release]; sharedInstance = nil;
}

- (NSString *)adiumFrameAutosaveName
{
	return @"PrivacyWindow";
}

- (void)dealloc
{
	[accountCol release];
	[accountMenu release];
	[listContents release];
	[listContentsAllAccounts release];
	
	[super dealloc];
}

- (NSMutableArray*)listContents
{
	return listContents;
}

- (void)setListContents:(NSArray*)newList
{
	if (newList != listContents) {
		[listContents release];
		listContents = [newList mutableCopy];
	}
}


- (IBAction)addOrRemoveBlock:(id)sender
{
	NSInteger selectedSegment = [sender selectedSegment];
	
	switch (selectedSegment) {
		case 0:
			[self runBlockSheet];
			break;
		case 1:
			[self removeSelection];
			break;
	}
}

#pragma mark Adding a contact to the list

- (void)selectAccountInSheet:(AIAccount *)inAccount
{
	[popUp_sheetAccounts selectItemWithRepresentedObject:inAccount];
	[self configureTextField];
	
	NSString	*userNameLabel = [inAccount.service userNameLabel];
	
	[accountText setAutoresizingMask:NSViewMinXMargin];
	[buddyText setLocalizedString:[(userNameLabel ?
									userNameLabel : AILocalizedString(@"Contact ID",nil)) stringByAppendingString:AILocalizedString(@":", "Colon which will be appended after a label such as 'User Name', before an input field")]];
	[accountText setAutoresizingMask:NSViewMaxXMargin];
}

- (void)runBlockSheet
{
	[field setStringValue:@""];
	
	sheetAccountMenu = [[AIAccountMenu accountMenuWithDelegate:self
												   submenuType:AIAccountNoSubmenu
												showTitleVerbs:NO] retain];
	[self selectAccountInSheet:[[popUp_sheetAccounts selectedItem] representedObject]];
	
	[NSApp beginSheet:sheet 
	   modalForWindow:[self window]
		modalDelegate:self 
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
}


- (IBAction)cancelBlockSheet:(id)sender
{
    [NSApp endSheet:sheet];
}

- (void)addObject:(AIListContact *)inContact
{
	if (inContact) {
		if (![listContents containsObject:inContact]) {
			[listContents addObject:inContact];
		}
		
		[inContact setIsOnPrivacyList:YES updateList:YES privacyType:(([self selectedPrivacyOption] == AIPrivacyOptionAllowUsers) ?
																	  AIPrivacyTypePermit :
																	  AIPrivacyTypeDeny)];	
	}
}

- (IBAction)didBlockSheet:(id)sender
{
	NSSet *contactArray = [self contactsFromTextField];

	//Add the contact immediately
	if (contactArray && [contactArray count]) {
		AIListContact *contact;
		
		for (contact in contactArray) {
			[self addObject:contact];
		}
		
		[table reloadData];
	}

    [NSApp endSheet:sheet];
}


- (void)didEndSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheetAccountMenu release]; sheetAccountMenu = nil;
    [theSheet orderOut:self];
}

/*!
 * @brief Get a set of all contacts which are represented by the currently selected account and UID field
 *
 * @result A set of AIListContact objects
 */
- (NSSet *)contactsFromTextField
{
	AIListContact	*contact = nil;
	NSString		*UID = nil;
	AIAccount		*account = [[popUp_sheetAccounts selectedItem] representedObject];;
	NSArray			*accountArray;
	NSMutableSet	*contactsSet = [NSMutableSet set];
	NSEnumerator	*enumerator;
	id				impliedValue = [field impliedValue];

	if (account) {
		accountArray = [NSArray arrayWithObject:account];
	} else {
		//All accounts
		NSMutableArray	*tempArray = [NSMutableArray array];
		NSMenuItem		*menuItem;
		
		enumerator = [[[popUp_sheetAccounts menu] itemArray] objectEnumerator];
		while ((menuItem = [enumerator nextObject])) {
			AIAccount *anAccount;
			
			if ((anAccount = [menuItem representedObject])) {
				[tempArray addObject:anAccount];
			}
		}
		
		accountArray = tempArray;
	}

	for (account in accountArray) {
		if ([impliedValue isKindOfClass:[AIMetaContact class]]) {
			AIListContact *containedContact;
			NSEnumerator *contactEnumerator = [[(AIMetaContact *)impliedValue listContactsIncludingOfflineAccounts] objectEnumerator];
			
			while ((containedContact = [contactEnumerator nextObject])) {
				/* For each contact contained my the metacontact, check if its service class matches the current account's.
				 * If it does, add that contact to our list, using the contactController to get an AIListContact specific for the account.
				 */
				if ([containedContact.service.serviceClass isEqualToString:account.service.serviceClass]) {
					if ((contact = [adium.contactController contactWithService:account.service
																		 account:account
																			 UID:containedContact.UID])) {
						[contactsSet addObject:contact];
					}
				}
			}
			
		} else {
			if ([impliedValue isKindOfClass:[AIListContact class]]) {
				UID = [(AIListContact *)impliedValue UID];
			
			} else  if ([impliedValue isKindOfClass:[NSString class]]) {
				UID = [account.service normalizeUID:impliedValue removeIgnoredCharacters:YES];
			}
			
			if (UID) {
				//Get a contact with this UID on the current account
				if ((contact = [adium.contactController contactWithService:account.service
																	 account:account 
																		 UID:UID])) {
					[contactsSet addObject:contact];
				}
			}
		}
			
	}
	
	return contactsSet;
}

- (void)configureTextField
{
	AIAccount *account = [[popUp_sheetAccounts selectedItem] representedObject];
	NSEnumerator		*enumerator;
    AIListContact		*contact;
	
	//Clear the completing strings
	[field setCompletingStrings:nil];
	
	//Configure the auto-complete view to autocomplete for contacts matching the selected account's service
    enumerator = [adium.contactController.allContacts objectEnumerator];
    while ((contact = [enumerator nextObject])) {
		if (!account ||
			contact.service == account.service) {
			NSString *UID = contact.UID;
			[field addCompletionString:contact.formattedUID withImpliedCompletion:UID];
			[field addCompletionString:contact.displayName withImpliedCompletion:UID];
			[field addCompletionString:UID];
		}
    }
}

#pragma mark Removing a contact from the  list

- (void)removeSelection
{
	NSIndexSet		*selectedItems = [table selectedRowIndexes];
	
	// If there's anything selected..
	if ([selectedItems count]) {
		AIListContact	*contact;
		
		// Iterate through the selected rows (backwards)
		for (NSInteger selection = [selectedItems lastIndex]; selection != NSNotFound; selection = [selectedItems indexLessThanIndex:selection]) {
			contact = [listContents objectAtIndex:selection];
			// Remove from the serverside list
			[contact setIsOnPrivacyList:NO updateList:YES privacyType:(([self selectedPrivacyOption] == AIPrivacyOptionAllowUsers) ?
																	   AIPrivacyTypePermit :
																	   AIPrivacyTypeDeny)];
			[listContents removeObject:contact];
		}
		
		[table reloadData];
		[table deselectAll:nil];
	}

}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self removeSelection];
}

- (void)setAccountColumnsVisible:(BOOL)visible
{
	if (accountColumnsVisible != visible) {
		if (visible) {
			[table addTableColumn:accountCol];
		} else {
			[table removeTableColumn:accountCol];			
		}

		[table sizeToFit];
		accountColumnsVisible = visible;
	}
}
#pragma mark Privacy options menu

- (NSMenu *)privacyOptionsMenu
{
	//build the menu of states
	NSMenu *stateMenu = [[NSMenu alloc] init];

	NSMenuItem *menuItem;
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Allow anyone", nil) 
										  action:NULL
								   keyEquivalent:@""];
	[menuItem setTag:AIPrivacyOptionAllowAll];
	[stateMenu addItem:menuItem];
	[menuItem release];

	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Allow only contacts on my contact list", nil) 
										  action:NULL
								   keyEquivalent:@""];
	[menuItem setTag:AIPrivacyOptionAllowContactList];
	[stateMenu addItem:menuItem];
	[menuItem release];

	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Allow only certain contacts", nil) 
										  action:NULL
								   keyEquivalent:@""];
	[menuItem setTag:AIPrivacyOptionAllowUsers];
	[stateMenu addItem:menuItem];
	[menuItem release];

	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Block certain contacts", nil) 
										  action:NULL
								   keyEquivalent:@""];
	[menuItem setTag:AIPrivacyOptionDenyUsers];
	[stateMenu addItem:menuItem];
	[menuItem release];

	/*
	tmpItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Custom settings for each account", nil) action:NULL keyEquivalent:@""];
	[tmpItem setRepresentedObject:[NSNumber numberWithInt:AIPrivacyOptionCustom]];
	[stateMenu addItem:[tmpItem autorelease]];
	*/

	return [stateMenu autorelease];
}

- (AIPrivacyOption)selectedPrivacyOption
{
	return (AIPrivacyOption)[[stateChooser selectedItem] tag];
}

/*!
 * @brief Set a privacy option and update our view for it
 *
 * @param sender If nil, we update our display without attempting to change anything on our account
 */
- (IBAction)setPrivacyOption:(id)sender
{
	AIAccount<AIAccount_Privacy> *account = [self selectedAccount];
	AIPrivacyOption privacyOption = [self selectedPrivacyOption];

	//First, let's get the right tab view selected
	switch (privacyOption) {
		case AIPrivacyOptionAllowAll:
		case AIPrivacyOptionAllowContactList:
		case AIPrivacyOptionCustom:
			if (![[[tabView_contactList selectedTabViewItem] identifier] isEqualToString:@"empty"]) {
				[tabView_contactList selectTabViewItemWithIdentifier:@"empty"];
				[tabView_contactList setHidden:YES];

				NSRect frame = [[self window] frame];
				CGFloat tabViewHeight = [tabView_contactList frame].size.height;
				frame.size.height -= tabViewHeight;
				frame.origin.y += tabViewHeight;
				
				//Don't resize vertically now...
				[tabView_contactList setAutoresizingMask:NSViewWidthSizable];

				[[self window] setMinSize:NSMakeSize(250, frame.size.height)];
				[[self window] setMaxSize:NSMakeSize(CGFLOAT_MAX, frame.size.height)];
				
				AILog(@"Because of privacy option %i, resizing from %@ to %@",privacyOption,
					  NSStringFromRect([[self window] frame]),NSStringFromRect(frame));
				[[self window] setFrame:frame display:YES animate:YES];
			}
			break;
			
		case AIPrivacyOptionAllowUsers:
		case AIPrivacyOptionDenyUsers:
			if (![[[tabView_contactList selectedTabViewItem] identifier] isEqualToString:@"list"]) {
				[tabView_contactList selectTabViewItemWithIdentifier:@"list"];

				NSRect frame = [[self window] frame];
				CGFloat tabViewHeight = [tabView_contactList frame].size.height;
				frame.size.height += tabViewHeight;
				frame.origin.y -= tabViewHeight;
				
				[[self window] setMinSize:NSMakeSize(250, 320)];
				[[self window] setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
				
				//Set frame after fixing our min/max size so the resize won't fail
				AILog(@"Because of privacy option %i, resizing from %@ to %@",privacyOption,
					  NSStringFromRect([[self window] frame]),NSStringFromRect(frame));
				[[self window] setFrame:frame display:YES animate:YES];

				[tabView_contactList setHidden:NO];

				//Allow resizing vertically again
				[tabView_contactList setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
			}
			break;
		case AIPrivacyOptionDenyAll:
		case AIPrivacyOptionUnknown:
			NSLog(@"We should never see these...");
			break;
	}
	
	if (sender) {
		if (account) {
			[account setPrivacyOptions:privacyOption];
			
		} else {
			NSEnumerator	*enumerator = [[[popUp_accounts menu] itemArray] objectEnumerator];
			NSMenuItem						*menuItem;
			AIAccount<AIAccount_Privacy>	*representedAccount;

			while ((menuItem = [enumerator nextObject])) {
				if ((representedAccount = [menuItem representedObject])) {
					[representedAccount setPrivacyOptions:privacyOption];
				}
			}
		}
	}
	
	//Now make our listContents array match the serverside arrays for the selected account(s)
	[listContents removeAllObjects];
	if ((privacyOption == AIPrivacyOptionAllowUsers) ||
		(privacyOption == AIPrivacyOptionDenyUsers)) {
		if (account) {
			[listContents addObjectsFromArray:[account listObjectsOnPrivacyList:((privacyOption == AIPrivacyOptionAllowUsers) ?
																				 AIPrivacyTypePermit :
																				 AIPrivacyTypeDeny)]];		
		} else {
			NSEnumerator					*enumerator = [[[popUp_accounts menu] itemArray] objectEnumerator];
			NSMenuItem						*menuItem;
			AIAccount<AIAccount_Privacy>	*representedAccount;

			while ((menuItem = [enumerator nextObject])) {
				if ((representedAccount = [menuItem representedObject])) {
					[listContents addObjectsFromArray:[representedAccount listObjectsOnPrivacyList:((privacyOption == AIPrivacyOptionAllowUsers) ?
																									AIPrivacyTypePermit :
																									AIPrivacyTypeDeny)]];		
				}
			}
		}
	}

	[table reloadData];
}

- (void)selectPrivacyOption:(AIPrivacyOption)privacyOption
{
	if (privacyOption == AIPrivacyOptionCustom) {
		if (![stateChooser selectItemWithTag:privacyOption]) {
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"(Multiple privacy levels are active)", nil) 
															  action:NULL
													   keyEquivalent:@""];
			[menuItem setTag:AIPrivacyOptionCustom];
			[[stateChooser menu] addItem:menuItem];
			[menuItem release];
			
			[stateChooser selectItemWithTag:privacyOption];
		}

	} else {
		//Not on custom; make sure custom isn't still in the menu
		NSInteger customItemIndex = [stateChooser indexOfItemWithTag:AIPrivacyOptionCustom];
		if (customItemIndex != -1) {
			[[stateChooser menu] removeItemAtIndex:customItemIndex];
		}
	}

	//Now update our view for this privacy option
	[self setPrivacyOption:nil];
}

#pragma mark Account menu
/*!
 * @brief Return the currently selected account, or nil if the 'All' item is selected
 */
- (AIAccount<AIAccount_Privacy> *)selectedAccount
{
	return [[popUp_accounts selectedItem] representedObject];
}

/*!
 * @brief Action called when the account selection changes
 *
 * Update our view and the privacy option menu to be appropriate for the newly selected account.
 * This may be called with a sender of nil by code elsewhere to force an update
 */
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount
{
	if (inAccountMenu == accountMenu) {
		AIAccount<AIAccount_Privacy> *account = [self selectedAccount];
		if (account) {
			//Selected an account
			AIPrivacyOption privacyOption = [account privacyOptions];
			
			//Don't need the account column when we're showing for just one account
			[self setAccountColumnsVisible:NO];

			[self selectPrivacyOption:privacyOption];			

		} else {
			//Selected 'All'. We need to determine what privacy option to display for the set of all accounts.
			AIPrivacyOption currentState = AIPrivacyOptionUnknown;
			NSEnumerator	*enumerator = [[[popUp_accounts menu] itemArray] objectEnumerator];
			NSMenuItem		*menuItem;
			
			while ((menuItem = [enumerator nextObject])) {
				if ((account = [menuItem representedObject])) {
					AIPrivacyOption accountState = [account privacyOptions];
					
					if (currentState == AIPrivacyOptionUnknown) {
						//We don't know the state of an account yet
						currentState = accountState;
					} else if (accountState != currentState) {
						currentState = AIPrivacyOptionCustom;
					}				
				}
			}
			
			[self setAccountColumnsVisible:YES];

			[self selectPrivacyOption:currentState];
		}

	} else if (inAccountMenu == sheetAccountMenu) {
		//Update our sheet for the current account
		[self selectAccountInSheet:inAccount];
	}
}

/*!
 * @brief The 'All' menu item for accounts was selected
 *
 * We simulate an AIAccountMenu delegate call, since the All item was added by RAFBLockEditorWindowController.
 */
- (IBAction)selectedAllAccountItem:(id)sender
{
	AIAccountMenu *relevantAccountMenu = (([sender menu] == [popUp_accounts menu]) ?
										  accountMenu :
										  sheetAccountMenu);

	[self accountMenu:relevantAccountMenu didSelectAccount:nil];
}

/*!
 * @brief Select an account in our account menu, then update everything else to be appropriate for it
 */
- (void)selectAccount:(AIAccount *)inAccount
{
	[popUp_accounts selectItemWithRepresentedObject:inAccount];
	
	[self accountMenu:accountMenu didSelectAccount:inAccount];
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
	AIAccount	 *previouslySelectedAccount = nil;
	NSMenuItem	 *menuItem;
	NSMenu		 *menu = [[NSMenu alloc] init];

	/*
	 * accountMenu isn't set the first time we get here as the accountMenu is created. Similarly, sheetAccountMenu isn't created its first time.
	 * This code makes the (true) assumption that accountMenu is _always_ created before sheetAccountMenu.
	 */	
	BOOL isPrimaryAccountMenu = (!accountMenu || (inAccountMenu == accountMenu));

	if (isPrimaryAccountMenu) {
		if ([popUp_accounts menu]) {
			previouslySelectedAccount = [[popUp_accounts selectedItem] representedObject];
		}
	} else if (inAccountMenu == sheetAccountMenu) {
		if ([popUp_sheetAccounts menu]) {
			previouslySelectedAccount = [[popUp_sheetAccounts selectedItem] representedObject];
		}		
	}

	/*
	 * As we enumerate, we:
	 *	1) Determine what state the accounts within the menu are in
	 *  2) Add the menu items to our menu
	 */
	for (menuItem in menuItems) {		
		[menu addItem:menuItem];
	}

	if (isPrimaryAccountMenu) {
		[popUp_accounts setMenu:menu];

		/* Restore the previous account selection if there was one.
		 * Whether there was one or not, this will cause the rest of our view update to match the new/current selection
		 */
		[self selectAccount:previouslySelectedAccount];

	} else {
		[popUp_sheetAccounts setMenu:menu];
		
		[self selectAccountInSheet:previouslySelectedAccount];
	}

	[menu release];
}

//Add the All menu item first if we have more than one account listed
- (NSMenuItem *)accountMenuSpecialMenuItem:(AIAccountMenu *)inAccountMenu
{
	NSMenuItem	*allItem = nil;
	int			numberOfOnlineAccounts = 0;
	
	for (AIAccount *account in adium.accountController.accounts) {
		if ([self accountMenu:inAccountMenu shouldIncludeAccount:account]) {
			numberOfOnlineAccounts += 1;
			if (numberOfOnlineAccounts > 1) {
				allItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"All", nil)
													  target:self
													  action:@selector(selectedAllAccountItem:)
											   keyEquivalent:@""] autorelease];
				break;
			}
		}
	}
	
	return allItem;
}

- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount
{
	BOOL isPrimaryAccountMenu = (!accountMenu || (inAccountMenu == accountMenu));

	if (isPrimaryAccountMenu) {
		return (inAccount.online &&
				[inAccount conformsToProtocol:@protocol(AIAccount_Privacy)]);
	} else {
		AIAccount *selectedPrimaryAccount = self.selectedAccount;
		if (selectedPrimaryAccount) {
			//An account is selected in the main window; only incldue that account in our sheet
			return (inAccount == selectedPrimaryAccount);

		} else {
			//'All' is selected in the main window; include all accounts which are online and support privacy
			return (inAccount.online &&
					[inAccount conformsToProtocol:@protocol(AIAccount_Privacy)]);			
		}
	}
}

- (void)privacySettingsChangedExternally:(NSNotification *)inNotification
{
	[self accountMenu:accountMenu didSelectAccount:[self selectedAccount]];	
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inModifiedKeys containsObject:KEY_IS_BLOCKED]) {
		[self privacySettingsChangedExternally:nil];
	}
	
	return nil;
}

#pragma mark Table view

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [listContents count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString		*identifier = [aTableColumn identifier];
	AIListContact	*contact = [listContents objectAtIndex:rowIndex];

	if ([identifier isEqualToString:@"icon"]) {
		return [contact menuIcon];
		
	} else if ([identifier isEqualToString:@"contact"]) {
		return contact.formattedUID;

	} else if ([identifier isEqualToString:@"account"]) {
		return contact.account.formattedUID;
	}
	
	return nil;
}

- (BOOL)writeListObjects:(NSArray *)inArray toPasteboard:(NSPasteboard*)pboard
{
	[pboard declareTypes:[NSArray arrayWithObjects:@"AIListObject",@"AIListObjectUniqueIDs",nil] owner:self];
	[pboard setString:@"Private" forType:@"AIListObject"];

	if (dragItems != inArray) {
		[dragItems release];
		dragItems = [inArray retain];
	}
	
	return YES;
}

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{	
	NSMutableArray 	*itemArray = [NSMutableArray array];
	NSNumber		*rowNumber;
	for (rowNumber in rows) {
		[itemArray addObject:[listContents objectAtIndex:[rowNumber integerValue]]];
	}

	return [self writeListObjects:itemArray toPasteboard:pboard];
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	NSMutableArray 	*itemArray = [NSMutableArray array];
	id 				item;
	
	NSUInteger bufSize = [rowIndexes count];
	NSUInteger *buf = malloc(bufSize * sizeof(NSUInteger));
	NSUInteger i;
	
	NSRange range = NSMakeRange([rowIndexes firstIndex], ([rowIndexes lastIndex]-[rowIndexes firstIndex]) + 1);
	[rowIndexes getIndexes:buf maxCount:bufSize inIndexRange:&range];
	
	for (i = 0; i != bufSize; i++) {
		if ((item = [listContents objectAtIndex:buf[i]])) {
			[itemArray addObject:item];
		}
	}
	
	free(buf);
	
	return [self writeListObjects:itemArray toPasteboard:pboard];
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
	//Provide an array of internalObjectIDs which can be used to reference all the dragged contacts
	if ([type isEqualToString:@"AIListObjectUniqueIDs"]) {
		
		if (dragItems) {
			NSMutableArray	*dragItemsArray = [NSMutableArray array];
			AIListObject	*listObject;
			
			for (listObject in dragItems) {
				[dragItemsArray addObject:listObject.internalObjectID];
			}
			
			[sender setPropertyList:dragItemsArray forType:@"AIListObjectUniqueIDs"];
		}
	}
}

- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
    
    NSDragOperation dragOp = NSDragOperationCopy;
	
    if ([info draggingSource] == table) {
		dragOp =  NSDragOperationMove;
    }
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOp;
}

- (void)addListObjectToList:(AIListObject *)listObject
{
	AIListObject *containedObject;
	NSEnumerator *enumerator;

	if ([listObject isKindOfClass:[AIListGroup class]]) {
		enumerator = [[(AIListGroup *)listObject uniqueContainedObjects] objectEnumerator];
		while ((containedObject = [enumerator nextObject])) {
			[self addListObjectToList:containedObject];
		}

	} else if ([listObject isKindOfClass:[AIMetaContact class]]) {
		enumerator = [[(AIMetaContact *)listObject uniqueContainedObjects] objectEnumerator];
		while ((containedObject = [enumerator nextObject])) {
			[self addListObjectToList:containedObject];
		}

	} else if ([listObject isKindOfClass:[AIListContact class]]) {
		//if the account for this contact is connected...
		if ([(AIListContact *)listObject account].online) {
			[self addObject:(AIListContact *)listObject];
		}
	}
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
	BOOL accept = NO;

	if ([info.draggingPasteboard.types containsObject:@"AIListObjectUniqueIDs"]) {
		for (NSString *uniqueUID in [info.draggingPasteboard propertyListForType:@"AIListObjectUniqueIDs"])
			[self addListObjectToList:[adium.contactController existingListObjectWithUniqueID:uniqueUID]];
		accept = YES;
	}
	
    return accept;
}

@end
