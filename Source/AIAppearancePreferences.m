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

#import "AIAppearancePreferences.h"
#import "AIAppearancePreferencesPlugin.h"
#import "AIDockIconSelectionSheet.h"
#import "AIEmoticonPack.h"
#import "AIEmoticonPreferences.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIDockControllerProtocol.h>
#import <Adium/AIEmoticonControllerProtocol.h>
#import <Adium/AIIconState.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>
#import "AIMenuBarIcons.h"

typedef enum {
	AIEmoticonMenuNone = 1,
	AIEmoticonMenuMultiple
} AIEmoticonMenuTag;

@interface AIAppearancePreferences ()
- (NSMenu *)_emoticonPackMenu;
- (void)_rebuildEmoticonMenuAndSelectActivePack;

- (void)configureDockIconMenu;
- (void)configureStatusIconsMenu;
- (void)configureServiceIconsMenu;
- (void)configureMenuBarIconsMenu;
@end

@implementation AIAppearancePreferences

/*!
 * @brief Preference pane properties
 */
- (AIPreferenceCategory)category{
	return AIPref_Appearance;
}
- (NSString *)paneIdentifier
{
	return @"Icons";
}
- (NSString *)paneName{
    return AILocalizedString(@"Icons","Icons preferences label");
}
- (NSString *)nibName{
    return @"Preferences-Icons";
}
- (NSImage *)paneIcon
{
	return [NSImage imageNamed:@"pref-icons" forClass:[self class]];
}

/*!
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
	//Observe preference changes
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_EMOTICONS];
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];

	//Observe xtras changes
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:AIXtrasDidChangeNotification
									 object:nil];	
	[self xtrasChanged:nil];
}

- (void)localizePane
{
	[label_dockIcons setLocalizedString:AILocalizedString(@"Dock Icon:", nil)];
	[label_emoticons setLocalizedString:AILocalizedString(@"Emoticons:", nil)];
	[label_menuBarIcons setLocalizedString:AILocalizedString(@"Menu Bar Icons:", nil)];
	[label_serviceIcons setLocalizedString:AILocalizedString(@"Service Icons:", nil)];
	[label_statusIcons setLocalizedString:AILocalizedString(@"Status Icons:", nil)];
	
	[button_dockIcons setLocalizedString:AILocalizedString(@"Show All…", nil)];
	[button_emoticons setLocalizedString:AILocalizedString(@"Customize…", nil)];
}

/*!
 * @brief View will close
 */
- (void)viewWillClose
{
	[adium.preferenceController unregisterPreferenceObserver:self];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief Xtras changed, update our menus to reflect the new Xtras
 */
- (void)xtrasChanged:(NSNotification *)notification
{
	NSString *filenameExtension = [notification object];

	//Convert our filename extension into a Uniform Type Identifier so that we can robustly determine what type of Xtra this is.
	CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, 
																					   (__bridge CFStringRef)filenameExtension,
																					   /*inConformingToUTI*/ NULL);

	if (!type || UTTypeEqual(type, CFSTR("com.adiumx.emoticonset"))) {
		[self _rebuildEmoticonMenuAndSelectActivePack];
	}
	
	if (!type || UTTypeEqual(type, CFSTR("com.adiumx.dockicon"))) {
		[self configureDockIconMenu];
	}
	
	if (!type || UTTypeEqual(type, CFSTR("com.adiumx.serviceicons"))) {
		[self configureServiceIconsMenu];
	}
	
	if (!type || UTTypeEqual(type, CFSTR("com.adiumx.statusicons"))) {
		[self configureStatusIconsMenu];
	}
	
	if (!type || UTTypeEqual(type, CFSTR("com.adiumx.menubaricons"))) {
		[self configureMenuBarIconsMenu];
	}
}

