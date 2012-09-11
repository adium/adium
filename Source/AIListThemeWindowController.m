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

#import "AIListThemeWindowController.h"
#import "AISCLViewPlugin.h"
#import "AITextColorPreviewView.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIListOutlineView.h>

@interface AIListThemeWindowController ()

- (void)configureControls;
- (void)configureControlDimming;
- (void)updateSliderValues;
- (void)configureBackgroundColoring;
- (NSMenu *)displayImageStyleMenu;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

@end

@implementation AIListThemeWindowController

- (id)initWithName:(NSString *)inName notifyingTarget:(id)inTarget
{
    if ((self = [super initWithWindowNibName:@"ListThemeSheet"])) {	
		NSParameterAssert(inTarget && [inTarget respondsToSelector:@selector(listThemeEditorWillCloseWithChanges:forThemeNamed:)]);
	
		target = inTarget;
		themeName = inName;
	}
	
	return self;
}

#pragma mark Window Methods

- (void)windowDidLoad
{
	// Allow alpha in our color pickers
	[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];	

	[self configureControls];
	
	[textField_themeName setStringValue:(themeName ? themeName : @"")];
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
	[target listThemeEditorWillCloseWithChanges:NO forThemeNamed:themeName];
    [self closeWindow:sender];
}

- (IBAction)okay:(id)sender
{
	[target listThemeEditorWillCloseWithChanges:YES forThemeNamed:themeName];
	[self closeWindow:sender];
}

#pragma mark Window Methods

- (void)configureControls
{
    NSDictionary *prefDict = [adium.preferenceController preferencesForGroup:PREF_GROUP_LIST_THEME];

	// Colors
    [colorWell_away setColor:[[prefDict objectForKey:KEY_AWAY_COLOR] representedColor]];
    [colorWell_idle setColor:[[prefDict objectForKey:KEY_IDLE_COLOR] representedColor]];
    [colorWell_signedOff setColor:[[prefDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor]];
    [colorWell_signedOn setColor:[[prefDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor]];
    [colorWell_typing setColor:[[prefDict objectForKey:KEY_TYPING_COLOR] representedColor]];
    [colorWell_unviewedContent setColor:[[prefDict objectForKey:KEY_UNVIEWED_COLOR] representedColor]];
    [colorWell_online setColor:[[prefDict objectForKey:KEY_ONLINE_COLOR] representedColor]];
    [colorWell_idleAndAway setColor:[[prefDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor]];
    [colorWell_offline setColor:[[prefDict objectForKey:KEY_OFFLINE_COLOR] representedColor]];
	
    [colorWell_awayLabel setColor:[[prefDict objectForKey:KEY_LABEL_AWAY_COLOR] representedColor]];
    [colorWell_idleLabel setColor:[[prefDict objectForKey:KEY_LABEL_IDLE_COLOR] representedColor]];
    [colorWell_signedOffLabel setColor:[[prefDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColor]];
    [colorWell_signedOnLabel setColor:[[prefDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColor]];
    [colorWell_typingLabel setColor:[[prefDict objectForKey:KEY_LABEL_TYPING_COLOR] representedColor]];
    [colorWell_unviewedContentLabel setColor:[[prefDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColor]];
    [colorWell_onlineLabel setColor:[[prefDict objectForKey:KEY_LABEL_ONLINE_COLOR] representedColor]];
    [colorWell_idleAndAwayLabel setColor:[[prefDict objectForKey:KEY_LABEL_IDLE_AWAY_COLOR] representedColor]];
    [colorWell_offlineLabel setColor:[[prefDict objectForKey:KEY_LABEL_OFFLINE_COLOR] representedColor]];
	
    [checkBox_signedOff setState:[[prefDict objectForKey:KEY_SIGNED_OFF_ENABLED] boolValue]];
    [checkBox_signedOn setState:[[prefDict objectForKey:KEY_SIGNED_ON_ENABLED] boolValue]];
    [checkBox_away setState:[[prefDict objectForKey:KEY_AWAY_ENABLED] boolValue]];
    [checkBox_idle setState:[[prefDict objectForKey:KEY_IDLE_ENABLED] boolValue]];
    [checkBox_typing setState:[[prefDict objectForKey:KEY_TYPING_ENABLED] boolValue]];
    [checkBox_unviewedContent setState:[[prefDict objectForKey:KEY_UNVIEWED_ENABLED] boolValue]];
    [checkBox_online setState:[[prefDict objectForKey:KEY_ONLINE_ENABLED] boolValue]];
    [checkBox_idleAndAway setState:[[prefDict objectForKey:KEY_IDLE_AWAY_ENABLED] boolValue]];
    [checkBox_offline setState:[[prefDict objectForKey:KEY_OFFLINE_ENABLED] boolValue]];
	
	// Groups
	[colorWell_groupText setColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_TEXT_COLOR] representedColor]];
	[colorWell_groupBackground setColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_BACKGROUND] representedColor]];
	[colorWell_groupBackgroundGradient setColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_BACKGROUND_GRADIENT] representedColor]];
	[colorWell_groupShadow setColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_SHADOW_COLOR] representedColor]];
	[checkBox_groupGradient setState:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_GRADIENT] boolValue]];
	[checkBox_groupShadow setState:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_SHADOW] boolValue]];
	
	//
    [colorWell_statusText setColor:[[prefDict objectForKey:KEY_LIST_THEME_CONTACT_STATUS_COLOR] representedColor]];
	
	// Background Image
	[checkBox_useBackgroundImage setState:[[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED] boolValue]];
	[checkBox_useBackgroundImage setToolTip:AILocalizedString(@"Background images are only applicable to normal and borderless window styles", nil)];
	NSString *backgroundImagePath = [[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_PATH] lastPathComponent];
	
	if (backgroundImagePath) {
		[textField_backgroundImagePath setStringValue:backgroundImagePath];
	}
	
	//
    [colorWell_background setColor:[[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_COLOR] representedColor]];

    // Not all themes have highlight colours
    NSColor *color = [[prefDict objectForKey:KEY_LIST_THEME_HIGHLIGHT_COLOR] representedColor];
	
	if (color) {
		[colorWell_customHighlight setColor:color];
	}
    
	[colorWell_grid setColor:[[prefDict objectForKey:KEY_LIST_THEME_GRID_COLOR] representedColor]];	
	[slider_backgroundFade setDoubleValue:[[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_FADE] doubleValue]];
	
	// Not all themes have the draw-custom-highlight setting
	NSNumber *number = [prefDict objectForKey:KEY_LIST_THEME_HIGHLIGHT_ENABLED];
	[checkBox_drawCustomHighlight setState:number ? [number boolValue] : NSOffState];
	[checkBox_drawGrid setState:[[prefDict objectForKey:KEY_LIST_THEME_GRID_ENABLED] boolValue]];
	[checkBox_backgroundAsStatus setState:[[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_AS_STATUS] boolValue]];
	[checkBox_backgroundAsEvents setState:[[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_AS_EVENTS] boolValue]];
    [checkBox_fadeOfflineImages setState:[[prefDict objectForKey:KEY_LIST_THEME_FADE_OFFLINE_IMAGES] boolValue]];
	
	[popUp_displayImageStyle setMenu:[self displayImageStyleMenu]];
	[popUp_displayImageStyle selectItemWithTag:[[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_STYLE] integerValue]];
	
	[self updateSliderValues];
	[self configureControlDimming];
	[self configureBackgroundColoring];
}

