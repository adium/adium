//
//  AIFacebookXMPPAccount.m
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AIFacebookXMPPAccount.h"
#import "AIFacebookXMPPService.h"
#import <Adium/AIStatus.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIListContact.h>
#import "adiumPurpleCore.h"
#import <libpurple/jabber.h>
#import "ESPurpleJabberAccount.h"
#import "auth_fb.h"
#import "auth.h"

#import <AIUtilities/AIKeychain.h>

#import "AIFacebookXMPPOAuthWebViewWindowController.h"
#import "JSONKit.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIPasswordPromptController.h>
#import <Adium/AIService.h>

#import <libpurple/auth.h>
#import "auth_fb.h"

enum {
    AINoNetworkState,
    AIMeGraphAPINetworkState,
    AIPromoteSessionNetworkState
};

@interface AIFacebookXMPPAccount ()

@property (nonatomic, copy) NSString *oAuthToken;
@property (nonatomic, assign) NSUInteger networkState;
@property (nonatomic, assign) NSURLConnection *connection; // assign because NSURLConnection retains its delegate.
@property (nonatomic, retain) NSURLResponse *connectionResponse;
@property (nonatomic, retain) NSMutableData *connectionData;

- (void)meGraphAPIDidFinishLoading:(NSData *)graphAPIData response:(NSURLResponse *)response error:(NSError *)inError;
- (void)promoteSessionDidFinishLoading:(NSData *)secretData response:(NSURLResponse *)response error:(NSError *)inError;
@end

@implementation AIFacebookXMPPAccount

@synthesize oAuthWC;
@synthesize migrationData;
@synthesize oAuthToken;
@synthesize networkState, connection, connectionResponse, connectionData;

+ (BOOL)uidIsValidForFacebook:(NSString *)inUID
{
	return ((inUID.length > 0) &&
			[inUID stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]].length == 0);
}

- (id)initWithUID:(NSString *)inUID internalObjectID:(NSString *)inInternalObjectID service:(AIService *)inService
{
	if ((self = [super initWithUID:inUID internalObjectID:inInternalObjectID service:inService])) {
		if (![[self class] uidIsValidForFacebook:self.UID]) {
			[self setValue:[NSNumber numberWithBool:YES]
			   forProperty:@"Prompt For Password On Next Connect"
					notify:NotifyNever];
		}
	}
	
	return self;
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

#pragma mark Connectivitiy

- (const char*)protocolPlugin
{
	return "prpl-jabber";
}

- (NSString *)serverSuffix
{
	return @"@chat.facebook.com";
}

/* Specify a host for network-reachability-code purposes */
- (NSString *)host
{
	return @"chat.facebook.com";
}

- (NSString *)apiSecretAccountName
{
	return [NSString stringWithFormat:@"Adium.FB.%@", [self internalObjectID]];
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];

	purple_account_set_username(account, self.purpleAccountName);
	purple_account_set_string(account, "connection_security", "");
    purple_account_set_string(account, "fb_api_key", ADIUM_API_KEY);

/* 
 //Uncomment along with storage code in promoteSessionDidFinishLoading::: to use the session secret. 
	NSString *apiSecret = [[AIKeychain defaultKeychain_error:NULL] findGenericPasswordForService:self.service.serviceID
																						 account:self.apiSecretAccountName
																					keychainItem:NULL
																						   error:NULL];	
	purple_account_set_string(account, "fb_api_secret", [apiSecret UTF8String]);
*/	

    purple_account_set_string(account, "fb_api_secret", ADIUM_API_SECRET);
}


/* Add the authentication mechanism for X-FACEBOOK-PLATFORM. Note that if the server offers it,
 * it will be used preferentially over any other mechanism e.g. DIGEST-MD5. */
