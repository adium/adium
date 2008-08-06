//
//  AIFacebookAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//

#import "AIFacebookAccount.h"
#import <JSON/JSON.h>
#import <WebKit/WebKit.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIContentMessage.h>
#import "AIFacebookBuddyListManager.h"
#import "AIFacebookOutgoingMessageManager.h"
#import "AIFacebookIncomingMessageManager.h"
#import "AIFacebookStatusManager.h"

#define LOGIN_PAGE	@"https://login.facebook.com/login.php"
#define FACEBOOK_HOME_PAGE	@"http://www.facebook.com/home.php"

#define CONNECTION_DEBUG			TRUE
#define CONNECTION_TIME_OUT_DELAY	10.0

@interface AIFacebookAccount (PRIVATE)
- (void)extractLoginInfoFromHomePage:(NSString *)homeString;
- (void)postDictionary:(NSDictionary *)inDict toURL:(NSURL *)inURL;
@end

/*!
 * @class AIFacebookAccount
 * @brief Facebook account class
 *
 * Huge thanks to coderrr for his analysis of the Facebook protocol and sample implementation in Ruby.
 * http://coderrr.wordpress.com/2008/05/06/facebook-chat-api/
 */
@implementation AIFacebookAccount

- (void)initAccount
{
	[super initAccount];

	webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500) frameName:nil groupName:nil];

	//We must be Safari 3.x or greater for Facebook to be willing to chat
	[webView setApplicationNameForUserAgent:@"Safari/525.18"];
	[webView setResourceLoadDelegate:self];
}

- (void)dealloc
{
	[webView release]; webView = nil;
	
	[super dealloc];
}

#pragma mark Connectivity

- (void)didConnect
{
	[super didConnect];
	
	[[self class] cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(connectionAttemptTimedOut)
												   object:nil];
	
	[self silenceAllContactUpdatesForInterval:18.0];
	buddyListManager = [[AIFacebookBuddyListManager buddyListManagerForAccount:self] retain];
	incomingMessageManager = [[AIFacebookIncomingMessageManager incomingMessageManagerForAccount:self] retain];
}

//Connect this account (Our password should be in the instance variable 'password' all ready for us)
- (void)connect
{
	sentLogin = NO;

	[super connect];

	/*
	 //XXX Why doesn't this work? Facebook still thinks we don't have cookies enabled!
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:[NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:
																								 @"TRUE", NSHTTPCookieDiscard,
																								 @".facebook.com", NSHTTPCookieDomain,
																								 @"test_cookie", NSHTTPCookieName,
																								 @"1", NSHTTPCookieValue,
																								 nil]]];
	 
	 sentLogin = YES;
	 [self postDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
			[self UID], @"email",
			password, @"pass",
			@"Login", @"login",
			nil]
					toURL:[NSURL URLWithString:LOGIN_PAGE]];
	 
	 */
	
	[self performSelector:@selector(connectionAttemptTimedOut)
			   withObject:nil
			   afterDelay:CONNECTION_TIME_OUT_DELAY];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:LOGIN_PAGE]
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:120];
	[[webView mainFrame] loadRequest:request];
}

- (void)connectionAttemptTimedOut
{
	[self reconnect];
}

- (NSString *)host
{
	// Provide our host so that we know availability
	return @"www.facebook.com";
}

- (void)disconnect
{
	[self postDictionary:[NSDictionary dictionaryWithObject:@"1"
													 forKey:@"confirm"]
				   toURL:[NSURL URLWithString:@"http://www.facebook.com/logout.php"]];

	[buddyListManager disconnect];
	[buddyListManager release]; buddyListManager = nil;
	
	[incomingMessageManager disconnect];
	[incomingMessageManager release]; incomingMessageManager = nil;
	
	[super disconnect];
	
	[self didDisconnect];
}

- (void)reconnect
{
	[self setLastDisconnectionError:AILocalizedString(@"Waiting to reconnect", nil)];
	[self disconnect];
}

- (AIReconnectDelayType)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	if (*disconnectionError &&
		([*disconnectionError isEqualToString:AILocalizedString(@"Waiting to reconnect", nil)] ||
		 [*disconnectionError isEqualToString:AILocalizedString(@"Could not log in", nil)])) {
		return AIReconnectImmediately;
	}
	
	return [super shouldAttemptReconnectAfterDisconnectionError:disconnectionError];
}

