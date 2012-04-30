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


#import "AIMenuController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@interface AIMenuController ()
- (void)localizeMenuTitles;
- (void)updateAccountSpecificMenu:(NSMenu *)menu;
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray usingMenu:(NSMenu *)inMenu;
- (void)addMenuItemsForContact:(AIListContact *)inContact toMenu:(NSMenu *)workingMenu separatorItem:(BOOL *)separatorItem;
- (void)addMenuItemsForChat:(AIChat *)inContact toMenu:(NSMenu *)workingMenu separatorItem:(BOOL *)separatorItem;
@end

@implementation AIMenuController

- (id)init
{
	if ((self = [super init])) {
		//Set up our contextual menu stuff
		contextualMenu = [[NSMenu alloc] init];
		[contextualMenu setDelegate:self];

		contextualMenuItemDict = [[NSMutableDictionary alloc] init];
		currentContextMenuObject = nil;

		textViewContextualMenu = [[NSMenu alloc] init];
		[textViewContextualMenu setDelegate:self];
	}
	
	return self;
}

- (void)awakeFromNib
{
	//Build the array of menu locations
	locationArray = [[NSMutableArray alloc] initWithObjects:menu_Adium_About, menu_Adium_Preferences, menu_Adium_Other,
					 menu_File_New, menu_File_Close, menu_File_Save, menu_File_Accounts, menu_File_Additions,	
					 menu_Edit_Bottom, menu_Edit_Links, menu_Edit_Additions,
					 menu_View_General, menu_View_Sorting, menu_View_Toggles, menu_View_Counting_Toggles, menu_View_Appearance_Toggles, menu_View_Additions, 
					 menu_Display_General, menu_Display_Jump, menu_Display_MessageControl,
					 menu_Contact_Manage, menu_Contact_Info, menu_Contact_Action, menu_Contact_NegativeAction, menu_Contact_Additions,
					 menu_Status_State, menu_Status_SocialNetworking, menu_Status_Accounts, menu_Status_Additions,
					 menu_Format_Styles, menu_Format_Palettes, menu_Format_Additions,
					 menu_Window_Top, menu_Window_Commands, menu_Window_Auxiliary, menu_Window_Fixed,
					 menu_Help_Local, menu_Help_Web, menu_Help_Additions,
					 menu_Dock_Status, nil];
}

- (void)controllerDidLoad
{	
	[self localizeMenuTitles];	
}

//Close
- (void)controllerWillClose
{
	//There's no need to remove the menu items, the system will take them out for us.
}

//Add a menu item
- (void)addMenuItem:(NSMenuItem *)newItem toLocation:(AIMenuLocation)location
{
	NSMenuItem  *menuItem;
	NSMenu		*targetMenu = nil;
	NSInteger			targetIndex;
	NSInteger			destination;

	//Find the menu item (or the closest one above it)
	destination = location;
	menuItem = [locationArray objectAtIndex:destination];
	while ((menuItem == nilMenuItem) && (destination > 0)) {
		destination--;
		menuItem = [locationArray objectAtIndex:destination];
	}

	if ([menuItem isKindOfClass:[NSMenuItem class]]) {
		//If attached to a menu item, insert below that item
		targetMenu = [menuItem menu];
		targetIndex = [targetMenu indexOfItem:menuItem];
		
		//If the next item is its alternate, skip over it
		if ((targetIndex < [targetMenu numberOfItems]-1) && [[targetMenu itemAtIndex:targetIndex+1] isAlternate]) {
			targetIndex++;
		}
	} else {
		//If it's attached to an NSMenu (and not an NSMenuItem), insert at the top of the menu
		targetMenu = (NSMenu *)menuItem;
		targetIndex = -1;
	}

	//Insert the new item and a divider (if necessary)
	if (location != destination) {
		[targetMenu insertItem:[NSMenuItem separatorItem] atIndex:++targetIndex];
	}

	[targetMenu insertItem:newItem atIndex:targetIndex+1];

	//update the location array
	[locationArray replaceObjectAtIndex:location withObject:newItem];

	[[NSNotificationCenter defaultCenter] postNotificationName:AIMenuDidChange object:[newItem menu] userInfo:nil];
}

