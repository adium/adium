//
//  AIFacebookXMPPOAuthWebViewWindowController.m
//  Adium
//
//  Created by Colin Barrett on 11/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
//

#import "AIXMPPOAuthWebViewWindowController.h"
#import "AIXMPPOAuthAccountViewController.h"
#import "AIFacebookXMPPAccount.h"
#import "JSONKit.h"

#import "AIPurpleOAuthJabberAccount.h"

@implementation AIXMPPOAuthWebViewWindowController

@synthesize account;
@synthesize webView, spinner;
@synthesize autoFillPassword, autoFillUsername;
@synthesize isMigrating;

- (id)init
{
    if ((self = [super initWithWindowNibName:@"AIXMPPOAuthWebViewWindow"])) {
	
	}
    return self;
}

- (void)dealloc
{
	self.account = nil;
	
	[self.webView close];
	self.webView = nil;
	self.spinner = nil;
    
    [super dealloc];
}

- (NSString *)adiumFrameAutosaveName
{
    return @"OAuth Window Frame";
}

- (void)showWindow:(id)sender
{
    [super showWindow:sender];

    [webView setMainFrameURL:[account authorizeURL]];
	
	[spinner startAnimation:self];
    
    [self.window setTitle:AILocalizedString(@"Facebook Account Setup", nil)];
}

- (void)windowWillClose:(id)sender
{
    [super windowWillClose:sender];

    /* The user closed; notify the account of failure */
    if (!notifiedAccount)
        [self.account oAuthWebViewControllerDidFail:self];
}

- (NSDictionary*)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val = [[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
	return params;
}


- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	[spinner startAnimation:self];
	[sender display];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	if ([sender mainFrame] == frame) {
		[spinner stopAnimation:self];
		[sender display];
	}
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource;
{
    NSMutableURLRequest *mutableRequest = [[request mutableCopy] autorelease];
    [mutableRequest setHTTPShouldHandleCookies:YES];
	
	AILogWithSignature(@"%@", mutableRequest);
	
    if ([[[mutableRequest URL] host] isEqualToString:[account frameURLHost]] && [[[mutableRequest URL] path] isEqualToString:[account frameURLPath]]) {
		NSDictionary *urlParamDict = [self parseURLParams:[[mutableRequest URL] fragment]];
		
		NSString *token = [urlParamDict objectForKey:@"access_token"];
		if (token && ![token isEqualToString:@""]) {
    		[self.account oAuthWebViewController:self didSucceedWithToken:token];
		} else {
			/* Got a bad token, or the user canceled */
			[self.account oAuthWebViewControllerDidFail:self];

		}		

        notifiedAccount = YES;
		[self closeWindow:nil];
	}
	
	return mutableRequest;
}

@end
