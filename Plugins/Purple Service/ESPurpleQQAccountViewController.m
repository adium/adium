//
//  ESPurpleQQAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 8/7/06.
//

#import "ESPurpleQQAccountViewController.h"
#import "ESPurpleQQAccount.h"

@implementation ESPurpleQQAccountViewController
- (NSString *)nibName{
    return @"PurpleQQAccountView";
}

//Configure controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];

	[checkBox_useTCP setState:[[account preferenceForKey:KEY_QQ_USE_TCP 
												   group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_useTCP setLocalizedString:AILocalizedString(@"Connect using TCP", nil)];

	[label_connection setLocalizedString:AILocalizedString(@"Connection:", nil)];
}

//Save controls
- (void)saveConfiguration
{
	[account setPreference:[NSNumber numberWithBool:[checkBox_useTCP state]] 
					forKey:KEY_QQ_USE_TCP group:GROUP_ACCOUNT_STATUS];

	[super saveConfiguration];
}

@end
