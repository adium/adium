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
#import "AIAccountListPreferences.h"
#import <Adium/AIContactControllerProtocol.h>
#import "AIStatusController.h"
#import "AIEditAccountWindowController.h"
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>
#import <AIUtilities/AITableViewAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIAccountMenu.h>
#import <Adium/AIListObject.h>
#import <Adium/AIService.h>
#import <Adium/AIStatusMenu.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIServiceMenu.h>
#import <Adium/AIStatusIcons.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import "KFTypeSelectTableView.h"

#define MINIMUM_ROW_HEIGHT				34
#define MINIMUM_CELL_SPACING			 4

#define	ACCOUNT_DRAG_TYPE				@"AIAccount"	    			//ID for an account drag

#define NEW_ACCOUNT_DISPLAY_TEXT		AILocalizedString(@"<New Account>", "Placeholder displayed as the name of a new account")

@interface AIAccountListPreferences (PRIVATE)
- (void)configureAccountList;
- (void)accountListChanged:(NSNotification *)notification;

- (void)calculateHeightForRow:(int)row;
- (void)calculateAllHeights;

- (void)updateReconnectTime:(NSTimer *)timer;
@end

/*!
 * @class AIAccountListPreferences
 * @brief Shows a list of accounts and provides for management of them
 */
@implementation AIAccountListPreferences

/*!
 * @brief Preference pane properties
 */
- (NSString *)paneIdentifier
{
	return @"Accounts";
}
- (NSString *)paneName{
    return AILocalizedString(@"Accounts","Accounts preferences label");
}
- (NSString *)nibName{
    return @"AccountListPreferences";
}
- (NSImage *)paneIcon
{
	return [NSImage imageNamed:@"pref-accounts" forClass:[self class]];
}

/*!
 * @brief Configure the view initially
 */
- (void)viewDidLoad
{
	//Configure the account list
	[self configureAccountList];
	[self updateAccountOverview];
	
	//Build the 'add account' menu of each available service
	NSMenu	*serviceMenu = [AIServiceMenu menuOfServicesWithTarget:self 
												activeServicesOnly:NO
												   longDescription:YES
															format:AILocalizedString(@"%@",nil)];
	[serviceMenu setAutoenablesItems:YES];
	
	//Indent each item in the service menu one level
	NSEnumerator	*enumerator = [[serviceMenu itemArray] objectEnumerator];
	NSMenuItem		*menuItem;
	while ((menuItem = [enumerator nextObject])) {
		[menuItem setIndentationLevel:[menuItem indentationLevel]+1];
	}

	//Add a label to the top of the menu to clarify why we're showing this list of services
	[serviceMenu insertItemWithTitle:AILocalizedString(@"Add an account for:",nil)
							  action:NULL
					   keyEquivalent:@""
							 atIndex:0];
	
	//Assign the menu
	[button_newAccount setMenu:serviceMenu];
	
	//Set ourselves up for Account Menus
	accountMenu_options = [[AIAccountMenu accountMenuWithDelegate:self
													  submenuType:AIAccountOptionsSubmenu
												   showTitleVerbs:NO] retain];
	
	accountMenu_status = [[AIAccountMenu accountMenuWithDelegate:self
													 submenuType:AIAccountStatusSubmenu
												  showTitleVerbs:NO] retain];

	//Observe status icon pack changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(iconPackDidChange:)
									   name:AIStatusIconSetDidChangeNotification
									 object:nil];
	
	//Observe service icon pack changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(iconPackDidChange:)
									   name:AIServiceIconSetDidChangeNotification
									 object:nil];
	
	[tableView_accountList accessibilitySetOverrideValue:AILocalizedString(@"Accounts", nil)
											forAttribute:NSAccessibilityRoleDescriptionAttribute];

	// Start updating the reconnect time if an account is already reconnecting.	
	[self updateReconnectTime:nil];
}

/*!
 * @brief Perform actions before the view closes
 */
- (void)viewWillClose
{
	[[adium contactController] unregisterListObjectObserver:self];
	[[adium notificationCenter] removeObserver:self];
	
	[accountArray release]; accountArray = nil;
	[requiredHeightDict release]; requiredHeightDict = nil;
	[accountMenu_options release]; accountMenu_options = nil;
	[accountMenu_status release]; accountMenu_status = nil;
	
	// Cancel our auto-refreshing reconnect countdown.
	[reconnectTimeUpdater invalidate];
	[reconnectTimeUpdater release]; reconnectTimeUpdater = nil;
}

- (void)dealloc
{
	[accountArray release];
	[super dealloc];
}