- (void)setFacebookMechEnabled:(BOOL)inEnabled
{
	static BOOL enabledFacebookMech = NO;
	if (inEnabled != enabledFacebookMech) {
		if (inEnabled)
			jabber_auth_add_mech(jabber_auth_get_fb_mech());
		else
			jabber_auth_remove_mech(jabber_auth_get_fb_mech());
		
		enabledFacebookMech = inEnabled;
	}
}

- (void)connect
{
	[self setFacebookMechEnabled:YES];
	[super connect];
}

- (void)didConnect
{
	[self setFacebookMechEnabled:NO];
	[super didConnect];	
}

- (void)didDisconnect
{
	[self setFacebookMechEnabled:NO];
	[super didDisconnect];	
}

- (const char *)purpleAccountName
{
	NSString	*userNameWithHost = nil, *completeUserName = nil;
	BOOL		serverAppendedToUID;
	
	serverAppendedToUID = ([UID rangeOfString:[self serverSuffix]
									  options:(NSCaseInsensitiveSearch | NSBackwardsSearch | NSAnchoredSearch)].location != NSNotFound);
	
	if (serverAppendedToUID) {
		userNameWithHost = UID;
	} else {
		userNameWithHost = [UID stringByAppendingString:[self serverSuffix]];
	}
	
	completeUserName = [NSString stringWithFormat:@"-%@/Adium" ,userNameWithHost];
	
	return [completeUserName UTF8String];
}

- (BOOL)encrypted
{
	return NO;
}

- (BOOL)allowAccountUnregistrationIfSupportedByLibpurple
{
	return NO;
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
		[self requestFacebookAuthorization];

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
		[self requestFacebookAuthorization];

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

#pragma mark Account configuration

- (void)setName:(NSString *)name UID:(NSString *)inUID
{
	[self filterAndSetUID:inUID];
	
	[self setFormattedUID:name notify:NotifyNever];
}

#pragma mark Contacts

/*!
 * @brief Set an alias for a contact
 *
 * Normally, we consider the name a 'serverside alias' unless it matches the UID's characters
 * However, the UID in facebook should never be presented to the user if possible; it's for internal use
 * only.  We'll therefore consider any alias a formatted UID such that it will replace the UID when displayed
 * in Adium.
 */
- (void)updateContact:(AIListContact *)theContact toAlias:(NSString *)purpleAlias
{
	if (![purpleAlias isEqualToString:theContact.formattedUID] && 
		![purpleAlias isEqualToString:theContact.UID]) {
		[theContact setFormattedUID:purpleAlias
							 notify:NotifyLater];
		
		//Apply any changes
		[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
	}
}

- (NSMutableArray *)arrayOfDictionariesFromPurpleNotifyUserInfo:(PurpleNotifyUserInfo *)user_info forContact:(AIListContact *)contact
{
	NSMutableArray *array = [super arrayOfDictionariesFromPurpleNotifyUserInfo:user_info forContact:contact];
	
	NSString *displayUID = contact.UID;
	displayUID = [displayUID stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
	if ([displayUID hasSuffix:@"@chat.facebook.com"])
		displayUID = [displayUID substringToIndex:(displayUID.length - @"@chat.facebook.com".length)];

	[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					  AILocalizedString(@"Facebook ID", nil), KEY_KEY,
					  displayUID, KEY_VALUE,
					  nil]];

	return array;
}

#pragma mark Authorization

- (void)requestFacebookAuthorization
{
	self.oAuthWC = [[[AIFacebookXMPPOAuthWebViewWindowController alloc] init] autorelease];
	self.oAuthWC.account = self;

	[[NSNotificationCenter defaultCenter] postNotificationName:AIFacebookXMPPAuthProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIFacebookXMPPAuthProgressPromptingUser]
								 forKey:KEY_FB_XMPP_AUTH_STEP]];

	if (![[self class] uidIsValidForFacebook:self.UID]) {
		/* We have a UID which isn't a Facebook numeric username. That can come from:
		 *	 1. The setup wizard
		 *   2. Facebook-HTTP account from Adium <= 1.4.2
		 */
		self.oAuthWC.autoFillUsername = self.UID;
		self.oAuthWC.autoFillPassword = [adium.accountController passwordForAccount:self];
		self.oAuthWC.isMigrating = ![self.service.serviceID isEqualToString:FACEBOOK_XMPP_SERVICE_ID];

		self.migrationData = [NSDictionary dictionaryWithObjectsAndKeys:
							  self.UID, @"originalUID",
							  self.service.serviceID, @"originalServiceID",
							  nil];
	}

	[self.oAuthWC showWindow:self];
}

