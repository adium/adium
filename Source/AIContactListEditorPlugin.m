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
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AIContactListEditorPlugin.h"
#import <Adium/AIMenuControllerProtocol.h>
#import "AINewContactWindowController.h"
#import "AINewGroupWindowController.h"
#import <Adium/AIToolbarControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIMetaContact.h>

#define ADD_CONTACT							AILocalizedString(@"Add Contact",nil)
#define ADD_CONTACT_ELLIPSIS				[ADD_CONTACT stringByAppendingEllipsis]

#define ADD_CONTACT_TO_GROUP				AILocalizedString(@"Add Contact To Group",nil)
#define ADD_CONTACT_TO_GROUP_ELLIPSIS		[ADD_CONTACT_TO_GROUP stringByAppendingEllipsis]

#define ADD_GROUP							AILocalizedString(@"Add Group",nil)
#define ADD_GROUP_ELLIPSIS					[ADD_GROUP stringByAppendingEllipsis]

#define DELETE_CONTACT_ELLIPSIS				[AILocalizedString(@"Remove Contact",nil) stringByAppendingEllipsis]
#define DELETE_GROUP_ELLIPSIS				[AILocalizedString(@"Remove Group",nil) stringByAppendingEllipsis]
#define DELETE_CONTACT_OR_GROUP_ELLIPSIS				[AILocalizedString(@"Remove Contact or Group",nil) stringByAppendingEllipsis]
#define DELETE_CONTACT_CONTEXT_ELLIPSIS		[AILocalizedString(@"Remove",nil) stringByAppendingEllipsis]

#define RENAME_GROUP						AILocalizedString(@"Rename Group",nil)
#define RENAME_GROUP_ELLIPSIS				[RENAME_GROUP stringByAppendingEllipsis]

#define	ADD_CONTACT_IDENTIFIER				@"AddContact"
#define ADD_GROUP_IDENTIFIER				@"AddGroup"



@interface AIContactListEditorPlugin ()
- (void)deleteFromArray:(NSArray *)array;
- (void)promptForNewContactOnWindow:(NSWindow *)inWindow selectedListObject:(AIListObject *)inListObject;

- (IBAction)addContactFromTab:(id)sender;
- (void)addContactRequest:(NSNotification *)notification;
- (IBAction)deleteSelection:(id)sender;
- (IBAction)deleteSelectionFromTab:(id)sender;
@end

/*!
 * @class AIContactListEditorPlugin
 * @brief Component for managing adding and deleting contacts and groups
 */
@implementation AIContactListEditorPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    NSMenuItem		*menuItem;
	NSToolbarItem	*toolbarItem;
	
	//Add Contact
    menuItem_addContact = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_CONTACT_ELLIPSIS
																				target:self
																				action:@selector(addContact:)
																		 keyEquivalent:@"d"];
    [adium.menuController addMenuItem:menuItem_addContact toLocation:LOC_Contact_Manage];
	
	menuItem_addContactContext = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_CONTACT_TO_GROUP_ELLIPSIS
																					  target:self
																					  action:@selector(addContact:)
																			   keyEquivalent:@""];
	[adium.menuController addContextualMenuItem:menuItem_addContactContext toLocation:Context_Group_Manage];
	
	menuItem_tabAddContact = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_CONTACT_ELLIPSIS
																				   target:self 
																				   action:@selector(addContactFromTab:)
																			keyEquivalent:@""] autorelease];
    [adium.menuController addContextualMenuItem:menuItem_tabAddContact toLocation:Context_Contact_Stranger_ChatAction];

	[[NSNotificationCenter defaultCenter] addObserver:self 
								   selector:@selector(addContactRequest:) 
									   name:Contact_AddNewContact 
									 object:nil];
	
	//Add Group
    menuItem_addGroup = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_GROUP_ELLIPSIS
																			 target:self
																			 action:@selector(addGroup:) 
																	  keyEquivalent:@"D"];
    [adium.menuController addMenuItem:menuItem_addGroup toLocation:LOC_Contact_Manage];

	//Delete Selection
    menuItem_delete = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:DELETE_CONTACT_ELLIPSIS
																		   target:self
																		   action:@selector(deleteSelection:) 
																	keyEquivalent:@"\b"];
    [adium.menuController addMenuItem:menuItem_delete toLocation:LOC_Contact_Manage];

	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:DELETE_CONTACT_CONTEXT_ELLIPSIS
																	 target:self
																	 action:@selector(deleteSelectionFromTab:) 
															  keyEquivalent:@""] autorelease];
	[adium.menuController addContextualMenuItem:menuItem toLocation:Context_Contact_NegativeAction];
	
	//Add Contact toolbar item
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:ADD_CONTACT_IDENTIFIER
														  label:ADD_CONTACT
												   paletteLabel:ADD_CONTACT
														toolTip:AILocalizedString(@"Add a new contact",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"msg-add-contact" forClass:[self class] loadLazily:YES]
														 action:@selector(addContact:)
														   menu:nil];
    [adium.toolbarController registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief Validate our menu items
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem == menuItem_delete) {
		AIListObject *selectedListObject = [adium.interfaceController selectedListObjectInContactList];
		if (!selectedListObject) {
			[menuItem setTitle:DELETE_CONTACT_OR_GROUP_ELLIPSIS];
			return NO;
		} else {
			[menuItem setTitle:([selectedListObject isKindOfClass:[AIListGroup class]] ? DELETE_GROUP_ELLIPSIS : DELETE_CONTACT_ELLIPSIS)];
			return YES;
		}
		
	} else if (menuItem == menuItem_tabAddContact) {
		return adium.menuController.currentContextMenuObject != nil;
	
	} else if (menuItem == menuItem_addContact || menuItem == menuItem_addContactContext) {
		for (AIAccount *account in adium.accountController.accounts) {	
			if (account.contactListEditable) return YES;
		}
		
		return NO;

	} else if (menuItem == menuItem_addGroup) {
		/* The user can always add groups; accounts should simulate serverside groups if necessary */
		return YES;

	}
	
	return YES;
}