/*!
 * @brief Account status changed.
 *
 * Disable the service menu and user name field for connected accounts
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		if ([inModifiedKeys containsObject:@"Online"] ||
			[inModifiedKeys containsObject:@"Enabled"] ||
		   [inModifiedKeys containsObject:@"Connecting"] ||
		   [inModifiedKeys containsObject:@"Waiting to Reconnect"] ||
		   [inModifiedKeys containsObject:@"Disconnecting"] ||
		   [inModifiedKeys containsObject:@"ConnectionProgressString"] ||
		   [inModifiedKeys containsObject:@"ConnectionProgressPercent"] ||
		   [inModifiedKeys containsObject:@"Waiting for Network"] ||
		   [inModifiedKeys containsObject:@"IdleSince"] ||
		   [inModifiedKeys containsObject:@"StatusState"]) {

			//Refresh this account in our list
			int accountRow = [accountArray indexOfObject:inObject];
			if (accountRow >= 0 && accountRow < [accountArray count]) {
				[tableView_accountList setNeedsDisplayInRect:[tableView_accountList rectOfRow:accountRow]];
				// Update the height of the row.
				[self calculateHeightForRow:accountRow];
				[tableView_accountList noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:accountRow]];

				// If necessary, update our reconnection display time.
				if (!reconnectTimeUpdater) {
					[self updateReconnectTime:nil];
				}
			}
			
			//Update our account overview
			[self updateAccountOverview];
		}
	}
    
    return nil;
}

//Actions --------------------------------------------------------------------------------------------------------------
#pragma mark Actions
/*!
 * @brief Create a new account
 *
 * Called when a service type is selected from the Add menu
 */
- (IBAction)selectServiceType:(id)sender
{
	AIService	*service = [sender representedObject];
	AIAccount	*account = [[adium accountController] createAccountWithService:service
																		   UID:[service defaultUserName]];

	[AIEditAccountWindowController editAccount:account
									  onWindow:[[self view] window]
							   notifyingTarget:self];
}

- (void)editAccount:(AIAccount *)inAccount
{
	[AIEditAccountWindowController editAccount:inAccount
									  onWindow:[[self view] window]
							   notifyingTarget:self];	
}

/*!
 * @brief Edit the currently selected account using <tt>AIEditAccountWindowController</tt>
 */
- (IBAction)editSelectedAccount:(id)sender
{
    int	selectedRow = [tableView_accountList selectedRow];
	if ([tableView_accountList numberOfSelectedRows] == 1 && selectedRow >= 0 && selectedRow < [accountArray count]) {
		[self editAccount:[accountArray objectAtIndex:selectedRow]];
    }
}

/*!
 * @brief Handle a double click within our table
 *
 * Ignore double clicks on the enable/disable checkbox
 */
- (void)doubleClickInTableView:(id)sender
{
	if (!(NSPointInRect([tableView_accountList convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil],
						[tableView_accountList rectOfColumn:[tableView_accountList columnWithIdentifier:@"enabled"]]))) {
		[self editSelectedAccount:sender];
	}
}

/*!
 * @brief Editing of an account completed
 */
