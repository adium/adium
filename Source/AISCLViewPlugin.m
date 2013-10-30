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
#import "AISCLViewPlugin.h"
#import "ESContactListAdvancedPreferences.h"
#import "AIBorderlessListWindowController.h"
#import "AIStandardListWindowController.h"
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIListGroup.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIContactList.h>

#define PREF_GROUP_APPEARANCE		@"Appearance"

#define DETACHED_DEFAULT_WINDOW			@"Default Window"
#define DETACHED_WINDOWS				@"Windows"
#define DETACHED_WINDOW_GROUPS			@"Groups"
#define DETACHED_WINDOW_LOCATION		@"Location"

@interface AISCLViewPlugin ()
- (NSString *)humanReadableNameForGroup:(AIListGroup *)listGroup;
- (void)moveListGroup:(AIListGroup *)listGroup toContactList:(AIContactList *)destinationGroup;

- (void)loadDetachedGroups;
- (void)loadWindowPreferences:(NSDictionary *)windowPreferences;
- (void)saveAndCloseDetachedGroups;

- (void)detachFromWindow:(id)sender;
- (void)contactListIsEmpty:(NSNotification *)notification;
- (void)attachToWindow:(id)sender;
- (void)closeAndReopencontactList;
- (void)dummyAction:(id)sender;
@end

/*!
 * @class AISCLViewPlugin
 * @brief This component plugin is responsible for controlling the main contact list and detached contact lists window and view.
 *
 * Either an AIStandardListWindowController or AIBorderlessListWindowController, each of which is a subclass of AIListWindowController,
 * is instantiated. This window controller, with the help of the plugin, will be responsible for display of an AIListOutlineView.
 * The borderless window controller uses an AIBorderlessListOutlineView.
 *
 * In either case, the outline view itself is controlled by an instance of AIListController.
 *
 * AISCLViewPlugin's class methods also manage ListLayout and ListTheme preference sets. ListLayout sets determine the contents and layout
 * of the contact list; ListTheme sets control the colors used in the contact list.
 */
@implementation AISCLViewPlugin

- (void)installPlugin
{
	// List of windows
	contactLists = [[NSMutableArray alloc] init];
	
    [adium.interfaceController registerContactListController:self];
	
	//Install our preference view
	advancedPreferences = (ESContactListAdvancedPreferences *)[ESContactListAdvancedPreferences preferencePane];
	
	attachSubmenu = [[NSMenu alloc] init];
	[attachSubmenu setDelegate:self];
	
	//Context submenu
	attachMenuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Attach To Window", "Menu item for attaching groups to detachable windows")
												target:self
												action:@selector(dummyAction:)
										 keyEquivalent:@""];
	
	[attachMenuItem setSubmenu:attachSubmenu];
	
	[adium.menuController addContextualMenuItem:attachMenuItem toLocation:Context_Group_AttachDetach];
	
	//Context submenu
	detachMenuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Detach From Window", "Menu item for detaching groups from their window")
												target:self
												action:@selector(detachFromWindow:)
										 keyEquivalent:@""];
	
	[adium.menuController addContextualMenuItem:detachMenuItem toLocation:Context_Group_AttachDetach];

	//Control detached groups menu
	[adium.menuController addMenuItem:[NSMenuItem separatorItem] toLocation:LOC_Window_Commands];
	
	menuItem_consolidate = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Consolidate Detached Groups", "menu item title")
													  target:self
													  action:@selector(closeDetachedContactLists) 
											   keyEquivalent:@""];
	[adium.menuController addMenuItem:menuItem_consolidate toLocation:LOC_Window_Commands];
	
	menuItem_nextDetached = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Next Detached Group", "menu item title")
													   target:self
													   action:@selector(nextDetachedContactList) 
												keyEquivalent:@""];
	[adium.menuController addMenuItem:menuItem_nextDetached toLocation:LOC_Window_Commands];
	
	menuItem_previousDetached = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Previous Detached Group", "menu item title")
														   target:self
														   action:@selector(previousDetachedContactList) 
													keyEquivalent:@""];
	[adium.menuController addMenuItem:menuItem_previousDetached toLocation:LOC_Window_Commands];
	
	
	//Observe list closing
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(contactListDidClose:)
									   name:Interface_ContactListDidClose
									 object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(contactListIsEmpty:)
									   name:DetachedContactListIsEmpty
									 object:nil];
	
	//Now register our other defaults
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:@"ContactListDefaults"
																		forClass:[self class]]
										  forGroup:PREF_GROUP_CONTACT_LIST];										  
											  
	//Observe window style changes 
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];

	//Detached state
	hasLoaded = NO;
	detachedCycle = 0;
}

