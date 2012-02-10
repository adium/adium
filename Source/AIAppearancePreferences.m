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
#import "AIListLayoutWindowController.h"
#import "AIListThemeWindowController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIDockControllerProtocol.h>
#import <Adium/AIEmoticonControllerProtocol.h>
#import <Adium/AIIconState.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/ESPresetManagementController.h>
#import <Adium/ESPresetNameSheetController.h>
#import "AIMenuBarIcons.h"

typedef enum {
	AIEmoticonMenuNone = 1,
	AIEmoticonMenuMultiple
} AIEmoticonMenuTag;

@interface AIAppearancePreferences ()
- (NSMenu *)_windowStyleMenu;
- (NSMenu *)_emoticonPackMenu;
- (NSMenu *)_listLayoutMenu;
- (NSMenu *)_colorThemeMenu;
- (void)_rebuildEmoticonMenuAndSelectActivePack;
- (void)_addWindowStyleOption:(NSString *)option withTag:(NSInteger)tag toMenu:(NSMenu *)menu;
- (void)_updateSliderValues;
- (void)_editListThemeWithName:(NSString *)name;
- (void)_editListLayoutWithName:(NSString *)name;
- (void)xtrasChanged:(NSNotification *)notification;

- (void)configureDockIconMenu;
- (void)configureStatusIconsMenu;
- (void)configureServiceIconsMenu;
- (void)configureMenuBarIconsMenu;
@end

@implementation AIAppearancePreferences

/*!
 * @brief Preference pane properties
 */
- (NSString *)paneIdentifier
{
	return @"Appearance";
}
- (NSString *)paneName{
    return AILocalizedString(@"Appearance","Appearance preferences label");
}
- (NSString *)nibName{
    return @"AppearancePrefs";
}
- (NSImage *)paneIcon
{
	return [NSImage imageNamed:@"pref-appearance" forClass:[self class]];
}

