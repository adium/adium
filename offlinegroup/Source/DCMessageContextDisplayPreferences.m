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

#import "DCMessageContextDisplayPlugin.h"
#import "DCMessageContextDisplayPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageAdditions.h>

typedef enum {
	AIMessageHistory_Always = 0,
	AIMessageHistory_HaveTalkedInInterval,
	AIMessageHistory_HaveNotTalkedInInterval
} AIMessageHistoryDisplayPref;

@interface DCMessageContextDisplayPreferences (PRIVATE)
- (NSMenu *)intervalUnitsMenu;
@end

@implementation DCMessageContextDisplayPreferences

//Preference pane properties
- (AIPreferenceCategory)category{
    return AIPref_Advanced;
}
- (NSString *)label{
    return AILocalizedString(@"Message History",nil);
}
- (NSString *)nibName{
    return @"MessageContextDisplayPrefs";
}
- (NSImage *)image{
	return [NSImage imageNamed:@"pref-messagehistory" forClass:[self class]];
}


//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [adium.preferenceController preferencesForGroup:PREF_GROUP_CONTEXT_DISPLAY];
    
    // Set the values of the controls and fields
    [checkBox_showContext setState:[[preferenceDict objectForKey:KEY_DISPLAY_CONTEXT] boolValue]];
	[textField_linesToDisplay setIntegerValue:[[preferenceDict objectForKey:KEY_DISPLAY_LINES] integerValue]];
	[textField_haveTalkedDays setIntegerValue:[[preferenceDict objectForKey:KEY_HAVE_TALKED_DAYS] integerValue]];
	[textField_haveNotTalkedDays setIntegerValue:[[preferenceDict objectForKey:KEY_HAVE_NOT_TALKED_DAYS] integerValue]];
	[matrix_radioButtons selectCellAtRow:[[preferenceDict objectForKey:KEY_DISPLAY_MODE] integerValue] column:0];
	
	NSMenu	*intervalUnitsMenu = [self intervalUnitsMenu];
	[menu_haveTalkedUnits setMenu:intervalUnitsMenu];
	[menu_haveNotTalkedUnits setMenu:[[intervalUnitsMenu copy] autorelease]];

	[menu_haveTalkedUnits selectItemAtIndex:[[preferenceDict objectForKey:KEY_HAVE_TALKED_UNITS] integerValue]];
	[menu_haveNotTalkedUnits selectItemAtIndex:[[preferenceDict objectForKey:KEY_HAVE_NOT_TALKED_UNITS] integerValue]];

	[self configureControlDimming];
}

- (IBAction)changePreference:(id)sender
{
	if ( sender == checkBox_showContext ) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_DISPLAY_CONTEXT
											  group:PREF_GROUP_CONTEXT_DISPLAY];
		[self configureControlDimming];
		
	} else if ( sender == textField_linesToDisplay ) {
		
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender integerValue]]
											 forKey:KEY_DISPLAY_LINES
											  group:PREF_GROUP_CONTEXT_DISPLAY];
	} else if ( sender == textField_haveTalkedDays ) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender integerValue]]
											 forKey:KEY_HAVE_TALKED_DAYS
											  group:PREF_GROUP_CONTEXT_DISPLAY];
	} else if (sender == textField_haveNotTalkedDays ) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender integerValue]]
											 forKey:KEY_HAVE_NOT_TALKED_DAYS
											  group:PREF_GROUP_CONTEXT_DISPLAY];
	} else if ( sender == matrix_radioButtons ) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender selectedRow]]
											 forKey:KEY_DISPLAY_MODE
											  group:PREF_GROUP_CONTEXT_DISPLAY];
		[self configureControlDimming];
	} else if ( sender == menu_haveTalkedUnits ) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender indexOfSelectedItem]]
											 forKey:KEY_HAVE_TALKED_UNITS
											  group:PREF_GROUP_CONTEXT_DISPLAY];
	} else if ( sender == menu_haveNotTalkedUnits ) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender indexOfSelectedItem]]
											 forKey:KEY_HAVE_NOT_TALKED_UNITS
											  group:PREF_GROUP_CONTEXT_DISPLAY];
	}
	
}

- (void)configureControlDimming
{
	NSInteger		selectedRow = [matrix_radioButtons selectedRow];
	BOOL	contextEnabled =[checkBox_showContext state];
		
	[textField_linesToDisplay setEnabled:contextEnabled];
	[stepper_linesToDisplay setEnabled:contextEnabled];
	
	[textField_haveTalkedDays setEnabled:contextEnabled];
	[stepper_haveTalkedDays setEnabled:contextEnabled];
	[textField_haveNotTalkedDays setEnabled:contextEnabled];
	[stepper_haveNotTalkedDays setEnabled:contextEnabled];
	
	[menu_haveTalkedUnits setEnabled:contextEnabled];
	[menu_haveNotTalkedUnits setEnabled:contextEnabled];
	
	[matrix_radioButtons setEnabled:contextEnabled];
	
	if ( [checkBox_showContext state] ) {
		switch ( selectedRow ) {
			case AIMessageHistory_Always:
				[textField_haveTalkedDays setEnabled:NO];
				[stepper_haveTalkedDays setEnabled:NO];
				[textField_haveNotTalkedDays setEnabled:NO];
				[stepper_haveNotTalkedDays setEnabled:NO];
				[menu_haveTalkedUnits setEnabled:NO];
				[menu_haveNotTalkedUnits setEnabled:NO];
				break;
				
			case AIMessageHistory_HaveTalkedInInterval:
				[textField_haveTalkedDays setEnabled:YES];
				[stepper_haveTalkedDays setEnabled:YES];
				[textField_haveNotTalkedDays setEnabled:NO];
				[stepper_haveNotTalkedDays setEnabled:NO];
				[menu_haveTalkedUnits setEnabled:YES];
				[menu_haveNotTalkedUnits setEnabled:NO];
				break;
				
			case AIMessageHistory_HaveNotTalkedInInterval:
				[textField_haveTalkedDays setEnabled:NO];
				[stepper_haveTalkedDays setEnabled:NO];
				[textField_haveNotTalkedDays setEnabled:YES];
				[stepper_haveNotTalkedDays setEnabled:YES];
				[menu_haveTalkedUnits setEnabled:NO];
				[menu_haveNotTalkedUnits setEnabled:YES];
		}
	}
}


@end
