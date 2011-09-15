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

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIPasswordPromptController.h>
#import <Adium/AIService.h>

#import <Libpurple/auth.h>
#import "auth_fb.h"

@implementation AIFacebookXMPPAccount

@synthesize migrationData;

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
- (void)setMechEnabled:(BOOL)inEnabled
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
		[super passwordReturnedForConnect:inPassword returnCode:returnCode context:inContext];
	}
}

- (void)retrievePasswordThenConnect
{
	if ([self boolValueForProperty:@"Prompt For Password On Next Connect"]) 
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

- (void)didCompleteFacebookAuthorization
{
	/* Restart the connect process; we're currently considered 'connecting', so passwordReturnedForConnect:::
	 * isn't going to restart it for us. */
	[self connect];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIOAuth2ProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIOAuth2ProgressSuccess]
								 forKey:KEY_OAUTH2_STEP]];	
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
	
	NSString *sessionKey = [[[self oAuthToken] componentsSeparatedByString:@"|"] objectAtIndex:1];
	[[adium accountController] setPassword:sessionKey forAccount:self];

	/* When we're newly authorized, connect! */
	[self passwordReturnedForConnect:sessionKey
						  returnCode:AIPasswordPromptOKReturn
							 context:nil];

	[self didCompleteFacebookAuthorization];

	self.oAuthWC = nil;
    self.oAuthToken = nil;
}

- (NSString *)meURL
{
	return @"https://graph.facebook.com/me?access_token=%@";
}

- (NSString *)oAuthURL
{
	return @"https://graph.facebook.com/oauth/authorize?"
	@"client_id=" ADIUM_APP_ID "&"
	@"redirect_uri=http%3A%2F%2Fwww.facebook.com%2Fconnect%2Flogin_success.html&"
	@"scope=xmpp_login,offline_access&"
	@"type=user_agent&"
	@"display=popup";
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

- (NSString *)tokenFromURL:(NSURL *)url
{
	if ([[url host] isEqual:@"www.facebook.com"] && [[url path] isEqual:@"/connect/login_success.html"]) {
		NSDictionary *urlParamDict = [self parseURLParams:[url fragment]];
		NSString *token = [urlParamDict objectForKey:@"access_token"];
		
		return token ?: @"";
	}
	
	return nil;
}

@end
