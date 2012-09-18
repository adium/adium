//
//  AIPurpleOAuthJabberAccount.m
//  Adium
//
//  Created by Thijs Alkemade on 18-09-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import "AIPurpleOAuthJabberAccount.h"
#import <Adium/AIAccountControllerProtocol.h>

#import "JSONKit.h"

@implementation AIPurpleOAuthJabberAccount

@synthesize oAuthWC;
@synthesize oAuthToken;
@synthesize networkState, connection, connectionResponse, connectionData;

+ (BOOL)uidIsValid:(NSString *)inUID
{
	return YES;
}

- (void)dealloc
{
    [oAuthWC release];
    [oAuthToken release];
    
    [connection cancel];
    [connectionResponse release];
    [connectionData release];
	
    [super dealloc];
}

#pragma mark Account configuration

- (void)setName:(NSString *)name UID:(NSString *)inUID
{
	[self filterAndSetUID:inUID];
	
	[self setFormattedUID:name notify:NotifyNever];
}

/*!
 * @brief Password entered callback
 *
 * Callback after the user enters her password for connecting; finish the connect process.
 */
- (void)passwordReturnedForConnect:(NSString *)inPassword returnCode:(AIPasswordPromptReturn)returnCode context:(id)inContext
{
    if ((returnCode == AIPasswordPromptOKReturn) && (inPassword.length == 0)) {
		/* No password retrieved from the keychain */
		[self requestAuthorization];
		
	} else {
		[self setValue:nil
		   forProperty:@"mustPromptForPasswordOnNextConnect"
				notify:NotifyNever];
		[super passwordReturnedForConnect:inPassword returnCode:returnCode context:inContext];
	}
}


- (void)retrievePasswordThenConnect
{
	if ([self boolValueForProperty:@"Prompt For Password On Next Connect"] ||
		[self boolValueForProperty:@"mustPromptForPasswordOnNextConnect"])
	/* We attempted to connect, but we had incorrect authorization. Display our auth request window. */
		[self requestAuthorization];
	
	else {
		/* Retrieve the user's password. Never prompt for a password, as we'll implement our own authorization handling
		 * if the password can't be retrieved.
		 */
		[adium.accountController passwordForAccount:self
									   promptOption:AIPromptNever
									notifyingTarget:self
										   selector:@selector(passwordReturnedForConnect:returnCode:context:)
											context:nil];
	}
}


- (void)requestAuthorization
{
	self.oAuthWC = [[[AIXMPPOAuthWebViewWindowController alloc] init] autorelease];
	self.oAuthWC.account = self;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIXMPPAuthProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIXMPPOAuthProgressPromptingUser]
								 forKey:KEY_XMPP_OAUTH_STEP]];
	
	[self.oAuthWC showWindow:self];
}



- (void)oAuthWebViewController:(AIXMPPOAuthWebViewWindowController *)wc didSucceedWithToken:(NSString *)token
{
    [self setOAuthToken:token];
    
    NSString *urlstring = [self graphURLForToken:[self oAuthToken]];
    NSURL *url = [NSURL URLWithString:[urlstring stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    self.networkState = AIMeGraphAPINetworkState;
    self.connectionData = [NSMutableData data];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIXMPPAuthProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIXMPPOAuthProgressContactingServer]
								 forKey:KEY_XMPP_OAUTH_STEP]];
}

- (void)oAuthWebViewControllerDidFail:(AIXMPPOAuthWebViewWindowController *)wc
{
	[self setOAuthToken:nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIXMPPAuthProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIXMPPOAuthProgressFailure]
								 forKey:KEY_XMPP_OAUTH_STEP]];
	
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
	
    NSString *secretURLString = [self promoteURLForToken:[self oAuthToken]];
    NSURL *secretURL = [NSURL URLWithString:[secretURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *secretRequest = [NSURLRequest requestWithURL:secretURL];
	
    self.networkState = AIPromoteSessionNetworkState;
    self.connectionData = [NSMutableData data];
    self.connection = [NSURLConnection connectionWithRequest:secretRequest delegate:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIXMPPAuthProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIXMPPOAuthProgressPromotingForChat]
								 forKey:KEY_XMPP_OAUTH_STEP]];
}

- (void)didCompleteAuthorization
{
	/* Restart the connect process; we're currently considered 'connecting', so passwordReturnedForConnect:::
	 * isn't going to restart it for us. */
	[self connect];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIXMPPAuthProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIXMPPOAuthProgressSuccess]
								 forKey:KEY_XMPP_OAUTH_STEP]];
}

- (void)promoteSessionDidFinishLoading:(NSData *)secretData response:(NSURLResponse *)response error:(NSError *)inError
{
    if (inError) {
        NSLog(@"error promoting session: %@", inError);
        // TODO: indicate setup failed
        return;
    }
	
	NSString *sessionKey = [self oAuthToken];
	[[adium accountController] setPassword:sessionKey forAccount:self];
	
	/* When we're newly authorized, connect! */
	[self passwordReturnedForConnect:sessionKey
						  returnCode:AIPasswordPromptOKReturn
							 context:nil];
	
	[self didCompleteAuthorization];
	
	self.oAuthWC = nil;
    self.oAuthToken = nil;
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

@end
