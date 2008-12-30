//
//  AIFacebookBuddyProfileManager.m
//  Adium
//
//  Created by Evan Schoenberg on 10/14/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "AIFacebookBuddyProfileManager.h"
#import <Adium/AIListContact.h>
#import <Adium/AIHTMLDecoder.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <WebKit/WebKit.h>

@interface AIFacebookBuddyProfileManager ()
+ (NSArray *)extractProfileFromSource:(NSString *)source forContact:(AIListContact *)currentContact;
@end

@implementation AIFacebookBuddyProfileManager

static WebView *webView = nil;
static AIListContact *currentContact = nil;
static NSURL	*currentURL = nil;

+ (void)retrieveProfileForContact:(AIListContact *)contact
{
	if (!webView) {
		webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500) frameName:nil groupName:nil];
		
		//We must be Safari 3.x or greater for Facebook to be willing to chat
		[webView setApplicationNameForUserAgent:@"Safari/525.18"];
		[webView setResourceLoadDelegate:self];
	}
	
	[currentContact release];
	currentContact = [contact retain];

	[currentURL release];
	currentURL = [[NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/profile.php?id=%@&v=info",
									   [contact UID]]] retain];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:currentURL
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:120];
	[[webView mainFrame] loadRequest:request];

}

+ (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
	if ([[request URL] isEqual:currentURL]) {
		return @"Profile";
	}
	
	return nil;
}
+ (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource
{
	AILogWithSignature(@"%@ resource %@ error %@ (%@)", sender, identifier, error, [error localizedDescription]);
	[currentContact release]; currentContact = nil;
	[currentURL release]; currentURL = nil;
}

+ (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
	if (identifier) {
		NSArray *profileArray = [self extractProfileFromSource:[[dataSource representation] documentSource]
													forContact:currentContact];
		[currentContact setProfileArray:profileArray notify:NotifyNow];
		[sender stopLoading:self];
	}

//
}

+ (NSArray *)extractProfileFromSource:(NSString *)source forContact:(AIListContact *)currentContact
{
	NSMutableArray *profileArray = [NSMutableArray array];
	NSScanner *scanner = [[NSScanner alloc] initWithString:source];
	AIHTMLDecoder *decoder = [AIHTMLDecoder decoder];
	[decoder setBaseURL:@"http://www.facebook.com/"];

	if ([currentContact statusMessage]) {
		[profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 AILocalizedString(@"Status", nil), KEY_KEY,
								 [currentContact statusMessage], KEY_VALUE,
								 nil]];		
	}
	/* Key is between <dt> and </dt> */
	while ([scanner scanUpToString:@"<dt>" intoString:NULL]) {
		NSString *key, *value;
		if ([scanner scanString:@"<dt>" intoString:NULL] &&
			[scanner scanUpToString:@"</dt>" intoString:&key] &&
			[scanner scanString:@"</dt>" intoString:NULL] &&
			/* Value immediately follows between <dd> and </dd> */
			[scanner scanString:@"<dd>" intoString:NULL] &&
			[scanner scanUpToString:@"</dd>" intoString:&value]) {

			key = [[decoder decodeHTML:key] string];
			
			if ([value rangeOfString:@"<li></li>" options:(NSLiteralSearch | NSCaseInsensitiveSearch)].location != NSNotFound) {
				//Remove any empty bullet points
				NSMutableString *newValue = [value mutableCopy];
				[newValue replaceOccurrencesOfString:@"<li></li>" withString:@"" options:(NSLiteralSearch | NSCaseInsensitiveSearch)];
				value = [newValue autorelease];
			}

			NSMutableAttributedString *attributedValue = [[decoder decodeHTML:value] mutableCopy];

			//Remove the million links to Facebook internals
			[attributedValue removeAttribute:NSLinkAttributeName range:NSMakeRange(0, [attributedValue length])];

			//Facebook sometimes leaves trailing whitespace after HTML is decoded, which we don't want
			CFStringTrimWhitespace((CFMutableStringRef)[attributedValue mutableString]);

			[profileArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									 key, KEY_KEY,
									 attributedValue, KEY_VALUE,
									 nil]];
			[attributedValue release];
		}
	}

	[scanner release];
	
	return profileArray;
}

@end
