//
//  AIAdvancedInspectorPane.m
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//  Copyright 2008 The Adium Team. All rights reserved.
//

#import "AIAdvancedInspectorPane.h"
#import <Adium/AIAccountMenu.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>

#define ADVANCED_NIB_NAME (@"AIAdvancedInspectorPane")

@interface AIAdvancedInspectorPane(PRIVATE)
- (void)updateGroupList;
-(void)reloadPopup;
@end

@interface NSMenuItem (NSMenItem_AdvancedInspectorPane)
- (void)setAttributes:(NSDictionary *)attributes;
@end

@implementation AIAdvancedInspectorPane

- (id) init
{
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:[self nibName] owner:self];
		
		//Load Encryption menus
		[popUp_encryption setMenu:[[adium contentController] encryptionMenuNotifyingTarget:self withDefault:YES]];
		[[popUp_encryption menu] setAutoenablesItems:NO];

		//Configure Table view
		[accountsTableView setUsesAlternatingRowBackgroundColors:YES];
		[accountsTableView setAcceptsFirstMouse:YES];

		//[[[accountsTableView tableColumnWithIdentifier:@"account"] headerCell] setTitle:AILocalizedString(@"Account",nil)];
		[[[accountsTableView tableColumnWithIdentifier:@"contact"] headerCell] setTitle:AILocalizedString(@"Contact","This header for the table in the Accounts tab of the Get Info window indicates the name of the contact within a metacontact")];
		[[[accountsTableView tableColumnWithIdentifier:@"group"] headerCell] setTitle:AILocalizedString(@"Group",nil)];
		contactsColumnIsInAccountsTableView = YES; //It's in the table view in the nib.
		
		//Observe contact list changes
		[[adium notificationCenter] addObserver:self
								   selector:@selector(contactListChanged)
									   name:Contact_ListChanged
									 object:nil];	
		//Observe account changes
		[[adium notificationCenter] addObserver:self
								   selector:@selector(accountListChanged)
									   name:Account_ListChanged
									 object:nil];

		[self updateGroupList];
		accountMenu = [[AIAccountMenu accountMenuWithDelegate:self
												  submenuType:AIAccountNoSubmenu
											   showTitleVerbs:NO] retain];
	
		[accountsTableView sizeToFit];
	}
	
	return self;
}

- (void) dealloc
{
	[accountMenu release]; accountMenu = nil;
	[accounts release]; accounts = nil;
	[contacts release]; contacts = nil;
    [displayedObject release]; displayedObject = nil;
	[inspectorContentView release]; inspectorContentView = nil;

	[[adium notificationCenter] removeObserver:self]; 
	[super dealloc];
}


-(NSString *)nibName
{
	return ADVANCED_NIB_NAME;
}

-(NSView *)inspectorContentView
{
	return inspectorContentView;
}

-(void)updateForListObject:(AIListObject *)inObject
{
	if (displayedObject != inObject) {
		//Update the table view to have or not have the "Individual Contact" column, as appropriate.
		//It should have the column when our list object is a metacontact.
		if ([inObject isKindOfClass:[AIMetaContact class]]) {
			if (!contactsColumnIsInAccountsTableView) {
				//Add the column.
				[accountsTableView addTableColumn:contactsColumn];
				//It was added as last; move to the middle.
				[accountsTableView moveColumn:1 toColumn:0];
				//Set all of the table view's columns to be the same width.
				float columnWidth = [accountsTableView frame].size.width / 2.0;
				//NSLog(@"Setting columnWidth to: %f / 2.0 == %f", [accountsTableView frame].size.width, columnWidth);
				[[accountsTableView tableColumns] setValue:[NSNumber numberWithFloat:columnWidth] forKey:@"width"];
				[accountsTableView sizeToFit];
				//We don't need it retained anymore.
				[contactsColumn release];

				contactsColumnIsInAccountsTableView = YES;
			}
		} else if(contactsColumnIsInAccountsTableView) {
			//Remove the column.
			//Note that the column is in the table in the nib, so it is in the table view before we have been configured for the first time.
			//And be sure to retain it before removing it from the view.
			[contactsColumn retain];
			[accountsTableView removeTableColumn:contactsColumn];
			//Set both of the table view's columns to be the same width.
			float columnWidth = [accountsTableView frame].size.width;
			//NSLog(@"Setting columnWidth to: %f", [accountsTableView frame].size.width);
			[[accountsTableView tableColumns] setValue:[NSNumber numberWithFloat:columnWidth] forKey:@"width"];
			[accountsTableView sizeToFit];

			contactsColumnIsInAccountsTableView = NO;
		}
	
		[displayedObject release];
		displayedObject = ([inObject isKindOfClass:[AIListContact class]] ?
					[(AIListContact *)inObject parentContact] :
					inObject);
		[displayedObject retain];
		
		//Rebuild the account list
		[self reloadPopup];
	}
	
	NSNumber *encryption;
	
	encryption = [inObject preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE group:GROUP_ENCRYPTION];
	
	if(!encryption) {
		[popUp_encryption compatibleSelectItemWithTag:EncryptedChat_Default];
	}
	
	[popUp_encryption compatibleSelectItemWithTag:[encryption intValue]];
	
	[checkBox_alwaysShow setEnabled:![inObject isKindOfClass:[AIListGroup class]]];
	[checkBox_alwaysShow setState:[inObject alwaysVisible]];
}

