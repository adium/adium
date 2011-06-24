﻿//
//  AIFacebookXMPPOAuthWebViewWindowController.m
//  Adium
//
//  Created by Colin Barrett on 11/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AIFacebookXMPPOAuthWebViewWindowController.h"
#import "AIFacebookXMPPAccountViewController.h"
#import "AIFacebookXMPPAccount.h"
#import "JSONKit.h"


@interface AIFacebookXMPPOAuthWebViewWindowController ()
- (void)addCookiesFromResponse:(NSHTTPURLResponse *)response;
- (void)addCookiesToRequest:(NSMutableURLRequest *)request;
@end

@implementation AIFacebookXMPPOAuthWebViewWindowController

@synthesize account;
@synthesize cookies;
@synthesize webView, spinner;
@synthesize autoFillPassword, autoFillUsername;

- (id)init
{
    if ((self = [super initWithWindowNibName:@"AIFacebookXMPPOauthWebViewWindow"])) {
        self.cookies = [[[NSMutableSet alloc] init] autorelease];
    }
    return self;
}

- (void)dealloc
{
	self.account = nil;
	self.cookies = nil;
	
	[self.webView close];
	self.webView = nil;
	self.spinner = nil;
    
    [super dealloc];
}

- (NSString *)adiumFrameAutosaveName
{
    return @"Facebook OAuth Window Frame";
}

- (void)showWindow:(id)sender
{
    [super showWindow:sender];

    [webView setMainFrameURL:@"https://graph.facebook.com/oauth/authorize?"
     @"client_id=" APP_ID "&"
     @"redirect_uri=http%3A%2F%2Fwww.facebook.com%2Fconnect%2Flogin_success.html&"
	 @"scope=xmpp_login,offline_access&"
     @"type=user_agent&"
     @"display=popup"];
	
	[spinner startAnimation:self];
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
		
		if ([frame.dataSource.request.URL.host isEqual:@"www.facebook.com"] && [frame.dataSource.request.URL.path isEqual:@"/login.php"]) {
			//Set email and password
			DOMDocument *domDoc = [frame DOMDocument];
			[[domDoc getElementById:@"email"] setValue:self.autoFillUsername];
			[[domDoc getElementById:@"pass"] setValue:self.autoFillPassword];
		}
	}
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource;
{    
    if (redirectResponse) {
        [self addCookiesFromResponse:(id)redirectResponse];
    }
    NSMutableURLRequest *mutableRequest = [[request mutableCopy] autorelease];
    [mutableRequest setHTTPShouldHandleCookies:NO];
    [self addCookiesToRequest:mutableRequest];
	
    if ([[[mutableRequest URL] host] isEqual:@"www.facebook.com"] && [[[mutableRequest URL] path] isEqual:@"/connect/login_success.html"]) {
		NSDictionary *urlParamDict = [self parseURLParams:[[mutableRequest URL] fragment]];
		
		NSString *token = [urlParamDict objectForKey:@"access_token"];
		if (token && ![token isEqualToString:@""]) {
    		[self.account oAuthWebViewController:self didSucceedWithToken:token];
		} else {
			/* Got a bad token, or the user canceled */
		}		

		[self closeWindow:nil];
	}
	
	return mutableRequest;
}


- (void)webView:(WebView *)sender resource:(id)identifier didReceiveResponse:(NSURLResponse *)response fromDataSource:(WebDataSource *)dataSource;
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        [self addCookiesFromResponse:(NSHTTPURLResponse *)response];
    }
}

- (void)addCookiesFromResponse:(NSHTTPURLResponse *)response
{
    NSArray *newCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:[response URL]];
    [cookies addObjectsFromArray:newCookies];
}

- (void)addCookiesToRequest:(NSMutableURLRequest *)request
{
    NSURL *requestURL = [request URL];
    //NSLog(@"requestURL: %@", requestURL);
    NSMutableArray *sentCookies = [NSMutableArray array];
    
    // same origin: domain, port, path.
    for (NSHTTPCookie *cookie in cookies) {
        if ([[cookie expiresDate] timeIntervalSinceNow] < 0) {
            //NSLog(@"****** expired: %@", cookie);
            continue;
        }
        
        if ([cookie isSecure] && ![[requestURL scheme] isEqualToString:@"https"]) {
            //NSLog(@"****** secure not https: %@", cookie);
            continue;
        }
        
        if ([[cookie domain] hasPrefix:@"."]) { // ".example.com" should match "foo.example.com" and "example.com"            
            if (!([[requestURL host] hasSuffix:[cookie domain]] ||
                  [[@"." stringByAppendingString:[requestURL host]] isEqualToString:[cookie domain]])) {
                //NSLog(@"****** dot prefix host mismatch: %@", cookie);
                continue;
            }
        } else {
            if (![[requestURL host] isEqualToString:[cookie domain]]) {
                //NSLog(@"****** host mismatch: %@", cookie);
                continue;
            }
        }
        
        if ([cookie portList] && ![[cookie portList] containsObject:[requestURL port]]) {
            //NSLog(@"****** port mismatch: %@", cookie);
            continue;
        }
        
        if (![[requestURL path] hasPrefix:[cookie path]]) {
            //NSLog(@"****** path mismatch: %@", cookie);
            continue;
        }
        
        //NSLog(@"adding cookie: %@", cookie);
        [sentCookies addObject:cookie];
    }
    
    NSMutableDictionary *headers = [[[request allHTTPHeaderFields] mutableCopy] autorelease];
    [headers setValuesForKeysWithDictionary:[NSHTTPCookie requestHeaderFieldsWithCookies:sentCookies]];
    [request setAllHTTPHeaderFields:headers];
}

@end
