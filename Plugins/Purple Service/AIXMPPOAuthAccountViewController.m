//
//  AIFacebookXMPPAccountViewController.m
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AIPurpleOAuthJabberAccount.h"
#import "AIXMPPOAuthAccountViewController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <AIUtilities/AIStringAdditions.h>

@interface AIXMPPOAuthAccountViewController ()
- (void)authProgressDidChange:(NSNotification *)notification;
@end

@implementation AIXMPPOAuthAccountViewController

@synthesize spinner, textField_OAuthStatus, button_OAuthStart, button_help;

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	return view_setup;
}

- (NSString *)nibName
{
    return @"AIXMPPOAuthAccountView";
}

/*!
 * @brief Configure controls
 */
- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	if ([[AIPurpleOAuthJabberAccount class] uidIsValid:account.UID] &&
		[adium.accountController passwordForAccount:account].length) {
		[textField_OAuthStatus setStringValue:AILocalizedString(@"Adium is authorized for Facebook Chat.", nil)];
		[button_OAuthStart setEnabled:NO];
	} else {
		[textField_OAuthStatus setStringValue:@""];
		[button_OAuthStart setEnabled:YES]; 
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(authProgressDidChange:)
												 name: AIXMPPAuthProgressNotification
											   object:inAccount];
}

- (void) authProgressDidChange:(NSNotification *)notification
{
	AIXMPPOAuthProgressStep step = [[notification.userInfo objectForKey:KEY_XMPP_OAUTH_STEP] intValue];
	
	switch (step) {
		case AIXMPPOAuthProgressPromptingUser:
			[textField_OAuthStatus setStringValue:[AILocalizedString(@"Requesting authorization", nil) stringByAppendingEllipsis]];
			break;
			
		case AIXMPPOAuthProgressContactingServer:
			[textField_OAuthStatus setStringValue:[AILocalizedString(@"Contacting authorization server", nil) stringByAppendingEllipsis]];
			break;

		case AIXMPPOAuthProgressPromotingForChat:
			[textField_OAuthStatus setStringValue:[AILocalizedString(@"Promoting authorization for chat", nil) stringByAppendingEllipsis]];
			break;

		case AIXMPPOAuthProgressSuccess:
			[textField_OAuthStatus setStringValue:AILocalizedString(@"Adium is authorized for Facebook Chat.", nil)];
			break;
			
		case AIXMPPOAuthProgressFailure:
			[textField_OAuthStatus setStringValue:AILocalizedString(@"Could not complete authorization.", nil)];
			[button_OAuthStart setEnabled:YES];
			break;
	}
}

/*!
 * @brief A preference was changed
 *
 * Don't save here; merely update controls as necessary.
 */
- (IBAction)changedPreference:(id)sender
{
	if (sender == button_OAuthStart) {
		[(AIPurpleOAuthJabberAccount *)account requestAuthorization];
		[button_OAuthStart setEnabled:NO];

	} else 
		[super changedPreference:sender];
}

/* xxx it'd be better to link to an entry in our docs */
- (IBAction)showHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://trac.adium.im/wiki/FacebookChat"]];
}

@end