//Called by a context menu
- (IBAction)renameGroup:(id)sender
{
	//	AIListObject	*object = adium.menuController.currentContextMenuObject;
	//<renameGroup> : I wish I worked... :(	
}

//Add Contact ----------------------------------------------------------------------------------------------------------
#pragma mark Add Contact
/*!
 * @brief Prompt for a new contact
 */
- (IBAction)addContact:(id)sender
{
	[self promptForNewContactOnWindow:nil selectedListObject:adium.interfaceController.selectedListObject];
}


/*!
 * @brief Prompt for a new contact with the current tab's name
 */
- (IBAction)addContactFromTab:(id)sender
{
	[self promptForNewContactOnWindow:nil selectedListObject:adium.menuController.currentContextMenuObject];
}

/*!
 * @brief Prompt for a new contact
 *
 * @param inWindow If non-nil, display the new contact prompt as a sheet on inWindow
 * @param inListObject If a contact and a stranger, will be autofilled into the new contact window
 */
- (void)promptForNewContactOnWindow:(NSWindow *)inWindow selectedListObject:(AIListObject *)inListObject
{
	//We only autofill if the selected list object is a contact, a stranger or a call from a Group (add Contact in Group)
	AINewContactWindowController *newContactWindowController;

	if ([inListObject isKindOfClass:[AIListGroup class]]) {
		newContactWindowController = [[AINewContactWindowController alloc] initWithGroupName : (inListObject ? inListObject.UID:nil)];

	} else if ([inListObject isKindOfClass:[AIListContact class]]) {
		newContactWindowController = [[AINewContactWindowController alloc] initWithContactName:(inListObject ? inListObject.UID:nil)
																					   service:(inListObject ? [(AIListContact *)inListObject service]:nil)
																					   account:nil];
	} else {
		newContactWindowController = [[AINewContactWindowController alloc] initWithContactName:nil
																					   service:nil
																					   account:nil];
	}
	
	[newContactWindowController showOnWindow:inWindow];
}

/*!
 * @brief Add contact request notification
 *
 * Display the add contact window.  Triggered by an incoming Contact_AddNewContact notification 
 * @param notification Notification with a userInfo containing @"UID" and @"Service" keys
 */
- (void)addContactRequest:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	if (userInfo) {
		AINewContactWindowController *newContactWindowController = [[AINewContactWindowController alloc] initWithContactName:[userInfo objectForKey:@"UID"]
																													 service:[userInfo objectForKey:@"AIService"]
																													 account:[userInfo objectForKey:@"AIAccount"]];
		[newContactWindowController showOnWindow:nil];
	}
}


//Add Group ------------------------------------------------------------------------------------------------------------
#pragma mark Add Group
/*!
 * @brief Prompt for a new group
 */