- (BOOL)isSigningOn
{
	return silentAndDelayed;
}

- (NSString *)facebookUID
{
	return facebookUID;	
}

- (NSString *)channel
{
	return channel;
}

- (NSString *)postFormID
{
	return postFormID;
}

#pragma mark Messaging
- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	[AIFacebookOutgoingMessageManager sendMessageObject:inContentMessage];
	
	return YES;
}

- (void)sendTypingObject:(AIContentTyping *)inContentTyping
{
	[AIFacebookOutgoingMessageManager sendTypingObject:inContentTyping];
}


- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{
	return [[inContentMessage message] string];
}

//Initiate a new chat
- (BOOL)openChat:(AIChat *)chat
{
	return YES;
}

//Close a chat instance
- (BOOL)closeChat:(AIChat *)inChat
{
	return YES;
}

#pragma mark Contact list
- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group
{
	NSEnumerator	*enumerator;
	AIListContact	*listObject;
	
	//Move the objects to it
	enumerator = [objects objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		[buddyListManager moveContact:listObject
					  toGroupWithName:[group UID]];
	}
}

#pragma mark Status

- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage
{
	if ([statusState statusType] == AIOfflineStatusType) {
		[self disconnect];
	} else {
		if (![self online]) {
			[self connect];
		}
	}
}

- (void)setSocialNetworkingStatusMessage:(NSAttributedString *)statusMessage
{
	[AIFacebookStatusManager setFacebookStatusMessage:[statusMessage string] forAccount:self];
}

#pragma mark Connection processing
+ (NSData *)postDataForDictionary:(NSDictionary *)inDict
{
	NSMutableString *post = [NSMutableString string];
	
	//Build post
	NSEnumerator *enumerator = [inDict keyEnumerator];
	NSString	*key;
	while ((key = [enumerator nextObject])) {
		if ([post length] != 0) [post appendString:@"&"];
		
		NSMutableString *value = [[[inDict objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] mutableCopy];
		[value replaceOccurrencesOfString:@"&" withString:@"%26" options:NSLiteralSearch range:NSMakeRange(0, [value length])];

		key = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		[post appendFormat:@"%@=%@", key, value];

		[value release];
	}
	
	return [post dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)postDictionary:(NSDictionary *)inDict toURL:(NSURL *)inURL
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:inURL
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:120];	
	
	NSData *postData = [AIFacebookAccount postDataForDictionary:inDict];
	
	[request setHTTPMethod:@"POST"];
	[request setValue:[NSString stringWithFormat:@"%lu", [postData length]] forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:postData];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
	[[webView mainFrame] loadRequest:request];
}

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
	if ([[request URL] isEqual:[NSURL URLWithString:LOGIN_PAGE]]) {
		return @"Logging in";
	} else if ([[request URL] isEqual:[NSURL URLWithString:FACEBOOK_HOME_PAGE]]) {
		return @"Home";
	} else {
		return nil;
	}
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
	AILogWithSignature(@"%@ resource %@ finished loading %@", sender, identifier, dataSource);

	if ([identifier isEqualToString:@"Logging in"]) {
		if (sentLogin) {
#ifdef CONNECTION_DEBUG
			AILogWithSignature(@"Should now be logged in; login.php result is %@", [[dataSource representation] documentSource]);
#endif
			//We sent our login; proceed with the home page
			[sender stopLoading:self];
			
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:FACEBOOK_HOME_PAGE]
																   cachePolicy:NSURLRequestUseProtocolCachePolicy
															   timeoutInterval:120];	
			
			[[webView mainFrame] loadRequest:request];
			
		} else {
#ifdef CONNECTION_DEBUG
			AILogWithSignature(@"Loaded login.php initially: %@", [[dataSource representation] documentSource]);
			AILogWithSignature(@"%@",
							   [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:LOGIN_PAGE]]);
#endif
			//We loaded login.php; now we can send the email and password
			sentLogin = YES;
			[sender stopLoading:self];
			
			[self postDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
								  [self UID], @"email",
								  password, @"pass",
								  @"Login", @"login",
								  nil]
						   toURL:[NSURL URLWithString:LOGIN_PAGE]];
		}
	} else if ([identifier isEqualToString:@"Home"]) {
		//We finished logging in and got the home page
		[self extractLoginInfoFromHomePage:[[dataSource representation] documentSource]];

		AILogWithSignature(@"facebookUID is %@, channel is %@, post form ID is %@", facebookUID, channel, postFormID);
		
		[sender stopLoading:self];
		
		if (facebookUID && channel && postFormID) {
			[self didConnect];
		} else {
			[self serverReportedInvalidPassword];
			[self setLastDisconnectionError:AILocalizedString(@"Could not log in", nil)];
			[self disconnect];
		}
	}
}

