//
//  AIFacebookXMPPAccountViewController.m
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AIFacebookXMPPOAuthWebViewWindowController.h"

#import "AIFacebookXMPPAccount.h"
#import "AIFacebookXMPPAccountViewController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <JSON/JSON.h>

@implementation AIFacebookXMPPAccountViewController
@synthesize spinner, textField_OAuthStatus, button_OAuthStart;

- (id)init
{
    if ((self = [super init])) {
        webViewWindowController = [[AIFacebookXMPPOAuthWebViewWindowController alloc] init];
    }
	
    return self;
}

- (void)dealloc
{
    [webViewWindowController release];
    
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
	if(sender == button_OAuthStart) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(OAuthDidFinish:)
													 name:FACEBOOK_OAUTH_FINISHED
												   object:nil];
		[webViewWindowController showWindow:self];
	}
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
}

- (void)OAuthDidFinish:(NSNotification *)note
{
	NSString *token = [[note object] objectForKey:@"access_token"];
	NSAssert(token && ![token isEqualToString:@""], @"got bad token!");
    
    NSString *urlstring = [NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@", token];
	NSURL *url = [NSURL URLWithString:[urlstring stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	NSURLResponse *response;
	NSError *error;
	
	NSData *conn = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	NSDictionary *resp = [[[[NSString alloc] initWithData:conn encoding:NSUTF8StringEncoding] autorelease] JSONValue];
	NSString *uuid = [resp objectForKey:@"id"];
	NSString *name = [resp objectForKey:@"name"];
    
    NSString *sessionKey = [[token componentsSeparatedByString:@"|"] objectAtIndex:1];
    
    NSString *secretURLString = [NSString stringWithFormat:@"https://api.facebook.com/method/auth.promoteSession?access_token=%@&format=JSON", token];
    NSURL *secretURL = [NSURL URLWithString:[secretURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *secretRequest = [NSURLRequest requestWithURL:secretURL];
    NSData *secretData = [NSURLConnection sendSynchronousRequest:secretRequest returningResponse:&response error:&error];
    NSString *secret = [[[NSString alloc] initWithData:secretData encoding:NSUTF8StringEncoding] autorelease];
    secret = [secret substringWithRange:NSMakeRange(1, [secret length] - 2)]; // strip off the quotes
    
    [[adium accountController] setPassword:sessionKey forAccount:account];
    [account setPasswordTemporarily:sessionKey];
    [(AIFacebookXMPPAccount *)account setSessionSecret:secret];
    
	[account filterAndSetUID:uuid];
	[account setFormattedUID:name notify:NotifyNever];
	NSString *connectHost = @"FBXMPP";
	
	[account setPreference:connectHost
					forKey:KEY_CONNECT_HOST
					 group:GROUP_ACCOUNT_STATUS];
    NSLog(@"token %@", token);
	NSLog(@"fUID %@", account.formattedUID);
	NSLog(@"UID %@", account.UID);
	NSLog(@"service %@", account);
}

//Save controls
- (void)saveConfiguration
{
	
}

@end