//Remove a menu item
- (void)removeMenuItem:(NSMenuItem *)targetItem
{
	NSMenu		*targetMenu = [targetItem menu];
	if (!targetMenu) return;

	NSInteger			targetIndex = [targetMenu indexOfItem:targetItem];
	NSUInteger	loop, maxLoop;
	
	//Fix the pointer if this is one
	for (loop = 0, maxLoop = [locationArray count]; loop < maxLoop; loop++) {
		NSMenuItem	*menuItem = [locationArray objectAtIndex:loop];

		//Move to the item above it, nil if a divider
		if (menuItem == targetItem) {
			if (targetIndex != 0) {
				NSMenuItem	*previousItem = [targetMenu itemAtIndex:(targetIndex - 1)];

				if ([previousItem isSeparatorItem]) {
					[locationArray replaceObjectAtIndex:loop withObject:nilMenuItem];
				} else {
					[locationArray replaceObjectAtIndex:loop withObject:previousItem];
				}
			} else {
				//If there are no more items, attach to the menu
				[locationArray replaceObjectAtIndex:loop withObject:targetMenu];
			}
		}
	}

	//Remove the item
	[targetMenu removeItem:targetItem];

	if (!menuItemProcessingDelays) {
		//Remove any double dividers by removing the upper divier. Also, remove dividers at the top or bottom of the menu
		for (loop = 0; loop < [targetMenu numberOfItems]; loop++) {
			if (([[targetMenu itemAtIndex:loop] isSeparatorItem]) && 
				((loop == [targetMenu numberOfItems] - 1) || (loop == 0) || ([[targetMenu itemAtIndex:loop-1] isSeparatorItem]))) {
				[targetMenu removeItemAtIndex:loop];
				loop--;//re-search the location
			}
		}
		
		/* XXX Note that this notification isn't being posted if triggerred while in menuItemProcessingDelays.
		 * It's not currently needed in that situation so this is a very small performance hack... it could move outside the
		 * conditional if necessary. -evands
		 */
		[[NSNotificationCenter defaultCenter] postNotificationName:AIMenuDidChange object:targetMenu userInfo:nil];
	}
}

- (void)delayMenuItemPostProcessing
{
	menuItemProcessingDelays++;
}

- (void)endDelayMenuItemPostProcessing
{
	menuItemProcessingDelays--;	
}

#pragma mark Contextual menu

/*!
 * @brief Register a menu item for inclusion in contextual menus
 *
 * @param newItem The NSMenuItem to add
 * @param location The AIContextMenuLocation associated with this menu item.  Ordering within a given location is not defined.
 */
- (void)addContextualMenuItem:(NSMenuItem *)newItem toLocation:(AIContextMenuLocation)location
{
	NSNumber			*key;
	NSMutableArray		*itemArray;

	//Search for an existing item array for menu items in this location
	key = [NSNumber numberWithInteger:location];
	itemArray = [contextualMenuItemDict objectForKey:key];

	//If one is not found, create it
	if (!itemArray) {
		itemArray = [NSMutableArray array];
		[contextualMenuItemDict setObject:itemArray forKey:key];
	}

	//Add the passed menu item to the array
	[itemArray addObject:newItem];
}