- (void)preferenceChanged:(id)sender
{
    if (sender == colorWell_away) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_AWAY_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_away setNeedsDisplay:YES];
		
    } else if (sender == colorWell_idle) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_IDLE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_idle setNeedsDisplay:YES];
		
    } else if (sender == colorWell_signedOff) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SIGNED_OFF_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_signedOff setNeedsDisplay:YES];
		
    } else if (sender == colorWell_signedOn) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SIGNED_ON_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_signedOn setNeedsDisplay:YES];
		
    } else if (sender == colorWell_typing) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_TYPING_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_typing setNeedsDisplay:YES];
		
    } else if (sender == colorWell_unviewedContent) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_UNVIEWED_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_unviewedContent setNeedsDisplay:YES];
		
    } else if (sender == colorWell_online) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_ONLINE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_online setNeedsDisplay:YES];
		
    } else if (sender == colorWell_idleAndAway) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_IDLE_AWAY_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_idleAndAway setNeedsDisplay:YES];
		
    } else if (sender == colorWell_offline) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_OFFLINE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_offline setNeedsDisplay:YES];
		
    } else if (sender == colorWell_signedOffLabel) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_SIGNED_OFF_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_signedOff setNeedsDisplay:YES];
		
    } else if (sender == colorWell_signedOnLabel) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_SIGNED_ON_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_signedOn setNeedsDisplay:YES];
		
    } else if (sender == colorWell_awayLabel) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_AWAY_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_away setNeedsDisplay:YES];
		
    } else if (sender == colorWell_idleLabel) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_IDLE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_idle setNeedsDisplay:YES];
		
    } else if (sender == colorWell_typingLabel) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_TYPING_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_typing setNeedsDisplay:YES];
		
    } else if (sender == colorWell_unviewedContentLabel) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_UNVIEWED_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_unviewedContent setNeedsDisplay:YES];
		
    } else if (sender == colorWell_onlineLabel) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_ONLINE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_online setNeedsDisplay:YES];
		
    } else if (sender == colorWell_idleAndAwayLabel) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_IDLE_AWAY_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_idleAndAway setNeedsDisplay:YES];
        
    } else if (sender == colorWell_offlineLabel) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_OFFLINE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_offline setNeedsDisplay:YES];
		
        
    } else if (sender == checkBox_signedOff) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SIGNED_OFF_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == checkBox_signedOn) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SIGNED_ON_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == checkBox_away) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_AWAY_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == checkBox_idle) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == checkBox_typing) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TYPING_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == checkBox_unviewedContent) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_UNVIEWED_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == checkBox_online) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_ONLINE_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == checkBox_idleAndAway) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_AWAY_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
	} else if (sender == checkBox_offline) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_OFFLINE_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
	} else if (sender == checkBox_useBackgroundImage) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED
											  group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == checkBox_drawCustomHighlight) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_THEME_HIGHLIGHT_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == checkBox_drawGrid) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_THEME_GRID_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == colorWell_background) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_BACKGROUND_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_background setNeedsDisplay:YES];
		[preview_group setNeedsDisplay:YES];

    } else if (sender == colorWell_customHighlight) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_HIGHLIGHT_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_customHighlight setNeedsDisplay:YES];
		
    } else if (sender == colorWell_grid) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_GRID_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_grid setNeedsDisplay:YES];
		
    } else if (sender == slider_backgroundFade) {
        [adium.preferenceController setPreference:[NSNumber numberWithDouble:[sender doubleValue]]
                                             forKey:KEY_LIST_THEME_BACKGROUND_FADE
                                              group:PREF_GROUP_LIST_THEME];
		[self updateSliderValues];
		
    } else if (sender == colorWell_groupText) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_GROUP_TEXT_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_group setNeedsDisplay:YES];
		
    } else if (sender == colorWell_groupBackground) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_GROUP_BACKGROUND
                                              group:PREF_GROUP_LIST_THEME];
		[preview_group setNeedsDisplay:YES];
		
    } else if (sender == colorWell_groupBackgroundGradient) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_GROUP_BACKGROUND_GRADIENT
                                              group:PREF_GROUP_LIST_THEME];
		[preview_group setNeedsDisplay:YES];
		
	} else if (sender == colorWell_groupShadow) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_GROUP_SHADOW_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_group setNeedsDisplay:YES];
		
    } else if (sender == checkBox_backgroundAsStatus) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_THEME_BACKGROUND_AS_STATUS
                                              group:PREF_GROUP_LIST_THEME];
		[self configureBackgroundColoring];
		
    } else if (sender == checkBox_backgroundAsEvents) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_THEME_BACKGROUND_AS_EVENTS
                                              group:PREF_GROUP_LIST_THEME];
		[self configureBackgroundColoring];
		
    } else if (sender == colorWell_statusText) {
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_CONTACT_STATUS_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == checkBox_fadeOfflineImages) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_THEME_FADE_OFFLINE_IMAGES
                                              group:PREF_GROUP_LIST_THEME];
		
    } else if (sender == checkBox_groupGradient) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_THEME_GROUP_GRADIENT
                                              group:PREF_GROUP_LIST_THEME];
		[preview_group setNeedsDisplay:YES];
		
    } else if (sender == checkBox_groupShadow) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_THEME_GROUP_SHADOW
                                              group:PREF_GROUP_LIST_THEME];
		[preview_group setNeedsDisplay:YES];
		
	} else if (sender == popUp_displayImageStyle) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_THEME_BACKGROUND_IMAGE_STYLE
											  group:PREF_GROUP_LIST_THEME];	
	}
	
	[self configureControlDimming];
}