/*!
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
	[slider_windowOpacity setMinValue:0.0];
	[slider_windowOpacity setMaxValue:100.0];

	//Other list options
	[popUp_windowStyle setMenu:[self _windowStyleMenu]];
		
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
	CFStringRef type = (CFStringRef)[(NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, 
																					   (CFStringRef)filenameExtension,
																					   /*inConformingToUTI*/ NULL) autorelease];

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
	
	if (!type || UTTypeEqual(type, CFSTR("com.adiumx.contactlisttheme"))) {
		[popUp_colorTheme setMenu:[self _colorThemeMenu]];
		[popUp_colorTheme selectItemWithRepresentedObject:[adium.preferenceController preferenceForKey:KEY_LIST_THEME_NAME
																								   group:PREF_GROUP_APPEARANCE]];
	}

	if (!type || UTTypeEqual(type, CFSTR("com.adiumx.contactlistlayout"))) {
		[popUp_listLayout setMenu:[self _listLayoutMenu]];
		[popUp_listLayout selectItemWithRepresentedObject:[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_NAME
																								   group:PREF_GROUP_APPEARANCE]];
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
		if (firstTime) {
			[popUp_windowStyle selectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] integerValue]];	
			[checkBox_verticalAutosizing setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE] boolValue]];
			[checkBox_horizontalAutosizing setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue]];
			[slider_windowOpacity setDoubleValue:([[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_OPACITY] doubleValue] * 100.0)];
			[slider_horizontalWidth setIntegerValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] integerValue]];
			[self _updateSliderValues];
		}
		
		//Horizontal resizing label
		if (firstTime || 
			[key isEqualToString:KEY_LIST_LAYOUT_WINDOW_STYLE] ||
			[key isEqualToString:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE]) {

			AIContactListWindowStyle windowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
			BOOL horizontalAutosize = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue];
			
			if (windowStyle == AIContactListWindowStyleStandard) {
				//In standard mode, disable the horizontal autosizing slider if horiztonal autosizing is off
				[textField_horizontalWidthText setLocalizedString:AILocalizedString(@"Maximum Width:",nil)];
				[slider_horizontalWidth setEnabled:horizontalAutosize];
				
			} else {
				//In all the borderless transparent modes, the horizontal autosizing slider becomes the
				//horizontal sizing slider when autosizing is off
				if (horizontalAutosize) {
					[textField_horizontalWidthText setLocalizedString:AILocalizedString(@"Maximum Width:",nil)];
				} else {
					[textField_horizontalWidthText setLocalizedString:AILocalizedString(@"Width:",nil)];			
				}
				[slider_horizontalWidth setEnabled:YES];
			}
			
			//Configure vertical autosizing's appearance. AIListWindowController must match this behavior for this to make sense.
			switch (windowStyle) {
				case AIContactListWindowStyleStandard:
				case AIContactListWindowStyleBorderless:
				case AIContactListWindowStyleGroupChat:
					//Standard and borderless don't have to vertically autosize
					[checkBox_verticalAutosizing setEnabled:YES];
					[checkBox_verticalAutosizing setState:[[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE
																									group:PREF_GROUP_APPEARANCE] integerValue]];
					break;
				case AIContactListWindowStyleGroupBubbles:
				case AIContactListWindowStyleContactBubbles:
				case AIContactListWindowStyleContactBubbles_Fitted:
					//The bubbles styles don't show a window; force them to autosize
					[checkBox_verticalAutosizing setEnabled:NO];
					[checkBox_verticalAutosizing setState:YES];
			}			
		}

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
		if (firstTime || [key isEqualToString:KEY_LIST_LAYOUT_NAME]) {
			[popUp_listLayout selectItemWithRepresentedObject:[prefDict objectForKey:KEY_LIST_LAYOUT_NAME]];
		}
		if (firstTime || [key isEqualToString:KEY_LIST_THEME_NAME]) {
			[popUp_colorTheme selectItemWithRepresentedObject:[prefDict objectForKey:KEY_LIST_THEME_NAME]];	
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
		
	} else if (sender == popUp_listLayout) {
        [adium.preferenceController setPreference:[[sender selectedItem] title]
                                             forKey:KEY_LIST_LAYOUT_NAME
                                              group:PREF_GROUP_APPEARANCE];		
		
	} else if (sender == popUp_colorTheme) {
		[adium.preferenceController setPreference:[[sender selectedItem] title]
											 forKey:KEY_LIST_THEME_NAME
											  group:PREF_GROUP_APPEARANCE];

	} else if (sender == popUp_windowStyle) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_WINDOW_STYLE
											  group:PREF_GROUP_APPEARANCE];
		
    } else if (sender == checkBox_verticalAutosizing) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE
                                              group:PREF_GROUP_APPEARANCE];
		
    } else if (sender == checkBox_horizontalAutosizing) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE
                                              group:PREF_GROUP_APPEARANCE];

    } else if (sender == slider_windowOpacity) {
        [adium.preferenceController setPreference:[NSNumber numberWithDouble:([sender doubleValue] / 100.0)]
                                             forKey:KEY_LIST_LAYOUT_WINDOW_OPACITY
                                              group:PREF_GROUP_APPEARANCE];
		[self _updateSliderValues];
		
	} else if (sender == slider_horizontalWidth) {
		NSInteger newValue = [sender integerValue];
		NSInteger oldValue = [[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH
																 group:PREF_GROUP_APPEARANCE] integerValue];
		if (newValue != oldValue) { 
			[adium.preferenceController setPreference:[NSNumber numberWithInteger:newValue]
												 forKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH
												  group:PREF_GROUP_APPEARANCE];
			[self _updateSliderValues];
		}
		
	} else if (sender == popUp_emoticons) {
		if ([[sender selectedItem] tag] != AIEmoticonMenuMultiple) {
			//Disable all active emoticons
			NSArray			*activePacks = [[[adium.emoticonController activeEmoticonPacks] mutableCopy] autorelease];
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

/*!
 *
 */
- (void)_updateSliderValues
{
	[textField_windowOpacity setStringValue:[NSString stringWithFormat:@"%ld%%", (NSInteger)[slider_windowOpacity doubleValue]]];
	[textField_horizontalWidthIndicator setStringValue:[NSString stringWithFormat:@"%ldpx",[slider_horizontalWidth integerValue]]];
}

//Emoticons ------------------------------------------------------------------------------------------------------------
#pragma mark Emoticons
/*!
 *
 */
- (IBAction)customizeEmoticons:(id)sender
{
	AIEmoticonPreferences *emoticonPreferences = [[AIEmoticonPreferences alloc] init];
	[emoticonPreferences openOnWindow:[[self view] window]];
}

/*!
 *
 */
- (NSMenu *)_emoticonPackMenu
{
	NSMenu			*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator = [[adium.emoticonController availableEmoticonPacks] objectEnumerator];
	AIEmoticonPack	*pack;
	NSMenuItem		*menuItem;
		
	//Add the "No Emoticons" option
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"None",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setImage:[NSImage imageNamed:@"emoticonBlank" forClass:[self class]]];
	[menuItem setTag:AIEmoticonMenuNone];
	[menu addItem:menuItem];
	
	//Add the "Multiple packs selected" option
	if ([[adium.emoticonController activeEmoticonPacks] count] > 1) {
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Multiple Packs Selected",nil)
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setImage:[NSImage imageNamed:@"emoticonBlank" forClass:[self class]]];
		[menuItem setTag:AIEmoticonMenuMultiple];
		[menu addItem:menuItem];
	}

	//Divider
	[menu addItem:[NSMenuItem separatorItem]];

	//Emoticon Packs
	while ((pack = [enumerator nextObject])) {
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[pack name]
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:pack];
		[menuItem setImage:[pack menuPreviewImage]];
		[menu addItem:menuItem];
	}

	return [menu autorelease];
}