- (void)uninstallPlugin
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
}

- (void)dealloc
{	
	[attachSubmenu setDelegate:nil];
}

//Contact List Windows -------------------------------------------------------------------------------------------------
#pragma mark Contact List Window

/*!
 * @brief Creates a new window with a specified contact list
 *
 * @param contactList contaclist to be used in new contact list window
 *
 * @return Newly created contact list window controller
 */
- (id)detachContactList:(AIContactList *)contactList 
{
	NSParameterAssert(contactList != nil);
	
	AIListWindowController  *newContactList = [AIBorderlessListWindowController listWindowControllerForContactList:contactList];
	
	[contactLists addObject:newContactList];
	[newContactList showWindowInFrontIfAllowed:YES];
		
	return newContactList;
}

/*!
 * @brief Closes window specified 
 *
 * @param windowController Controller of window that will be closed (although 
 * this could be used with any contact list window controller, it should only
 * be used with detached contact lists)
 */
- (void)closeContactList:(AIListWindowController *)window
{		
	// Close contact list	
	[[window window] performClose:nil];
}

/*!
 * @brief Closes contact list based on given AIListOutlineView or AIListObject
 *
 * @param notification Notification containing either an AIListOutlineView or 
 * AIListObject object to be used to determine contact list's window. 
 */
- (void)contactListIsEmpty:(NSNotification *)notification
{
	AIContactList *object = [notification object];
	
	for (AIListWindowController *windowController in [contactLists copy]) {
		if (windowController.listController.contactList == object) {
			[self closeContactList:windowController];
			return;
		}
	}
}

//Contact List Controller ----------------------------------------------------------------------------------------------
#pragma mark Contact List Controller

/*!
 * @brief Retrieve the AIListWindowController in use
 */
- (AIListWindowController *)contactListWindowController {
	return defaultController;
}

/*!
 * @brief Brings main contact list to either front or back
 *
 * @param bringToFront Wether to bring contact list to front of back
 */
- (void)showContactListAndBringToFront:(BOOL)bringToFront
{
	// Check that main contact list has been created
    if (!defaultController) {
		[self loadDetachedGroups];
    }
	
	// Bring all detached windows to front as well
	AIListWindowController *window;
	for(window in contactLists)
		[window showWindowInFrontIfAllowed:bringToFront];
	
	[defaultController showWindowInFrontIfAllowed:bringToFront];
}

/*!
 * @brief Returns YES if the contact list is visible and in front
 */
- (BOOL)contactListIsVisibleAndMain
{
	return ([self contactListIsVisible] &&
			[[defaultController window] isMainWindow]);
}

/*!
 * @brief Returns YES if hte contact list is visible
 */
- (BOOL)contactListIsVisible
{
	return (defaultController &&
			[[defaultController window] isVisible] &&
			([defaultController windowSlidOffScreenEdgeMask] == AINoEdges));
}

/*!
 * @brief Close contact list
 */
- (void)closeContactList
{
	// Close main window
    if (defaultController)
		[[defaultController window] performClose:nil];
	
	[self saveAndCloseDetachedGroups];
	
	// So that in the future detached windows will reopen as well
	hasLoaded = NO;
}

/*!
 * @brief Closes all detached contact lists
 */
- (void)closeDetachedContactLists
{
	// Close all other windows
	for (AIListWindowController *windowController in [contactLists copy]) {
		[self closeContactList:windowController];
	}
}

/*!
 * @brief Callback when the contact list closes, clear our reference to it
 */
- (void)contactListDidClose:(NSNotification *)notification
{
	AIListWindowController *windowController = [notification object]; 
	
	if (windowController == defaultController) {
		defaultController = nil;
	} else {
		//Return the groups in this detached contact list to the main contact list
		for (AIListGroup *group in windowController.contactList) {
			[adium.contactController moveGroup:group 
							   fromContactList:(AIContactList *)windowController.contactList
								 toContactList:adium.contactController.contactList];
		}
		
		[adium.contactController removeDetachedContactList:(AIContactList *)[windowController contactList]];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"Contact_ListChanged"
												  object:adium.contactController.contactList 
												userInfo:nil];
			
		[contactLists removeObject:windowController];
	}
	
}

//Navigate Through Detached Windows ------------------------------------------------------------------------------------
#pragma mark Navigate Through Detached Windows

/*!
 * @brief Attempts to bring the next detached contact list to the front 
 */