// Prompt for an image to use
- (IBAction)selectBackgroundImage:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:@"Background Image"];
	[openPanel setAllowedFileTypes:[NSImage imageFileTypes]];
	 
	if ([openPanel runModal] == NSOKButton) {
		NSString *filename = [[openPanel URL] path];
		[adium.preferenceController setPreference:filename
											 forKey:KEY_LIST_THEME_BACKGROUND_IMAGE_PATH
											  group:PREF_GROUP_LIST_THEME];
		if (filename) {
			[textField_backgroundImagePath setStringValue:filename];
		}
	}
}

- (void)updateSliderValues
{
	[textField_backgroundFade setStringValue:[NSString stringWithFormat:@"%ld%%", (NSInteger)([slider_backgroundFade doubleValue] * 100.0)]];
}

// Configure control dimming
- (void)configureControlDimming
{
	NSInteger backStatus = [checkBox_backgroundAsStatus state];
	NSInteger backEvent = [checkBox_backgroundAsEvents state];
	
	// Enable/Disable status color wells
    [colorWell_away setEnabled:[checkBox_away state]];
    [colorWell_awayLabel setEnabled:([checkBox_away state] && backStatus)];
    [colorWell_idle setEnabled:[checkBox_idle state]];
    [colorWell_idleLabel setEnabled:([checkBox_idle state] && backStatus)];
    [colorWell_online setEnabled:[checkBox_online state]];
    [colorWell_onlineLabel setEnabled:([checkBox_online state] && backStatus)];
    [colorWell_idleAndAway setEnabled:[checkBox_idleAndAway state]];
    [colorWell_idleAndAwayLabel setEnabled:([checkBox_idleAndAway state] && backStatus)];
	[colorWell_offline setEnabled:[checkBox_offline state]];
    [colorWell_offlineLabel setEnabled:([checkBox_offline state] && backStatus)];
	
	// Enable/Disable event color wells
    [colorWell_signedOff setEnabled:[checkBox_signedOff state]];
    [colorWell_signedOffLabel setEnabled:([checkBox_signedOff state] && backEvent)];	
    [colorWell_signedOn setEnabled:[checkBox_signedOn state]];
    [colorWell_signedOnLabel setEnabled:([checkBox_signedOn state] && backEvent)];
    [colorWell_typing setEnabled:[checkBox_typing state]];
    [colorWell_typingLabel setEnabled:([checkBox_typing state] && backEvent)];
    [colorWell_unviewedContent setEnabled:[checkBox_unviewedContent state]];
    [colorWell_unviewedContentLabel setEnabled:([checkBox_unviewedContent state] && backEvent)];
	
	// Background image
	[button_setBackgroundImage setEnabled:[checkBox_useBackgroundImage state]];
	[textField_backgroundImagePath setEnabled:[checkBox_useBackgroundImage state]];
	[popUp_displayImageStyle setEnabled:[checkBox_useBackgroundImage state]];
}

