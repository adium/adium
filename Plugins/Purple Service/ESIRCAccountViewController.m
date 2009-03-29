//
//  ESIRCAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESIRCAccountViewController.h"
#import "ESIRCAccount.h"
#import "AIService.h"
#import <AIUtilities/AIStringFormatter.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

@implementation ESIRCAccountViewController

- (NSString *)nibName{
    return @"ESIRCAccountView";
}

- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	//Connection security
	[checkbox_useSSL setState:[[account preferenceForKey:KEY_IRC_USE_SSL group:GROUP_ACCOUNT_STATUS] boolValue]];

	// Disable the server field when online, since this will change our Purple account name
	[textField_connectHost setEnabled:!account.online];
	
	// Execute commands
	NSString *commands = [account preferenceForKey:KEY_IRC_COMMANDS group:GROUP_ACCOUNT_STATUS] ?: @"";
	[textView_commands.textStorage setAttributedString:[NSAttributedString stringWithString:commands]];
	
	// Username
	NSString *username = [account preferenceForKey:KEY_IRC_USERNAME group:GROUP_ACCOUNT_STATUS] ?: @"";
	[textField_username setStringValue:username];
	[textField_username.cell setPlaceholderString:((ESIRCAccount *)account).defaultUsername];
	
	// Realname
	NSString *realname = [account preferenceForKey:KEY_IRC_REALNAME group:GROUP_ACCOUNT_STATUS] ?: @"";
	[textField_realname setStringValue:realname];
	[textField_realname.cell setPlaceholderString:((ESIRCAccount *)account).defaultRealname];
}

- (void)saveConfiguration
{
	[super saveConfiguration];
	
	[account setPreference:[NSNumber numberWithBool:[checkbox_useSSL state]]
					forKey:KEY_IRC_USE_SSL
					 group:GROUP_ACCOUNT_STATUS];
	
	// Execute commands
	[account setPreference:textView_commands.textStorage.string forKey:KEY_IRC_COMMANDS group:GROUP_ACCOUNT_STATUS];
	
	// Username
	[account setPreference:(textField_username.stringValue.length ? textField_username.stringValue : nil)
					forKey:KEY_IRC_USERNAME
					 group:GROUP_ACCOUNT_STATUS];
	
	// Realname
	[account setPreference:(textField_realname.stringValue.length ? textField_realname.stringValue : nil)
					forKey:KEY_IRC_REALNAME
					 group:GROUP_ACCOUNT_STATUS];
}	

@end