- (void)nextDetachedContactList
{
	if (detachedCycle >= [contactLists count] || detachedCycle == NSNotFound)
		detachedCycle = 0;
	if (detachedCycle != NSNotFound && detachedCycle < [contactLists count])
		[[contactLists objectAtIndex:detachedCycle++] showWindowInFrontIfAllowed:YES];
}

/*!
 * @brief Attempts to bring the previous detached contact list to the front 
 */
- (void)previousDetachedContactList {
	if (detachedCycle == NSNotFound || detachedCycle >= [contactLists count])
		detachedCycle = [contactLists count]-1;
	if (detachedCycle != NSNotFound && detachedCycle < [contactLists count])
		[[contactLists objectAtIndex:detachedCycle--] showWindowInFrontIfAllowed:YES];
}

//Context menu ---------------------------------------------------------------------------------------------------------
#pragma mark Context menu

/*!
 * @brief Does nothing
 * 
 * In order for the "Attach" menu item to get validated, it needs an action.
 */
- (void)dummyAction:(id)sender { }

/*!
 * @brief Updates the Attach/Detach submenu
 */
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	// Our only delegate should be attachOrDetachSubmenu
	if (menu != attachSubmenu)
		return;
	
	[menu removeAllItems];
	
	// We're only called on list groups; determine which is our current selected one.
	AIListGroup			*selectedObject = (AIListGroup *)adium.menuController.currentContextMenuObject;
	
	// If this group isn't part of the main contact list, provide a menu item to add it back.
	if (selectedObject.contactList != adium.contactController.contactList) {
		[menu addItemWithTitle:AILocalizedString(@"Main Window", "Option in the 'Attach to Window' for the main contact list window")
						target:self
						action:@selector(attachToWindow:)
				 keyEquivalent:@""
			 representedObject:adium.contactController.contactList];
	}
	
	AIListWindowController		*window;
	
	for (window in contactLists) {
		// Don't add an "attach" option for the window we're already a part of.
		if (window.contactList == selectedObject.contactList) {
			continue;
		}
		
		[menu addItemWithTitle:[self humanReadableNameForGroup:(AIListGroup *)[window contactList]]
						target:self
						action:@selector(attachToWindow:)
				 keyEquivalent:@""
			 representedObject:[window contactList]];
	}
}

/*!
 * @brief Called by the "attach to .." menu item
 *
 * [sender representedObject] is the [window contactList] of the group to be added.
 */
- (void)attachToWindow:(id)sender
{
	// Attach the group to its new window.
	[self moveListGroup:(AIListGroup *)adium.menuController.currentContextMenuObject
		  toContactList:[sender representedObject]];
}

/*!
 * @brief Called by the "detach from.." menu item
 */
- (void)detachFromWindow:(id)sender
{
	AIContactList *destinationGroup = [adium.contactController createDetachedContactList];

	// Detaching is the same as moving to a new group.
	[self moveListGroup:(AIListGroup *)adium.menuController.currentContextMenuObject
		  toContactList:destinationGroup];
	
	[[[self detachContactList:destinationGroup] window] setFrameTopLeftPoint:[NSEvent mouseLocation]];
}

/*!
 * @brief Moves one list group to the [window contactList] of a detached group
 *
 * @param listGroup The list group being moved
 * @param destinationGroup The contactList of a detached windo which we're adding to
 */
- (void)moveListGroup:(AIListGroup *)listGroup toContactList:(AIContactList *)destinationList
{
	[adium.contactController moveGroup:listGroup fromContactList:listGroup.contactList toContactList:destinationList];
}

/*!
 * @brief Creates a human-readable name for a group
 *
 * Concatenates the names of group entries to produce a human-readable name, up to the first 4 group entries
 */
- (NSString *)humanReadableNameForGroup:(AIListGroup *)listGroup
{
	NSString			*returnString = @"";
	
	NSUInteger			currentCount = 0;
	for (AIListObject *listObject in listGroup) {
		currentCount++;
		
		// Only include up to an arbitrary number of group entries
		if (currentCount == 4 || currentCount == [listGroup countOfContainedObjects]) {
			returnString = [returnString stringByAppendingString:listObject.displayName];
		} else {
			returnString = [returnString stringByAppendingFormat:@"%@, ", listObject.displayName];
		}
		
		// Only include up to the first 4
		if (currentCount == 4 && [listGroup countOfContainedObjects] > 4) {
			returnString = [returnString stringByAppendingEllipsis];
			break;
		}
	}
	
	return returnString;
}

