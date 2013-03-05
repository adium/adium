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

#import "AIListLayoutWindowController.h"
#import "AIDockController.h"
#import "AISCLViewPlugin.h"
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>

#define	MAX_ALIGNMENT_CHOICES 10

@interface AIListLayoutWindowController ()

- (void)configureControls;
- (void)configureControlDimming;
- (void)updateSliderValues;
- (void)updateDisplayedTabsFromPrefDict:(NSDictionary *)prefDict;
- (void)updateStatusAndServiceIconMenusFromPrefDict:(NSDictionary *)prefDict;
- (void)updateUserIconMenuFromPrefDict:(NSDictionary *)prefDict;
- (NSMenu *)alignmentMenuWithChoices:(NSInteger [])alignmentChoices;
- (NSMenu *)positionMenuWithChoices:(NSInteger [])positionChoices;
- (NSMenu *)extendedStatusStyleMenu;
- (NSMenu *)extendedStatusPositionMenu;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

@end

@implementation AIListLayoutWindowController

- (id)initWithName:(NSString *)inName notifyingTarget:(id)inTarget
{
    if ((self = [super initWithWindowNibName:@"ListLayoutSheet"])) {
		NSParameterAssert(inTarget && [inTarget respondsToSelector:@selector(listLayoutEditorWillCloseWithChanges:forLayoutNamed:)]);
	
		target = inTarget;
		layoutName = inName;
	}

	return self;
}

#pragma mark Window Methods

- (void)windowDidLoad
{
	// Allow alpha in our color pickers
	[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];	

	// Setup
	[fontField_contact setShowPointSize:YES];
	[fontField_contact setShowFontFace:YES];
	[fontField_status setShowPointSize:YES];
	[fontField_status setShowFontFace:YES];
	[fontField_group setShowPointSize:YES];
	[fontField_group setShowFontFace:YES];
	
	[self configureControls];
}

// Called as the sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[[NSColorPanel sharedColorPanel] close];
	
	// No longer allow alpha in our color pickers
	[[NSColorPanel sharedColorPanel] setShowsAlpha:NO];
	
	[super sheetDidEnd:sheet returnCode:returnCode contextInfo:contextInfo];
}

// Cancel
- (IBAction)cancel:(id)sender
{
	[target listLayoutEditorWillCloseWithChanges:NO forLayoutNamed:layoutName];
	[self closeWindow:sender];
}

// Okay
- (IBAction)okay:(id)sender
{
	[target listLayoutEditorWillCloseWithChanges:YES forLayoutNamed:layoutName];
	[self closeWindow:sender];
}

#pragma mark Window Methods

- (void)configureControls
{
	NSDictionary 	*prefDict = [adium.preferenceController preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
	NSInteger 		textAlignmentChoices[4];
	
	textAlignmentChoices[0] = NSLeftTextAlignment;
	textAlignmentChoices[1] = NSCenterTextAlignment;
	textAlignmentChoices[2] = NSRightTextAlignment;
	textAlignmentChoices[3] = -1;
	
	[self updateDisplayedTabsFromPrefDict:prefDict];
	[self updateStatusAndServiceIconMenusFromPrefDict:prefDict];
	[self updateUserIconMenuFromPrefDict:prefDict];
	
	// Context text alignment
	[popUp_contactTextAlignment setMenu:[self alignmentMenuWithChoices:textAlignmentChoices]];
	[popUp_contactTextAlignment selectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] integerValue]];
	
	// Group text alignment
	[popUp_groupTextAlignment setMenu:[self alignmentMenuWithChoices:textAlignmentChoices]];
	[popUp_groupTextAlignment selectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT] integerValue]];

	// Extended Status position
	[popUp_extendedStatusPosition setMenu:[self extendedStatusPositionMenu]];
	[popUp_extendedStatusPosition selectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_POSITION] integerValue]];
	
	// Window style
	[popUp_extendedStatusStyle setMenu:[self extendedStatusStyleMenu]];
	[popUp_extendedStatusStyle selectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_STYLE] integerValue]];
	
	[slider_userIconSize setIntegerValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] integerValue]];
	[slider_contactSpacing setIntegerValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] integerValue]];

	[slider_groupTopSpacing setIntegerValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_TOP_SPACING] integerValue]];
	[slider_groupTopSpacing setMinValue:0];
	[slider_groupTopSpacing setMaxValue:16];

	[slider_contactLeftIndent setIntegerValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT] integerValue]];
	[slider_contactRightIndent setIntegerValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT] integerValue]];
	[self updateSliderValues];
	
	[fontField_contact setFont:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_FONT] representedFont]];
	[fontField_status setFont:[[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_FONT] representedFont]];
	[fontField_group setFont:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_FONT] representedFont]];
	
	[self configureControlDimming];
}