//Contact list options -------------------------------------------------------------------------------------------------
#pragma mark Contact list options
/*!
 *
 */
- (NSMenu *)_windowStyleMenu
{
	NSMenu	*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];

	[self _addWindowStyleOption:AILocalizedString(@"Regular Window",nil)
						withTag:AIContactListWindowStyleStandard
						 toMenu:menu];
	[menu addItem:[NSMenuItem separatorItem]];
	[self _addWindowStyleOption:AILocalizedString(@"Borderless Window",nil)
						withTag:AIContactListWindowStyleBorderless
						 toMenu:menu];
	[self _addWindowStyleOption:AILocalizedString(@"Group Bubbles",nil)
						withTag:AIContactListWindowStyleGroupBubbles
						 toMenu:menu];
	[self _addWindowStyleOption:AILocalizedString(@"Contact Bubbles",nil)
						withTag:AIContactListWindowStyleContactBubbles
						 toMenu:menu];
	[self _addWindowStyleOption:AILocalizedString(@"Contact Bubbles (To Fit)",nil)
						withTag:AIContactListWindowStyleContactBubbles_Fitted
						 toMenu:menu];

	return [menu autorelease];
}
- (void)_addWindowStyleOption:(NSString *)option withTag:(NSInteger)tag toMenu:(NSMenu *)menu{
    NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:option
																				  target:nil
																				  action:nil
																		   keyEquivalent:@""] autorelease];
	[menuItem setTag:tag];
	[menu addItem:menuItem];
}


//Contact list layout & theme ----------------------------------------------------------------------------------------
#pragma mark Contact list layout & theme

/*!
 * @brief Create a new theme
 */
- (IBAction)createListTheme:(id)sender
{
	NSString *theme = [adium.preferenceController preferenceForKey:KEY_LIST_THEME_NAME group:PREF_GROUP_APPEARANCE];
	
	ESPresetNameSheetController *presetNameSheetController = [[ESPresetNameSheetController alloc] initWithDefaultName:[[theme stringByAppendingString:@" "] stringByAppendingString:AILocalizedString(@"(Copy)", nil)]
																									  explanatoryText:AILocalizedString(@"Enter a unique name for this new theme.",nil)
																									  notifyingTarget:self
																											 userInfo:@"theme"];
	
	[presetNameSheetController showOnWindow:[[self view] window]];
}

/*!
 * @brief Customize the active theme
 */
- (IBAction)customizeListTheme:(id)sender
{
	NSString *theme = [adium.preferenceController preferenceForKey:KEY_LIST_THEME_NAME group:PREF_GROUP_APPEARANCE];	
	
	AIListThemeWindowController *listThemeWindowController = [[AIListThemeWindowController alloc] initWithName:theme
																							   notifyingTarget:self];
	[listThemeWindowController showOnWindow:[[self view] window]];
}

/*!
 * @brief Save (or revert) changes made when editing a theme
 */
