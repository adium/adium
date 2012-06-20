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

#import "AIWindowHandlingPreferences.h"
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AIDualWindowInterfacePlugin.h"
#import <Adium/AIContactControllerProtocol.h>
#import "AIListWindowController.h"

@implementation AIWindowHandlingPreferences
@synthesize label_contactList, label_autoHide, label_statusWindow, label_chatWindows, label_show, label_order;
@synthesize matrix_hiding;
@synthesize popUp_chatWindowPosition, popUp_contactListWindowPosition;
@synthesize checkBox_hideOnScreenEdgesOnlyInBackground, checkBox_hideInBackground, checkBox_showOnAllSpaces;
@synthesize checkBox_statusWindowHideInBackground, checkBox_statusWindowAlwaysOnTop;

#pragma mark Preference Pane
- (AIPreferenceCategory)category{
	return AIPref_Advanced;
}
- (NSString *)paneIdentifier{
	return @"WindowHandlingPreferences";
}
- (NSString *)paneName{
    return AILocalizedString(@"Window Handling",nil);
}
- (NSString *)nibName{
    return @"Preferences-WindowHandling";
}
- (NSImage *)paneIcon{
	return [NSImage imageNamed:@"pref-windowhandling" forClass:[self class]];
}

- (void)viewDidLoad
{
	//Setup popups
	NSInteger menuIndex;
	[popUp_chatWindowPosition setMenu:[adium.interfaceController menuForWindowLevelsNotifyingTarget:self]];
	NSInteger level = [[adium.preferenceController preferenceForKey:KEY_WINDOW_LEVEL
															  group:PREF_GROUP_DUAL_WINDOW_INTERFACE] integerValue];
	menuIndex =  [popUp_chatWindowPosition indexOfItemWithTag:level];
	if (menuIndex >= 0 && menuIndex < [popUp_chatWindowPosition numberOfItems]) {
		[popUp_chatWindowPosition selectItemAtIndex:menuIndex];
	}
	
	[popUp_contactListWindowPosition setMenu:[adium.interfaceController menuForWindowLevelsNotifyingTarget:self]];
	level = [[adium.preferenceController preferenceForKey:KEY_CL_WINDOW_LEVEL
													group:PREF_GROUP_CONTACT_LIST] integerValue];
	menuIndex =  [popUp_contactListWindowPosition indexOfItemWithTag:level];
	if (menuIndex >= 0 && menuIndex < [popUp_contactListWindowPosition numberOfItems]) {
		[popUp_contactListWindowPosition selectItemAtIndex:menuIndex];
	}
}

- (void)localizePane
{
	[label_contactList setLocalizedString:AILocalizedString(@"Contact list", nil)];
	[label_autoHide setLocalizedString:AILocalizedString(@"Automatically hide:", nil)];
	[label_chatWindows setLocalizedString:AILocalizedString(@"Chat windows:", nil)];
	[label_statusWindow setLocalizedString:AILocalizedString(@"Away status window:", nil)];
	[label_show setLocalizedString:AILocalizedString(@"Show:", nil)];
	[label_order setLocalizedString:AILocalizedString(@"Order:", nil)];
	
	[[matrix_hiding cellWithTag:AIContactListWindowHidingStyleNone] setTitle:AILocalizedString(@"Never", nil)];
	[[matrix_hiding cellWithTag:AIContactListWindowHidingStyleBackground] setTitle:AILocalizedString(@"While Adium is in the background","Checkbox to indicate that something should occur while Adium is not the active application")];
	[[matrix_hiding cellWithTag:AIContactListWindowHidingStyleSliding] setTitle:AILocalizedString(@"On screen edges", "Advanced contact list: hide the contact list: On screen edges")];
	
	[checkBox_hideOnScreenEdgesOnlyInBackground setLocalizedString:AILocalizedString(@"…only while Adium is in the background", "Checkbox under 'on screen edges' in the advanced contact list preferences")];
	[checkBox_hideInBackground setLocalizedString:AILocalizedString(@"Hide when Adium is in the background", nil)];
	[checkBox_showOnAllSpaces setLocalizedString:AILocalizedString(@"Show on all spaces", nil)];
	
	[checkBox_statusWindowHideInBackground setLocalizedString:AILocalizedString(@"Hide when Adium is not active", nil)];
	[checkBox_statusWindowAlwaysOnTop setLocalizedString:AILocalizedString(@"Show above other windows", nil)];
}

- (BOOL)hideOnScreenEdgesOnlyInBackgroundEnabled
{
	return [[matrix_hiding selectedCell] tag] == AIContactListWindowHidingStyleSliding;
}

/*!
 * @brief Called in response to all preference controls, applies new settings
 */
- (IBAction)changePreference:(id)sender
{
	if (sender == matrix_hiding) {
		[checkBox_hideOnScreenEdgesOnlyInBackground setEnabled:[self hideOnScreenEdgesOnlyInBackgroundEnabled]];
	}
}

- (void)selectedWindowLevel:(id)sender
{
	if ([sender menu] == [popUp_contactListWindowPosition menu]) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender tag]]
										   forKey:KEY_CL_WINDOW_LEVEL
											group:PREF_GROUP_CONTACT_LIST];
	} else if ([sender menu] == [popUp_chatWindowPosition menu]) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender tag]]
										   forKey:KEY_WINDOW_LEVEL
											group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	}
}

@end