- (void)editAccountSheetDidEndForAccount:(AIAccount *)inAccount withSuccess:(BOOL)successful
{
	BOOL existingAccount = ([[[adium accountController] accounts] containsObject:inAccount]);
	
	if (!existingAccount && successful) {
		//New accounts need to be added to our account list once they're configured
		[[adium accountController] addAccount:inAccount];

		//Scroll the new account visible so that the user can see we added it
		[tableView_accountList scrollRowToVisible:[accountArray indexOfObject:inAccount]];
		
		//Put new accounts online by default
		[inAccount setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
	} else if (existingAccount && successful && [inAccount enabled]) {
		//If the user edited an account that is "reconnecting" or "connecting", disconnect it and try to reconnect.
		if ([[inAccount valueForProperty:@"Connecting"] boolValue] ||
			[inAccount valueForProperty:@"Waiting to Reconnect"]) {
			// Stop connecting or stop waiting to reconnect.
			[inAccount setShouldBeOnline:NO];
			// Connect it.
			[inAccount setShouldBeOnline:YES];
		}
	}	
}

/*!
 * @brief Delete the selected account
 *
 * Prompts for confirmation first
 */
- (IBAction)deleteAccount:(id)sender
{
    int index = [tableView_accountList selectedRow];

    if ([tableView_accountList numberOfSelectedRows] == 1 && index >= 0 && index < [accountArray count]) {
		[[(AIAccount *)[accountArray objectAtIndex:index] confirmationDialogForAccountDeletion] beginSheetModalForWindow:[[self view] window]];
	}
}

/*!
* @brief Toggles an account online or offline.
 */
- (void)toggleShouldBeOnline:(id)sender
{
	AIAccount		*account = [sender representedObject];
	if (![account enabled])
		[account setEnabled:YES];
	else
		[account toggleOnline];
}

#pragma mark AIAccountMenu Delegates

/*!
* @brief AIAccountMenu delieate method
 */
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems {
	return;
}

/*!
* @brief AIAccountMenu delegate method -- this allows disabled items to have menus.
 */
- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount
{
	return YES;
}

//Account List ---------------------------------------------------------------------------------------------------------
#pragma mark Account List
/*!
 * @brief Configure the account list table
 */
- (void)configureAccountList
{
    AIImageTextCell		*cell;
	NSRect				oldFrame, newFrame;
	
	//Setup our edit button, keeping its right side in the same location
	oldFrame = [button_editAccount frame];
	[button_editAccount setTitle:AILocalizedStringFromTable(@"Edit", @"Buttons", "Verb 'edit' on a button")];
	[button_editAccount sizeToFit];
	newFrame = [button_editAccount frame];
	if (newFrame.size.width < oldFrame.size.width) newFrame.size.width = oldFrame.size.width;
	newFrame.origin.x = oldFrame.origin.x + oldFrame.size.width - newFrame.size.width;
	[button_editAccount setFrame:newFrame];

	//Configure our table view
	[tableView_accountList setTarget:self];
	[tableView_accountList setDoubleAction:@selector(doubleClickInTableView:)];
	[tableView_accountList setIntercellSpacing:NSMakeSize(MINIMUM_CELL_SPACING, MINIMUM_CELL_SPACING)];

	//Enable dragging of accounts
	[tableView_accountList registerForDraggedTypes:[NSArray arrayWithObjects:ACCOUNT_DRAG_TYPE,nil]];
	
    //Custom vertically-centered text cell for account names
	/*
	cell = [[AIBlankCell alloc] init];
	[[tableView_accountList tableColumnWithIdentifier:@"blank1"] setDataCell:cell];
	[[tableView_accountList tableColumnWithIdentifier:@"blank2"] setDataCell:cell];
	[cell release];
	*/
	
    cell = [[AIImageTextCell alloc] init];
    [cell setFont:[NSFont boldSystemFontOfSize:13]];
	[cell setDrawsImageAfterMainString:YES];
    [[tableView_accountList tableColumnWithIdentifier:@"name"] setDataCell:cell];
	[cell setLineBreakMode:NSLineBreakByWordWrapping];
	[cell release];

    cell = [[AIImageTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:13]];
    [cell setAlignment:NSRightTextAlignment];
	[cell setLineBreakMode:NSLineBreakByWordWrapping];
    [[tableView_accountList tableColumnWithIdentifier:@"status"] setDataCell:cell];
	[cell accessibilitySetOverrideValue:[NSNumber numberWithBool:YES]
						   forAttribute:NSAccessibilityEnabledAttribute];
	[cell release];
    
	[tableView_accountList sizeToFit];

	//Observe changes to the account list
    [[adium notificationCenter] addObserver:self
								   selector:@selector(accountListChanged:) 
									   name:Account_ListChanged 
									 object:nil];
	[self accountListChanged:nil];
	
	//Observe accounts so we can display accurate status
    [[adium contactController] registerListObjectObserver:self];
}

/*!
 * @brief Account list changed, refresh our table
 */
- (void)accountListChanged:(NSNotification *)notification
{
    //Update our list of accounts
    [accountArray release];
	accountArray = [[[adium accountController] accounts] retain];

	//Refresh the account table
	[tableView_accountList reloadData];
	[self updateControlAvailability];
	[self updateAccountOverview];
	[self calculateAllHeights];
}

/*!
 * @brief Returns the status menu associated with several rows
 */
- (NSMenu *)menuForRowIndexes:(NSIndexSet *)indexes
{
	NSMenu			*statusMenu = nil, *optionsMenu = [[[NSMenu alloc] init] autorelease];
	NSMenuItem		*statusMenuItem = nil;
	NSArray			*accounts = [accountArray objectsAtIndexes:indexes];
	AIAccount		*account;
	NSEnumerator	*enumerator = [accounts objectEnumerator];
	BOOL			atLeastOneDisabledAccount = NO, atLeastOneOfflineAccount = NO;
	
	// Check the accounts' enabled/disabled and online/offline status.
	while ((account = [enumerator nextObject])) {
		if (![account enabled])
			atLeastOneDisabledAccount = YES;
		
		if (![account online] && ![[account valueForProperty:@"Connecting"] boolValue])
			atLeastOneOfflineAccount = YES;
		
		if (atLeastOneOfflineAccount && atLeastOneDisabledAccount)
			break;
	}
	
	statusMenuItem = [optionsMenu addItemWithTitle:AILocalizedString(@"Set Status", "Used in the context menu for the accounts list for the sub menu to set status in.")
											target:nil
											action:nil
									 keyEquivalent:@""];

	statusMenu = [AIStatusMenu staticStatusStatesMenuNotifyingTarget:self
														selector:@selector(updateAccountsForStatus:)];
	[statusMenuItem setSubmenu:statusMenu];
	
	//If any accounts are offline, present the option to connect them all.
	if (atLeastOneOfflineAccount) {
		[optionsMenu addItemWithTitle:AILocalizedString(@"Connect",nil)
							   target:self
							   action:@selector(toggleOnlineForAccounts:)
						keyEquivalent:@""
					representedObject:[NSDictionary dictionaryWithObjectsAndKeys:accounts,@"Accounts",
						[NSNumber numberWithBool:YES],@"Connect",nil]];
	}
	[optionsMenu addItemWithTitle:AILocalizedString(@"Disconnect",nil)
						   target:self
						   action:@selector(toggleOnlineForAccounts:)
					keyEquivalent:@""
				representedObject:[NSDictionary dictionaryWithObjectsAndKeys:accounts,@"Accounts",
					[NSNumber numberWithBool:NO],@"Connect",nil]];
	
	[optionsMenu addItem:[NSMenuItem separatorItem]];
	
	// If any accounts are disable,d show the option to enable them.
	if (atLeastOneDisabledAccount) {
		[optionsMenu addItemWithTitle:AILocalizedString(@"Enable",nil)
							   target:self
							   action:@selector(toggleEnabledForAccounts:)
						keyEquivalent:@""
					representedObject:[NSDictionary dictionaryWithObjectsAndKeys:accounts,@"Accounts",
						[NSNumber numberWithBool:YES],@"Enable",nil]];
		
	}
	[optionsMenu addItemWithTitle:AILocalizedString(@"Disable",nil)
						   target:self
						   action:@selector(toggleEnabledForAccounts:)
					keyEquivalent:@""
				representedObject:[NSDictionary dictionaryWithObjectsAndKeys:accounts,@"Accounts",
					[NSNumber numberWithBool:NO],@"Enable",nil]];
	
	return optionsMenu;
}

/*!
 * @brief Callback for the Connect/Disconnect menu item in a multiple account selection
 */
- (void)toggleOnlineForAccounts:(id)sender
{
	NSDictionary		*dict		= [sender representedObject];
	NSEnumerator		*enumerator	= [[dict objectForKey:@"Accounts"] objectEnumerator];
	BOOL				connect		= [[dict objectForKey:@"Connect"] boolValue];
	AIAccount			*account;

	while ((account = [enumerator nextObject])) {
		if (![account enabled] && connect)
			[account setEnabled:YES];
		[account setShouldBeOnline:connect];
	}
}

/*!
 * @brief Callback for the Enable/Disable menu item in a multiple account selection
 */
- (void)toggleEnabledForAccounts:(id)sender
{
	NSDictionary		*dict		= [sender representedObject];
	NSEnumerator		*enumerator	= [[dict objectForKey:@"Accounts"] objectEnumerator];
	BOOL				enable		= [[dict objectForKey:@"Enable"] boolValue];
	AIAccount			*account;

	while ((account = [enumerator nextObject])) {
		[account setEnabled:enable];
	}	
}

/*!
 * @brief Callback for the Set Status menu item in a multiple-account selection
 */
- (void)updateAccountsForStatus:(id)sender
{
	NSEnumerator	*enumerator	= [[accountArray objectsAtIndexes:[tableView_accountList selectedRowIndexes]] objectEnumerator];
	AIStatus		*status		= [[sender representedObject] objectForKey:@"AIStatus"];
	AIAccount		*account;
	
	while ((account = [enumerator nextObject])) {
		[account setStatusState:status];
		
		//Enable the account if it isn't currently enabled and this isn't an offline status
		if (![account enabled] && [status statusType] != AIOfflineStatusType) {
			[account setEnabled:YES];
		}
	}
}

/*!
* @brief Callback for the Copy Error Message menu item for an account
 */
- (void)copyStatusMessage:(id)sender
{
	NSPasteboard		*generalPasteboard = [NSPasteboard generalPasteboard];
	
	[generalPasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType]
							  owner:nil];
	[generalPasteboard setString:[self statusMessageForAccount:[sender representedObject]]
						 forType:NSStringPboardType];
}

