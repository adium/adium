//
//  ESIRCAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESIRCAccountViewController.h"
#import "ESIRCAccount.h"

@implementation ESIRCAccountViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	//Connection security
	[checkbox_useSSL setState:[[account preferenceForKey:KEY_IRC_USE_SSL group:GROUP_ACCOUNT_STATUS] boolValue]];
}

- (void)saveConfiguration
{
	[super saveConfiguration];
	
	[account setPreference:[NSNumber numberWithBool:[checkbox_useSSL state]]
					forKey:KEY_IRC_USE_SSL group:GROUP_ACCOUNT_STATUS];

}	

@end
