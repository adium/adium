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

#import "AIXMPPOAuthWebViewWindowController.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIPasswordPromptController.h>
#import <Adium/AIService.h>

#import <libpurple/auth.h>
#import "auth_fb.h"

@implementation AIFacebookXMPPAccount

@synthesize migrationData;

+ (BOOL)uidIsValid:(NSString *)inUID
{
	return ((inUID.length > 0) &&
			[inUID stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]].length == 0);
}

- (id)initWithUID:(NSString *)inUID internalObjectID:(NSString *)inInternalObjectID service:(AIService *)inService
{
	if ((self = [super initWithUID:inUID internalObjectID:inInternalObjectID service:inService])) {
		if (![[self class] uidIsValid:self.UID]) {
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

- (NSString *)graphURLForToken:(NSString *)token
{
	return [NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@", token];
}

- (NSString *)promoteURLForToken:(NSString *)token
{
	return [NSString stringWithFormat:@"https://api.facebook.com/method/auth.promoteSession?access_token=%@&format=JSON", token];
}

- (NSString *)authorizeURL
{
	return @"https://graph.facebook.com/oauth/authorize?"
	@"client_id=" ADIUM_APP_ID "&"
	@"redirect_uri=http%3A%2F%2Fwww.facebook.com%2Fconnect%2Flogin_success.html&"
	@"scope=xmpp_login,offline_access&"
	@"type=user_agent&"
	@"display=popup";
}

- (NSString *)frameURLHost
{
	return @"www.facebook.com";
}

- (NSString *)frameURLPath
{
	return @"/connect/login_success.html";
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

- (BOOL)allowAccountUnregistrationIfSupportedByLibpurple
{
	return NO;
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

- (void)requestAuthorization
{
	if (![[self class] uidIsValid:self.UID]) {
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
	
	[super requestAuthorization];
}

@end