/*!
 * @brief Returns the status menu associated with a particular row
 */
- (NSMenu *)menuForRow:(int)row
{
	if (row >= 0 && row < [accountArray count]) {
		AIAccount		*account = [accountArray objectAtIndex:row];
		NSMenu			*optionsMenu = [[[NSMenu alloc] init] autorelease];
		NSMenu			*accountOptionsMenu = [[accountMenu_options menuItemForAccount:account] submenu];

		NSMenuItem	*statusMenuItem = [optionsMenu addItemWithTitle:AILocalizedString(@"Set Status", "Used in the context menu for the accounts list for the sub menu to set status in.")
															 target:nil
															 action:nil
													  keyEquivalent:@""];

		//We can't put the submenu into our menu directly or otherwise modify the accountMenu_status, as we may want to use it again
		[statusMenuItem setSubmenu:[[[[accountMenu_status menuItemForAccount:account] submenu] copy] autorelease]];
		
		if (![account online] && ![[account valueForProperty:@"Connecting"] boolValue] && [self statusMessageForAccount:account]) {
			[optionsMenu addItemWithTitle:AILocalizedString(@"Copy Error Message","Menu Item for the context menu of an account in the accounts list")
								   target:self
								   action:@selector(copyStatusMessage:)
							keyEquivalent:@""
						representedObject:account];
		}
		
		if ([[statusMenuItem submenu] numberOfItems] >= 2) {
			//Remove the 'Disable' item
			[[statusMenuItem submenu] removeItemAtIndex:([[statusMenuItem submenu] numberOfItems] - 1)];
			
			//And remove the separator above it
			[[statusMenuItem submenu] removeItemAtIndex:([[statusMenuItem submenu] numberOfItems] - 1)];
		}
		
		//Connect or disconnect the account. Enabling a disabled account will connect it, so this is only valid for non-disabled accounts.
		//Only online & connecting can be "Disconnected"; those offline or waiting to reconnect can be "Connected"
		[optionsMenu addItemWithTitle:(([account online] || [[account valueForProperty:@"Connecting"] boolValue]) ?
									   AILocalizedString(@"Disconnect",nil) :
									   AILocalizedString(@"Connect",nil))
							   target:self
							   action:@selector(toggleShouldBeOnline:)
						keyEquivalent:@""
					representedObject:account];
				
		//Add a separator if we have any items shown so far
		[optionsMenu addItem:[NSMenuItem separatorItem]];
		
		//Add account options
		NSMenuItem *menuItem;
		NSEnumerator *enumerator = [[accountOptionsMenu itemArray] objectEnumerator];
		while ((menuItem = [enumerator nextObject])) {
			//Use copies of the menu items rather than moving the actual items, as we may want to use them again
			[optionsMenu addItem:[[menuItem copy] autorelease]];
		}

		return optionsMenu;
	}
	
	return nil;
}