- (void)listThemeEditorWillCloseWithChanges:(BOOL)saveChanges forThemeNamed:(NSString *)name
{
	if (saveChanges) {
		//Update the modified theme
		if ([plugin createSetFromPreferenceGroup:PREF_GROUP_LIST_THEME
										withName:name
									   extension:LIST_THEME_EXTENSION
										inFolder:LIST_THEME_FOLDER]) {
			
			[adium.preferenceController setPreference:name
												 forKey:KEY_LIST_THEME_NAME
												  group:PREF_GROUP_APPEARANCE];
		}
		
	} else {
		//Revert back to selected theme
		NSString *theme = [adium.preferenceController preferenceForKey:KEY_LIST_THEME_NAME group:PREF_GROUP_APPEARANCE];	
		
		//Reapply the selected theme
		[plugin applySetWithName:theme
					   extension:LIST_THEME_EXTENSION
						inFolder:LIST_THEME_FOLDER
			   toPreferenceGroup:PREF_GROUP_LIST_THEME];
			   
		//Revert back to the current theme name in popUp_colorTheme component
		[popUp_colorTheme selectItemWithTitle:[adium.preferenceController preferenceForKey:KEY_LIST_THEME_NAME group:PREF_GROUP_APPEARANCE]];		
	}
}

/*!
 * @brief Manage available themes
 */
- (void)manageListThemes:(id)sender
{
	_listThemes = [plugin availableThemeSets];
	ESPresetManagementController *presetManagementController = [[ESPresetManagementController alloc] initWithPresets:_listThemes
																										  namedByKey:@"name"
																										withDelegate:self];
	[presetManagementController showOnWindow:[[self view] window]];
	
	[popUp_colorTheme selectItemWithRepresentedObject:[adium.preferenceController preferenceForKey:KEY_LIST_THEME_NAME
																							   group:PREF_GROUP_APPEARANCE]];		
}

/*!
 * @brief Create a new layout
 */
- (IBAction)createListLayout:(id)sender
{
	NSString *layout = [adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_NAME group:PREF_GROUP_APPEARANCE];
	
	ESPresetNameSheetController *presetNameSheetController = [[ESPresetNameSheetController alloc] initWithDefaultName:[[layout stringByAppendingString:@" "] stringByAppendingString:AILocalizedString(@"(Copy)",nil)]
																									  explanatoryText:AILocalizedString(@"Enter a unique name for this new layout.",nil)
																									  notifyingTarget:self
																											 userInfo:@"layout"];
	
	[presetNameSheetController showOnWindow:[[self view] window]];
}

/*!
 * @brief Customize the active layout
 */
- (IBAction)customizeListLayout:(id)sender
{
	NSString *theme = [adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_NAME group:PREF_GROUP_APPEARANCE];	
	
	AIListLayoutWindowController *listLayoutWindowController = [[AIListLayoutWindowController alloc] initWithName:theme
																								  notifyingTarget:self];
	[listLayoutWindowController showOnWindow:[[self view] window]];
}

/*!
 * @brief Save (or revert) changes made when editing a layout
 */
- (void)listLayoutEditorWillCloseWithChanges:(BOOL)saveChanges forLayoutNamed:(NSString *)name
{
	if (saveChanges) {
		//Update the modified layout
		if ([plugin createSetFromPreferenceGroup:PREF_GROUP_LIST_LAYOUT
										withName:name
									   extension:LIST_LAYOUT_EXTENSION
										inFolder:LIST_LAYOUT_FOLDER]) {
			
			[adium.preferenceController setPreference:name
												 forKey:KEY_LIST_LAYOUT_NAME
												  group:PREF_GROUP_APPEARANCE];
		}
		
	} else {
		//Revert back to selected layout
		NSString *layout = [adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_NAME group:PREF_GROUP_APPEARANCE];	

		//Reapply the selected layout
		[plugin applySetWithName:layout
					   extension:LIST_LAYOUT_EXTENSION
						inFolder:LIST_LAYOUT_FOLDER
			   toPreferenceGroup:PREF_GROUP_LIST_LAYOUT];
			   
		//Revert back to the current layout name in popUp_listLayout component
		[popUp_listLayout selectItemWithTitle:[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_NAME group:PREF_GROUP_APPEARANCE]];
	}
}

/*!
 * @brief Manage available layouts
 */
- (void)manageListLayouts:(id)sender
{
	_listLayouts = [plugin availableLayoutSets];
	ESPresetManagementController *presetManagementController = [[ESPresetManagementController alloc] initWithPresets:_listLayouts
																										  namedByKey:@"name"
																										withDelegate:self];
	[presetManagementController showOnWindow:[[self view] window]];

	[popUp_listLayout selectItemWithRepresentedObject:[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_NAME
																							   group:PREF_GROUP_APPEARANCE]];		
}