/*!
 * @brief Obtain an NSMenu of contextual menu items for a list object
 *
 * @param inLocationArray An NSArray of NSNumbers whose intValues are AIContextMenuLocation. The menu will be returned with these locations' items in order, separated by NSMenuItemSeparators.
 * @param inObject The object for which menu items should be generated
 */
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forListObject:(AIListObject *)inObject
{
	NSMenu		*workingMenu;
	BOOL		separatorItem;

	//Remember what our menu is configured for
	[currentContextMenuObject release];
	currentContextMenuObject = [inObject retain];

	//Get the pre-created contextual menu items
	workingMenu = [self contextualMenuWithLocations:inLocationArray usingMenu:contextualMenu];

	//Add any account-specific menu items
	separatorItem = YES;
	if ([inObject isKindOfClass:[AIMetaContact class]]) {
		for (AIListContact *aListContact in ((AIMetaContact *)inObject).uniqueContainedObjects) {
			[self addMenuItemsForContact:aListContact
								  toMenu:workingMenu
						   separatorItem:&separatorItem];
		}

	} else if ([inObject isKindOfClass:[AIListContact class]] && ![inObject isKindOfClass:[AIListBookmark class]]) {
		[self addMenuItemsForContact:(AIListContact *)inObject
							  toMenu:workingMenu
					   separatorItem:&separatorItem];
	}

	return workingMenu;
}

/*!
 * @brief Obtain an NSMenu of contextual menu items for a chat
 *
 * @param inLocationArray An NSArray of NSNumbers whose intValues are AIContextMenuLocation. The menu will be returned with these locations' items in order, separated by NSMenuItemSeparators.
 * @param inChat The chat for which menu items should be generated
 */
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forChat:(AIChat *)inChat
{
	NSMenu		*workingMenu;
	BOOL		separatorItem;
	
	//Remember what our menu is configured for
	[currentContextMenuChat release];
	currentContextMenuChat = [inChat retain];
	
	//Get the pre-created contextual menu items
	workingMenu = [self contextualMenuWithLocations:inLocationArray usingMenu:contextualMenu];
	
	//Add any account-specific menu items
	separatorItem = (workingMenu.numberOfItems != 0);

	[self addMenuItemsForChat:inChat
					   toMenu:workingMenu
				separatorItem:&separatorItem];
	
	return workingMenu;
}

- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forListObject:(AIListObject *)inObject inChat:(AIChat *)inChat
{
	[currentContextMenuChat release];
	currentContextMenuChat = [inChat retain];
	
	return [self contextualMenuWithLocations:inLocationArray forListObject:inObject];
}

/*!
 * @brief Add account-specific menuItems for a passed contact to a menu. 
 * @param inContact The contact
 * @param workingMenu The NSMenu, which must not be nil
 * @param seperatorItem Pointer to a BOOL which can be YES to indicate that a separator item should be inserted before the menu items if any are added. It will then be set to NO.
 */
- (void)addMenuItemsForContact:(AIListContact *)inContact toMenu:(NSMenu *)workingMenu separatorItem:(BOOL *)separatorItem
{
	NSArray			*itemArray = [inContact.account menuItemsForContact:inContact];

	if (itemArray && [itemArray count]) {
		NSMenuItem		*menuItem;

		if (*separatorItem == YES) {
			[workingMenu addItem:[NSMenuItem separatorItem]];
			*separatorItem = NO;
		}

		for (menuItem in itemArray) {
			[workingMenu addItem:menuItem];
		}
	}
}

/*!
 * @brief Add account-specific menuItems for a passed chat to a menu. 
 * @param inChat The chat
 * @param workingMenu The NSMenu, which must not be nil
 * @param seperatorItem Pointer to a BOOL which can be YES to indicate that a separator item should be inserted before the menu items if any are added. It will then be set to NO.
 */
- (void)addMenuItemsForChat:(AIChat *)inContact toMenu:(NSMenu *)workingMenu separatorItem:(BOOL *)separatorItem
{
	NSArray			*itemArray = [inContact.account menuItemsForChat:inContact];
	
	if (itemArray && [itemArray count]) {
		NSMenuItem		*menuItem;
		
		if (*separatorItem == YES) {
			[workingMenu addItem:[NSMenuItem separatorItem]];
			*separatorItem = NO;
		}
		
		for (menuItem in itemArray) {
			[workingMenu addItem:menuItem];
		}
	}
}

- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray
{
	return [self contextualMenuWithLocations:inLocationArray usingMenu:textViewContextualMenu];
}

- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray usingMenu:(NSMenu *)inMenu
{
	NSNumber		*location;
	NSMenuItem		*menuItem;
	BOOL			itemsAbove = NO;

	//Remove all items from the existing menu
	[inMenu removeAllItems];

	//Process each specified location
	for (location in inLocationArray) {
		NSArray			*menuItems = [contextualMenuItemDict objectForKey:location];

		//Add a seperator
		if (itemsAbove && [menuItems count]) {
			[inMenu addItem:[NSMenuItem separatorItem]];
			itemsAbove = NO;
		}

		//Add each menu item in the location
		for (menuItem in menuItems) {
			//Add the menu item
			[inMenu addItem:menuItem];
			itemsAbove = YES;
		}
	}

	return inMenu;
}

- (AIListObject *)currentContextMenuObject
{
	return currentContextMenuObject;
}

- (AIChat *)currentContextMenuChat
{
	return currentContextMenuChat;
}

#pragma mark Italics

- (void)removeItalicsKeyEquivalent
{
	[menuItem_Format_Italics setKeyEquivalent:@""];
}

- (void)restoreItalicsKeyEquivalent
{
	[menuItem_Format_Italics setKeyEquivalent:@"i"];
}

#pragma mark Localization

- (void)localizeMenuTitles
{
	//Menu items in MainMenu.nib for localization purposes
	[menuItem_file setTitle:AILocalizedString(@"File","Title of the File menu")];
	[menuItem_edit setTitle:AILocalizedString(@"Edit","Title of the Edit menu")];
	[menuItem_view setTitle:AILocalizedString(@"View","Title of the View menu")];
	[menuItem_display setTitle:AILocalizedString(@"Display", "Title of the Display menu")];
	[menuItem_status setTitle:AILocalizedString(@"Status","Title of the Status menu")];
	[menuItem_contact setTitle:AILocalizedString(@"Contact","Title of the Contact menu")];
	[menuItem_format setTitle:AILocalizedString(@"Format","Title of the Format menu")];
	[menuItem_window setTitle:AILocalizedString(@"Window","Title of the Window menu")];
	[menuItem_help setTitle:AILocalizedString(@"Help","Title of the Help menu")];
	
	//Also set the title of their submenus (Leopard requires this)
	[[menuItem_file submenu] setTitle:AILocalizedString(@"File","Title of the File menu")];
	[[menuItem_edit submenu] setTitle:AILocalizedString(@"Edit","Title of the Edit menu")];
	[[menuItem_view submenu] setTitle:AILocalizedString(@"View","Title of the View menu")];
	[[menuItem_display submenu] setTitle:AILocalizedString(@"Display", "Title of the Display menu")];
	[[menuItem_status submenu] setTitle:AILocalizedString(@"Status","Title of the Status menu")];
	[[menuItem_contact submenu] setTitle:AILocalizedString(@"Contact","Title of the Contact menu")];
	[[menuItem_format submenu] setTitle:AILocalizedString(@"Format","Title of the Format menu")];
	[[menuItem_window submenu] setTitle:AILocalizedString(@"Window","Title of the Window menu")];
	[[menuItem_help submenu] setTitle:AILocalizedString(@"Help","Title of the Help menu")];
	
	//Adium menu
	[menuItem_aboutAdium setTitle:AILocalizedString(@"About Adium",nil)];
	[menuItem_adiumXtras setTitle:[AILocalizedString(@"Xtras Manager",nil) stringByAppendingEllipsis]];
	[menuItem_checkForUpdates setTitle:[AILocalizedString(@"Check For Updates",nil) stringByAppendingEllipsis]];
	[menuItem_preferences setTitle:[AILocalizedString(@"Preferences",nil) stringByAppendingEllipsis]];
	[menuItem_donate setTitle:[AILocalizedString(@"Donate",nil) stringByAppendingEllipsis]];
	[menuItem_helpOut setTitle:[AILocalizedString(@"Contributing to Adium",nil) stringByAppendingEllipsis]];

	[menuItem_services setTitle:AILocalizedString(@"Services","Services menu item in the Adium menu")];
	[menuItem_hideAdium setTitle:AILocalizedString(@"Hide Adium",nil)];
	[menuItem_hideOthers setTitle:AILocalizedString(@"Hide Others",nil)];
	[menuItem_showAll setTitle:AILocalizedString(@"Show All",nil)];
	[menuItem_quitAdium setTitle:AILocalizedString(@"Quit Adium",nil)];

	//File menu	
	[menuItem_reopenTab setTitle:AILocalizedString(@"Reopen Closed Tab", "Title for the reopen closed tab menu item")];
	[menuItem_close setTitle:AILocalizedString(@"Close Window","Title for the close window menu item")];
	[menuItem_closeChat setTitle:AILocalizedString(@"Close Chat","Title for the close chat menu item")];
	[menuItem_closeAllChats setTitle:AILocalizedString(@"Close All Chats","Title for the close all chats menu item")];
	[menuItem_saveAs setTitle:[AILocalizedString(@"Save As",nil) stringByAppendingEllipsis]];
	[menuItem_print setTitle:[AILocalizedString(@"Print",nil) stringByAppendingEllipsis]];

	//Edit menu
	[menuItem_cut setTitle:AILocalizedString(@"Cut",nil)];
	[menuItem_copy setTitle:AILocalizedString(@"Copy",nil)];
	[menuItem_paste setTitle:AILocalizedString(@"Paste",nil)];
	[menuItem_pasteWithImagesAndColors setTitle:AILocalizedString(@"Paste with Images and Colors",nil)];
	[menuItem_pasteAndMatchStyle setTitle:AILocalizedString(@"Paste and Match Style",nil)];
	[menuItem_clear setTitle:AILocalizedString(@"Clear",nil)];
	[menuItem_selectAll setTitle:AILocalizedString(@"Select All",nil)];
    [menuItem_deselectAll setTitle:AILocalizedString(@"Deselect All",nil)];

#define TITLE_FIND AILocalizedString(@"Find",nil)
	[menuItem_find setTitle:TITLE_FIND];
	[menuItem_findCommand setTitle:[TITLE_FIND stringByAppendingEllipsis]];
	[menuItem_findNext setTitle:AILocalizedString(@"Find Next",nil)];
	[menuItem_findPrevious setTitle:AILocalizedString(@"Find Previous",nil)];
	[menuItem_findUseSelectionForFind setTitle:AILocalizedString(@"Use Selection for Find",nil)];
	[menuItem_findJumpToSelection setTitle:AILocalizedString(@"Jump to Selection",nil)];

#define TITLE_SPELLING AILocalizedString(@"Spelling",nil)
	[menuItem_spelling setTitle:TITLE_SPELLING];
	[menuItem_spellingCommand setTitle:[TITLE_SPELLING stringByAppendingEllipsis]];
	[menuItem_spellingCheckSpelling setTitle:AILocalizedString(@"Check Spelling",nil)];
	[menuItem_spellingCheckSpellingAsYouType setTitle:AILocalizedString(@"Check Spelling As You Type",nil)];
	[menuItem_spellingCheckGrammarWithSpelling setTitle:AILocalizedString(@"Check Grammar With Spelling",nil)];
	
	[menuItem_speech setTitle:AILocalizedString(@"Speech",nil)];
	[menuItem_startSpeaking setTitle:AILocalizedString(@"Start Speaking",nil)];
	[menuItem_stopSpeaking setTitle:AILocalizedString(@"Stop Speaking",nil)];
	
	//View menu
	[menuItem_customizeToolbar setTitle:[AILocalizedString(@"Customize Toolbar",nil) stringByAppendingEllipsis]];

	//Format menu
	[menuItem_bold setTitle:AILocalizedString(@"Bold",nil)];
	[menuItem_italic setTitle:AILocalizedString(@"Italic",nil)];
	[menuItem_underline setTitle:AILocalizedString(@"Underline",nil)];
	[menuItem_showFonts setTitle:AILocalizedString(@"Show Fonts",nil)];
	[menuItem_showColors setTitle:AILocalizedString(@"Show Colors",nil)];
	[menuItem_bigger setTitle:AILocalizedString(@"Bigger", "Menu item title for making the font size bigger")];
	[menuItem_smaller setTitle:AILocalizedString(@"Smaller", "Menu item title for making the font size smaller")];
	[menuItem_copyStyle setTitle:AILocalizedString(@"Copy Style",nil)];
	[menuItem_pasteStyle setTitle:AILocalizedString(@"Paste Style",nil)];
	[menuItem_writingDirection setTitle:AILocalizedString(@"Writing Direction",nil)];
	[menuItem_rightToLeft setTitle:AILocalizedString(@"Right to Left", "Menu item in a submenu under 'writing direction' for writing which goes from right to left")];
	
	//Window menu
	[menuItem_minimize setTitle:AILocalizedString(@"Minimize", "Minimize menu item title int he Wndow menu")];
	[menuItem_zoom setTitle:AILocalizedString(@"Zoom", "Zoom menu item title in the Window menu")];
	[menuItem_bringAllToFront setTitle:AILocalizedString(@"Bring All to Front",nil)];

	//Help menu
	[menuItem_adiumHelp setTitle:AILocalizedString(@"Adium Help",nil)];
	[menuItem_releaseNotes setTitle:AILocalizedString(@"View Release Notes",nil)];
	[menuItem_contribute setTitle:AILocalizedString(@"Contribute",nil)];
	[menuItem_reportABug setTitle:AILocalizedString(@"Report a Bug",nil)];
	[menuItem_sendFeedback setTitle:AILocalizedString(@"Send Feedback",nil)];
	[menuItem_adiumForums setTitle:AILocalizedString(@"Adium Forums",nil)];
}