- (IBAction)selectedEncryptionPreference:(id)sender
{
	if(!displayedObject)
		return;
	[displayedObject setPreference:[NSNumber numberWithInt:[sender tag]] 
							forKey:KEY_ENCRYPTED_CHAT_PREFERENCE 
							group:GROUP_ENCRYPTION];
}

- (IBAction)setVisible:(id)sender
{
	if(!displayedObject)
		return;
	
	[displayedObject setAlwaysVisible:[checkBox_alwaysShow state]];
}

#pragma mark Accounts Table View methods

/*!
 * @brief Update our list of groups
 */
- (void)updateGroupList
{
	//Get the new groups
	NSMenu		*groupMenu = [[adium contactController] menuOfAllGroupsInGroup:nil withTarget:self];
	NSMenuItem  *notListedMenuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"(Not Listed)", nil)
																						 target:self
																action:@selector(selectGroup:)
														 keyEquivalent:@""
													 representedObject:nil];
	[groupMenu insertItem:notListedMenuItem atIndex:0];
	[notListedMenuItem release];
	[groupMenu insertItem:[NSMenuItem separatorItem] atIndex:1];

	[[groupMenu itemArray] makeObjectsPerformSelector:@selector(setAttributes:)
										   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
													   [NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]], NSFontAttributeName,
													   [NSParagraphStyle styleWithAlignment:NSLeftTextAlignment
																			  lineBreakMode:NSLineBreakByTruncatingTail], NSParagraphStyleAttributeName,
													   nil]];
	 
	[[[accountsTableView tableColumnWithIdentifier:@"group"] dataCell] setMenu:groupMenu];
	
	//Refresh our table
	[accountsTableView reloadData];
}

- (NSArray *)accountsForCurrentObject
{
	if ([displayedObject isKindOfClass:[AIMetaContact class]]) {
		NSMutableSet *set = [NSMutableSet set];
		NSEnumerator *enumerator = [[[(AIMetaContact *)displayedObject listContacts] valueForKey:@"service"] objectEnumerator];
		AIService *service;
		while ((service = [enumerator nextObject])) {
			[set addObjectsFromArray:[[adium accountController] accountsCompatibleWithService:service]];
		}

		return [set allObjects];

	} else 	if ([displayedObject isKindOfClass:[AIListContact class]]) {
		return [[adium accountController] accountsCompatibleWithService:[displayedObject service]];

	} else {
		return nil;
	}
}

- (NSArray *)contactsForCurrentObjectCompatibleWithAccount:(AIAccount *)inAccount
{
	if ([displayedObject isKindOfClass:[AIMetaContact class]]) {
		NSMutableArray *array = [NSMutableArray array];
		NSEnumerator *enumerator = [[(AIMetaContact *)displayedObject listContacts] objectEnumerator];
		AIListContact *contact;
		while ((contact = [enumerator nextObject])) {
			if ([[contact serviceClass] isEqualToString:[inAccount serviceClass]]) {
				[array addObject:[[adium contactController] contactWithService:[contact service]
																	   account:inAccount
																		   UID:[contact UID]]];
			}
		}
		
		return array;

	} else 	if ([displayedObject isKindOfClass:[AIListContact class]]) {
		return [NSArray arrayWithObject:displayedObject];
		
	} else {
		return nil;
	}
}

