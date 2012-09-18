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

#import "AIDualWindowInterfacePlugin.h"
#import "ESDualWindowMessageAdvancedPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIImageAdditions.h>

#import "AIDockController.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AIPreferenceWindowController.h"

@interface ESDualWindowMessageAdvancedPreferences ()
- (NSMenu *)_fontSizeMenu;
- (NSMenu *)_timeStampMenu;
- (void)_addTimeStampChoice:(NSDateFormatter *)formatter toMenu:(NSMenu *)menu;
- (void)configurePreferencesForTab;
@end

@implementation ESDualWindowMessageAdvancedPreferences

- (NSString *)label{
    return AILocalizedString(@"Messages",nil);
}
- (NSString *)nibName{
    return @"DualWindowMessageAdvanced";
}
- (NSImage *)image{
	return [NSImage imageNamed:@"pref-messages" forClass:[AIPreferenceWindowController class]];
}

- (AIWebkitStyleType)currentTab
{
	if (tabView_messageType.selectedTabViewItem == tabViewItem_regular) {
		return AIWebkitRegularChat;
	} else {
		return AIWebkitGroupChat;
	}
}

- (NSString *)preferenceGroupForCurrentTab
{
	NSString *prefGroup = nil;
	
	switch(self.currentTab) {
		case AIWebkitRegularChat:
			prefGroup = PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY;
			break;
			
		case AIWebkitGroupChat:
			prefGroup = PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY;
			break;		
	}
	
	return prefGroup;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	[self configurePreferencesForTab];
}

- (void)configurePreferencesForTab
{
	NSDictionary *prefDict = [adium.preferenceController preferencesForGroup:self.preferenceGroupForCurrentTab];
	
	[checkBox_customNameFormatting setState:[[prefDict objectForKey:KEY_WEBKIT_USE_NAME_FORMAT] boolValue]];
	[popUp_nameFormat selectItemWithTag:[[prefDict objectForKey:KEY_WEBKIT_NAME_FORMAT] integerValue]];
	
	[popUp_minimumFontSize setMenu:[self _fontSizeMenu]];
	[popUp_minimumFontSize selectItemWithTag:[[prefDict objectForKey:KEY_WEBKIT_MIN_FONT_SIZE] integerValue]];
	
	[popUp_timeStampFormat setMenu:[self _timeStampMenu]];
	[popUp_timeStampFormat selectItemWithRepresentedObject:[prefDict objectForKey:KEY_WEBKIT_TIME_STAMP_FORMAT]];
	
	BOOL showTabCount = [[adium.preferenceController preferenceForKey:(self.currentTab == AIWebkitGroupChat ? KEY_TABBAR_SHOW_UNREAD_COUNT_GROUP : KEY_TABBAR_SHOW_UNREAD_COUNT)
																group:PREF_GROUP_DUAL_WINDOW_INTERFACE] boolValue];
	[checkBox_showTabCount setState:showTabCount];
	
	[checkBox_unreadMentionCount setState:[[adium.preferenceController preferenceForKey:KEY_TABBAR_SHOW_UNREAD_MENTION_ONLYGROUP
																				  group:PREF_GROUP_DUAL_WINDOW_INTERFACE] boolValue]];
	
	[self configureControlDimming];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if (sender == autohide_tabBar) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:![sender state]]
											 forKey:KEY_AUTOHIDE_TABBAR
											  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];

	} else if (sender == checkBox_hide) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
											 forKey:KEY_WINDOW_HIDE
											  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
		
	} else if (sender == checkBox_psychicOpen) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
											 forKey:KEY_PSYCHIC
											  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	
	} else if (sender == checkBox_customNameFormatting) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_WEBKIT_USE_NAME_FORMAT
											  group:self.preferenceGroupForCurrentTab];
		
	} else if (sender == popUp_nameFormat) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedItem] tag]]
											 forKey:KEY_WEBKIT_NAME_FORMAT
											  group:self.preferenceGroupForCurrentTab];

	} else if (sender == popUp_minimumFontSize) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedItem] tag]]
											 forKey:KEY_WEBKIT_MIN_FONT_SIZE
											  group:self.preferenceGroupForCurrentTab];
		
	} else if (sender == popUp_timeStampFormat) {
		[adium.preferenceController setPreference:[[sender selectedItem] representedObject]
											 forKey:KEY_WEBKIT_TIME_STAMP_FORMAT
											  group:self.preferenceGroupForCurrentTab];
		
	} else if (sender == checkBox_showTabCount) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
										   forKey:(self.currentTab == AIWebkitGroupChat ? KEY_TABBAR_SHOW_UNREAD_COUNT_GROUP : KEY_TABBAR_SHOW_UNREAD_COUNT)
											group:PREF_GROUP_DUAL_WINDOW_INTERFACE];

	} else if (sender == checkBox_unreadMentionCount) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
										   forKey:KEY_TABBAR_SHOW_UNREAD_MENTION_ONLYGROUP
											group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	}
	
	[self configureControlDimming];
}

