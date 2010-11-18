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

#import "ESWKMVAdvancedPreferences.h"
#import "AIWebKitMessageViewPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>

@implementation ESWKMVAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return AIPref_Advanced_Messages;
}
- (NSString *)label{
    return AILocalizedString(@"Messages","Message Display Options advanced preferences label");
}
- (NSString *)nibName{
    return @"WebKitAdvancedPreferencesView";
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:WEBKIT_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];	
	return defaultsDict;
}

//Configure the preference view
- (void)viewDidLoad
{

	[self configureControlDimming];
}

- (IBAction)changePreference:(id)sender
{

}



@end
