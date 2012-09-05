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

#import "ESContactListAdvancedPreferences.h"
#import "AISCLViewPlugin.h"
#import "AIAppearancePreferencesPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import "AIPreferenceWindowController.h"
#import "AIListWindowController.h"
#import "AIListLayoutWindowController.h"
#import "AIListThemeWindowController.h"
#import <Adium/AIDockControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/ESPresetManagementController.h>
#import <Adium/ESPresetNameSheetController.h>
#import "AIXtrasManager.h"

@interface ESContactListAdvancedPreferences ()
- (NSMenu *)_windowStyleMenu;
- (NSMenu *)_listLayoutMenu;
- (NSMenu *)_colorThemeMenu;
- (void)_addWindowStyleOption:(NSString *)option withTag:(NSInteger)tag toMenu:(NSMenu *)menu;
- (void)_updateSliderValues;
- (void)_editListThemeWithName:(NSString *)name;
- (void)_editListLayoutWithName:(NSString *)name;
- (void)xtrasChanged:(NSNotification *)notification;

- (void)applySetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toPreferenceGroup:(NSString *)preferenceGroup;
- (BOOL)createSetFromPreferenceGroup:(NSString *)preferenceGroup withName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder;
- (BOOL)deleteSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder;
- (BOOL)renameSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toName:(NSString *)newName;
- (BOOL)duplicateSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder newName:(NSString *)newName;
- (NSArray *)availableSetsWithExtension:(NSString *)extension fromFolder:(NSString *)folder;
- (NSArray *)availableLayoutSets;
- (NSArray *)availableThemeSets;
@end

/*!
 * @class ESContactListAdvancedPreferences
 * @brief Advanced contact list preferences
 */
@implementation ESContactListAdvancedPreferences
- (AIPreferenceCategory)category{
	return AIPref_Appearance;
}
- (NSString *)paneIdentifier{
	return @"Contact List";
}
- (NSString *)paneName{
    return AILocalizedString(@"Contact List","Name of the window which lists contacts");
}
- (NSString *)nibName{
    return @"Preferences-ContactList";
}
- (NSImage *)paneIcon{
	return [NSImage imageNamed:@"pref-contactList" forClass:[AIPreferenceWindowController class]];
}

/*!
 * @brief View loaded; configure it for display
 */
