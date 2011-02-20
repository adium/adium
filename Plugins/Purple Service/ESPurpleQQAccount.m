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

#import "ESPurpleQQAccount.h"


@implementation ESPurpleQQAccount

- (const char*)protocolPlugin
{
    return "prpl-qq";
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];
	
	purple_account_set_bool(account, "use_tcp", [[self preferenceForKey:KEY_QQ_USE_TCP group:GROUP_ACCOUNT_STATUS] boolValue]);
	purple_account_set_string(account, "client_version", [[self preferenceForKey:KEY_QQ_CLIENT_VERSION group:GROUP_ACCOUNT_STATUS] UTF8String]);
}

/*!
 * @brief The server name to be passed to libpurple
 * QQ prpl will choose a server randomly for load balancing if we don't pass one, so do that.  -self.host returns the first server
 * for host reachability checking purpoes.
 */
- (NSString *)hostForPurple
{
	NSString *specifiedHost = [self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS];
	return (specifiedHost ? specifiedHost : nil);			
}

- (NSString *)host
{
/* This is not technically right, since the qq plugin randomly chooses one of many different servers at connect time.
 * "sz.tencent.com" or "sz#.tencent.com" for UDP
 * "tcpconn.tencent.com" or "tcpconn#.tencent.com" where (# <= 6) for TCP.
 * Specifying the host is important for network reachability checking, though, and generally all hosts should be up if one is reachable.
 */
	NSString *host = [self hostForPurple];
	if (!host)
		host = ([[self preferenceForKey:KEY_QQ_USE_TCP group:GROUP_ACCOUNT_STATUS] boolValue] ? @"tcpconn.tencent.com" : @"sz.tencent.com");
	
	return host;
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if (label && (strcmp(label, _("Modify my information")) == 0)) {
		return AILocalizedString(@"Modify My Information", "Menu title for configuring the public information for a QQ account");
	}
	
	return [super titleForAccountActionMenuLabel:label];
}

@end