-(void)reloadPopup
{
	[accounts release]; accounts = nil;
	accounts = [[self accountsForCurrentObject] retain];
	
	[accountMenu rebuildMenu];
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount
{
	[contacts release]; contacts = nil;
	if (inAccount)
		contacts = [[self contactsForCurrentObjectCompatibleWithAccount:inAccount] retain];

	//Refresh our table
	[accountsTableView reloadData];
}

- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount
{
	return [accounts containsObject:inAccount];
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems
{
	[popUp_accounts setMenu:[inAccountMenu menu]];

	//Select an account and redisplay
	[self accountMenu:inAccountMenu didSelectAccount:([popUp_accounts numberOfItems] ?
													  [[popUp_accounts selectedItem] representedObject] :
													  nil)];
}

- (NSControlSize)controlSizeForAccountMenu:(AIAccountMenu *)inAccountMenu
{
	return NSSmallControlSize;
}

- (void)accountListChanged
{
	[self reloadPopup];
}

- (void)contactListChanged
{
	/* Prevent reentry, as Heisenberg knows out that observing contacts may change them. */
	if (!rebuildingContacts) {
		rebuildingContacts = YES;
		[self accountMenu:accountMenu didSelectAccount:([popUp_accounts numberOfItems] ?
														[[popUp_accounts selectedItem] representedObject] :
														nil)];
		rebuildingContacts = NO;
	}
}

#pragma mark Accounts Table View Data Sources

/*!
 * @brief Number of table view rows
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [contacts count];
}

/*!
 * @brief Table view object value
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	id result = @"";

	NSString		*identifier = [tableColumn identifier];

	//if ([identifier isEqualToString:@"account"]) {
//		AIAccount		*account = [accounts objectAtIndex:row];
//		NSString	*accountFormattedUID = [account formattedUID];
//		
//		if ([account online]) {
//			result = accountFormattedUID;
//			
//		} else {
//			//Gray the names of offline accounts
//			NSDictionary		*attributes = [NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
//			NSAttributedString	*string = [[NSAttributedString alloc] initWithString:accountFormattedUID attributes:attributes];
//			result = [string autorelease];
//		}
		
	/*} else*/ if ([identifier isEqualToString:@"contact"]) {
		AIListObject *contact = [contacts objectAtIndex:row];
		result = [contact formattedUID];
	}
	
	return result;
}

/*!
 * @brief Table view will display a cell
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString		*identifier = [tableColumn identifier];
	AIAccount		*account;
	AIListContact	*exactContact;
	BOOL			accountOnline;
		
	//account =  [accounts objectAtIndex:row];
	account = [[popUp_accounts selectedItem] representedObject];
	accountOnline = [account online];

	exactContact = [contacts objectAtIndex:row];				

	//Disable cells for offline accounts
	[cell setEnabled:accountOnline];
	
	//Select active group
	if ([identifier isEqualToString:@"group"]) {
		if (accountOnline) {
			AIListGroup	*group;
			
			if ((group = [[adium contactController] remoteGroupForContact:exactContact])) {
				[cell selectItemWithRepresentedObject:group];
			} else {
				[cell selectItemAtIndex:0];			
			}
		} else {
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]], NSFontAttributeName,
										[NSParagraphStyle styleWithAlignment:NSLeftTextAlignment lineBreakMode:NSLineBreakByTruncatingTail], NSParagraphStyleAttributeName,
										nil];
			NSAttributedString *attTitle = [[[NSAttributedString alloc] initWithString:AILocalizedString(@"(Unavailable)",nil) attributes:attributes] autorelease];
			[cell setAttributedTitle:attTitle];
		}
	}
}

/*!
 * @brief Empty.  This method is the target of our menus, and needed for menu validation.
 */
- (void)selectGroup:(id)sender {};

/*!
 * @brief Table view set object value
 */
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString		*identifier = [tableColumn identifier];
	
	if ([identifier isEqualToString:@"group"]) {
		NSMenu		*menu = [[tableColumn dataCell] menu];
		int			menuIndex = [object intValue];
		
		if (menuIndex >= 0 && menuIndex < [menu numberOfItems]) {
			AIListGroup		*group = [[menu itemAtIndex:menuIndex] representedObject];
			AIListContact	*contactOnClickedRow = [contacts objectAtIndex:row];
			AIListContact	*exactContact;

			//Retrieve an AIListContact on this account
			exactContact = [[adium contactController] contactWithService:[contactOnClickedRow service]
																 account:[[popUp_accounts selectedItem] representedObject]
																	 UID:[contactOnClickedRow UID]];

			if (group) {				
				if (![[group UID] isEqualToString:[exactContact remoteGroupName]]) {
					if ([exactContact remoteGroupName]) {
						//Move contact
						[[adium contactController] moveContact:exactContact intoObject:group];

					} else {						
						[[adium contactController] addContacts:[NSArray arrayWithObject:exactContact] 
													   toGroup:group];
					}
				}

			} else {
				//User selected not listed, so we'll remove that contact
				[[adium contactController] removeListObjects:[NSArray arrayWithObject:exactContact]];
			}
		}
	}
}

@end

@implementation NSMenuItem (NSMenItem_AdvancedInspectorPane)
- (void)setAttributes:(NSDictionary *)attributes
{
	[self setAttributedTitle:[[[NSAttributedString alloc] initWithString:[self title]
															  attributes:attributes] autorelease]];
}
@end