- (void)preferenceChanged:(id)sender
{
	if (sender == popUp_contactTextAlignment) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_ALIGNMENT
											  group:PREF_GROUP_LIST_LAYOUT];
		
		NSDictionary *prefDict = [adium.preferenceController preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
		
		[self updateStatusAndServiceIconMenusFromPrefDict:prefDict];
		[self updateUserIconMenuFromPrefDict:prefDict];
		[self configureControlDimming];
		
	} else if (sender == popUp_groupTextAlignment) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT
											  group:PREF_GROUP_LIST_LAYOUT];
		
	} else if (sender == popUp_extendedStatusPosition) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_POSITION
											  group:PREF_GROUP_LIST_LAYOUT];
		
	} else if (sender == popUp_userIconPosition) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_USER_ICON_POSITION
											  group:PREF_GROUP_LIST_LAYOUT];
		
	} else if (sender == popUp_statusIconPosition) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_STATUS_ICON_POSITION
											  group:PREF_GROUP_LIST_LAYOUT];
		
	} else if (sender == popUp_serviceIconPosition) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_SERVICE_ICON_POSITION
											  group:PREF_GROUP_LIST_LAYOUT];
		
	} else if (sender == popUp_extendedStatusStyle) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_STYLE
											  group:PREF_GROUP_LIST_LAYOUT];
		
		
	} else if (sender == slider_userIconSize) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender integerValue]]
											 forKey:KEY_LIST_LAYOUT_USER_ICON_SIZE
											  group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];
		
	} else if (sender == slider_contactSpacing) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender integerValue]]
											 forKey:KEY_LIST_LAYOUT_CONTACT_SPACING
											  group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];
	} else if (sender == slider_groupTopSpacing) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender integerValue]]
											 forKey:KEY_LIST_LAYOUT_GROUP_TOP_SPACING
											  group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];
		
	} else if (sender == checkBox_userIconVisible) {
		NSDictionary	*prefDict;
		
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_ICON
											  group:PREF_GROUP_LIST_LAYOUT];
		
		prefDict  = [adium.preferenceController preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
		// Update the status and service icon menus to show/hide the badge options
		[self updateStatusAndServiceIconMenusFromPrefDict:prefDict];
		[self configureControlDimming];
		
	} else if (sender == checkBox_extendedStatusVisible) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS
											  group:PREF_GROUP_LIST_LAYOUT];
		[self configureControlDimming];
		
	} else if (sender == checkBox_statusIconsVisible) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS
											  group:PREF_GROUP_LIST_LAYOUT];
		[self configureControlDimming];
		
	} else if (sender == checkBox_serviceIconsVisible) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS
											  group:PREF_GROUP_LIST_LAYOUT];
		[self configureControlDimming];
		
    } else if (sender == checkBox_outlineBubbles) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_LAYOUT_OUTLINE_BUBBLE
                                              group:PREF_GROUP_LIST_LAYOUT];
		[self configureControlDimming];
		
    } else if (sender == checkBox_drawContactBubblesWithGraadient) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_LAYOUT_CONTACT_BUBBLE_GRADIENT
                                              group:PREF_GROUP_LIST_LAYOUT];
		
    } else if (sender == checkBox_showGroupBubbles) {
		BOOL shouldHideGroupBubbles = ![sender state];
		
        [adium.preferenceController setPreference:[NSNumber numberWithBool:shouldHideGroupBubbles]
                                             forKey:KEY_LIST_LAYOUT_GROUP_HIDE_BUBBLE
                                              group:PREF_GROUP_LIST_LAYOUT];
		[self configureControlDimming];
		
    } else if (sender == slider_contactLeftIndent) {
        [adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender integerValue]]
                                             forKey:KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT
                                              group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];
		
    } else if (sender == slider_contactRightIndent) {
        [adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender integerValue]]
                                             forKey:KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT
                                              group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];
		
	} else if (sender == slider_outlineWidth) {
		NSInteger newValue = [sender integerValue];
		NSInteger oldValue = [[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_OUTLINE_BUBBLE_WIDTH
																 group:PREF_GROUP_LIST_LAYOUT] integerValue];
		if (newValue != oldValue) { 
			[adium.preferenceController setPreference:[NSNumber numberWithInteger:newValue]
												 forKey:KEY_LIST_LAYOUT_OUTLINE_BUBBLE_WIDTH
												  group:PREF_GROUP_LIST_LAYOUT];
			[self updateSliderValues];
		}
	}
}

