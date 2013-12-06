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

#import "AIContactInfoWindowPlugin.h"
#import "AIContactInfoWindowController.h"
#import "ESShowContactInfoPromptController.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>

#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListBookmark.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>

#define VIEW_CONTACTS_INFO				AILocalizedString(@"Get Info",nil)
#define VIEW_CONTACTS_INFO_WITH_PROMPT	[AILocalizedString(@"Get Info for Contact", nil) stringByAppendingEllipsis]
#define VIEW_BOOKMARK_GET_INFO			AILocalizedString(@"Get Info for Bookmark", nil)
#define GET_INFO_MASK					(NSCommandKeyMask | NSShiftKeyMask)
#define ALTERNATE_GET_INFO_MASK			(NSCommandKeyMask | NSShiftKeyMask | NSControlKeyMask)

#define	TITLE_SHOW_INFO					AILocalizedString(@"Get Info",nil)
#define	TOOLTIP_SHOW_INFO				AILocalizedString(@"Show information about this contact or group and change settings specific to it","Tooltip for the Get Info toolbar button")

@interface AIContactInfoWindowPlugin ()
- (void)prepareContactInfo;
- (void)contactListDidBecomeMain:(NSNotification *)notification;
- (void)contactListDidResignMain:(NSNotification *)notification;
@end

@implementation AIContactInfoWindowPlugin
- (void)installPlugin
{
	[self prepareContactInfo];
}

- (void)uninstallPlugin
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

//Contact Info --------------------------------------------------------------------------------
#pragma mark Contact Info
/*!
 * @brief Show the information for a contact
 *
 * Shows the information of a contact which is the object of the notification.
 */
- (void)showContactInfoForNotification:(NSNotification *)notification
{
	if (!notification.object)
		return;
	
	[AIContactInfoWindowController showInfoWindowForListObject:notification.object];
}

//Show info for the selected contact
- (IBAction)showContactInfo:(id)sender
{
	AIListObject *listObject = nil;
	
	if ([sender isKindOfClass:[NSToolbarItem class]]) {
		for(NSWindow *currentWindow in [NSApp windows]) {
			if (currentWindow.toolbar == ((NSToolbarItem *)sender).toolbar) {
				AIChat *chat = [adium.interfaceController activeChatInWindow:currentWindow];
				
				if (chat.isGroupChat) {
					listObject = [adium.contactController existingBookmarkForChat:chat];
				} else {
					listObject = chat.listObject;
				}
				
				break;
			}
		}
	}
	
	if (!listObject && adium.interfaceController.activeChat.isGroupChat && sender != menuItem_getInfoContextualContact) {
		listObject = [adium.contactController existingBookmarkForChat:adium.interfaceController.activeChat];
	}
	
	if (!listObject && (sender == menuItem_getInfoAlternate || sender == menuItem_getInfo)) {
		listObject = adium.interfaceController.selectedListObject;
	}
		
	if (!listObject) {
		listObject = adium.menuController.currentContextMenuObject;
	}
		
	if ([listObject isKindOfClass:[AIListObject class]]) {
		[NSApp activateIgnoringOtherApps:YES];

		[AIContactInfoWindowController showInfoWindowForListObject:listObject];
	}
}

- (IBAction)showBookmarkInfo:(id)sender
{
	AIListBookmark *bookmark = [adium.contactController existingBookmarkForChat:adium.menuController.currentContextMenuChat];
	
	[NSApp activateIgnoringOtherApps:YES];
	
	[AIContactInfoWindowController showInfoWindowForListObject:bookmark];	
}

- (void)showSpecifiedContactInfo:(id)sender
{
	[ESShowContactInfoPromptController showPrompt];
}