- (IBAction)addGroup:(id)sender
{
	AINewGroupWindowController *newGroupController = [[AINewGroupWindowController alloc] init];
	[newGroupController showOnWindow:nil];
}


//Delete Selection -----------------------------------------------------------------------------------------------------
#pragma mark Delete Selection
/*!
 * @brief Delete the list objects selected in the contact list
 */
- (IBAction)deleteSelection:(id)sender
{	
	[self deleteFromArray:[adium.interfaceController arrayOfSelectedListObjectsWithGroupsInContactList]];
}

/*!
 * @brief Delete the list object associated with the current context menu
 */
- (IBAction)deleteSelectionFromTab:(id)sender
{
	NSArray *selectedObjects = [adium.interfaceController arrayOfSelectedListObjectsWithGroupsInContactList];
	
	if (selectedObjects) {
		[self deleteFromArray:selectedObjects];
	} else {
		AIListObject   *currentContextMenuObject;
		if ((currentContextMenuObject = adium.menuController.currentContextMenuObject)) {
			NSMutableArray *contactInstances = [NSMutableArray array];
			
			for (AIListGroup *group in currentContextMenuObject.groups) {
				[contactInstances addObject:[NSDictionary dictionaryWithObjectsAndKeys:currentContextMenuObject, @"ListObject",
											 group, @"ContainingObject", nil]];
			}

			[self deleteFromArray:contactInstances];
		}
	}
}

/*!
 * @brief Delete an array of contacts
 *
 * After a modal confirmation prompt, the objects in the array are deleted.
 *
 * @param array An NSArray of NSDictionarys describing the AIListObjects
 */
- (void)deleteFromArray:(NSArray *)array
{
	if (!array) {
		NSBeep();
		return;
	}
	
	NSString *message = nil;

	/* XXX Should allow the account to determine if the message will indicate the group is just hidden, not deleted, á la Twitter */
	if (array.count == 1) {
		AIListObject *listObject = [[array objectAtIndex:0] objectForKey:@"ListObject"];
		AIListObject <AIContainingObject> *containingObject = [[array objectAtIndex:0] objectForKey:@"ContainingObject"];
		
		if ([listObject isKindOfClass:[AIListGroup class]]) {
			message = [NSString stringWithFormat:AILocalizedString(@"This will remove the group \"%@\" from the contact lists of your online accounts. The %lu contacts within this group will also be removed.\n\nThis action can not be undone.", nil),
					   listObject.displayName,
					   ((AIListGroup *)listObject).countOfContainedObjects];
		} else {
			if (listObject.containingObjects.count == 1) {
				message = [NSString stringWithFormat:AILocalizedString(@"This will remove %@ from the contact lists of your online accounts.",nil), listObject.displayName];
			} else {
				message = [NSString stringWithFormat:AILocalizedString(@"This will remove %@ from the group \"%@\" of your online accounts.",nil),
						   listObject.displayName,
						   containingObject.displayName];
			}
		}
	} else {
		BOOL		containsGroup = NO;
		
		for (NSDictionary *dict in array) {
			if ([[dict objectForKey:@"ListObject"] isKindOfClass:[AIListGroup class]]) {
				containsGroup = YES;
				break;
			}
		}
		
		if (containsGroup) {
			message = [NSString stringWithFormat:AILocalizedString(@"This will remove %lu items from the contact lists of your online accounts. Contacts in any deleted groups will also be removed.\n\nThis action can not be undone.",nil), array.count];
		} else {
			message = [NSString stringWithFormat:AILocalizedString(@"This will remove %lu contacts from the contact lists of your online accounts.\n\nThis action cannot be undone.",nil), array.count];
		}	
	}

	//Make sure we're in the front so our prompt is visible
	[NSApp activateIgnoringOtherApps:YES];
	
	//Guard deletion with a warning prompt		
	NSInteger result = NSRunAlertPanel(AILocalizedString(@"Remove from list?",nil),
								 AILocalizedString(@"Removing any contacts from their last group will permanently remove them from your contact list.\n\n%@", nil),
								 AILocalizedString(@"Remove",nil),
								 AILocalizedString(@"Cancel",nil),
								 nil, message);

	if (result == NSAlertDefaultReturn) {
		for (NSDictionary *dict in array) {
			[[dict objectForKey:@"ListObject"] removeFromGroup:[dict objectForKey:@"ContainingObject"]];
		}
	}
}

@end