/*!
 * @brief Preferences changed
 *
 * Update controls in our view to reflect the changed preferences
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Emoticons
	if ([group isEqualToString:PREF_GROUP_EMOTICONS] && !firstTime) {
		[self _rebuildEmoticonMenuAndSelectActivePack];
	}
	
	//Appearance
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		//Selected menu items
		if (firstTime || [key isEqualToString:KEY_STATUS_ICON_PACK]) {
			[popUp_statusIcons selectItemWithTitle:[prefDict objectForKey:KEY_STATUS_ICON_PACK]];
			
			//If the prefDict's item isn't present, we're using the default, so select that one
			if (![popUp_statusIcons selectedItem]) {
				[popUp_statusIcons selectItemWithTitle:[adium.preferenceController defaultPreferenceForKey:KEY_STATUS_ICON_PACK
																										group:PREF_GROUP_APPEARANCE
																									   object:nil]];
			}			
		}
		if (firstTime || [key isEqualToString:KEY_SERVICE_ICON_PACK]) {
			[popUp_serviceIcons selectItemWithTitle:[prefDict objectForKey:KEY_SERVICE_ICON_PACK]];
			
			//If the prefDict's item isn't present, we're using the default, so select that one
			if (![popUp_serviceIcons selectedItem]) {
				[popUp_serviceIcons selectItemWithTitle:[adium.preferenceController defaultPreferenceForKey:KEY_SERVICE_ICON_PACK
																										group:PREF_GROUP_APPEARANCE
																									   object:nil]];
			}
		}
		if (firstTime || [key isEqualToString:KEY_MENU_BAR_ICONS]) {
			[popUp_menuBarIcons selectItemWithTitle:[prefDict objectForKey:KEY_MENU_BAR_ICONS]];
			
			//If the prefDict's item isn't present, we're using the default, so select that one
			if (![popUp_menuBarIcons selectedItem]) {
				[popUp_menuBarIcons selectItemWithTitle:[adium.preferenceController defaultPreferenceForKey:KEY_MENU_BAR_ICONS
																										group:PREF_GROUP_APPEARANCE
																									   object:nil]];
			}
		}
		if (firstTime || [key isEqualToString:KEY_ACTIVE_DOCK_ICON]) {
			/* popUp_dockIcon initially is a single-item popup menu with just the active icon; it is built
			 * lazily in menuNeedsUpdate:.  If we haven't displayed it yet, we'll need to configure again
			 * to show just the current icon */
			if (![popUp_dockIcon selectItemWithRepresentedObject:[prefDict objectForKey:KEY_ACTIVE_DOCK_ICON]])
				[self configureDockIconMenu];
		}
	}
}

/*!
 * @brief Rebuild the emoticon menu
 */
- (void)_rebuildEmoticonMenuAndSelectActivePack
{
	[popUp_emoticons setMenu:[self _emoticonPackMenu]];
	
	//Update the selected pack
	NSArray	*activeEmoticonPacks = [adium.emoticonController activeEmoticonPacks];
	NSInteger		numActivePacks = [activeEmoticonPacks count];
	
	if (numActivePacks == 0) {
		[popUp_emoticons selectItemWithTag:AIEmoticonMenuNone];
	} else if (numActivePacks > 1) {
		[popUp_emoticons selectItemWithTag:AIEmoticonMenuMultiple];
	} else {
		[popUp_emoticons selectItemWithRepresentedObject:[activeEmoticonPacks objectAtIndex:0]];
	}
}

/*!
 * @brief Save changed preferences
 */
- (IBAction)changePreference:(id)sender
{
 	if (sender == popUp_statusIcons) {
        [adium.preferenceController setPreference:[[sender selectedItem] title]
                                             forKey:KEY_STATUS_ICON_PACK
                                              group:PREF_GROUP_APPEARANCE];
		
	} else if (sender == popUp_serviceIcons) {
        [adium.preferenceController setPreference:[[sender selectedItem] title]
                                             forKey:KEY_SERVICE_ICON_PACK
                                              group:PREF_GROUP_APPEARANCE];
	} else if (sender == popUp_menuBarIcons) {
        [adium.preferenceController setPreference:[[sender selectedItem] title]
                                             forKey:KEY_MENU_BAR_ICONS
                                              group:PREF_GROUP_APPEARANCE];	
	} else if (sender == popUp_dockIcon) {
        [adium.preferenceController setPreference:[[sender selectedItem] representedObject]
                                             forKey:KEY_ACTIVE_DOCK_ICON
                                              group:PREF_GROUP_APPEARANCE];
		
	} else if (sender == popUp_emoticons) {
		if ([[sender selectedItem] tag] != AIEmoticonMenuMultiple) {
			//Disable all active emoticons
			NSArray			*activePacks = [[adium.emoticonController activeEmoticonPacks] mutableCopy];
			AIEmoticonPack	*pack, *selectedPack;
			
			selectedPack = [[sender selectedItem] representedObject];
			
			[adium.preferenceController delayPreferenceChangedNotifications:YES];

			for (pack in activePacks) {
				[adium.emoticonController setEmoticonPack:pack enabled:NO];
			}
			
			//Enable the selected pack
			if (selectedPack) [adium.emoticonController setEmoticonPack:selectedPack enabled:YES];

			[adium.preferenceController delayPreferenceChangedNotifications:NO];
		}
	}
}