/*!
 * @brief Validates a menu item; used only for Window menu items
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	// Only Next Detached, Previous Deatached and Consolidate need validation.
	if ((menuItem == menuItem_nextDetached) ||
		(menuItem == menuItem_previousDetached) ||
		(menuItem == menuItem_consolidate) ||
		(menuItem == attachMenuItem)) {
		return [contactLists count] > 0;
	} else if (menuItem == detachMenuItem) {
		return ((AIListGroup *)adium.menuController.currentContextMenuObject).contactList.countOfContainedObjects > 1;
	}
	
	return YES;
}

//Themes and Layouts --------------------------------------------------------------------------------------------------
#pragma mark Contact List Controller
//Apply any theme/layout changes
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{	
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		if (firstTime || !key || [key isEqualToString:KEY_LIST_LAYOUT_WINDOW_STYLE]) {
			AIContactListWindowStyle	newWindowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
			
			if (newWindowStyle != windowStyle) {
				windowStyle = newWindowStyle;
				
				//If a contact list is visible and the window style has changed, update for the new window style
				if (defaultController) {
					//XXX - Evan: I really do not like this at all.  What to do?
					//We can't close and reopen the contact list from within a preferencesChanged call, as the
					//contact list itself is a preferences observer and will modify the array for its group as it
					//closes... and you can't modify an array while enuemrating it, which the preferencesController is
					//currently doing.  This isn't pretty, but it's the most efficient fix I could come up with.
					//It has the obnoxious side effect of the contact list changing its view prefs and THEN closing and
					//reopening with the right windowStyle.
					[self performSelector:@selector(closeAndReopencontactList)
							   withObject:nil
							   afterDelay:0];
				}
			}
		}
	}
}

/*!
 * @brief Closes main contact list and reopens it
 *
 * Useful for updating settings and data of the main contact list
 */
- (void)closeAndReopencontactList
{
	BOOL isVisibleAndMain = [self contactListIsVisibleAndMain];

	[self saveAndCloseDetachedGroups];

	hasLoaded = NO;
	[defaultController close];
	defaultController = nil;

	[self showContactListAndBringToFront:isVisibleAndMain];
}

// Preferences --------------------------------------------------------------------------------------------------------
#pragma mark Preferences
/*!
 * @brief Saves location of contact list and information about the detached groups
 */
- (void)saveAndCloseDetachedGroups
{		
	NSMutableArray *detachedWindowsDicts = [[NSMutableArray alloc] init];

	for (AIListWindowController *windowController in [contactLists copy]) {
		NSDictionary *dict = [NSDictionary dictionaryWithObject:[[[windowController contactList] containedObjects] valueForKey:@"UID"]
														 forKey:DETACHED_WINDOW_GROUPS];
		[detachedWindowsDicts addObject:dict];
		[self closeContactList:windowController];
	}

	[adium.preferenceController setPreference:detachedWindowsDicts
										 forKey:DETACHED_WINDOWS
										  group:PREF_DETACHED_GROUPS];
}

/*!
 * @brief Loads main contact list window if not already loaded and if this 
 * is the first time that that we are loading the contact list we detached
 * groups and place them in the correct location
 */
- (void)loadDetachedGroups
{
	if (!defaultController && windowStyle == AIContactListWindowStyleStandard) {
		defaultController = [AIStandardListWindowController listWindowControllerForContactList:adium.contactController.contactList];
	} else if (!defaultController) {
		defaultController = [AIBorderlessListWindowController listWindowControllerForContactList:adium.contactController.contactList];
	}
	
	if (!hasLoaded) {
		NSArray *detachedWindowsDict = [adium.preferenceController preferenceForKey:DETACHED_WINDOWS
																				group:PREF_DETACHED_GROUPS];
		NSDictionary *windowPreferenceDict;
		
		for (windowPreferenceDict in detachedWindowsDict) {
			[self loadWindowPreferences:windowPreferenceDict];
		}
		
		hasLoaded = YES;
	}

}

/*!
 * @brief Loads detached window based on saved preferences
 */
- (void)loadWindowPreferences:(NSDictionary *)windowPreferences
{
	NSArray *groups = [windowPreferences objectForKey:DETACHED_WINDOW_GROUPS];

	if ([groups count] == 0)
		return;

	AIContactList *contactList = [adium.contactController createDetachedContactList];

	for (NSString *groupUID in groups) {
		AIListGroup		*group = [adium.contactController groupWithUID:groupUID];
		
		[adium.contactController moveGroup:group fromContactList:group.contactList toContactList:contactList];
	}
	
	[self detachContactList:contactList];
}

@end