- (BOOL)fontPreviewField:(JVFontPreviewField *)field shouldChangeToFont:(NSFont *)font
{
	return YES;
}

- (void)fontPreviewField:(JVFontPreviewField *)field didChangeToFont:(NSFont *)font
{
	if (field == fontField_contact) {
        [adium.preferenceController setPreference:[font stringRepresentation]
                                             forKey:KEY_LIST_LAYOUT_CONTACT_FONT
                                              group:PREF_GROUP_LIST_LAYOUT];
	} else if (field == fontField_status) {
        [adium.preferenceController setPreference:[font stringRepresentation]
                                             forKey:KEY_LIST_LAYOUT_STATUS_FONT
                                              group:PREF_GROUP_LIST_LAYOUT];
	} else if (field == fontField_group) {
        [adium.preferenceController setPreference:[font stringRepresentation]
                                             forKey:KEY_LIST_LAYOUT_GROUP_FONT
                                              group:PREF_GROUP_LIST_LAYOUT];
	}
}

- (void)updateSliderValues
{
	NSInteger iconSize = [slider_userIconSize integerValue];
	[textField_userIconSize setStringValue:[NSString stringWithFormat:@"%ldx%ld", iconSize,iconSize]];
	[textField_contactSpacing setStringValue:[NSString stringWithFormat:@"%ldpx", [slider_contactSpacing integerValue]]];
	[textField_groupTopSpacing setStringValue:[NSString stringWithFormat:@"%ldpx", [slider_groupTopSpacing integerValue]]];
	[textField_contactLeftIndent setStringValue:[NSString stringWithFormat:@"%ldpx", [slider_contactLeftIndent integerValue]]];
	[textField_contactRightIndent setStringValue:[NSString stringWithFormat:@"%ldpx", [slider_contactRightIndent integerValue]]];
	[textField_outlineWidthIndicator setStringValue:[NSString stringWithFormat:@"%ldpx", [slider_outlineWidth integerValue]]];
}

