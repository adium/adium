/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AITwitterAccountOAuthSetup.h"

#import <OAuthConsumer/OAuthConsumer.h>

@interface AITwitterAccountOAuthSetup ()
- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error;

- (void)accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error;
@end

@implementation AITwitterAccountOAuthSetup

- (id)initWithDelegate:(id <AITwitterAccountOAuthSetupDelegate>)inDelegate
			forAccount:(AITwitterAccount *)inAccount
{
	if ((self = [super init])) {
		delegate = inDelegate;
		account = [inAccount retain];
	}
	
	return self;
}	

- (void)dealloc
{
	[account release];
	[requestToken release];
	[consumer release];
	[account release];
	[super dealloc];
}

#pragma mark Requesting
- (void)beginSetup
{
	[delegate OAuthSetup:self changedToStep:AIOAuthStepStart withToken:nil responseBody:nil];
	
	consumer = [[OAConsumer alloc] initWithKey:account.consumerKey
										 secret:account.secretKey];
	
	NSURL *url = [NSURL URLWithString:account.tokenRequestURL];
	
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
                                                                     token:nil
                                                                     realm:nil
                                                         signatureProvider:nil];
	
    [request setHTTPMethod:@"POST"];
	
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:request
																						  delegate:self
																				 didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
																				   didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
	
	[fetcher start];
	[request release];
}

@synthesize verifier;

- (void)fetchAccessToken
{
	if (!requestToken) {
		[delegate OAuthSetup:self changedToStep:AIOAuthStepFailure withToken:nil responseBody:nil];
	}
	
	[delegate OAuthSetup:self changedToStep:AIOAuthStepVerifyingRequest withToken:nil responseBody:nil];
	
	NSURL *url = [NSURL URLWithString:account.tokenAccessURL];
	
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:consumer
                                                                      token:requestToken
                                                                      realm:nil
                                                          signatureProvider:nil];
    [request setHTTPMethod:@"POST"];
	
	if (verifier) {
		NSString *verifierString = [NSString stringWithFormat:@"oauth_verifier=%@", verifier];
		
		[request setHTTPBody:[verifierString dataUsingEncoding:NSUTF8StringEncoding]];
	}

    OAAsynchronousDataFetcher *fetcher  = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:request
																						   delegate:self
																				  didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
																					didFailSelector:@selector(accessTokenTicket:didFailWithError:)];
	
	[fetcher start];
	[request release];
}

#pragma mark Request token processing
- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	if (ticket.didSucceed) {
		NSString *responseBody = [[[NSString alloc] initWithData:data
														encoding:NSUTF8StringEncoding] autorelease];
		
		requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		
		[delegate OAuthSetup:self
			   changedToStep:AIOAuthStepRequestToken
				   withToken:requestToken
				responseBody:responseBody];
	} else {
		[delegate OAuthSetup:self changedToStep:AIOAuthStepFailure withToken:nil responseBody:nil];
		AILogWithSignature(@"%@ failure in request token", account);	
	}
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
	[delegate OAuthSetup:self changedToStep:AIOAuthStepFailure withToken:nil responseBody:nil];
	AILogWithSignature(@"%@ failure: %@", account, error);
}

#pragma mark Access token processing
- (void)accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	if (ticket.didSucceed) {
		NSString *responseBody = [[[NSString alloc] initWithData:data
														encoding:NSUTF8StringEncoding] autorelease];

		OAToken *accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		
		[delegate OAuthSetup:self
			   changedToStep:AIOAuthStepAccessToken
				   withToken:accessToken
				responseBody:responseBody];
		
		[accessToken release];
	} else {
		[delegate OAuthSetup:self changedToStep:AIOAuthStepFailure withToken:nil responseBody:nil];
		AILogWithSignature(@"%@ failure in access token", account);	
	}
}


- (void)accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
	[delegate OAuthSetup:self changedToStep:AIOAuthStepFailure withToken:nil responseBody:nil];
	AILogWithSignature(@"%@ failure: %@", account, error);
}

@end
