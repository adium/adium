//
//  ESPurpleQQAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 8/7/06.
//

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