/*!
 * @brief Validate a layout or theme name to ensure it is unique
 */
- (BOOL)presetNameSheetController:(ESPresetNameSheetController *)controller
			  shouldAcceptNewName:(NSString *)newName
						 userInfo:(id)userInfo
{
	NSEnumerator	*enumerator;
	NSDictionary	*presetDict;

	//Scan the correct presets to ensure this name doesn't already exist
	if ([userInfo isEqualToString:@"theme"]) {
		enumerator = [[plugin availableThemeSets] objectEnumerator];
	} else {
		enumerator = [[plugin availableLayoutSets] objectEnumerator];
	}
	
	while ((presetDict = [enumerator nextObject])) {
		if ([newName isEqualToString:[presetDict objectForKey:@"name"]]) return NO;
	}
	
	return YES;
}

/*!
 * @brief Create a new theme with the user supplied name, activate and edit it
 */
- (void)presetNameSheetControllerDidEnd:(ESPresetNameSheetController *)controller 
							 returnCode:(ESPresetNameSheetReturnCode)returnCode
								newName:(NSString *)newName
							   userInfo:(id)userInfo
{
	switch (returnCode) {
		case ESPresetNameSheetOkayReturn:
			//User has created a new theme/layout	: show the editor
			if ([userInfo isEqualToString:@"theme"]) {
				[self performSelector:@selector(_editListThemeWithName:) withObject:newName afterDelay:0];
			} else {
				[self performSelector:@selector(_editListLayoutWithName:) withObject:newName afterDelay:0];
			}
		break;
			
		case ESPresetNameSheetCancelReturn:
			//User has canceled the operation	: revert back to the current theme 
			if ([userInfo isEqualToString:@"theme"]) {
				[popUp_colorTheme selectItemWithTitle:[adium.preferenceController preferenceForKey:KEY_LIST_THEME_NAME group:PREF_GROUP_APPEARANCE]];
			} else {
				[popUp_listLayout selectItemWithTitle:[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_NAME group:PREF_GROUP_APPEARANCE]];
			}			
		break;	
	}
}
- (void)_editListThemeWithName:(NSString *)name{
	AIListThemeWindowController *listThemeWindowController = [[AIListThemeWindowController alloc] initWithName:name
																							   notifyingTarget:self];
	[listThemeWindowController showOnWindow:[[self view] window]];
}
- (void)_editListLayoutWithName:(NSString *)name{
	AIListLayoutWindowController *listLayoutWindowController = [[AIListLayoutWindowController alloc] initWithName:name
																								  notifyingTarget:self];
	[listLayoutWindowController showOnWindow:[[self view] window]];
}

/*!
 * 
 */
- (NSArray *)renamePreset:(NSDictionary *)preset toName:(NSString *)newName inPresets:(NSArray *)presets renamedPreset:(id *)renamedPreset
{
	NSArray		*newPresets;
	
	if (presets == _listLayouts) {
		[plugin renameSetWithName:[preset objectForKey:@"name"]
						extension:LIST_LAYOUT_EXTENSION
						 inFolder:LIST_LAYOUT_FOLDER
						   toName:newName];		
		_listLayouts = [plugin availableLayoutSets];
		newPresets = _listLayouts;
		
	} else if (presets == _listThemes) {
		[plugin renameSetWithName:[preset objectForKey:@"name"]
						extension:LIST_THEME_EXTENSION
						 inFolder:LIST_THEME_FOLDER
						   toName:newName];		
		_listThemes = [plugin availableThemeSets];
		newPresets = _listThemes;
		
	} else {
		newPresets = nil;
	}
	
	//Return the new duplicate by reference for the preset controller
	if (renamedPreset) {
		NSDictionary	*aPreset;
		
		for (aPreset in newPresets) {
			if ([newName isEqualToString:[aPreset objectForKey:@"name"]]) {
				*renamedPreset = aPreset;
				break;
			}
		}
	}
	
	return newPresets;
}

/*!
 * 
 */