// Update the previews for our background coloring toggles
- (void)configureBackgroundColoring
{
	NSColor	*color;
	
	// Status
	color = ([checkBox_backgroundAsStatus state] ? nil : [colorWell_background color]);
	[preview_away setBackColorOverride:color];
	[preview_idle setBackColorOverride:color];
	[preview_online setBackColorOverride:color];
	[preview_idleAndAway setBackColorOverride:color];
	[preview_offline setBackColorOverride:color];
	
	// Events
	color = ([checkBox_backgroundAsEvents state] ? nil : [colorWell_background color]);
	[preview_signedOff setBackColorOverride:color];
	[preview_signedOn setBackColorOverride:color];
	[preview_typing setBackColorOverride:color];
	[preview_unviewedContent setBackColorOverride:color];
	
	// Redisplay
	[preview_away setNeedsDisplay:YES];
	[preview_idle setNeedsDisplay:YES];
	[preview_online setNeedsDisplay:YES];
	[preview_idleAndAway setNeedsDisplay:YES];
	[preview_offline setNeedsDisplay:YES];
	[preview_signedOff setNeedsDisplay:YES];
	[preview_signedOn setNeedsDisplay:YES];
	[preview_typing setNeedsDisplay:YES];
	[preview_unviewedContent setNeedsDisplay:YES];
}

- (NSMenu *)displayImageStyleMenu
{
	NSMenu		*displayImageStyleMenu = [[NSMenu alloc] init];
    NSMenuItem	*menuItem;
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Normal",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setTag:AINormalBackground];
	[displayImageStyleMenu addItem:menuItem];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Tile",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setTag:AITileBackground];
	[displayImageStyleMenu addItem:menuItem];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Fill",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setTag:AIFillProportionatelyBackground];
	[displayImageStyleMenu addItem:menuItem];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Stretch to fill",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setTag:AIFillStretchBackground];
	[displayImageStyleMenu addItem:menuItem];
	
	return displayImageStyleMenu;
}

@end