// Configure control dimming
- (void)configureControlDimming
{
	NSDictionary	*prefDict = [adium.preferenceController preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
	NSInteger		windowStyle = [[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE group:PREF_GROUP_APPEARANCE] integerValue];
	
	// Bubble to fit limitations
	BOOL nonFitted = (windowStyle != AIContactListWindowStyleContactBubbles_Fitted);
	
	if (nonFitted) {
		// For the non-fitted styles, enable and set the proper state
		[checkBox_extendedStatusVisible setEnabled:YES];
		[checkBox_extendedStatusVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS] boolValue]];
	} else {
		// For the fitted style, disable and set to NO the extendedStatus
		[checkBox_extendedStatusVisible setEnabled:NO];
		[checkBox_extendedStatusVisible setState:NO];
	}
	
	if (nonFitted || ([[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] integerValue] != NSCenterTextAlignment)) {
		// For non-fitted or non-centered fitted, enable and set the appropriate value
		[checkBox_userIconVisible setEnabled:YES];
		[checkBox_userIconVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue]];
		
		[checkBox_statusIconsVisible setEnabled:YES];
		[checkBox_statusIconsVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS] boolValue]];
		
		[checkBox_serviceIconsVisible setEnabled:YES];
		[checkBox_serviceIconsVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS] boolValue]];	
		
	} else {
		// For fitted and centered, disable and set to NO
		[checkBox_userIconVisible setEnabled:NO];
		[checkBox_userIconVisible setState:NO];
		
		[checkBox_statusIconsVisible setEnabled:NO];
		[checkBox_statusIconsVisible setState:NO];
		
		[checkBox_serviceIconsVisible setEnabled:NO];
		[checkBox_serviceIconsVisible setState:NO];
	}
	
	// User icon controls
	[slider_userIconSize setEnabled:([checkBox_userIconVisible state] && [checkBox_userIconVisible isEnabled])];
	[textField_userIconSize setEnabled:([checkBox_userIconVisible state] && [checkBox_userIconVisible isEnabled])];
	[popUp_userIconPosition setEnabled:([checkBox_userIconVisible state] && [checkBox_userIconVisible isEnabled])];
	
	// Other controls
	BOOL extendedStatusEnabled = ([checkBox_extendedStatusVisible state] && [checkBox_extendedStatusVisible isEnabled]);
	
	[popUp_extendedStatusStyle setEnabled:extendedStatusEnabled];
	[popUp_extendedStatusPosition setEnabled:extendedStatusEnabled];
	[popUp_statusIconPosition setEnabled:([checkBox_statusIconsVisible state] && 
										  [checkBox_statusIconsVisible isEnabled] &&
										  ([popUp_statusIconPosition numberOfItems] > 0))];
	[popUp_serviceIconPosition setEnabled:([checkBox_serviceIconsVisible state] &&
										   [checkBox_serviceIconsVisible isEnabled] &&
										   ([popUp_serviceIconPosition numberOfItems] > 0))];
	[popUp_userIconPosition setEnabled:([checkBox_userIconVisible state] &&
										[checkBox_userIconVisible isEnabled] &&
										([popUp_userIconPosition numberOfItems] > 0))];
	
	// Disable group spacing when not using mockie
	[slider_groupTopSpacing setEnabled:(windowStyle == AIContactListWindowStyleGroupBubbles)];
	[textField_groupTopSpacing setEnabled:(windowStyle == AIContactListWindowStyleGroupBubbles)];
	
	// Contact Bubbles Advanced
	
	// Only enable the outline width slider if outline width is being shown
	[slider_outlineWidth setEnabled:[checkBox_outlineBubbles state]];
}

- (void)updateStatusAndServiceIconMenusFromPrefDict:(NSDictionary *)prefDict
{
	NSInteger	statusAndServicePositionChoices[7];
	BOOL		showUserIcon = [[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue];
	NSInteger	indexForFinishingChoices = 0;
	
	if ([[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE group:PREF_GROUP_APPEARANCE] integerValue] != AIContactListWindowStyleContactBubbles_Fitted) {
		statusAndServicePositionChoices[0] = LIST_POSITION_FAR_LEFT;
		statusAndServicePositionChoices[1] = LIST_POSITION_LEFT;
		statusAndServicePositionChoices[2] = LIST_POSITION_RIGHT;
		statusAndServicePositionChoices[3] = LIST_POSITION_FAR_RIGHT;
		
		indexForFinishingChoices = 4;
		
	} else {
		// For fitted pillows, only show the options which correspond to the text alignment
		switch ([[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] integerValue]) {
			case NSLeftTextAlignment:
				statusAndServicePositionChoices[0] = LIST_POSITION_FAR_LEFT;
				statusAndServicePositionChoices[1] = LIST_POSITION_LEFT;
				indexForFinishingChoices = 2;
				break;

			case NSRightTextAlignment:
				statusAndServicePositionChoices[0] = LIST_POSITION_RIGHT;
				statusAndServicePositionChoices[1] = LIST_POSITION_FAR_RIGHT;
				indexForFinishingChoices = 2;
				break;
				
			case NSCenterTextAlignment:
				break;
		}	
	}
	
	// Only show the badge choices if we are showing the user icon
	if (showUserIcon && (indexForFinishingChoices != 0)) {
		statusAndServicePositionChoices[indexForFinishingChoices] = LIST_POSITION_BADGE_LEFT;
		statusAndServicePositionChoices[indexForFinishingChoices + 1] = LIST_POSITION_BADGE_RIGHT;
		statusAndServicePositionChoices[indexForFinishingChoices + 2] = -1;

	} else {
		statusAndServicePositionChoices[indexForFinishingChoices] = -1;
		
	}
	
	/* If we can't select an item in the status icon or service icon menu, that means our previous selection is no longer available;
	 * set the preference to whichever option we just 'selected' by default.
	 */
	[popUp_statusIconPosition setMenu:[self positionMenuWithChoices:statusAndServicePositionChoices]];
	
	if ([popUp_statusIconPosition numberOfItems] &&
		![popUp_statusIconPosition selectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_ICON_POSITION] integerValue]]) {
		[popUp_statusIconPosition selectItemAtIndex:0];
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[popUp_statusIconPosition selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_STATUS_ICON_POSITION
											  group:PREF_GROUP_LIST_LAYOUT];		
	}

	[popUp_serviceIconPosition setMenu:[self positionMenuWithChoices:statusAndServicePositionChoices]];
	
	if ([popUp_serviceIconPosition numberOfItems] &&
		![popUp_serviceIconPosition selectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_SERVICE_ICON_POSITION] integerValue]]) {
		[popUp_serviceIconPosition selectItemAtIndex:0];
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[popUp_serviceIconPosition selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_SERVICE_ICON_POSITION
											  group:PREF_GROUP_LIST_LAYOUT];
	}
}