//These should be regexps, really
- (void)extractLoginInfoFromHomePage:(NSString *)homeString
{
	[facebookUID release]; facebookUID = nil;
	[channel release]; channel = nil;
	[postFormID release]; postFormID = nil;

	/* New Facebook Layout: We need our own UID. It'll be inside:
	 * <input type="hidden" id="user" name="user" value="XXXXXXX" />
	 * where XXXXX is an integer.
	 */
	NSRange profileRange = [homeString rangeOfString:@"<input type=\"hidden\" id=\"user\" name=\"user\" value=\"" options:NSLiteralSearch];
	if (profileRange.location != NSNotFound) {
		AILogWithSignature(@"Using new layout");
		NSRange endProfileRange = [homeString rangeOfString:@"\""
													options:NSLiteralSearch
													  range:NSMakeRange(NSMaxRange(profileRange),
																		[homeString length] - NSMaxRange(profileRange))];
		if (endProfileRange.location != NSNotFound) {
			facebookUID = [[homeString substringWithRange:NSMakeRange(NSMaxRange(profileRange),
																	  endProfileRange.location - NSMaxRange(profileRange))] retain];
		}

	} else {
		/* Old Facebook Layout: We need our own UID. It'll be inside:
		 * <a href="http://www.facebook.com/profile.php?id=XXXXX" class="profile_nav_link">Profile</a>
		 * where XXXXX is an integer. There is only one profile_nav_link item.
		 */		
		profileRange = [homeString rangeOfString:@"\" class=\"profile_nav_link\"" options:NSLiteralSearch];
		if (profileRange.location != NSNotFound) {
			NSRange linkBeforeProfile = [homeString rangeOfString:@"<a href=\"http://www.facebook.com/profile.php?id="
														  options:(NSBackwardsSearch | NSLiteralSearch)
															range:NSMakeRange(0, profileRange.location)];
			if (linkBeforeProfile.location != NSNotFound) {
				facebookUID = [[homeString substringWithRange:NSMakeRange(NSMaxRange(linkBeforeProfile),
																		  profileRange.location - NSMaxRange(linkBeforeProfile))] retain];
			}
		}
	}

	NSRange channelRange = [homeString rangeOfString:@", \"channel" options:NSLiteralSearch];
	if (channelRange.location != NSNotFound) {
		NSRange endChannelRange = [homeString rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(NSMaxRange(channelRange),
																										   [homeString length] - NSMaxRange(channelRange))];
		if (endChannelRange.location != NSNotFound) {
			channel = [[homeString substringWithRange:NSMakeRange(NSMaxRange(channelRange),
																  endChannelRange.location - NSMaxRange(channelRange))] retain];
		}
	}
	
	NSRange postFormIDRange = [homeString rangeOfString:@"<input type=\"hidden\" id=\"post_form_id\" name=\"post_form_id\" value=\"" options:NSLiteralSearch];
	if (postFormIDRange.location != NSNotFound) {
		NSRange endPostFormIDRange = [homeString rangeOfString:@"\""
													  options:NSLiteralSearch
														 range:NSMakeRange(NSMaxRange(postFormIDRange),
																		   [homeString length] - NSMaxRange(postFormIDRange))];
		if (endPostFormIDRange.location != NSNotFound) {
			postFormID = [[homeString substringWithRange:NSMakeRange(NSMaxRange(postFormIDRange),
																	  endPostFormIDRange.location - NSMaxRange(postFormIDRange))] retain];
		}
	}
	
	if (!facebookUID || !channel || !postFormID) {
		AILogWithSignature(@"Could not extract information (ID %@, channel %@, postFormID %@) from:\n******\n%@\nn******",
						   facebookUID, channel, postFormID,
						   homeString);
	}
	
	if (facebookUID && postFormID && !channel) {
		channel = [@"1" retain];
		AILogWithSignature(@"Faking the channel (1). Hope this works!");
	}
}

@end
