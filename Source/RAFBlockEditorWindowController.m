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
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIImageTextCell.h>

#define MINIMUM_ROW_HEIGHT				34
#define MINIMUM_CELL_SPACING			 4

@interface RAFBlockEditorWindowController ()
- (AIAccount<AIAccount_Privacy> *)selectedAccount;
- (void)configureTextField;
- (NSSet *)contactsFromTextField;
- (AIPrivacyOption)selectedPrivacyOption;
- (void)privacySettingsChangedExternally:(NSNotification *)inNotification;
- (void)runBlockSheet;
- (void)removeSelection;
- (void)accountListChanged:(NSNotification *)note;
- (void)addObject:(AIListContact *)inContact;
- (void)addListObjectToList:(AIListObject *)listObject;
@end

@implementation RAFBlockEditorWindowController
@synthesize sheet;
@synthesize accountTable, contactTable;
@synthesize privacyLevel;
@synthesize label_information, label_contact, label_blockInformation;
@synthesize addRemoveContact, addContactField, addContact, cancelSheet;

static RAFBlockEditorWindowController *sharedInstance = nil;

+ (void)showWindow
{	
	[adium.preferenceController openPreferencesToCategoryWithIdentifier:@"Privacy"];
}

/*!
 * @brief Preference pane properties
 */
- (AIPreferenceCategory)category{
	return AIPref_Advanced;
}
- (NSString *)paneIdentifier{
	return @"Privacy";
}
- (NSString *)paneName{
    return AILocalizedString(@"Privacy",nil);
}
- (NSImage *)paneIcon{
	return [NSImage imageNamed:@"msg-block-contact" forClass:[self class]];
}
- (NSString *)nibName{
    return @"Preferences-Privacy";
}

- (void)localizePane
{
	[cancelSheet setLocalizedString:AILocalizedString(@"Cancel","Cancel button for Privacy Settings")];
	[addContact setLocalizedString:AILocalizedString(@"Add","Add button for Privacy Settings")];
	[[[contactTable tableColumnWithIdentifier:@"contact"] headerCell] setStringValue:AILocalizedString(@"Contact","Title of column containing user IDs of blocked contacts")];
	[label_blockInformation setLocalizedString:AILocalizedString(@"Add a contact to block.",nil)];

	[[privacyLevel cellWithTag:AIPrivacyOptionAllowAll] setTitle:AILocalizedString(@"Allow anyone", @"Privacy blocking option")];
	[[privacyLevel cellWithTag:AIPrivacyOptionAllowContactList] setTitle:AILocalizedString(@"Allow only contacts on my contact list", @"Privacy blocking option")];
	[[privacyLevel cellWithTag:AIPrivacyOptionAllowUsers] setTitle:AILocalizedString(@"Allow only certain contacts", @"Privacy blocking option")];
	[[privacyLevel cellWithTag:AIPrivacyOptionDenyUsers] setTitle:AILocalizedString(@"Block certain contacts", @"Privacy blocking option")];
}

