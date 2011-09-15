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

#import "AIOAuth2XMPPAccount.h"
#import "JSONKit.h"

enum {
    AINoNetworkState,
    AIMeGraphAPINetworkState,
    AIPromoteSessionNetworkState
};

@interface AIOAuth2XMPPAccount ()

@property (nonatomic, assign) NSUInteger networkState;
@property (nonatomic, assign) NSURLConnection *connection; // assign because NSURLConnection retains its delegate.
@property (nonatomic, retain) NSURLResponse *connectionResponse;
@property (nonatomic, retain) NSMutableData *connectionData;

- (void)meGraphAPIDidFinishLoading:(NSData *)graphAPIData response:(NSURLResponse *)response error:(NSError *)inError;
- (void)promoteSessionDidFinishLoading:(NSData *)secretData response:(NSURLResponse *)response error:(NSError *)inError;
@end

@implementation AIOAuth2XMPPAccount

@synthesize oAuthWC, oAuthToken;
@synthesize networkState, connection, connectionResponse, connectionData;

- (void)dealloc
{
    [oAuthWC release];
    [oAuthToken release];
    
    [connection cancel];
    [connectionResponse release];
    [connectionData release];
	
    [super dealloc];
}

- (void)requestAuthorization
{
	self.oAuthWC = [[[AIFacebookXMPPOAuthWebViewWindowController alloc] init] autorelease];
	self.oAuthWC.account = self;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIOAuth2ProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIOAuth2ProgressPromptingUser]
								 forKey:KEY_OAUTH2_STEP]];
	
//	if (![[self class] uidIsValidForFacebook:self.UID]) {
		/* We have a UID which isn't a Facebook numeric username. That can come from:
		 *	 1. The setup wizard
		 *   2. Facebook-HTTP account from Adium <= 1.4.2
		 */
//		self.oAuthWC.autoFillUsername = self.UID;
//		self.oAuthWC.autoFillPassword = [adium.accountController passwordForAccount:self];
//		self.oAuthWC.isMigrating = ![self.service.serviceID isEqualToString:FACEBOOK_XMPP_SERVICE_ID];
		
//		self.migrationData = [NSDictionary dictionaryWithObjectsAndKeys:
//							  self.UID, @"originalUID",
//							  self.service.serviceID, @"originalServiceID",
//							  nil];
//	}
	
	[self.oAuthWC showWindow:self];
}

- (void)oAuthWebViewController:(AIFacebookXMPPOAuthWebViewWindowController *)wc didSucceedWithToken:(NSString *)token
{
    [self setOAuthToken:token];
    
    NSString *urlstring = [NSString stringWithFormat:[self meURL], [self oAuthToken]];
    NSURL *url = [NSURL URLWithString:[urlstring stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    self.networkState = AIMeGraphAPINetworkState;
    self.connectionData = [NSMutableData data];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIOAuth2ProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIOAuth2ProgressContactingServer]
								 forKey:KEY_OAUTH2_STEP]];
}

- (void)oAuthWebViewControllerDidFail:(AIFacebookXMPPOAuthWebViewWindowController *)wc
{
	[self setOAuthToken:nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIOAuth2ProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIOAuth2ProgressFailure]
								 forKey:KEY_OAUTH2_STEP]];
	
}

#pragma mark Account configuration

- (void)setName:(NSString *)name UID:(NSString *)inUID
{
	[self filterAndSetUID:inUID];
	
	[self setFormattedUID:name notify:NotifyNever];
}

- (void)meGraphAPIDidFinishLoading:(NSData *)graphAPIData response:(NSURLResponse *)inResponse error:(NSError *)inError
{
    if (inError) {
        NSLog(@"error loading graph API: %@", inError);
        // TODO: indicate setup failed 
        return;
    }
    
    NSError *error = nil;
    NSDictionary *resp = [graphAPIData objectFromJSONDataWithParseOptions:JKParseOptionNone error:&error];
    if (!resp) {
        NSLog(@"error decoding graph API response: %@", error);
        // TODO: indicate setup failed
        return;
    }
    
    NSString *uuid = [resp objectForKey:@"id"];
    NSString *name = [resp objectForKey:@"name"];
    
    /* Passwords are keyed by UID, so we need to make this change before storing the password */
	[self setName:name UID:uuid];
	
	[[adium accountController] setPassword:[self oAuthToken] forAccount:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIOAuth2ProgressNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIOAuth2ProgressSuccess]
																						   forKey:KEY_OAUTH2_STEP]];
//    NSString *secretURLString = [NSString stringWithFormat:@"https://api.facebook.com/method/auth.promoteSession?access_token=%@&format=JSON", [self oAuthToken]];
//    NSURL *secretURL = [NSURL URLWithString:[secretURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//    NSURLRequest *secretRequest = [NSURLRequest requestWithURL:secretURL];
//	
//    self.networkState = AIPromoteSessionNetworkState;
//    self.connectionData = [NSMutableData data];
//    self.connection = [NSURLConnection connectionWithRequest:secretRequest delegate:self];
//	
//	[[NSNotificationCenter defaultCenter] postNotificationName:AIOAuth2ProgressNotification
//														object:self
//													  userInfo:
//	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIOAuth2ProgressPromotingForChat]
//								 forKey:KEY_OAUTH2_STEP]];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)inConnection didReceiveResponse:(NSURLResponse *)response
{
    [[self connectionData] setLength:0];
    [self setConnectionResponse:response];
}

- (void)connection:(NSURLConnection *)inConnection didReceiveData:(NSData *)data
{
    [[self connectionData] appendData:data];
}

- (void)connection:(NSURLConnection *)inConnection didFailWithError:(NSError *)error
{
    NSUInteger state = [self networkState];
    
    [self setNetworkState:AINoNetworkState];
    [self setConnection:nil];
    [self setConnectionResponse:nil];
    [self setConnectionData:nil];    
    
    if (state == AIMeGraphAPINetworkState) {
        [self meGraphAPIDidFinishLoading:nil response:nil error:error];
    } else if (state == AIPromoteSessionNetworkState) {
        [self promoteSessionDidFinishLoading:nil response:nil error:error];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)inConnection
{
    NSURLResponse *response = [[[self connectionResponse] retain] autorelease];
    NSMutableData *data = [[[self connectionData] retain] autorelease];
    NSUInteger state = [self networkState]; 
    
    [self setNetworkState:AINoNetworkState];
    [self setConnection:nil];
    [self setConnectionResponse:nil];
    [self setConnectionData:nil];
    
    if (state == AIMeGraphAPINetworkState) {
        [self meGraphAPIDidFinishLoading:data response:response error:nil];
    } else if (state == AIPromoteSessionNetworkState) {
        [self promoteSessionDidFinishLoading:data response:response error:nil];
    }    
}



- (void)connect
{
	[self setMechEnabled:YES];
	[super connect];
}

- (void)didConnect
{
	[self setMechEnabled:NO];
	[super didConnect];	
}

- (void)didDisconnect
{
	[self setMechEnabled:NO];
	[super didDisconnect];	
}

@end
