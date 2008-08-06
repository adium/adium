//
//  AIContactInfoWindowPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 7/27/06.
//

#import "AIContactInfoWindowPlugin.h"
#import "AIContactInfoWindowController.h"
#import "ESShowContactInfoPromptController.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>

#import <Adium/AIListObject.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>

#define VIEW_CONTACTS_INFO				AILocalizedString(@"Get Info",nil)
#define VIEW_CONTACTS_INFO_WITH_PROMPT	[AILocalizedString(@"Get Info for Contact", nil) stringByAppendingEllipsis]
#define GET_INFO_MASK					(NSCommandKeyMask | NSShiftKeyMask)
#define ALTERNATE_GET_INFO_MASK			(NSCommandKeyMask | NSShiftKeyMask | NSControlKeyMask)

#define	TITLE_SHOW_INFO					AILocalizedString(@"Show Info",nil)
#define	TOOLTIP_SHOW_INFO				AILocalizedString(@"Show information about this contact or group and change settings specific to it","Tooltip for the Show Info toolbar button")

@interface AIContactInfoWindowPlugin (PRIVATE)
- (void)prepareContactInfo;
@end

@implementation AIContactInfoWindowPlugin
- (void)installPlugin
{
	[self prepareContactInfo];
}

//Contact Info --------------------------------------------------------------------------------
#pragma mark Contact Info
//Show info for the selected contact
- (IBAction)showContactInfo:(id)sender
{
	AIListObject *listObject = nil;

	if ((sender == menuItem_getInfoAlternate) || (sender == menuItem_getInfo) || ([sender isKindOfClass:[NSToolbarItem class]])) {
		listObject = [[adium interfaceController] selectedListObject];
	}
	
	if (!listObject) {
		listObject = [[adium menuController] currentContextMenuObject];
	}
	
	if (listObject) {
		[NSApp activateIgnoringOtherApps:YES];

		[AIContactInfoWindowController showInfoWindowForListObject:listObject];
	}
}

- (void)showSpecifiedContactInfo:(id)sender
{
	[ESShowContactInfoPromptController showPrompt];
}

//Prepare the contact info menu and toolbar items
- (void)prepareContactInfo
{
	//Add our get info contextual menu item
	menuItem_getInfoContextualContact = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_CONTACTS_INFO
																							 target:self
																							 action:@selector(showContactInfo:)
																					  keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:menuItem_getInfoContextualContact
									   toLocation:Context_Contact_Manage];
	
	menuItem_getInfoContextualGroup = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_CONTACTS_INFO
																						   target:self
																						   action:@selector(showContactInfo:)
																					keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:menuItem_getInfoContextualGroup
									   toLocation:Context_Group_Manage];
	
	//Install the standard Get Info menu item which will always be command-shift-I
	menuItem_getInfo = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_CONTACTS_INFO
																			target:self
																			action:@selector(showContactInfo:)
																	 keyEquivalent:@"i"];
	[menuItem_getInfo setKeyEquivalentModifierMask:GET_INFO_MASK];
	[[adium menuController] addMenuItem:menuItem_getInfo toLocation:LOC_Contact_Info];
	
	/* Install the alternate Get Info menu item which will be alternately command-I and command-shift-I, in the contact list
		* and in all other places, respectively.
		*/
	menuItem_getInfoAlternate = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_CONTACTS_INFO
																					 target:self
																					 action:@selector(showContactInfo:)
																			  keyEquivalent:@"i"];
	[menuItem_getInfoAlternate setKeyEquivalentModifierMask:ALTERNATE_GET_INFO_MASK];
	[menuItem_getInfoAlternate setAlternate:YES];
	[[adium menuController] addMenuItem:menuItem_getInfoAlternate toLocation:LOC_Contact_Info];
	
	//Register for the contact list notifications
	[[adium notificationCenter] addObserver:self selector:@selector(contactListDidBecomeMain:)
									   name:Interface_ContactListDidBecomeMain
									 object:nil];
	[[adium notificationCenter] addObserver:self selector:@selector(contactListDidResignMain:)
									   name:Interface_ContactListDidResignMain
									 object:nil];
	
	//Watch changes in viewContactInfoMenuItem_alternate's menu so we can maintain its alternate status
	//(it will expand into showing both the normal and the alternate items when the menu changes)
	[[adium notificationCenter] addObserver:self selector:@selector(menuChanged:)
									   name:AIMenuDidChange
									 object:[menuItem_getInfoAlternate menu]];
	
	//Install the Get Info (prompting for a contact name) menu item
	menuItem_getInfoWithPrompt = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VIEW_CONTACTS_INFO_WITH_PROMPT
																					  target:self
																					  action:@selector(showSpecifiedContactInfo:)
																			   keyEquivalent:@"i"];
	[menuItem_getInfoWithPrompt setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
	[[adium menuController] addMenuItem:menuItem_getInfoWithPrompt toLocation:LOC_Contact_Info];
	
	//Add our get info toolbar item
	NSToolbarItem *toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"ShowInfo"
																		 label:AILocalizedString(@"Info",nil)
																  paletteLabel:TITLE_SHOW_INFO
																	   toolTip:TOOLTIP_SHOW_INFO
																		target:self
															   settingSelector:@selector(setImage:)
																   itemContent:[NSImage imageNamed:@"pref-personal" forClass:[self class] loadLazily:YES]
																		action:@selector(showContactInfo:)
																		  menu:nil];
	[[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
}

//Always be able to show the inspector
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ((menuItem == menuItem_getInfo) || (menuItem == menuItem_getInfoAlternate)) {
		return [[adium interfaceController] selectedListObject] != nil;
		
	} else if ((menuItem == menuItem_getInfoContextualContact) || (menuItem == menuItem_getInfoContextualGroup)) {
		return [[adium menuController] currentContextMenuObject] != nil;
		
	} else if (menuItem == menuItem_getInfoWithPrompt) {
		return [[adium accountController] oneOrMoreConnectedAccounts];
	}
	
	return YES;
}

- (void)contactListDidBecomeMain:(NSNotification *)notification
{
    [[adium menuController] removeItalicsKeyEquivalent];
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
    [[adium menuController] restoreItalicsKeyEquivalent];
}

- (void)menuChanged:(NSNotification *)notification
{
	[NSMenu updateAlternateMenuItem:menuItem_getInfoAlternate];
}

@end
