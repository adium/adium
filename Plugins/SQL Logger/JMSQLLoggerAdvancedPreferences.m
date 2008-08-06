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

#import "AISQLLoggerPlugin.h"
#import "JMSQLLoggerAdvancedPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>

@interface JMSQLLoggerAdvancedPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation JMSQLLoggerAdvancedPreferences

- (NSString *)label{
    return @"SQL Logging";
}
- (NSString *)nibName{
    return @"SQL_Logger_Prefs";
}

//Configure the preference view
- (void)viewDidLoad
{
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_SQL_LOGGING];
}

- (void)viewWillClose
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

//Reflect new preferences in view
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	id				tmp;
	
	[checkbox_enableSQLLogging setState:[[prefDict objectForKey:KEY_SQL_LOGGER_ENABLE] boolValue]];
	
	//This ugliness is because setStringValue doesn't like being passed nil
	[text_Username setStringValue:(tmp = [prefDict objectForKey:KEY_SQL_USERNAME]) ? tmp : @""];
	[text_Port setStringValue:(tmp = [prefDict objectForKey:KEY_SQL_PORT]) ? tmp: @""];
	[text_database setStringValue:(tmp = [prefDict objectForKey:KEY_SQL_DATABASE]) ? tmp: @""];
	[text_Password setStringValue:(tmp = [prefDict objectForKey:KEY_SQL_PASSWORD]) ? tmp: @""];
	[text_URL setStringValue:(tmp = [prefDict objectForKey:KEY_SQL_URL]) ? tmp: @""];
}

//Save changed preference
- (IBAction)changePreference:(id)sender
{
    if (sender == checkbox_enableSQLLogging) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SQL_LOGGER_ENABLE
                                              group:PREF_GROUP_SQL_LOGGING];
    } else if (sender == text_Username) {
		[[adium preferenceController] setPreference:[sender stringValue]
                                             forKey:KEY_SQL_USERNAME
                                              group:PREF_GROUP_SQL_LOGGING];
	} else if (sender == text_URL) {
		[[adium preferenceController] setPreference:[sender stringValue]
                                             forKey:KEY_SQL_URL
                                              group:PREF_GROUP_SQL_LOGGING];
	} else if (sender == text_Port) {
		[[adium preferenceController] setPreference:[sender stringValue]
                                             forKey:KEY_SQL_PORT
                                              group:PREF_GROUP_SQL_LOGGING];
	} else if (sender == text_database) {
		[[adium preferenceController] setPreference:[sender stringValue]
                                             forKey:KEY_SQL_DATABASE
                                              group:PREF_GROUP_SQL_LOGGING];
	} else if (sender == text_Password) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SQL_PASSWORD
                                              group:PREF_GROUP_SQL_LOGGING];
	}
}

@end