- (void)oAuthWebViewController:(AIFacebookXMPPOAuthWebViewWindowController *)wc didSucceedWithToken:(NSString *)token
{
    [self setOAuthToken:token];
    
    NSString *urlstring = [NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@", [self oAuthToken]];
    NSURL *url = [NSURL URLWithString:[urlstring stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    self.networkState = AIMeGraphAPINetworkState;
    self.connectionData = [NSMutableData data];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIFacebookXMPPAuthProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIFacebookXMPPAuthProgressContactingServer]
								 forKey:KEY_FB_XMPP_AUTH_STEP]];	
}

- (void)oAuthWebViewControllerDidFail:(AIFacebookXMPPOAuthWebViewWindowController *)wc
{
	[self setOAuthToken:nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:AIFacebookXMPPAuthProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIFacebookXMPPAuthProgressFailure]
								 forKey:KEY_FB_XMPP_AUTH_STEP]];	
	
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
        
    NSString *secretURLString = [NSString stringWithFormat:@"https://api.facebook.com/method/auth.promoteSession?access_token=%@&format=JSON", [self oAuthToken]];
    NSURL *secretURL = [NSURL URLWithString:[secretURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *secretRequest = [NSURLRequest requestWithURL:secretURL];

    self.networkState = AIPromoteSessionNetworkState;
    self.connectionData = [NSMutableData data];
    self.connection = [NSURLConnection connectionWithRequest:secretRequest delegate:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIFacebookXMPPAuthProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIFacebookXMPPAuthProgressPromotingForChat]
								 forKey:KEY_FB_XMPP_AUTH_STEP]];		
}

- (void)didCompleteFacebookAuthorization
{
	/* Restart the connect process; we're currently considered 'connecting', so passwordReturnedForConnect:::
	 * isn't going to restart it for us. */
	[self connect];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIFacebookXMPPAuthProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIFacebookXMPPAuthProgressSuccess]
								 forKey:KEY_FB_XMPP_AUTH_STEP]];	
}

- (void)promoteSessionDidFinishLoading:(NSData *)secretData response:(NSURLResponse *)response error:(NSError *)inError
{
    if (inError) {
        NSLog(@"error promoting session: %@", inError);
        // TODO: indicate setup failed
        return;
    }    
    

	/* Uncomment the below to store the Session Secret in the keychain. It doesn't seem to be used.
	 
	 NSString *secret = [[[NSString alloc] initWithData:secretData encoding:NSUTF8StringEncoding] autorelease];
	 secret = [secret substringWithRange:NSMakeRange(1, [secret length] - 2)]; // strip off the quotes    
	 
	 
	//Delete before adding; otherwise we'll just get errSecDuplicateItem
	[[AIKeychain defaultKeychain_error:NULL] deleteGenericPasswordForService:self.service.serviceID
																	 account:self.apiSecretAccountName
																	   error:NULL];
	[[AIKeychain defaultKeychain_error:NULL] addGenericPassword:secret
													 forService:self.service.serviceID
														account:self.apiSecretAccountName
												   keychainItem:NULL
														  error:NULL];
	 */
	
	NSString *sessionKey = [self oAuthToken];
	[[adium accountController] setPassword:sessionKey forAccount:self];

	/* When we're newly authorized, connect! */
	[self passwordReturnedForConnect:sessionKey
						  returnCode:AIPasswordPromptOKReturn
							 context:nil];

	[self didCompleteFacebookAuthorization];

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