//Emoticons ------------------------------------------------------------------------------------------------------------
#pragma mark Emoticons
/*!
 *
 */
- (IBAction)customizeEmoticons:(id)sender
{
	AIEmoticonPreferences *emoticonPreferences = [[AIEmoticonPreferences alloc] init];
	[emoticonPreferences showOnWindow:[[self view] window]];
}

/*!
 *
 */
- (NSMenu *)_emoticonPackMenu
{
	NSMenu			*menu = [[NSMenu alloc] init];
	NSMenuItem		*menuItem;
		
	//Add the "No Emoticons" option
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"None",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setImage:[NSImage imageNamed:@"emoticonBlank" forClass:[self class]]];
	[menuItem setTag:AIEmoticonMenuNone];
	[menu addItem:menuItem];
	
	//Add the "Multiple packs selected" option
	if ([[adium.emoticonController activeEmoticonPacks] count] > 1) {
		menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Multiple Packs Selected",nil)
																		 target:nil
																		 action:nil
																  keyEquivalent:@""];
		[menuItem setImage:[NSImage imageNamed:@"emoticonBlank" forClass:[self class]]];
		[menuItem setTag:AIEmoticonMenuMultiple];
		[menu addItem:menuItem];
	}

	//Divider
	[menu addItem:[NSMenuItem separatorItem]];

	//Emoticon Packs
	for (AIEmoticonPack *pack  in [adium.emoticonController availableEmoticonPacks]) {
		menuItem = [[NSMenuItem alloc] initWithTitle:[pack name]
																		 target:nil
																		 action:nil
																  keyEquivalent:@""];
		[menuItem setRepresentedObject:pack];
		[menuItem setImage:[pack menuPreviewImage]];
		[menu addItem:menuItem];
	}

	return menu;
}

//Dock icons -----------------------------------------------------------------------------------------------------------
#pragma mark Dock icons
/*!
 *
 */
- (IBAction)showAllDockIcons:(id)sender
{
	AIDockIconSelectionSheet *dockIconSelectionSheet = [[AIDockIconSelectionSheet alloc] init];
	[dockIconSelectionSheet showOnWindow:[[self view] window]];
}

/*!
 * @brief Return the menu item for a dock icon
 */
- (NSMenuItem *)meuItemForDockIconPackAtPath:(NSString *)packPath
{
	NSMenuItem	*menuItem;
	NSString	*name = nil;
	NSString	*packName = [[packPath lastPathComponent] stringByDeletingPathExtension];
	AIIconState	*preview = nil;
	
	[adium.dockController getName:&name
					   previewState:&preview
				  forIconPackAtPath:packPath];
	
	if (!name) {
		name = packName;
	}
	
	menuItem = [[NSMenuItem alloc] initWithTitle:name
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setRepresentedObject:packName];
	[menuItem setImage:[[preview image] imageByScalingForMenuItem]];
	
	return menuItem;
}

/*!
 * @brief Returns an array of menu items of all dock icon packs
 */
- (NSArray *)_dockIconMenuArray
{
	NSMutableArray		*menuItemArray = [NSMutableArray array];

	for (NSString *packPath in [adium.dockController availableDockIconPacks]) {
		[menuItemArray addObject:[self meuItemForDockIconPackAtPath:packPath]];
	}

	[menuItemArray sortUsingSelector:@selector(titleCompare:)];

	return menuItemArray;
}

/*!
 * @brief Configure the dock icon meu initially or after the xtras change
 *
 * Initially, the dock icon menu just has the currently selected icon; the others will be generated lazily if the icon is displayed, in menuNeedsUpdate:
 */