- (void)viewDidLoad
{
	[popUp_windowStyle setMenu:[self _windowStyleMenu]];
	
	//Observe preference changes
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
	[label_animation setLocalizedString:AILocalizedString(@"Animation:", nil)];
	[label_automaticSizing setLocalizedString:AILocalizedString(@"Automatic Sizing:", nil)];
	[label_colorTheme setLocalizedString:AILocalizedString(@"Color Theme:", nil)];
	[label_horizontalWidth setLocalizedString:AILocalizedString(@"Maximum Width:", nil)];
	[label_verticalHeight setLocalizedString:AILocalizedString(@"Maximum Height:", nil)];
	[label_listLayout setLocalizedString:AILocalizedString(@"List Layout:", nil)];
	[label_opacity setLocalizedString:AILocalizedString(@"Opacity:", nil)];
	[label_tooltips setLocalizedString:AILocalizedString(@"Tooltips:",nil)];
	[label_windowStyle setLocalizedString:AILocalizedString(@"Window Style:",nil)];
	
	[button_colorTheme setLocalizedString:AILocalizedString(@"Customize…", nil)];
	[button_listLayout setLocalizedString:AILocalizedString(@"Customize…", nil)];

	[checkBox_animateChanges setLocalizedString:AILocalizedString(@"Animate changes","This string is under the heading 'Contact List' and refers to changes such as sort order in the contact list being animated rather than occurring instantenously")];
	[checkBox_flash setLocalizedString:AILocalizedString(@"Flash names with unviewed messages",nil)];
	[checkBox_horizontalAutosizing setLocalizedString:AILocalizedString(@"Size to fit horizontally", nil)];
	[checkBox_verticalAutosizing setLocalizedString:AILocalizedString(@"Size to fit vertically", nil)];
	[checkBox_showTooltips setLocalizedString:AILocalizedString(@"Show contact information tooltips",nil)];
	[checkBox_showTooltipsInBackground setLocalizedString:AILocalizedString(@"While Adium is in the background","Checkbox to indicate that something should occur while Adium is not the active application")];
	[checkBox_verticalAutosizing setLocalizedString:AILocalizedString(@"Size to fit vertically", nil)];
	[checkBox_windowHasShadow setLocalizedString:AILocalizedString(@"Show window shadow",nil)];
	[checkBox_windowHasShadow setToolTip:@"Stay close to the Vorlon."];
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
	//Appearance
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		if (firstTime) {
			[popUp_windowStyle selectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] integerValue]];	
			[slider_windowOpacity setDoubleValue:([[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_OPACITY] doubleValue] * 100.0)];
			[slider_horizontalWidth setIntegerValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] integerValue]];
			[slider_verticalHeight setIntegerValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_HEIGHT] integerValue]];
			[self _updateSliderValues];
		}
		
		//Horizontal resizing label
		if (firstTime || 
			[key isEqualToString:KEY_LIST_LAYOUT_WINDOW_STYLE] ||
			[key isEqualToString:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] ||
			[key isEqualToString:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE]) {
			
			AIContactListWindowStyle windowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
			BOOL horizontalAutosize = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue];
			BOOL verticalAutosize = [[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE] boolValue];
			
			[label_horizontalWidth setLocalizedString:AILocalizedString(@"Maximum Width:",nil)];
			[label_verticalHeight setLocalizedString:AILocalizedString(@"Maximum Height:", nil)];
			
			if (windowStyle == AIContactListWindowStyleStandard) {
				//In standard mode, disable the autosizing sliders if their respective autosize is off
				[label_horizontalWidth setLocalizedString:AILocalizedString(@"Maximum Width:",nil)];
				[slider_horizontalWidth setEnabled:horizontalAutosize];
				[slider_verticalHeight setEnabled:verticalAutosize];
				
			} else {
				//In all the borderless transparent modes, the autosizing sliders control the fixed size
				[label_horizontalWidth setLocalizedString:AILocalizedString(@"Width:",nil)];
				[label_verticalHeight setLocalizedString:AILocalizedString(@"Height:", nil)];
				[slider_horizontalWidth setEnabled:YES];
				[slider_verticalHeight setEnabled:YES];
			}
			
			//Configure the silders' appearance. AIListWindowController must match this behavior for this to make sense.
			switch (windowStyle) {
				case AIContactListWindowStyleStandard:
				case AIContactListWindowStyleBorderless:
				case AIContactListWindowStyleGroupChat:
					//Standard and borderless don't have to vertically autosize
					[checkBox_verticalAutosizing setEnabled:YES];
					[checkBox_verticalAutosizing setState:[[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE
																								  group:PREF_GROUP_APPEARANCE] integerValue]];
					[checkBox_horizontalAutosizing setEnabled:YES];
					[checkBox_horizontalAutosizing setState:[[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE
																								  group:PREF_GROUP_APPEARANCE] integerValue]];
					break;
				case AIContactListWindowStyleGroupBubbles:
				case AIContactListWindowStyleContactBubbles:
				case AIContactListWindowStyleContactBubbles_Fitted:
					//The bubbles styles don't show a window; force them to autosize
					[checkBox_verticalAutosizing setEnabled:NO];
					[checkBox_verticalAutosizing setState:YES];
					[checkBox_horizontalAutosizing setEnabled:NO];
					[checkBox_horizontalAutosizing setState:YES];
			}			
		}
		
		//Selected menu items
		if (firstTime || [key isEqualToString:KEY_LIST_LAYOUT_NAME]) {
			[popUp_listLayout selectItemWithRepresentedObject:[prefDict objectForKey:KEY_LIST_LAYOUT_NAME]];
		}
		if (firstTime || [key isEqualToString:KEY_LIST_THEME_NAME]) {
			[popUp_colorTheme selectItemWithRepresentedObject:[prefDict objectForKey:KEY_LIST_THEME_NAME]];	
		}	
	}
}

/*!
 * @brief Save changed preferences
 */
- (IBAction)changePreference:(id)sender
{
	if (sender == popUp_listLayout) {
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
		
	} else if (sender == slider_verticalHeight) {
		NSInteger newValue = [sender integerValue];
		NSInteger oldValue = [[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_VERTICAL_HEIGHT
																	 group:PREF_GROUP_APPEARANCE] integerValue];
		if (newValue != oldValue) {
			[adium.preferenceController setPreference:[NSNumber numberWithInteger:newValue]
											   forKey:KEY_LIST_LAYOUT_VERTICAL_HEIGHT 
												group:PREF_GROUP_APPEARANCE];
			[self _updateSliderValues];
		}
	}
}

/*!
 *
 */