- (void)updateUserIconMenuFromPrefDict:(NSDictionary *)prefDict
{
	NSInteger userIconPositionChoices[3];
	
	if ([[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE group:PREF_GROUP_APPEARANCE] integerValue] != AIContactListWindowStyleContactBubbles_Fitted) {
		userIconPositionChoices[0] = LIST_POSITION_LEFT;
		userIconPositionChoices[1] = LIST_POSITION_RIGHT;
		userIconPositionChoices[2] = -1;
	} else {
		// For fitted pillows, only show the options which correspond to the text alignment
		switch ([[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] integerValue]) {
			case NSLeftTextAlignment:
				userIconPositionChoices[0] = LIST_POSITION_LEFT;
				userIconPositionChoices[1] = -1;
				break;
				
			case NSRightTextAlignment:		
				userIconPositionChoices[0] = LIST_POSITION_RIGHT;
				userIconPositionChoices[1] = -1;
				break;
			case NSCenterTextAlignment:
				userIconPositionChoices[0] = -1;				
				break;
		}	
	}

	// User icon position
	[popUp_userIconPosition setMenu:[self positionMenuWithChoices:userIconPositionChoices]];
	[popUp_userIconPosition selectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_POSITION] integerValue]];
}

#pragma mark Menu generation

- (NSMenu *)alignmentMenuWithChoices:(NSInteger [])alignmentChoices
{
    NSMenu		*alignmentMenu = [[NSMenu alloc] init];
	NSMenuItem	*menuItem;

	NSUInteger	i = 0;
	
	while (alignmentChoices[i] != -1) {
		NSString *menuTitle = nil;
		
		switch (alignmentChoices[i]) {
			case NSLeftTextAlignment:	menuTitle = AILocalizedString(@"Left",nil);
				break;
			case NSCenterTextAlignment:	menuTitle = AILocalizedString(@"Center",nil);
				break;
			case NSRightTextAlignment:	menuTitle = AILocalizedString(@"Right",nil);
				break;
		}
		menuItem = [[NSMenuItem alloc] initWithTitle:menuTitle
																		 target:nil
																		 action:nil
																  keyEquivalent:@""];
		[menuItem setTag:alignmentChoices[i]];
		[alignmentMenu addItem:menuItem];
		
		i++;
	}
	
	return alignmentMenu;
	
}

