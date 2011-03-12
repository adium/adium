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

#import "CBStatusMenuItemPlugin.h"
#import "ESStatusAdvancedPreferences.h"
#import "AIStatusController.h"
#import "AIPreferenceWindowController.h"
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@implementation ESStatusAdvancedPreferences
//Preference pane properties
- (AIPreferenceCategory)category{
    return AIPref_Advanced;
}
- (NSString *)label{
    return AILocalizedString(@"Status",nil);
}
- (NSString *)nibName{
    return @"StatusPreferencesAdvanced";
}
- (NSImage *)image{
	return [NSImage imageNamed:@"pref-status" forClass:[AIPreferenceWindowController class]];
}

//Configure the preference view
- (void)viewDidLoad
{
	[label_statusWindow setLocalizedString:AILocalizedString(@"Away Status Window", nil)];
	[checkBox_statusWindowHideInBackground setLocalizedString:AILocalizedString(@"Hide the status window when Adium is not active", nil)];
	[checkBox_statusWindowAlwaysOnTop setLocalizedString:AILocalizedString(@"Show the status window above other windows", nil)];
	
	[super viewDidLoad];
}


@end