- (void)viewDidLoad
{
	//Setup tables
	AIImageTextCell *cell;
	cell = [[AIImageTextCell alloc] init];
	[cell setFont:[NSFont systemFontOfSize:12]];
	[[accountTable tableColumnWithIdentifier:@"account"] setDataCell:cell];
	[cell release];
	
	cell = [[AIImageTextCell alloc] init];
	[cell setFont:[NSFont systemFontOfSize:12]];
	[[contactTable tableColumnWithIdentifier:@"contact"] setDataCell:cell];
	[cell release];

	listContents = [[NSMutableArray alloc] init];
	[self accountListChanged:nil];

	[contactTable registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListObject", @"AIListObjectUniqueIDs",nil]];
	[accountTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(privacySettingsChangedExternally:)
												 name:@"AIPrivacySettingsChangedOutsideOfPrivacyWindow"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(accountListChanged:) 
												 name:Account_ListChanged 
											   object:nil];

	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

- (void)updateAccountSelection
{
	AIAccount<AIAccount_Privacy> *account = [self selectedAccount];
	BOOL hasPrivacy = [account respondsToSelector:@selector(privacyOptions)];
	BOOL online = (account && account.online && hasPrivacy);

	//Control dimming
	[privacyLevel setEnabled:online];
	[contactTable setEnabled:online];
	[addRemoveContact setEnabled:online];

	if (!hasPrivacy)
		[label_information setStringValue:AILocalizedString(@"Account does not support privacy settings.", nil)];
	else if (!online)
		[label_information setStringValue:AILocalizedString(@"Account is offline.", nil)];
	else
		[label_information setStringValue:@""];

	if (listContents.count > 0) {
		[listContents release];
		listContents = [[NSMutableArray alloc] init];
		[contactTable reloadData];
	}

	if (online) {
		AIPrivacyOption privacyOption = [account privacyOptions];
		
		[listContents addObjectsFromArray:[account listObjectsOnPrivacyList:((privacyOption == AIPrivacyOptionAllowUsers) ?
																			 AIPrivacyTypePermit :
																			 AIPrivacyTypeDeny)]];
		
		[privacyLevel selectCellWithTag:privacyOption];
		[self setPrivacyOption:nil];
	}
}

- (void)dealloc
{
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[sharedInstance release]; sharedInstance = nil;
	[listContents release];
	
	[super dealloc];
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

#pragma mark - Adding a contact to the list

- (void)runBlockSheet
{
	[self configureTextField];

	[NSApp beginSheet:sheet
	   modalForWindow:self.view.window
		modalDelegate:self 
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)cancelBlockSheet:(id)sender
{
	[sheet orderOut:nil];
	[NSApp endSheet:sheet];
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
		
		[contactTable reloadData];
	}

	[sheet orderOut:nil];
	[NSApp endSheet:sheet];
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
	AIAccount		*account = [self selectedAccount];
	NSMutableSet	*contactsSet = [NSMutableSet set];
	id				impliedValue = [addContactField impliedValue];

	if (account) {
		if ([impliedValue isKindOfClass:[AIMetaContact class]]) {
			for (AIListContact *containedContact in [(AIMetaContact *)impliedValue listContactsIncludingOfflineAccounts]) {
				/* For each contact contained in the metacontact, check if its service class matches the current account's.
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
	[addContactField setStringValue:@""];

	//Clear the completing strings
	[addContactField setCompletingStrings:nil];
	
	//Configure the auto-complete view to autocomplete for contacts matching the selected account's service
	AIAccount *account = [self selectedAccount];
    for (AIListContact *contact in adium.contactController.allContacts) {
		if (!account || contact.service == account.service) {
			NSString *UID = contact.UID;
			[addContactField addCompletionString:contact.formattedUID withImpliedCompletion:UID];
			[addContactField addCompletionString:contact.displayName withImpliedCompletion:UID];
			[addContactField addCompletionString:UID];
		}
    }
}

#pragma mark - Removing a contact from the list

- (void)removeSelection
{
	NSIndexSet		*selectedItems = [contactTable selectedRowIndexes];
	
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
		
		[contactTable reloadData];
		[contactTable deselectAll:nil];
	}

}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self removeSelection];
}

- (AIPrivacyOption)selectedPrivacyOption
{
	return (AIPrivacyOption)[privacyLevel selectedTag];
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

	if (sender && account)
		[account setPrivacyOptions:privacyOption];
	
	//Now make our listContents array match the serverside arrays for the selected account(s)
	[listContents removeAllObjects];
	if ((privacyOption == AIPrivacyOptionAllowUsers) ||
		(privacyOption == AIPrivacyOptionDenyUsers)) {
		if (account) {
			[listContents addObjectsFromArray:[account listObjectsOnPrivacyList:((privacyOption == AIPrivacyOptionAllowUsers) ?
																				 AIPrivacyTypePermit :
																				 AIPrivacyTypeDeny)]];
		}
	}

	[contactTable reloadData];
}

- (void)selectPrivacyOption:(AIPrivacyOption)privacyOption
{
	[privacyLevel selectCellWithTag:privacyOption];
	//Now update our view for this privacy option
	[self setPrivacyOption:nil];
}

#pragma mark - Account Settings
/*!
 * @brief Return the currently selected account, or nil if the 'All' item is selected
 */
- (AIAccount<AIAccount_Privacy> *)selectedAccount
{
	if ([accountTable selectedRow] >= 0)
		return [accountArray objectAtIndex:[accountTable selectedRow]];
	return nil;
}

- (void)accountListChanged:(NSNotification *)note
{
	//Update our list of accounts
	[accountArray release];
	accountArray = [adium.accountController.accounts retain];
	
	[accountTable reloadData];
}

- (void)privacySettingsChangedExternally:(NSNotification *)inNotification
{
	[self updateAccountSelection];
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inModifiedKeys containsObject:KEY_IS_BLOCKED]) {
		[self privacySettingsChangedExternally:nil];
	} else if ([inObject isKindOfClass:[AIAccount class]] && [inModifiedKeys containsObject:@"isOnline"]) {
		[self updateAccountSelection];
	}
	
	return nil;
}

#pragma mark - Table view

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == contactTable && listContents)
		return [listContents count];
	else if (tableView == accountTable && accountArray)
		return [accountArray count];
	
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == contactTable) {
		AIListContact *contact = [listContents objectAtIndex:row];
		NSString *identifier = [tableColumn identifier];
		
		if ([identifier isEqualToString:@"icon"]) {
			return [AIServiceIcons serviceIconForObject:contact
												   type:AIServiceIconLarge
											  direction:AIIconNormal];
		} else if ([identifier isEqualToString:@"contact"]) {
			return contact.formattedUID;
		}
		
	} else if (tableView == accountTable) {
		if ([[accountArray objectAtIndex:row] isKindOfClass:[AIAccount class]]) {
			AIAccount	*account = [accountArray objectAtIndex:row];
			return [account explicitFormattedUID];
		} else {
			return [accountArray objectAtIndex:row];
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString 	*identifier = [tableColumn identifier];
	
	if ([identifier isEqualToString:@"account"]) {
		if ([[accountArray objectAtIndex:row] isKindOfClass:[AIAccount class]]) {
			AIAccount	*account = [accountArray objectAtIndex:row];
			[cell setImage:[AIServiceIcons serviceIconForObject:account
															type:AIServiceIconLarge
													  direction:AIIconNormal]];
		} else {
			[cell setImage:nil];
		}
	}
}

- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
    
    NSDragOperation dragOp = NSDragOperationCopy;
	
    if ([info draggingSource] == contactTable) {
		dragOp =  NSDragOperationMove;
    }
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOp;
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

- (void)addListObjectToList:(AIListObject *)listObject
{
	if ([listObject isKindOfClass:[AIListGroup class]]) {
		for (AIListObject *containedObject in [(AIListGroup *)listObject uniqueContainedObjects])
			[self addListObjectToList:containedObject];
		
	} else if ([listObject isKindOfClass:[AIMetaContact class]]) {
		for (AIListObject *containedObject in [(AIMetaContact *)listObject uniqueContainedObjects])
			[self addListObjectToList:containedObject];
		
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

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == accountTable)
		[self updateAccountSelection];

	BOOL selection = ([contactTable numberOfSelectedRows] > 0 && [contactTable selectedRow] != -1);
	[addRemoveContact setEnabled:selection forSegment:1];
}

@end
