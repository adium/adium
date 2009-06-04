//
//  ESStatusAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 1/6/06.
//

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