//Prepare the contact info menu and toolbar items
- (void)prepareContactInfo
{
	//Add our get info contextual menu item
	menuItem_getInfoContextualContact = [[NSMenuItem alloc] initWithTitle:VIEW_CONTACTS_INFO
																							 target:self
																							 action:@selector(showContactInfo:)
																					  keyEquivalent:@""];
	[adium.menuController addContextualMenuItem:menuItem_getInfoContextualContact
									   toLocation:Context_Contact_Manage];
	
	menuItem_getInfoContextualGroup = [[NSMenuItem alloc] initWithTitle:VIEW_CONTACTS_INFO
																						   target:self
																						   action:@selector(showContactInfo:)
																					keyEquivalent:@""];
	[adium.menuController addContextualMenuItem:menuItem_getInfoContextualGroup
									   toLocation:Context_Group_Manage];
	
	menuItem_getInfoContextualGroupChat = [[NSMenuItem alloc] initWithTitle:VIEW_BOOKMARK_GET_INFO
																							   target:self
																							   action:@selector(showBookmarkInfo:)
																						keyEquivalent:@""];
	[adium.menuController addContextualMenuItem:menuItem_getInfoContextualGroupChat toLocation:Context_GroupChat_Manage];
	
	
	//Install the standard Get Info menu item which will always be command-shift-I
	menuItem_getInfo = [[NSMenuItem alloc] initWithTitle:VIEW_CONTACTS_INFO
																			target:self
																			action:@selector(showContactInfo:)
																	 keyEquivalent:@"i"];
	[menuItem_getInfo setKeyEquivalentModifierMask:GET_INFO_MASK];
	[adium.menuController addMenuItem:menuItem_getInfo toLocation:LOC_Contact_Info];
	
	/* Install the alternate Get Info menu item which will be alternately command-I and command-shift-I, in the contact list
		* and in all other places, respectively.
		*/
	menuItem_getInfoAlternate = [[NSMenuItem alloc] initWithTitle:VIEW_CONTACTS_INFO
																					 target:self
																					 action:@selector(showContactInfo:)
																			  keyEquivalent:@"i"];
	[menuItem_getInfoAlternate setKeyEquivalentModifierMask:ALTERNATE_GET_INFO_MASK];
	[menuItem_getInfoAlternate setAlternate:YES];
	[adium.menuController addMenuItem:menuItem_getInfoAlternate toLocation:LOC_Contact_Info];
	
	//Register for the contact list notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactListDidBecomeMain:)
									   name:Interface_ContactListDidBecomeMain
									 object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactListDidResignMain:)
									   name:Interface_ContactListDidResignMain
									 object:nil];
	
	//Watch changes in viewContactInfoMenuItem_alternate's menu so we can maintain its alternate status
	//(it will expand into showing both the normal and the alternate items when the menu changes)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuChanged:)
									   name:AIMenuDidChange
									 object:[menuItem_getInfoAlternate menu]];
	
	//Install the Get Info (prompting for a contact name) menu item
	menuItem_getInfoWithPrompt = [[NSMenuItem alloc] initWithTitle:VIEW_CONTACTS_INFO_WITH_PROMPT
																					  target:self
																					  action:@selector(showSpecifiedContactInfo:)
																			   keyEquivalent:@"i"];
	[menuItem_getInfoWithPrompt setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
	[adium.menuController addMenuItem:menuItem_getInfoWithPrompt toLocation:LOC_Contact_Info];
	
	//Add our get info toolbar item
	NSToolbarItem *toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"ShowInfo"
																		 label:AILocalizedString(@"Info",nil)
																  paletteLabel:TITLE_SHOW_INFO
																	   toolTip:TOOLTIP_SHOW_INFO
																		target:self
															   settingSelector:@selector(setImage:)
																   itemContent:[NSImage imageNamed:@"get-info" forClass:[self class] loadLazily:YES]
																		action:@selector(showContactInfo:)
																		  menu:nil];
	[adium.toolbarController registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showContactInfoForNotification:)
												 name:@"AIShowContactInfo"
											   object:nil];
}

//Always be able to show the inspector
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ((menuItem == menuItem_getInfo) || (menuItem == menuItem_getInfoAlternate)) {
		return adium.interfaceController.selectedListObject != nil || adium.interfaceController.activeChat.isGroupChat;
		
	} else if ((menuItem == menuItem_getInfoContextualContact) || (menuItem == menuItem_getInfoContextualGroup)) {
		return adium.menuController.currentContextMenuObject != nil;
		
	} else if (menuItem == menuItem_getInfoWithPrompt) {
		return [adium.accountController oneOrMoreConnectedAccounts];
	} else if ([menuItem.title isEqualToString:VIEW_BOOKMARK_GET_INFO]) {
		// WKMV's context menu makes a copy of menu items; check against title.
		return ([adium.contactController existingBookmarkForChat:adium.menuController.currentContextMenuChat] != nil);
	}
	
	return YES;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
	for(NSWindow *currentWindow in [NSApp windows]) {
		if (currentWindow.toolbar == toolbarItem.toolbar) {
			AIChat *chat = [adium.interfaceController activeChatInWindow:currentWindow];

			if (chat.isGroupChat && [adium.contactController existingBookmarkForChat:chat])
				return YES;
				
			if (!chat.isGroupChat)
				return YES;
		}
	}
	
	return NO;
}

- (void)contactListDidBecomeMain:(NSNotification *)notification
{
    [adium.menuController removeItalicsKeyEquivalent];
    [menuItem_getInfoAlternate setKeyEquivalentModifierMask:(NSCommandKeyMask)];
	[menuItem_getInfoAlternate setAlternate:YES];
}

- (void)contactListDidResignMain:(NSNotification *)notification
{
    //set our alternate modifier mask back to the obscure combination
    [menuItem_getInfoAlternate setKeyEquivalent:@"i"];
    [menuItem_getInfoAlternate setKeyEquivalentModifierMask:ALTERNATE_GET_INFO_MASK];
    [menuItem_getInfoAlternate setAlternate:YES];
	
    //Now give the italics its combination back
    [adium.menuController restoreItalicsKeyEquivalent];
}

- (void)menuChanged:(NSNotification *)notification
{
	[NSMenu updateAlternateMenuItem:menuItem_getInfoAlternate];
}

@end
