//
//  PurpleAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 11/9/07.
//

#import "PurpleAccountViewController.h"
#import "CBPurpleAccount.h"

@implementation PurpleAccountViewController

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	[checkBox_broadcastMusic setState:[[inAccount preferenceForKey:KEY_BROADCAST_MUSIC_INFO group:GROUP_ACCOUNT_STATUS] boolValue]];
}

//Save controls
- (void)saveConfiguration
{
    [super saveConfiguration];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_broadcastMusic state]]
					forKey:KEY_BROADCAST_MUSIC_INFO
					 group:GROUP_ACCOUNT_STATUS];
}


@end
