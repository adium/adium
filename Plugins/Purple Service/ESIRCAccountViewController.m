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
	
	//UID
	NSString *nick = @"";
	NSString	*formattedUID = account.formattedUID;
	
	if(formattedUID) {
		NSRange range = [formattedUID rangeOfString:@"@"];
		
		if(range.location == NSNotFound)
			nick = formattedUID;
		else
			nick = [formattedUID substringToIndex:range.location];
	}
	
	[textfield_Nick setStringValue:nick];
	
	NSMutableCharacterSet *allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	[allowedCharacters addCharactersInString:@"[]\\`_^{|}"]; // not using -allowedCharacters, because we must not allow @ and .
	[textfield_Nick setFormatter:[AIStringFormatter stringFormatterAllowingCharacters:allowedCharacters
																			   length:[inAccount.service allowedLengthForAccountName]
																		caseSensitive:[inAccount.service caseSensitive]
																		 errorMessage:AILocalizedStringFromTableInBundle(@"The characters you're entering are not valid for an account name on this service.", nil, [NSBundle bundleForClass:[AIAccountViewController class]], nil)]];
	[allowedCharacters release];
	
	// Execute commands
	NSString *commands = [account preferenceForKey:KEY_IRC_COMMANDS group:GROUP_ACCOUNT_STATUS] ?: @"";
	
	[textView_commands.textStorage setAttributedString:[NSAttributedString stringWithString:commands]];
}

- (void)saveConfiguration
{
	[super saveConfiguration];
	
	[account setPreference:[NSNumber numberWithBool:[checkbox_useSSL state]]
					forKey:KEY_IRC_USE_SSL group:GROUP_ACCOUNT_STATUS];
	
	//UID - account 
	NSString *newUID = [NSString stringWithFormat:@"%@@%@", [textfield_Nick stringValue], [textField_connectHost stringValue]];
	if (![account.UID isEqualToString:newUID] ||
		![account.formattedUID isEqualToString:newUID]) {
		[account filterAndSetUID:newUID];
	}
	
	// Execute commands
	[account setPreference:textView_commands.textStorage.string forKey:KEY_IRC_COMMANDS group:GROUP_ACCOUNT_STATUS];
}	

@end