- (void)configureDockIconMenu
{
	NSMenu		*tempMenu = [[NSMenu alloc] init];
	NSString	*iconPath;
	NSString	*activePackName = [adium.preferenceController preferenceForKey:KEY_ACTIVE_DOCK_ICON
																		   group:PREF_GROUP_APPEARANCE];
	iconPath = [adium pathOfPackWithName:activePackName
							   extension:@"AdiumIcon"
					  resourceFolderName:FOLDER_DOCK_ICONS];
	
	[tempMenu addItem:[self meuItemForDockIconPackAtPath:iconPath]];
	[tempMenu setDelegate:self];
	[tempMenu setTitle:@"Temporary Dock Icon Menu"];

	[popUp_dockIcon setMenu:tempMenu];
	[popUp_dockIcon selectItemWithRepresentedObject:activePackName];
}

//Status, Service and Menu Bar icons ---------------------------------------------------------------------------------------------
#pragma mark Status, service and menu bar icons
- (NSMenuItem *)menuItemForIconPackAtPath:(NSString *)packPath class:(Class)iconClass
{
	NSString	*name = [[packPath lastPathComponent] stringByDeletingPathExtension];
	NSMenuItem	*menuItem = [[NSMenuItem alloc] initWithTitle:name
																				  target:nil
																				  action:nil
																		   keyEquivalent:@""];
	[menuItem setRepresentedObject:name];
	[menuItem setImage:[iconClass previewMenuImageForIconPackAtPath:packPath]];	

	return menuItem;
}

/*!
 * @brief Builds and returns an icon pack menu
 *
 * @param packs NSArray of icon pack file paths
 * @param iconClass The controller class (AIStatusIcons, AIServiceIcons) for icon pack previews
 */
- (NSArray *)_iconPackMenuArrayForPacks:(NSArray *)packs class:(Class)iconClass
{
	NSMutableArray	*menuItemArray = [NSMutableArray array];
	NSString		*packPath;

	for (packPath in packs) {
		[menuItemArray addObject:[self menuItemForIconPackAtPath:packPath class:iconClass]];
	}
	
	[menuItemArray sortUsingSelector:@selector(titleCompare:)];

	return menuItemArray;	
}

- (void)configureStatusIconsMenu
{
	NSMenu		*tempMenu = [[NSMenu alloc] init];
	NSString	*iconPath;
	NSString	*activePackName = [adium.preferenceController preferenceForKey:KEY_STATUS_ICON_PACK
																		   group:PREF_GROUP_APPEARANCE];
	iconPath = [adium pathOfPackWithName:activePackName
							   extension:@"AdiumStatusIcons"
					  resourceFolderName:@"Status Icons"];
	
	if (!iconPath) {
		activePackName = [adium.preferenceController defaultPreferenceForKey:KEY_STATUS_ICON_PACK
																		 group:PREF_GROUP_APPEARANCE
																		object:nil];
		
		iconPath = [adium pathOfPackWithName:activePackName
								   extension:@"AdiumStatusIcons"
						  resourceFolderName:@"Status Icons"];		
	}
	[tempMenu addItem:[self menuItemForIconPackAtPath:iconPath class:[AIStatusIcons class]]];
	[tempMenu setDelegate:self];
	[tempMenu setTitle:@"Temporary Status Icons Menu"];
	
	[popUp_statusIcons setMenu:tempMenu];
	[popUp_statusIcons selectItemWithRepresentedObject:activePackName];
}

- (void)configureServiceIconsMenu
{
	NSMenu		*tempMenu = [[NSMenu alloc] init];
	NSString	*iconPath;
	NSString	*activePackName = [adium.preferenceController preferenceForKey:KEY_SERVICE_ICON_PACK
																		   group:PREF_GROUP_APPEARANCE];
	iconPath = [adium pathOfPackWithName:activePackName
							   extension:@"AdiumServiceIcons"
					  resourceFolderName:@"Service Icons"];
	
	if (!iconPath) {
		activePackName = [adium.preferenceController defaultPreferenceForKey:KEY_SERVICE_ICON_PACK
																		 group:PREF_GROUP_APPEARANCE
																		object:nil];
		
		iconPath = [adium pathOfPackWithName:activePackName
								   extension:@"AdiumServiceIcons"
						  resourceFolderName:@"Service Icons"];		
	}
	[tempMenu addItem:[self menuItemForIconPackAtPath:iconPath class:[AIServiceIcons class]]];
	[tempMenu setDelegate:self];
	[tempMenu setTitle:@"Temporary Service Icons Menu"];
	
	[popUp_serviceIcons setMenu:tempMenu];
	[popUp_serviceIcons selectItemWithRepresentedObject:activePackName];
}

