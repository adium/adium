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

#import <AIListObject.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIPlugin.h>

#import "AIPreferenceController.h"
#import "AIPreferenceWindowController.h"

#import "AIVideoConf.h"
#import "AIVideoConfController.h"

#import "QTPlugin.h"
#import "QTAdvancedPreferences.h"

@interface QTAdvancedPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark                 QuickTime Preferences
////////////////////////////////////////////////////////////////////////////////

@implementation QTAdvancedPreferences

// Preference pane properties
- (AIPreferenceCategory) category{
    return AIPref_Advanced;
}

- (NSString *) label {
    return @"QuickTime";
}

- (NSString *) nibName {
    return @"QT_Prefs";
}

- (NSImage *) image {
	return [NSImage imageNamed:@"pref-quicktime"];
}

// Configure the preference view
- (void) viewDidLoad
{
	[[adium preferenceController] registerPreferenceObserver:self forGroup:QUICKTIME_PREFS];
}

- (void) viewWillClose
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

// Reflect new preferences in view
- (void) preferencesChangedForGroup:(NSString *)group
								key:(NSString *)key
							 object:(AIListObject *)object
					 preferenceDict:(NSDictionary *)prefDict
						  firstTime:(BOOL)firstTime
{
	[micDefaultVolume setIntValue:[[prefDict objectForKey:KEY_MIC_VOLUME] intValue]];
	[outDefaultVolume setIntValue:[[prefDict objectForKey:KEY_OUT_VOLUME] intValue]];
}


/*!
 * Save changed preference
 */
- (IBAction) changePreference:(id)sender
{
    if (sender == micDefaultVolume) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_MIC_VOLUME
                                              group:QUICKTIME_PREFS];

	} else if (sender == outDefaultVolume) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_OUT_VOLUME
                                              group:QUICKTIME_PREFS];
	}
}

@end