- (void)_updateSliderValues
{
	[textField_windowOpacity setStringValue:[NSString stringWithFormat:@"%ld%%", (NSInteger)[slider_windowOpacity doubleValue]]];
	[textField_horizontalWidth setStringValue:[NSString stringWithFormat:@"%ldpx",[slider_horizontalWidth integerValue]]];
	[textField_verticalHeight setStringValue:[NSString stringWithFormat:@"%ldpx",[slider_verticalHeight integerValue]]];
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
		if ([self createSetFromPreferenceGroup:PREF_GROUP_LIST_THEME
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
		[self applySetWithName:theme
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
	_listThemes = [self availableThemeSets];
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
		if ([self createSetFromPreferenceGroup:PREF_GROUP_LIST_LAYOUT
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
		[self applySetWithName:layout
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
	_listLayouts = [self availableLayoutSets];
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
		enumerator = [[self availableThemeSets] objectEnumerator];
	} else {
		enumerator = [[self availableLayoutSets] objectEnumerator];
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
		[self renameSetWithName:[preset objectForKey:@"name"]
						extension:LIST_LAYOUT_EXTENSION
						 inFolder:LIST_LAYOUT_FOLDER
						   toName:newName];		
		_listLayouts = [self availableLayoutSets];
		newPresets = _listLayouts;
		
	} else if (presets == _listThemes) {
		[self renameSetWithName:[preset objectForKey:@"name"]
						extension:LIST_THEME_EXTENSION
						 inFolder:LIST_THEME_FOLDER
						   toName:newName];		
		_listThemes = [self availableThemeSets];
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
		[self duplicateSetWithName:[preset objectForKey:@"name"]
						   extension:LIST_LAYOUT_EXTENSION
							inFolder:LIST_LAYOUT_FOLDER
							 newName:newName];		
		_listLayouts = [self availableLayoutSets];
		newPresets = _listLayouts;
		
	} else if (presets == _listThemes) {
		[self duplicateSetWithName:[preset objectForKey:@"name"]
						   extension:LIST_THEME_EXTENSION
							inFolder:LIST_THEME_FOLDER
							 newName:newName];
		_listThemes = [self availableThemeSets];
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
		[self deleteSetWithName:[preset objectForKey:@"name"]
						extension:LIST_LAYOUT_EXTENSION
						 inFolder:LIST_LAYOUT_FOLDER];		
		_listLayouts = [self availableLayoutSets];
		
		return _listLayouts;
		
	} else if (presets == _listThemes) {
		[self deleteSetWithName:[preset objectForKey:@"name"]
						extension:LIST_THEME_EXTENSION
						 inFolder:LIST_THEME_FOLDER];		
		_listThemes = [self availableThemeSets];
		
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
	NSMenuItem		*menuItem;
	NSString		*name;
	
	//Available Layouts
	for (NSDictionary *set in self.availableLayoutSets) {
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
	NSMenuItem		*menuItem;
	NSString		*name;
	
	//Available themes
	for (NSDictionary *set in self.availableThemeSets) {
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

#pragma mark ListLayout and ListTheme preference management
//Apply a set of preferences
- (void)applySetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toPreferenceGroup:(NSString *)preferenceGroup
{
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	NSString		*fileName;
	NSDictionary	*setDictionary = nil;
	
	//Look in each resource location until we find it
	fileName = [setName stringByAppendingPathExtension:extension];
	
	for (NSString *resourcePath in [adium resourcePathsForName:folder]) {
		NSString		*filePath = [resourcePath stringByAppendingPathComponent:fileName];
		
		if ([defaultManager fileExistsAtPath:filePath]) {
			NSBundle *xtraBundle;
			if((xtraBundle = [NSBundle bundleWithPath:filePath]) &&
			   ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] integerValue] == 1)) {
				filePath = [[xtraBundle resourcePath] stringByAppendingPathComponent:@"Data.plist"];
			}
			
			setDictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
			if (setDictionary) break;
		}
	}
	
	//Apply its values
	if (setDictionary) {
		[adium.preferenceController setPreferences:setDictionary
										   inGroup:preferenceGroup];
	}
}

//Create a layout or theme set
- (BOOL)createSetFromPreferenceGroup:(NSString *)preferenceGroup withName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder
{
	NSString		*path;
	NSString		*fileName = [[setName safeFilenameString] stringByAppendingPathExtension:extension];
	
	//If we don't find one, create a path to a bundle in the application support directory
	path = [[[adium applicationSupportDirectory] stringByAppendingPathComponent:folder] stringByAppendingPathComponent:fileName];
	if ([AIXtrasManager createXtraBundleAtPath:path])
		path = [path stringByAppendingPathComponent:@"Contents/Resources/Data.plist"];
	
	if ([[adium.preferenceController preferencesForGroup:preferenceGroup] writeToFile:path atomically:NO]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:AIXtrasDidChangeNotification object:extension];
		
		return YES;
	} else {
		NSRunAlertPanel(AILocalizedString(@"Error Saving Theme",nil),
						AILocalizedString(@"Unable to write file %@ to %@",nil),
						AILocalizedString(@"OK",nil),
						nil,
						nil,
						fileName,
						path);
		return NO;
	}
}

//Delete a layout or theme set
- (BOOL)deleteSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder
{
	BOOL		success;
	
	success = [[NSFileManager defaultManager] removeItemAtPath:[adium pathOfPackWithName:setName
																			   extension:extension
																	  resourceFolderName:folder]
														 error:NULL];
	
	//The availability of an xtras just changed, since we deleted it... post a notification so we can update
	[[NSNotificationCenter defaultCenter] postNotificationName:AIXtrasDidChangeNotification object:extension];
	
	return success;
}

- (BOOL)renameSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toName:(NSString *)newName
{
	BOOL		success;
	
	NSString	*destFolder = [[adium applicationSupportDirectory] stringByAppendingPathComponent:folder];
	NSString	*newFileName = [newName stringByAppendingPathExtension:extension];
	
	success = [[NSFileManager defaultManager] moveItemAtPath:[adium pathOfPackWithName:setName
																			 extension:extension
																	resourceFolderName:folder]
													  toPath:[destFolder stringByAppendingPathComponent:newFileName]
													   error:NULL];
	
	//The availability of an xtras just changed, since we deleted it... post a notification so we can update
	[[NSNotificationCenter defaultCenter] postNotificationName:AIXtrasDidChangeNotification object:extension];
	
	return success;
}

- (BOOL)duplicateSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder newName:(NSString *)newName
{
	BOOL		success;
	
	//Duplicate the set
	NSString	*destFolder = [[adium applicationSupportDirectory] stringByAppendingPathComponent:folder];
	NSString	*newFileName = [newName stringByAppendingPathExtension:extension];
	
	success = [[NSFileManager defaultManager] copyItemAtPath:[adium pathOfPackWithName:setName
																			 extension:extension
																	resourceFolderName:folder]
													  toPath:[destFolder stringByAppendingPathComponent:newFileName]
													   error:NULL];
	
	//The availability of an xtras just changed, since we deleted it... post a notification so we can update
	[[NSNotificationCenter defaultCenter] postNotificationName:AIXtrasDidChangeNotification object:extension];
	
	return success;
}

- (NSArray *)availableSetsWithExtension:(NSString *)extension fromFolder:(NSString *)folder
{
	NSMutableArray	*setArray = [NSMutableArray array];
	NSMutableSet	*alreadyAddedArray = [NSMutableSet set];
	
    for (NSString *filePath in [adium allResourcesForName:folder withExtensions:extension]) {
		NSString		*name;
		NSBundle		*xtraBundle;
		NSDictionary 	*themeDict;
		
		name = [[filePath lastPathComponent] stringByDeletingPathExtension];
		
		if((xtraBundle = [NSBundle bundleWithPath:filePath]) &&
		   ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] integerValue] == 1)) {
			filePath = [[xtraBundle resourcePath] stringByAppendingPathComponent:@"Data.plist"];
		}
		
		if ((themeDict = [NSDictionary dictionaryWithContentsOfFile:filePath])) {			
			//The Adium resource path is last in our resourcePaths array; by only adding sets we haven't
			//already added, we allow precedence to occur rather than conflict.
			if (![alreadyAddedArray containsObject:name]) {
				[setArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									 name, @"name",
									 filePath, @"path",
									 themeDict, @"preferences",
									 nil]];
				[alreadyAddedArray addObject:name];
			}
		}
	}
	
	return [setArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [[obj1 objectForKey:@"name"] caseInsensitiveCompare:[obj2 objectForKey:@"name"]];
	}];
}

- (NSArray *)availableLayoutSets
{
	return [self availableSetsWithExtension:LIST_LAYOUT_EXTENSION 
								 fromFolder:LIST_LAYOUT_FOLDER];
}
- (NSArray *)availableThemeSets
{
	return [self availableSetsWithExtension:LIST_THEME_EXTENSION
								 fromFolder:LIST_THEME_FOLDER];
}

@end
