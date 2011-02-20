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
