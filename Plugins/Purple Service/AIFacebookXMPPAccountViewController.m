//
//  AIFacebookXMPPAccountViewController.m
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AIFacebookXMPPAccount.h"
#import "AIFacebookXMPPAccountViewController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <AIUtilities/AIStringAdditions.h>

@implementation AIFacebookXMPPAccountViewController
@synthesize view_migration, textField_migrationStatus, button_migrationHelp, button_migrationOAuthStart, migrationSpinner;
@synthesize spinner, textField_OAuthStatus, button_OAuthStart;

- (void)dealloc
{
    [super dealloc];
}

- (NSView *)optionsView
{
    return nil;
}

- (NSView *)privacyView
{
    return nil;
}

- (NSView *)setupView
{
	if ([(AIFacebookXMPPAccount *)account migratingAccount])
		return view_migration;
	
	return view_setup;
}

- (NSString *)nibName
{
    return @"AIFacebookXMPPAccountView";
}

/*!
 * @brief Configure controls
 */
- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	if ([[AIFacebookXMPPAccount class] uidIsValidForFacebook:account.UID] &&
		[adium.accountController passwordForAccount:account].length) {
		[textField_OAuthStatus setStringValue:AILocalizedString(@"Adium currently has access to your account.", nil)];
		[button_OAuthStart setEnabled:NO];
	}
}

/*!
 * @brief A preference was changed
 *
 * Don't save here; merely update controls as necessary.
 */
- (IBAction)changedPreference:(id)sender
{
	if (sender == button_OAuthStart || sender == button_migrationOAuthStart) {
		[(AIFacebookXMPPAccount *)account requestFacebookAuthorization];
		[textField_OAuthStatus setStringValue:[AILocalizedString(@"Requesting authorization", nil) stringByAppendingEllipsis]];

	} else if (sender == button_migrationHelp) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://trac.adium.im/wiki/FacebookChat"]];
	} else 
		[super changedPreference:sender];
}

@end