#pragma mark Menu delegate (contextual menu)

/*!
 * @brief Give menu items' targets the chance to update the menu before it is displayed
 *
 * This is useful since the menu is generated by many disparate classes; a single class as delegate can't handle all items.
 */
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSArray *menuItems = [[[menu itemArray] copy] autorelease];
	NSMenuItem *menuItem;
	for (menuItem in menuItems) {
		id target = [menuItem target];
		if ([target respondsToSelector:@selector(menu:needsUpdateForMenuItem:)])
			[target menu:menu needsUpdateForMenuItem:menuItem];
	}
	
	if (menu == menu_Contact_Manage) {
		[self updateAccountSpecificMenu:menu];
	}
}

/*!
 * @brief Add account-specific menu items to the main Contact menu.
 * 
 * These begin at the menu item by the id menu_Contact_AccountSpecific.
 */
- (void)updateAccountSpecificMenu:(NSMenu *)menu
{
	NSInteger separatorIndex = [menu indexOfItem:menu_Contact_AccountSpecific];
	[menu removeAllItemsAfterIndex:separatorIndex];
	
	BOOL separatorItem = NO;	
	// Add all items for this contact, if one exists.
	AIListObject *inObject = adium.interfaceController.selectedListObject;
	if ([inObject isKindOfClass:[AIMetaContact class]]) {
		for (AIListContact *aListContact in ((AIMetaContact *)inObject).uniqueContainedObjects) {
			[self addMenuItemsForContact:aListContact
								  toMenu:menu
						   separatorItem:&separatorItem];
		}
		
	} else if ([inObject isKindOfClass:[AIListContact class]] && ![inObject isKindOfClass:[AIListBookmark class]]) {
		[self addMenuItemsForContact:(AIListContact *)inObject
							  toMenu:menu
					   separatorItem:&separatorItem];
	} else if (adium.interfaceController.activeChat.isGroupChat) {
		[self addMenuItemsForChat:adium.interfaceController.activeChat
						   toMenu:menu
					separatorItem:&separatorItem];
	}
	
	// If no account specific items, hide the separator item.
	[menu_Contact_AccountSpecific setHidden:(menu.numberOfItems == separatorIndex+1)];
}

@end