- (NSArray *)duplicatePreset:(NSDictionary *)preset inPresets:(NSArray *)presets createdDuplicate:(id *)duplicatePreset
{
	NSString	*newName = [NSString stringWithFormat:@"%@ (%@)", [preset objectForKey:@"name"], AILocalizedString(@"Copy",nil)];
	NSArray		*newPresets = nil;
	
	if (presets == _listLayouts) {
		[plugin duplicateSetWithName:[preset objectForKey:@"name"]
						   extension:LIST_LAYOUT_EXTENSION
							inFolder:LIST_LAYOUT_FOLDER
							 newName:newName];		
		_listLayouts = [plugin availableLayoutSets];
		newPresets = _listLayouts;
		
	} else if (presets == _listThemes) {
		[plugin duplicateSetWithName:[preset objectForKey:@"name"]
						   extension:LIST_THEME_EXTENSION
							inFolder:LIST_THEME_FOLDER
							 newName:newName];
		_listThemes = [plugin availableThemeSets];
		newPresets = _listThemes;
	}
	
	//Return the new duplicate by reference for the preset controller
	if (duplicatePreset) {
		NSDictionary	*aPreset;
		
		for (aPreset in newPresets) {
			if ([newName isEqualToString:[aPreset objectForKey:@"name"]]) {
				*duplicatePreset = aPreset;
				break;
			}
		}
	}

	return newPresets;
}

/*!
 * 
 */
- (NSArray *)deletePreset:(NSDictionary *)preset inPresets:(NSArray *)presets
{
	if (presets == _listLayouts) {
		[plugin deleteSetWithName:[preset objectForKey:@"name"]
						extension:LIST_LAYOUT_EXTENSION
						 inFolder:LIST_LAYOUT_FOLDER];		
		_listLayouts = [plugin availableLayoutSets];
		
		return _listLayouts;
		
	} else if (presets == _listThemes) {
		[plugin deleteSetWithName:[preset objectForKey:@"name"]
						extension:LIST_THEME_EXTENSION
						 inFolder:LIST_THEME_FOLDER];		
		_listThemes = [plugin availableThemeSets];
		
		return _listThemes;
		
	} else {
		return nil;
	}
}

/*!
 *
 */
- (NSMenu *)_listLayoutMenu
{
	NSMenu			*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator = [[plugin availableLayoutSets] objectEnumerator];
	NSDictionary	*set;
	NSMenuItem		*menuItem;
	NSString		*name;
	
	//Available Layouts
	while ((set = [enumerator nextObject])) {
		name = [set objectForKey:@"name"];
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:name];
		[menu addItem:menuItem];
	}
	
	//Divider
	[menu addItem:[NSMenuItem separatorItem]];

	//Preset management	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Add New Layout",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(createListLayout:)
															  keyEquivalent:@""] autorelease];
	[menu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Edit Layouts",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(manageListLayouts:)
															  keyEquivalent:@""] autorelease];
	[menu addItem:menuItem];
	
	return [menu autorelease];	
}

/*!
 *
 */
- (NSMenu *)_colorThemeMenu
{
	NSMenu			*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSEnumerator	*enumerator = [[plugin availableThemeSets] objectEnumerator];
	NSDictionary	*set;
	NSMenuItem		*menuItem;
	NSString		*name;
	
	//Available themes
	while ((set = [enumerator nextObject])) {
		name = [set objectForKey:@"name"];
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:name];
		[menu addItem:menuItem];
	}

	//Divider
	[menu addItem:[NSMenuItem separatorItem]];
	
	//Preset management	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Add New Theme",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(createListTheme:)
															  keyEquivalent:@""] autorelease];
	[menu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Edit Themes",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(manageListThemes:)
															  keyEquivalent:@""] autorelease];
	[menu addItem:menuItem];
	
	return [menu autorelease];	
}


//Dock icons -----------------------------------------------------------------------------------------------------------
#pragma mark Dock icons
/*!
 *
 */
- (IBAction)showAllDockIcons:(id)sender
{
	AIDockIconSelectionSheet *dockIconSelectionSheet = [[AIDockIconSelectionSheet alloc] init];
	[dockIconSelectionSheet openOnWindow:[[self view] window]];
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
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
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
	NSEnumerator		*enumerator;
	NSString			*packPath;

	enumerator = [[adium.dockController availableDockIconPacks] objectEnumerator];
	while ((packPath = [enumerator nextObject])) {
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
	NSMenu		*tempMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
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
	NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																				  target:nil
																				  action:nil
																		   keyEquivalent:@""] autorelease];
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
	NSMenu		*tempMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
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
	NSMenu		*tempMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
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
	NSMenu		*tempMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
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