/*!
 * @brief Updates reconnecting time where necessary.
 */
- (void)updateReconnectTime:(NSTimer *)timer
{
	int				accountRow;
	BOOL			moreUpdatesNeeded = NO;

	for (accountRow = 0; accountRow < [accountArray count]; accountRow++) {
		if ([[accountArray objectAtIndex:accountRow] valueForProperty:@"Waiting to Reconnect"] != nil) {
			[tableView_accountList setNeedsDisplayInRect:[tableView_accountList rectOfRow:accountRow]];
			moreUpdatesNeeded = YES;
		}
	}

	if (moreUpdatesNeeded && reconnectTimeUpdater == nil) {
		reconnectTimeUpdater = [[NSTimer scheduledTimerWithTimeInterval:1.0
																 target:self 
															   selector:@selector(updateReconnectTime:) 
															   userInfo:nil
																repeats:YES] retain];
	} else if (!moreUpdatesNeeded && reconnectTimeUpdater != nil) {
		[reconnectTimeUpdater invalidate];
		[reconnectTimeUpdater release]; reconnectTimeUpdater = nil;
	}
}

/*!
 * @brief Status icons changed, refresh our table
 */
- (void)iconPackDidChange:(NSNotification *)notification
{
	[tableView_accountList reloadData];
}

/*!
 * @brief Update our account overview
 *
 * The overview indicates the total number of accounts and the number which are online.
 */
- (void)updateAccountOverview
{
	NSString	*accountOverview;
	int			accountArrayCount = [accountArray count];

	if (accountArrayCount == 0) {
		accountOverview = AILocalizedString(@"Click the + to add a new account","Instructions on how to add an account when none are present");

	} else {
		NSEnumerator	*enumerator = [accountArray objectEnumerator];
		AIAccount		*account;
		int				online = 0, enabled = 0;
		
		//Count online accounts
		while ((account = [enumerator nextObject])) {
			if ([account online]) online++;
			if ([account enabled]) enabled++;
		}
		
		if (enabled) {
			if ((accountArrayCount == enabled) ||
				(online == enabled)){
				accountOverview = [NSString stringWithFormat:AILocalizedString(@"%i accounts, %i online","Overview of total and online accounts"),
					accountArrayCount,
					online];
			} else {
				accountOverview = [NSString stringWithFormat:AILocalizedString(@"%i accounts, %i enabled, %i online","Overview of total, enabled, and online accounts"),
					accountArrayCount,
					enabled,
					online];			
			}
		} else {
			accountOverview = AILocalizedString(@"Check a box to enable an account","Instructions for enabling an account");
		}
	}

	[textField_overview setStringValue:accountOverview];
}