- (NSMenu *)positionMenuWithChoices:(NSInteger [])positionChoices
{
    NSMenu		*positionMenu = [[NSMenu alloc] init];
    NSMenuItem	*menuItem;
    
	NSUInteger	i = 0;
	
	while (positionChoices[i] != -1) {
		NSString *menuTitle = nil;
		
		switch (positionChoices[i]) {
			case LIST_POSITION_LEFT:
				menuTitle = AILocalizedString(@"Left",nil);
				break;
			case LIST_POSITION_RIGHT:
				menuTitle = AILocalizedString(@"Right",nil);
				break;
			case LIST_POSITION_FAR_LEFT: menuTitle = AILocalizedString(@"Far Left",nil);
				break;
			case LIST_POSITION_FAR_RIGHT: menuTitle = AILocalizedString(@"Far Right",nil);
				break;
			case LIST_POSITION_BADGE_LEFT: menuTitle = AILocalizedString(@"Badge (Lower Left)",nil);
				break;
			case LIST_POSITION_BADGE_RIGHT: menuTitle = AILocalizedString(@"Badge (Lower Right)",nil);
				break;
		}
		menuItem = [[NSMenuItem alloc] initWithTitle:menuTitle
																		 target:nil
																		 action:nil
																  keyEquivalent:@""];
		[menuItem setTag:positionChoices[i]];
		[positionMenu addItem:menuItem];
		
		i++;
	}
	
	return positionMenu;
}

- (NSMenu *)extendedStatusPositionMenu
{
	NSMenu		*extendedStatusPositionMenu = [[NSMenu alloc] init];
    NSMenuItem	*menuItem;
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Below Name",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setTag:EXTENDED_STATUS_POSITION_BELOW_NAME];
	[extendedStatusPositionMenu addItem:menuItem];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Beside Name",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setTag:EXTENDED_STATUS_POSITION_BESIDE_NAME];
	[extendedStatusPositionMenu addItem:menuItem];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Idle Beside, Status Below",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setTag:EXTENDED_STATUS_POSITION_BOTH];
	[extendedStatusPositionMenu addItem:menuItem];
	
	return extendedStatusPositionMenu;
}

- (NSMenu *)extendedStatusStyleMenu
{
    NSMenu		*extendedStatusStyleMenu = [[NSMenu alloc] init];
    NSMenuItem	*menuItem;
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Status",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setTag:STATUS_ONLY];
	[extendedStatusStyleMenu addItem:menuItem];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Idle Time",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setTag:IDLE_ONLY];
	[extendedStatusStyleMenu addItem:menuItem];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Idle and Status",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setTag:IDLE_AND_STATUS];
	[extendedStatusStyleMenu addItem:menuItem];
	
	return extendedStatusStyleMenu;
}

#pragma mark Displayed Tabs

- (void)updateDisplayedTabsFromPrefDict:(NSDictionary *)prefDict
{
	AIContactListWindowStyle windowStyle;
	BOOL tabViewCurrentHasAdvancedContactBubbles;
	
	windowStyle = [[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE group:PREF_GROUP_APPEARANCE] intValue];
	tabViewCurrentHasAdvancedContactBubbles = ([[tabView_preferences tabViewItems] containsObjectIdenticalTo:tabViewItem_advancedContactBubbles]);
	
	if ((windowStyle == AIContactListWindowStyleContactBubbles_Fitted) ||
		(windowStyle == AIContactListWindowStyleContactBubbles)) {
		
		if (!tabViewCurrentHasAdvancedContactBubbles) {
			[tabView_preferences addTabViewItem:tabViewItem_advancedContactBubbles];
		}
		
		// Configure the controls whose state we only care about if we are showing this tab view item
		BOOL showGroupBubbles = ![[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_HIDE_BUBBLE] boolValue];
		[checkBox_showGroupBubbles setState:showGroupBubbles];
		
		[checkBox_outlineBubbles setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_OUTLINE_BUBBLE] boolValue]];
		[checkBox_drawContactBubblesWithGraadient setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_BUBBLE_GRADIENT] boolValue]];
		
		[slider_outlineWidth setIntegerValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_OUTLINE_BUBBLE_WIDTH] integerValue]];
		
	} else {
		if (tabViewCurrentHasAdvancedContactBubbles) {
			[tabView_preferences removeTabViewItem:tabViewItem_advancedContactBubbles];
		}		
	}
}

@end
