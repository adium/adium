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

@synthesize account;
@synthesize cookies;
@synthesize webView, spinner;

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

/* XXX need a failure handler? */

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

		[self.account oAuthWebViewController:self
						  didSucceedWithName:name
										 UID:uuid
								  sessionKey:sessionKey
									  secret:secret];
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