- (void)configureMenuBarIconsMenu
{
	NSMenu		*tempMenu = [[NSMenu alloc] init];
	NSString	*iconPath;
	NSString	*activePackName = [adium.preferenceController preferenceForKey:KEY_MENU_BAR_ICONS
																		   group:PREF_GROUP_APPEARANCE];
	iconPath = [adium pathOfPackWithName:activePackName
							   extension:@"AdiumMenuBarIcons"
					  resourceFolderName:@"Menu Bar Icons"];
	
	if (!iconPath) {
		activePackName = [adium.preferenceController defaultPreferenceForKey:KEY_MENU_BAR_ICONS
																		 group:PREF_GROUP_APPEARANCE
																		object:nil];
		
		iconPath = [adium pathOfPackWithName:activePackName
								   extension:@"AdiumMenuBarIcons"
						  resourceFolderName:@"Menu Bar Icons"];		
	}
	[tempMenu addItem:[self menuItemForIconPackAtPath:iconPath class:[AIMenuBarIcons class]]];
	[tempMenu setDelegate:self];
	[tempMenu setTitle:@"Temporary Menu Bar Icons Menu"];
	
	[popUp_menuBarIcons setMenu:tempMenu];
	[popUp_menuBarIcons selectItemWithRepresentedObject:activePackName];
}

#pragma mark Menu delegate
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSString		*title =[menu title];
	NSString		*repObject = nil;
	NSArray			*menuItemArray = nil;
	NSPopUpButton	*popUpButton;
	
	if ([title isEqualToString:@"Temporary Dock Icon Menu"]) {
		//If the menu has @"Temporary Dock Icon Menu" as its title, we should update it to have all dock icons, not just our selected one
		menuItemArray = [self _dockIconMenuArray];
		repObject = [adium.preferenceController preferenceForKey:KEY_ACTIVE_DOCK_ICON
															 group:PREF_GROUP_APPEARANCE];
		popUpButton = popUp_dockIcon;
		
	} else if ([title isEqualToString:@"Temporary Status Icons Menu"]) {		
		menuItemArray = [self _iconPackMenuArrayForPacks:[adium allResourcesForName:@"Status Icons" 
																	 withExtensions:@"AdiumStatusIcons"] 
												   class:[AIStatusIcons class]];
		repObject = [adium.preferenceController preferenceForKey:KEY_STATUS_ICON_PACK
															 group:PREF_GROUP_APPEARANCE];
		popUpButton = popUp_statusIcons;
		
	} else if ([title isEqualToString:@"Temporary Service Icons Menu"]) {		
		menuItemArray = [self _iconPackMenuArrayForPacks:[adium allResourcesForName:@"Service Icons" 
																	 withExtensions:@"AdiumServiceIcons"] 
												   class:[AIServiceIcons class]];
		repObject = [adium.preferenceController preferenceForKey:KEY_SERVICE_ICON_PACK
															 group:PREF_GROUP_APPEARANCE];
		popUpButton = popUp_serviceIcons;
		
	} else if ([title isEqualToString:@"Temporary Menu Bar Icons Menu"]) {
		menuItemArray = [self _iconPackMenuArrayForPacks:[adium allResourcesForName:@"Menu Bar Icons" 
																	 withExtensions:@"AdiumMenuBarIcons"] 
												   class:[AIMenuBarIcons class]];
		repObject = [adium.preferenceController preferenceForKey:KEY_MENU_BAR_ICONS
															 group:PREF_GROUP_APPEARANCE];
		popUpButton = popUp_menuBarIcons;	
	}
	
	if (menuItemArray) {
		NSMenuItem		*menuItem;
		
		//Remove existing items
		[menu removeAllItems];
		
		//Clear the title so we know we don't need to do this again
		[menu setTitle:@""];
		
		//Add the items
		for (menuItem in menuItemArray) {
			[menu addItem:menuItem];
		}
		
		//Clear the title so we know we don't need to do this again
		[menu setTitle:@""];
		
		//Put a checkmark by the appropriate menu item
		[popUpButton selectItemWithRepresentedObject:repObject];
	}	
}

@end