/*!
 * @brief Update control availability based on list selection
 */
- (void)updateControlAvailability
{
	BOOL	selection = ([tableView_accountList numberOfSelectedRows] == 1 && [tableView_accountList selectedRow] != -1);

	[button_editAccount setEnabled:selection];
	[button_deleteAccount setEnabled:selection];
}

/*!
* @brief Returns the status string associated with the account
 *
 * Returns a connection status if connecting, or an error if disconnected with an error
 */
- (NSString *)statusMessageForAccount:(AIAccount *)account
{
	NSString *statusMessage = nil;
	
	if ([account valueForProperty:@"ConnectionProgressString"] && [[account valueForProperty:@"Connecting"] boolValue]) {
		// Connection status if we're currently connecting, with the percent at the end
		statusMessage = [[account valueForProperty:@"ConnectionProgressString"] stringByAppendingFormat:@" (%2.f%%)", [[account valueForProperty:@"ConnectionProgressPercent"] floatValue]*100.0];
	} else if ([account lastDisconnectionError] && ![[account valueForProperty:@"Online"] boolValue] && ![[account valueForProperty:@"Connecting"] boolValue]) {
		// If there's an error and we're not online and not connecting
		NSMutableString *returnedMessage = [[[account lastDisconnectionError] mutableCopy] autorelease];
		
		// Replace the LibPurple error prefixes
		[returnedMessage replaceOccurrencesOfString:@"Could not establish a connection with the server:\n"
										 withString:@""
											options:NSLiteralSearch
											  range:NSMakeRange(0, [returnedMessage length])];
		[returnedMessage replaceOccurrencesOfString:@"Connection error from Notification server:\n"
										 withString:@""
											options:NSLiteralSearch
											  range:NSMakeRange(0, [returnedMessage length])];
		[returnedMessage replaceOccurrencesOfString:@"Could not connect to authentication server:\n"
										 withString:@""
											options:NSLiteralSearch
											  range:NSMakeRange(0, [returnedMessage length])];

		// Remove newlines from the error message, replace them with spaces
		[returnedMessage replaceOccurrencesOfString:@"\n"
										 withString:@" "
											options:NSLiteralSearch
											  range:NSMakeRange(0, [returnedMessage length])];
		
		statusMessage = [NSString stringWithFormat:@"%@: %@", AILocalizedString(@"Error", "Prefix to error messages in the Account List."), returnedMessage];
	}
	
	return statusMessage;
}

/*!
* @brief Calculates the height of a given row and stores it
 */
- (void)calculateHeightForRow:(int)row
{	
	// Make sure this is a valid row.
	if (row < 0 || row >= [accountArray count]) {
		return;
	}
	
	AIAccount		*account = [accountArray objectAtIndex:row];
	float			necessaryHeight = MINIMUM_ROW_HEIGHT;
	
	// If there's a status message, let's try size to fit it.
	if ([self statusMessageForAccount:account]) {
		NSTableColumn		*tableColumn = [tableView_accountList tableColumnWithIdentifier:@"name"];
		
		[self tableView:tableView_accountList willDisplayCell:[tableColumn dataCell] forTableColumn:tableColumn row:row];
		
		// Main string (account name)
		NSDictionary		*mainStringAttributes	= [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:13], NSFontAttributeName, nil];
		NSAttributedString	*mainTitle = [[NSAttributedString alloc] initWithString:([[account formattedUID] length] ? [account formattedUID] : NEW_ACCOUNT_DISPLAY_TEXT)
																		 attributes:mainStringAttributes];
		
		// Substring (the status message)
		NSDictionary		*subStringAttributes	= [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:10], NSFontAttributeName, nil];
		NSAttributedString	*subStringTitle = [[NSAttributedString alloc] initWithString:[self statusMessageForAccount:account]
																			  attributes:subStringAttributes];
		
		// Both heights combined, with spacing in-between
		float combinedHeight = [mainTitle heightWithWidth:[tableColumn width]] + [subStringTitle heightWithWidth:[tableColumn width]] + MINIMUM_CELL_SPACING;
		
		// Make sure we're not down-sizing
		if (combinedHeight > necessaryHeight) {
			necessaryHeight = combinedHeight;
		}
		
		[subStringTitle release];
		[mainTitle release];
	}
	
	// Cache the height value
	[requiredHeightDict setObject:[NSNumber numberWithFloat:necessaryHeight]
						   forKey:[NSNumber numberWithInt:row]];
}

/*!
* @brief Calculates the height of all rows
 */