/*!
* @brief User selected a window level
 */
- (void)selectedWindowLevel:(id)sender
{	
	[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender tag]]
										 forKey:KEY_WINDOW_LEVEL
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*prefDict;
	NSInteger				menuIndex;

	prefDict = [adium.preferenceController preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    [autohide_tabBar setState:![[prefDict objectForKey:KEY_AUTOHIDE_TABBAR] boolValue]];

	//Window position
	[popUp_windowPosition setMenu:[adium.interfaceController menuForWindowLevelsNotifyingTarget:self]];
	menuIndex =  [popUp_windowPosition indexOfItemWithTag:[[prefDict objectForKey:KEY_WINDOW_LEVEL] integerValue]];
	if (menuIndex >= 0 && menuIndex < [popUp_windowPosition numberOfItems]) {
		[popUp_windowPosition selectItemAtIndex:menuIndex];
	}
	
	[checkBox_hide setState:[[prefDict objectForKey:KEY_WINDOW_HIDE] boolValue]];
	[checkBox_psychicOpen setState:[[prefDict objectForKey:KEY_PSYCHIC] boolValue]];
	
	[self configurePreferencesForTab];
    [self configureControlDimming];
}

- (void)configureControlDimming
{
	// We load the regular preferences, since both group and regular are copies of each other for these.
	NSDictionary	*prefDict = [adium.preferenceController preferencesForGroup:self.preferenceGroupForCurrentTab];
	
	[popUp_nameFormat setEnabled:[[prefDict objectForKey:KEY_WEBKIT_USE_NAME_FORMAT] boolValue]];
	[checkBox_unreadMentionCount setEnabled:checkBox_showTabCount.state];
}

/*!
 * @brief Build & return a time stamp menu
 */
- (NSMenu *)_timeStampMenu
{
	NSMenu	*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
	
	//Generate all the available time stamp formats
	//If there is no difference between the time stamp with AM/PM and the one without, the localized time stamp must
	//not include AM/PM.  Since these menu items would appear as duplicates we exclude them.
	
    __block NSString	*sampleStampA, *sampleStampB;
	
	[NSDateFormatter withLocalizedDateFormatterShowingSeconds:NO showingAMorPM:YES perform:^(NSDateFormatter *noSecondsAMPM){
		sampleStampA = [[noSecondsAMPM stringForObjectValue:[NSDate date]] retain];
	}];
	[sampleStampA autorelease];
	
	[NSDateFormatter withLocalizedDateFormatterShowingSeconds:NO showingAMorPM:NO perform:^(NSDateFormatter *noSecondsNoAMPM){
		sampleStampB = [[noSecondsNoAMPM stringForObjectValue:[NSDate date]] retain];
	}];
	[sampleStampB autorelease];
	
	BOOL		noAMPM = [sampleStampA isEqualToString:sampleStampB];
	
	//Build the menu from the available formats
	[NSDateFormatter withLocalizedDateFormatterShowingSeconds:NO showingAMorPM:NO perform:^(NSDateFormatter *noSecondsNoAMPM){
		[self _addTimeStampChoice:noSecondsNoAMPM toMenu:menu];
	}];
	
	[NSDateFormatter withLocalizedDateFormatterShowingSeconds:NO showingAMorPM:YES perform:^(NSDateFormatter *noSecondsAMPM){
		if (!noAMPM) [self _addTimeStampChoice:noSecondsAMPM toMenu:menu];
	}];
	
	[NSDateFormatter withLocalizedDateFormatterShowingSeconds:YES showingAMorPM:NO perform:^(NSDateFormatter *secondsNoAMPM){
		[self _addTimeStampChoice:secondsNoAMPM toMenu:menu];
	}];
	
	[NSDateFormatter withLocalizedDateFormatterShowingSeconds:YES showingAMorPM:YES perform:^(NSDateFormatter *secondsAMPM){
		if (!noAMPM) [self _addTimeStampChoice:secondsAMPM toMenu:menu];
	}];
	
	return menu;
}
- (void)_addTimeStampChoice:(NSDateFormatter *)formatter toMenu:(NSMenu *)menu
{	
	[menu addItemWithTitle:[formatter stringForObjectValue:[NSDate date]]
					target:nil
					action:nil
			 keyEquivalent:@""
		 representedObject:[formatter dateFormat]];
}

/*!
 * @brief Build & return a font size menu
 */
- (NSMenu *)_fontSizeMenu
{
	NSMenu		*menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
	NSMenuItem	*menuItem;

	NSUInteger sizes[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,18,20,22,24,36,48,64,72,96};
	NSUInteger loopCounter;

	for (loopCounter = 0; loopCounter < 23; loopCounter++) {
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[[NSNumber numberWithInteger:sizes[loopCounter]] stringValue]
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setTag:sizes[loopCounter]];
		[menu addItem:menuItem];
	}
	
	return menu;
}

@end
