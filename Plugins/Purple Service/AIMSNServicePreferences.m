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

#import "AIMSNServicePreferences.h"
#import "ESMSNService.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIServiceIcons.h>

@implementation AIMSNServicePreferences

//Preference pane properties
- (AIPreferenceCategory)category
{
    return AIPref_Advanced;
}
- (NSString *)label
{
    return AILocalizedString(@"MSN",nil);
}
- (NSString *)nibName
{
    return @"MSNServicePrefs";
}
- (NSImage *)image
{
	return [AIServiceIcons serviceIconForServiceID:@"MSN" type:AIServiceIconLarge direction:AIIconNormal];
}

- (void)viewDidLoad
{
	[checkBox_displayCustomEmoticons setState:[[[adium preferenceController] preferenceForKey:KEY_MSN_DISPLAY_CUSTOM_EMOTICONS
																						group:PREF_GROUP_MSN_SERVICE] boolValue]];
	[checkBox_displayCustomEmoticons setLocalizedString:AILocalizedString(@"Display custom emoticons", nil)];
}

- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_displayCustomEmoticons) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]] 
											 forKey:KEY_MSN_DISPLAY_CUSTOM_EMOTICONS
											  group:PREF_GROUP_MSN_SERVICE];
	}
}

@end