- (void)calculateAllHeights
{
	int accountNumber;

	[requiredHeightDict release]; requiredHeightDict = [[NSMutableDictionary alloc] init];

	for (accountNumber = 0; accountNumber < [accountArray count]; accountNumber++) {
		[self calculateHeightForRow:accountNumber];
	}
}


//Account List Table Delegate ------------------------------------------------------------------------------------------
#pragma mark Account List (Table Delegate)
/*!
 * @brief Delete the selected row
 */
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteAccount:nil];
}

/*!
 * @brief Number of rows in the table
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [accountArray count];
}

/*!
 * @brief Table values
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (row < 0 || row >= [accountArray count]) {
		return nil;
	}
	
	NSString 	*identifier = [tableColumn identifier];
	AIAccount	*account = [accountArray objectAtIndex:row];
	
	if ([identifier isEqualToString:@"service"]) {
		return [[AIServiceIcons serviceIconForObject:account
												type:AIServiceIconLarge
										   direction:AIIconNormal] imageByScalingToSize:NSMakeSize(MINIMUM_ROW_HEIGHT-2, MINIMUM_ROW_HEIGHT-2)
																			   fraction:([account enabled] ?
																						 1.0 :
																						 0.75)];

	} else if ([identifier isEqualToString:@"name"]) {
		return [[account formattedUIDForListDisplay] length] ? [account formattedUIDForListDisplay] : NEW_ACCOUNT_DISPLAY_TEXT;
		
	} else if ([identifier isEqualToString:@"status"]) {
		NSString	*title;
		
		if ([account enabled]) {
			if ([[account valueForProperty:@"Connecting"] boolValue]) {
				title = AILocalizedString(@"Connecting",nil);
			} else if ([[account valueForProperty:@"Disconnecting"] boolValue]) {
				title = AILocalizedString(@"Disconnecting",nil);
			} else if ([[account valueForProperty:@"Online"] boolValue]) {
				title = AILocalizedString(@"Online",nil);
			} else if ([account valueForProperty:@"Waiting to Reconnect"]) {
				title = AILocalizedString(@"Reconnecting", @"Used when the account will perform an automatic reconnection after a certain period of time.");
			} else if ([[account valueForProperty:@"Waiting for Network"] boolValue]) {
				title = AILocalizedString(@"Network Offline", @"Used when the account will connect once the network returns.");
			} else {
				title = [[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_OFFLINE];
			}

		} else {
			title = AILocalizedString(@"Disabled",nil);
		}

		return title;
		
	} else if ([identifier isEqualToString:@"statusicon"]) {

		return [AIStatusIcons statusIconForListObject:account type:AIStatusIconList direction:AIIconNormal];
		
	} else if ([identifier isEqualToString:@"enabled"]) {
		return nil;

	}

	return nil;
}
/*!
 * @brief Configure the height of each account for error messages if necessary
 */
- (float)tableView:(NSTableView *)tableView heightOfRow:(int)row
{
	// We should probably have this value cached.
	float necessaryHeight = MINIMUM_ROW_HEIGHT;
	
	NSNumber *cachedHeight = [requiredHeightDict objectForKey:[NSNumber numberWithInt:row]];
	if (cachedHeight) {
		necessaryHeight = [cachedHeight floatValue];
	}
	
	return necessaryHeight;
}

