//
//  ESPurpleSimpleAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 12/17/05.
//

#import "ESPurpleSimpleAccount.h"

@implementation ESPurpleSimpleAccount

- (const char*)protocolPlugin
{
    return "prpl-simple";
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];
	
	purple_account_set_bool(account, "udp", [[self preferenceForKey:KEY_SIMPLE_USE_UDP group:GROUP_ACCOUNT_STATUS] boolValue]);
	
	purple_account_set_bool(account, "dopublish", [[self preferenceForKey:KEY_SIMPLE_PUBLISH_STATUS group:GROUP_ACCOUNT_STATUS] boolValue]);
	
	purple_account_set_bool(account, "useproxy", [[self preferenceForKey:KEY_SIMPLE_USE_SIP_PROXY
																   group:GROUP_ACCOUNT_STATUS] boolValue]);
	purple_account_set_string(account, "proxy", [[self preferenceForKey:KEY_SIMPLE_SIP_PROXY
																  group:GROUP_ACCOUNT_STATUS] UTF8String]);
	purple_account_set_string(account, "authuser", [[self preferenceForKey:KEY_SIMPLE_AUTH_USER
																	 group:GROUP_ACCOUNT_STATUS] UTF8String]);
	purple_account_set_string(account, "authdomain", [[self preferenceForKey:KEY_SIMPLE_AUTH_DOMAIN
																	   group:GROUP_ACCOUNT_STATUS] UTF8String]);
}

- (const char *)purpleAccountName
{
	NSString	*userNameWithHost;

	/*
	 * Purple stores the username in the format username@server.  We need to pass it a username in this format.
	 */
	if ([UID rangeOfString:@"@"].location != NSNotFound) {
		userNameWithHost = UID;
	} else {
		userNameWithHost = [NSString stringWithFormat:@"%@@%@",UID,self.host];
	}
	
	return [userNameWithHost UTF8String];
}

@end
