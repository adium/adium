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

#import <Adium/AIContactControllerProtocol.h>
#import "AIContactSortSelectionPlugin.h"
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import "ESContactSortConfigurationWindowController.h"
#import "AIAlphabeticalSort.h"
#import "ESStatusSort.h"
#import "AIManualSort.h"

#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AISortController.h>

#define CONTACT_SORTING_DEFAULT_PREFS	@"SortingDefaults"
#define CONFIGURE_SORT_MENU_TITLE		[AILocalizedString(@"Configure Sorting",nil) stringByAppendingEllipsis]
#define SORT_MENU_TITLE					AILocalizedString(@"Sort Contacts",nil)

@interface AIContactSortSelectionPlugin (PRIVATE)
- (void)sortControllerListChanged:(NSNotification *)notification;
- (NSMenu *)_sortSelectionMenu;
- (void)_setActiveSortControllerFromPreferences;
- (void)_setConfigureSortMenuItemTitleForController:(AISortController *)controller;
- (void)_configureSortSelectionMenuItems;
@end

/*!
 * @class AIContactSortSelectionPlugin
 * @brief Component to manage contact sorting selection
 */
@implementation AIContactSortSelectionPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	enableConfigureSort = NO;
	
    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_SORTING_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_SORTING];

	//Wait for Adium to finish launching before we set up the sort controller
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:AIApplicationDidFinishLoadingNotification
									 object:nil];
	
	[[adium contactController] registerListSortController:[[[AIAlphabeticalSort alloc] init] autorelease]];
	[[adium contactController] registerListSortController:[[[ESStatusSort alloc] init] autorelease]];
	[[adium contactController] registerListSortController:[[[AIManualSort alloc] init] autorelease]];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[menuItem_configureSort release]; menuItem_configureSort = nil;
	[super dealloc];
}

/*!
 * @brief Our available sort controllers changed
 */
- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	//Inform the contactController of the active sort controller
	[self _setActiveSortControllerFromPreferences];
	
	[self _configureSortSelectionMenuItems];
}

/*!
 * @brief Set the active sort controller from the preferences
 */
- (void)_setActiveSortControllerFromPreferences
{
	NSEnumerator				*enumerator;
	AISortController 			*controller;
	NSString					*identifier;
	
	//
	identifier = [[adium preferenceController] preferenceForKey:KEY_CURRENT_SORT_MODE_IDENTIFIER
														  group:PREF_GROUP_CONTACT_SORTING];
	
	//
	enumerator = [[[adium contactController] sortControllerArray] objectEnumerator];
	while ((controller = [enumerator nextObject])) {
		if ([identifier compare:[controller identifier]] == NSOrderedSame) {
			[[adium contactController] setActiveSortController:controller];
			break;
		}
	}
	
	//Temporary failsafe for old preferences
	if (!controller) {
		[[adium contactController] setActiveSortController:[[[adium contactController] sortControllerArray] objectAtIndex:0]];
	}
}

/*!
 * @brief Configure the sort selection menu items
 */
- (void)_configureSortSelectionMenuItems
{
    NSMenu				*sortSelectionMenu;
    NSMenuItem			*menuItem;
    NSEnumerator		*enumerator;
	AISortController	*controller;
	
    //Create the menu
    sortSelectionMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
	
	//Add each sort controller
	enumerator = [[[adium contactController] sortControllerArray] objectEnumerator];
	while ((controller = [enumerator nextObject])) {
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[controller displayName]
																		 target:self
																		 action:@selector(changedSortSelection:)
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:controller];
		
		//Add the menu item
		[[adium menuController] addMenuItem:menuItem toLocation:LOC_View_Sorting];		
	}
	
	//Add the menu item for configuring the sort
	menuItem_configureSort = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:CONFIGURE_SORT_MENU_TITLE
																				  target:self
																				  action:@selector(configureSort:)
																		   keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem_configureSort toLocation:LOC_View_Sorting];
	
	AISortController	*activeSortController;
	int					index;
	
	//Show a check by the active sort controller's menu item...
	activeSortController = [[adium contactController] activeSortController];
	
	index = [[menuItem_configureSort menu] indexOfItemWithRepresentedObject:activeSortController];
	if (index != NSNotFound) {
		[[[menuItem_configureSort menu] itemAtIndex:index] setState:NSOnState];
	}
	
	///...and set the Configure Sort menu title appropriately
	[self _setConfigureSortMenuItemTitleForController:activeSortController];
}

/*!
 * @brief Configure the currently active sort
 */
- (void)configureSort:(id)sender
{
	AISortController *controller = [[adium contactController] activeSortController];
	[ESContactSortConfigurationWindowController showSortConfigurationWindowForController:controller];
}

/*!
 * @brief Changed sort selection
 *
 * @param sender <tt>NSMenuItem</tt> with an <tt>AISortController</tt> representedObject
 */
- (void)changedSortSelection:(id)sender
{
	AISortController	*controller = [sender representedObject];
	
	//Uncheck the old active sort controller
	int index = [[menuItem_configureSort menu] indexOfItemWithRepresentedObject:[[adium contactController] activeSortController]];
	if (index != NSNotFound) {
		[[[menuItem_configureSort menu] itemAtIndex:index] setState:NSOffState];
	}
	
	//Save the new preference
	[[adium preferenceController] setPreference:[controller identifier] forKey:KEY_CURRENT_SORT_MODE_IDENTIFIER group:PREF_GROUP_CONTACT_SORTING];

	//Inform the contact controller of the new active sort controller
	[[adium contactController] setActiveSortController:controller];
	
	//Check the menu item and update the configure sort menu item title
	[sender setState:NSOnState];
	[self _setConfigureSortMenuItemTitleForController:controller];
	
	if ([ESContactSortConfigurationWindowController sortConfigurationIsOpen]) {
		[self configureSort:nil];
	}
}

/*!
 * @brief Update the "configure sort" menu item for controller
 */
- (void)_setConfigureSortMenuItemTitleForController:(AISortController *)controller
{
	NSString *configureSortMenuItemTitle = [controller configureSortMenuItemTitle];
	if (configureSortMenuItemTitle) {
		[menuItem_configureSort setTitle:configureSortMenuItemTitle];
		enableConfigureSort = YES;
	} else {
		[menuItem_configureSort setTitle:CONFIGURE_SORT_MENU_TITLE];
		enableConfigureSort = NO;
	}
}

/* 
 * @brief Validate menu items
 *
 * All memu items should always be enabled except for menuItem_configureSort, which may be disabled
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem == menuItem_configureSort)
		return enableConfigureSort;
	else
		return YES;
}

@end
