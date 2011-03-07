//
//  AIFacebookXMPPOAuthWebViewWindowController.m
//  Adium
//
//  Created by Colin Barrett on 11/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AIFacebookXMPPOAuthWebViewWindowController.h"
#import "AIFacebookXMPPAccountViewController.h"

@interface AIFacebookXMPPOAuthWebViewWindowController ()
- (void)addCookiesFromResponse:(NSHTTPURLResponse *)response;
- (void)addCookiesToRequest:(NSMutableURLRequest *)request;
@end


@implementation AIFacebookXMPPOAuthWebViewWindowController

- (id)init
{
    if ((self = [super initWithWindowNibName:@"AIFacebookXMPPOauthWebViewWindow"])) {
        cookies = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [webView release];
    
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
     @"client_id=176717249009197&"
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
		NSString *val =
		[[kv objectAtIndex:1]
		 stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
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
    if (redirectResponse) {
        [self addCookiesFromResponse:(id)redirectResponse];
    }
    NSMutableURLRequest *mutableRequest = [[request mutableCopy] autorelease];
    [mutableRequest setHTTPShouldHandleCookies:NO];
    [self addCookiesToRequest:mutableRequest];
        
    if ([[[mutableRequest URL] host] isEqual:@"www.facebook.com"] && [[[mutableRequest URL] path] isEqual:@"/connect/login_success.html"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FACEBOOK_OAUTH_FINISHED
															object:[self parseURLParams:[[mutableRequest URL] fragment]]];
		[self closeWindow:nil];
		return nil;
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
    NSLog(@"requestURL: %@", requestURL);
    NSMutableArray *sentCookies = [NSMutableArray array];
    
    // same origin: domain, port, path.
    for (NSHTTPCookie *cookie in cookies) {
        if ([[cookie expiresDate] timeIntervalSinceNow] < 0) {
            NSLog(@"****** expired: %@", cookie);
            continue;
        }
        
        if ([cookie isSecure] && ![[requestURL scheme] isEqualToString:@"https"]) {
            NSLog(@"****** secure not https: %@", cookie);
            continue;
        }
        
        if ([[cookie domain] hasPrefix:@"."]) { // ".example.com" should match "foo.example.com" and "example.com"            
            if (!([[requestURL host] hasSuffix:[cookie domain]] ||
                  [[@"." stringByAppendingString:[requestURL host]] isEqualToString:[cookie domain]])) {
                NSLog(@"****** dot prefix host mismatch: %@", cookie);
                continue;
            }
        } else {
            if (![[requestURL host] isEqualToString:[cookie domain]]) {
                NSLog(@"****** host mismatch: %@", cookie);
                continue;
            }
        }
        
        if ([cookie portList] && ![[cookie portList] containsObject:[requestURL port]]) {
            NSLog(@"****** port mismatch: %@", cookie);
            continue;
        }
        
        if (![[requestURL path] hasPrefix:[cookie path]]) {
            NSLog(@"****** path mismatch: %@", cookie);
            continue;
        }
        
        NSLog(@"adding cookie: %@", cookie);
        [sentCookies addObject:cookie];
    }
    
    NSMutableDictionary *headers = [[[request allHTTPHeaderFields] mutableCopy] autorelease];
    [headers setValuesForKeysWithDictionary:[NSHTTPCookie requestHeaderFieldsWithCookies:sentCookies]];
    [request setAllHTTPHeaderFields:headers];
}

@end
