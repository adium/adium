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

#import "ESCLViewAdvancedPreferences.h"
#import "AISCLViewPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/CBApplicationAdditions.h>

@implementation ESCLViewAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return AIPref_Advanced_ContactList;
}
- (NSString *)label{
    return AILocalizedString(@"Display Preferences",nil);
}
- (NSString *)nibName{
    return @"CLViewAdvancedPrefs";
}

- (NSDictionary *)restorablePreferences
{
	NSLog(SCL_DEFAULT_PREFS);
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:SCL_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsTemp = [NSDictionary dictionaryWithObjectsAndKeys:
		[defaultPrefs objectForKey:KEY_SCL_BORDERLESS],KEY_SCL_BORDERLESS,
		[defaultPrefs objectForKey:KEY_SCL_SHADOWS],KEY_SCL_SHADOWS,
		[defaultPrefs objectForKey:KEY_SCL_SPACING],KEY_SCL_SPACING,
		[defaultPrefs objectForKey:KEY_SCL_OPACITY],KEY_SCL_OPACITY,
		[defaultPrefs objectForKey:KEY_SCL_OUTLINE_GROUPS],KEY_SCL_OUTLINE_GROUPS,
		[defaultPrefs objectForKey:KEY_SCL_OUTLINE_GROUPS_COLOR],KEY_SCL_OUTLINE_GROUPS_COLOR,
		[defaultPrefs objectForKey:KEY_SCL_SHOW_TOOLTIPS],KEY_SCL_SHOW_TOOLTIPS,
		nil];
								
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultsTemp forKey:PREF_GROUP_CONTACT_LIST_DISPLAY];
	return defaultsDict;
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == slider_opacity){
        [adium.preferenceController setPreference:[NSNumber numberWithDouble:[sender doubleValue]]
                                             forKey:KEY_SCL_OPACITY
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }else if(sender == checkbox_borderless){
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_BORDERLESS
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }else if(sender == checkbox_shadows){
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_SHADOWS
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }else if(sender == slider_rowSpacing){
        [adium.preferenceController setPreference:[NSNumber numberWithDouble:[sender doubleValue]]
                                             forKey:KEY_SCL_SPACING
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];   
    }else if(sender == checkbox_outlineGroups){
        [adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_OUTLINE_GROUPS
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }else if(sender == colorWell_outlineGroupsColor){
        [adium.preferenceController setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_OUTLINE_GROUPS_COLOR
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }else if(sender == checkBox_tooltips){
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_SCL_SHOW_TOOLTIPS
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	}
			
    [self configureControlDimming];
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [adium.preferenceController preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];

    [slider_opacity setDoubleValue:[[preferenceDict objectForKey:KEY_SCL_OPACITY] doubleValue]];
    [checkbox_borderless setState:[[preferenceDict objectForKey:KEY_SCL_BORDERLESS] boolValue]];
    [checkbox_shadows setState:[[preferenceDict objectForKey:KEY_SCL_SHADOWS] boolValue]];
    [checkbox_shadows setToolTip:@"Stay close to the Vorlon."];
    [checkBox_tooltips setState:[[preferenceDict objectForKey:KEY_SCL_SHOW_TOOLTIPS] boolValue]];
	
    [slider_rowSpacing setDoubleValue:[[preferenceDict objectForKey:KEY_SCL_SPACING] doubleValue]];
    [checkbox_outlineGroups setState:[[preferenceDict objectForKey:KEY_SCL_OUTLINE_GROUPS] boolValue]];
    [colorWell_outlineGroupsColor setColor:[[preferenceDict objectForKey:KEY_SCL_OUTLINE_GROUPS_COLOR] representedColor]];
    
    [self configureControlDimming];
}

- (void)viewWillClose
{
	if([colorWell_outlineGroupsColor isActive]) [colorWell_outlineGroupsColor deactivate];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
	[colorWell_outlineGroupsColor setEnabled:[checkbox_outlineGroups state]];
}

@end



