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

@implementation AIFacebookXMPPAccountViewController
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

- (NSString *)nibName
{
    return @"AIFacebookXMPPAccountView";
}

/*!
 * @brief A preference was changed
 *
 * Don't save here; merely update controls as necessary.
 */
- (IBAction)changedPreference:(id)sender
{
	if (sender == button_OAuthStart) {
		[(AIFacebookXMPPAccount *)account requestFacebookAuthorization];		
	} else 
		[super changedPreference:sender];
}

@end
