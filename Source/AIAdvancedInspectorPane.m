//
//  AIAdvancedInspectorPane.m
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//  Copyright 2008 The Adium Team. All rights reserved.
//

#import "AIAdvancedInspectorPane.h"
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIChat.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AILocalizationTextField.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIStringFormatter.h>

#import <Adium/AIAccountMenu.h>
#import <Adium/AIContactMenu.h>

#define ADVANCED_NIB_NAME (@"AIAdvancedInspectorPane")

@interface AIAdvancedInspectorPane()
- (void)reloadPopup;
- (void)configureControlDimming;
@end

@implementation AIAdvancedInspectorPane

- (id) init
{
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:[self nibName] owner:self];
		
		//Load Encryption menus
		[popUp_encryption setMenu:[adium.contentController encryptionMenuNotifyingTarget:self withDefault:YES]];
		[[popUp_encryption menu] setAutoenablesItems:NO];
		
		//Observe contact list changes
		[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(reloadPopup)
									   name:Contact_ListChanged
									 object:nil];	
		//Observe account changes
		[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(reloadPopup)
									   name:Account_ListChanged
									 object:nil];

		accountMenu = [[AIAccountMenu accountMenuWithDelegate:self
												  submenuType:AIAccountNoSubmenu
											   showTitleVerbs:NO] retain];
	}
	
	return self;
}

- (void) dealloc
{
	[accountMenu release]; accountMenu = nil;
	[contactMenu release]; contactMenu = nil;
    [displayedObject release]; displayedObject = nil;
	[inspectorContentView release]; inspectorContentView = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self]; 
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

- (void)configureControlDimming
{
	[button_removeGroup setEnabled:[tableView_groups numberOfSelectedRows]];	
}

-(void)updateForListObject:(AIListObject *)inObject
{
	if (displayedObject != inObject) {
		[displayedObject release];
		
		displayedObject = ([inObject isKindOfClass:[AIListContact class]] ?
						   [(AIListContact *)inObject parentContact] :
						   inObject);
		
		[displayedObject retain];
		
		//Rebuild the account and contacts lists
		[self reloadPopup];
	}
	
	if(![inObject isKindOfClass:[AIListContact class]]) {
		[popUp_encryption selectItemWithTag:EncryptedChat_Default];
	} else {
		[popUp_encryption selectItemWithTag:((AIListContact *)inObject).encryptedChatPreferences];
	}
	
	[checkBox_alwaysShow setEnabled:![inObject isKindOfClass:[AIListGroup class]]];
	[checkBox_alwaysShow setState:inObject.alwaysVisible];
	
	[checkBox_autoJoin setEnabled:[inObject isKindOfClass:[AIListBookmark class]]];
	[checkBox_autoJoin setState:[[inObject preferenceForKey:KEY_AUTO_JOIN group:GROUP_LIST_BOOKMARK] boolValue]];
	
	[popUp_accounts setEnabled:![inObject isKindOfClass:[AIListGroup class]]];
	[popUp_contact setEnabled:![inObject isKindOfClass:[AIListGroup class]]];
	[button_addGroup setEnabled:![inObject isKindOfClass:[AIListGroup class]]];
}

#pragma mark Preference callbacks

- (IBAction)selectedEncryptionPreference:(id)sender
{
	[displayedObject setPreference:[NSNumber numberWithInteger:[sender tag]] 
							forKey:KEY_ENCRYPTED_CHAT_PREFERENCE 
							group:GROUP_ENCRYPTION];
}

- (IBAction)setVisible:(id)sender
{
	[displayedObject setAlwaysVisible:[checkBox_alwaysShow state]];
}

- (IBAction)setAutoJoin:(id)sender
{
	[displayedObject setPreference:[NSNumber numberWithBool:[sender state]] 
							forKey:KEY_AUTO_JOIN
							 group:GROUP_LIST_BOOKMARK];
}

#pragma mark Menus
-(void)reloadPopup
{	
	[accountMenu rebuildMenu];
	
	[button_addGroup setMenu:[adium.contactController groupMenuWithTarget:self]];
	
	[self configureControlDimming];
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount
{
	currentSelectedAccount = inAccount;
	
	if (!contactMenu) {
		// Instantiate here so we don't end up creating a massive menu for all contacts.
		contactMenu = [[AIContactMenu contactMenuWithDelegate:self
										  forContactsInObject:displayedObject] retain];	
	} else {
		[contactMenu setContainingObject:displayedObject];
	}
}

- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount
{
	if (!inAccount.online) {
		return NO;
	}
	
	if ([displayedObject isKindOfClass:[AIMetaContact class]]) {
		NSArray *services = [((AIMetaContact *)displayedObject).uniqueContainedObjects valueForKeyPath:@"service.serviceClass"];
		return [services containsObject:inAccount.service.serviceClass];
	} else 	if ([displayedObject isKindOfClass:[AIListContact class]]) {
		return [displayedObject.service.serviceClass isEqualToString:inAccount.service.serviceClass];
	}
	
	return NO;
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems
{
	[popUp_accounts setMenu:[inAccountMenu menu]];

	[self accountMenu:inAccountMenu didSelectAccount:([popUp_accounts numberOfItems] ?
													  [[popUp_accounts selectedItem] representedObject] :
													  nil)];
}

- (void)contactMenu:(AIContactMenu *)inContactMenu didRebuildMenuItems:(NSArray *)menuItems
{
	[popUp_contact setMenu:inContactMenu.menu];
	
	[self contactMenu:inContactMenu didSelectContact:([popUp_contact numberOfItems] ?
													  [[popUp_contact selectedItem] representedObject] :
													  nil)];
}

- (void)contactMenu:(AIContactMenu *)inContactMenu didSelectContact:(AIListContact *)inContact
{
	currentSelectedContact = [adium.contactController contactWithService:inContact.service
																 account:currentSelectedAccount
																	 UID:inContact.UID];
	
	// Update the groups.
	[tableView_groups reloadData];
}

- (BOOL)contactMenu:(AIContactMenu *)inContactMenu shouldIncludeContact:(AIListContact *)inContact
{
	AIAccount *selectedAccount = currentSelectedAccount;
	
	// Include this contact if it's the same as the selected account.
	return [selectedAccount.service.serviceClass isEqualToString:inContact.service.serviceClass];
}

- (NSControlSize)controlSizeForAccountMenu:(AIAccountMenu *)inAccountMenu
{
	return NSSmallControlSize;
}

#pragma mark Group control
- (void)selectGroup:(id)sender
{
	AIListGroup *group = [sender representedObject];
	
	[currentSelectedAccount addContact:currentSelectedContact toGroup:group];
	
	[tableView_groups deselectAll:nil];
	[tableView_groups reloadData];
}

- (void)removeSelectedGroups:(id)sender
{
	for (AIListGroup *group in [currentSelectedContact.remoteGroups.allObjects objectsAtIndexes:tableView_groups.selectedRowIndexes]) {
		[currentSelectedContact removeFromGroup:group];
	}
	
	[tableView_groups deselectAll:nil];
	[tableView_groups reloadData];
}

#pragma mark Accounts Table View Data Sources
/*!
 * @brief Number of table view rows
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return currentSelectedContact.remoteGroups.count;
}

/*!
 * @brief Table view set object value
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString		*identifier = [tableColumn identifier];
	
	if ([identifier isEqualToString:@"group"]) {
		NSArray *contactGroups = currentSelectedContact.remoteGroups.allObjects;
		
		return ((AIListGroup *)[contactGroups objectAtIndex:row]).displayName;
	}
	
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self configureControlDimming];
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self removeSelectedGroups:nil];
}

@end