/*!
 * @brief Configure cells before display
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	// Make sure this row actually exists
	if (row < 0 || row >= [accountArray count]) {
		return;
	}

	NSString 	*identifier = [tableColumn identifier];
	AIAccount	*account = [accountArray objectAtIndex:row];
	
	if ([identifier isEqualToString:@"enabled"]) {
		[cell setState:([account enabled] ? NSOnState : NSOffState)];

	} else if ([identifier isEqualToString:@"name"]) {
		if ([account encrypted]) {
			[cell setImage:[NSImage imageForSSL]];
		} else {
			[cell setImage:nil];
		}

		[cell setImageTextPadding:MINIMUM_CELL_SPACING/2.0];
		
		[cell setEnabled:[account enabled]];

		// Update the subString with our current status message (if it exists);
		[cell setSubString:[self statusMessageForAccount:account]];
		
	} else if ([identifier isEqualToString:@"service"]) {
		[cell accessibilitySetOverrideValue:[[account service] longDescription]
							   forAttribute:NSAccessibilityTitleAttribute];		 
		[cell accessibilitySetOverrideValue:@" "
							   forAttribute:NSAccessibilityRoleDescriptionAttribute];		 
 

	} else if ([identifier isEqualToString:@"status"]) {
		if ([account enabled] && ![[account valueForProperty:@"Connecting"] boolValue] && [account valueForProperty:@"Waiting to Reconnect"]) {
			NSString *format = [NSDateFormatter stringForTimeInterval:[[account valueForProperty:@"Waiting to Reconnect"] timeIntervalSinceNow]
													   showingSeconds:YES
														  abbreviated:YES
														 approximated:NO];
			
			[cell setSubString:[NSString stringWithFormat:AILocalizedString(@"...in %@", @"The amount of time until a reconnect occurs. %@ is the formatted time remaining."), format]];
		} else {
			[cell setSubString:nil];
		}
		
		[cell setEnabled:([[account valueForProperty:@"Connecting"] boolValue] ||
						  [account valueForProperty:@"Waiting to Reconnect"] ||
						  [[account valueForProperty:@"Disconnecting"] boolValue] ||
						  [[account valueForProperty:@"Online"] boolValue])];

	} else if ([identifier isEqualToString:@"statusicon"]) {
		[cell accessibilitySetOverrideValue:@" "
							   forAttribute:NSAccessibilityTitleAttribute];
		[cell accessibilitySetOverrideValue:@" "
							   forAttribute:NSAccessibilityRoleDescriptionAttribute];

	} else if ([identifier isEqualToString:@"blank1"] || [identifier isEqualToString:@"blank2"]) {
		[cell accessibilitySetOverrideValue:@" "
							   forAttribute:NSAccessibilityTitleAttribute];		
		[cell accessibilitySetOverrideValue:@" "
							   forAttribute:NSAccessibilityRoleDescriptionAttribute];		
	}
}

/*!
 * @brief Handle a clicked active/inactive checkbox
 *
 * Checking the box both takes the account online and sets it to autoconnect. Unchecking it does the opposite.
 */
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (row >= 0 && row < [accountArray count] && [[tableColumn identifier] isEqualToString:@"enabled"]) {
		[[accountArray objectAtIndex:row] setEnabled:[(NSNumber *)object boolValue]];
	}
}

/*!
 * @brief Drag start
 */
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet*)rows toPasteboard:(NSPasteboard*)pboard
{
    tempDragAccounts = [accountArray objectsAtIndexes:rows];

    [pboard declareTypes:[NSArray arrayWithObject:ACCOUNT_DRAG_TYPE] owner:self];
    [pboard setString:@"Account" forType:ACCOUNT_DRAG_TYPE];
    
    return YES;
}

/*!
 * @brief Drag validate
 */
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if (op == NSTableViewDropAbove && row != -1) {
        return NSDragOperationPrivate;
    } else {
        return NSDragOperationNone;
    }
}

/*!
 * @brief Drag complete
 */
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    NSString		*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ACCOUNT_DRAG_TYPE]];
	
    if ([avaliableType isEqualToString:@"AIAccount"]) {
		NSEnumerator	*enumerator;
		AIAccount		*account;

		//Indexes are shifting as we're doing this, so we have to iterate in the right order
		//If we're moving accounts to an earlier point in the list, we've got to insert backwards
		if ([accountArray indexOfObject:[tempDragAccounts objectAtIndex:0]] >= row) 
			enumerator = [tempDragAccounts reverseObjectEnumerator];
		else //If we're inserting into a later part of the list, we've got to insert forwards
			enumerator = [tempDragAccounts objectEnumerator];
		
		[tableView_accountList deselectAll:nil];
		
		while ((account = [enumerator nextObject])) {
			[[adium accountController] moveAccount:account toIndex:row];
		}
		
		//Re-select our now-moved accounts
		[tableView_accountList selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([accountArray indexOfObject:[tempDragAccounts objectAtIndex:0]], [tempDragAccounts count])]
						   byExtendingSelection:NO];

        return YES;
    } else {
        return NO;
    }
}

/*!
 * @brief Selection change
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateControlAvailability];
}

- (NSMenu *)tableView:(NSTableView *)inTableView menuForEvent:(NSEvent *)theEvent
{
	NSIndexSet	*selectedIndexes	= [inTableView selectedRowIndexes];
	int			mouseRow			= [inTableView rowAtPoint:[inTableView convertPoint:[theEvent locationInWindow] toView:nil]];
	
	//Multiple rows selected where the right-clicked row is in the selection
	if ([selectedIndexes count] > 1 && [selectedIndexes containsIndex:mouseRow]) {
		//Display a multi-selection menu
		return [self menuForRowIndexes:selectedIndexes];
	} else {
		// Otherwise, select our new row and provide a menu for it.
		[inTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:mouseRow] byExtendingSelection:NO];

		// Return our delegate's menu for this row.
		return [self menuForRow:mouseRow];
	}	
}

/*!
 * @brief Set up KFTypeSelectTableView
 *
 * Only search the "name" column.
 */
- (void)configureTypeSelectTableView:(KFTypeSelectTableView *)tableView
{
    [tableView setSearchColumnIdentifiers:[NSSet setWithObject:@"name"]];
}

@end
