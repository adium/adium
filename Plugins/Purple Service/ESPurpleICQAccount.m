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

#import <Adium/AIStatusControllerProtocol.h>
#import "ESPurpleICQAccount.h"
#import <Adium/AIStatus.h>

@implementation ESPurpleICQAccount
- (const char *)protocolPlugin
{
    return "prpl-icq";
}

- (void)initAccount
{
	if (([[self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS] caseInsensitiveCompare:@"login.oscar.aol.com"] == NSOrderedSame) ||
		([[self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS] caseInsensitiveCompare:@"slogin.oscar.aol.com"] == NSOrderedSame) ||
		([[self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS] caseInsensitiveCompare:@"slogin.icq.com"] == NSOrderedSame)) {
		/* Reset to the default if we're set to the old AOL login server or its ssl variant.
		 * Reset to the default if we're set to use the ICQ SSL server, as it's currently broken. */
		[self setPreference:nil
					 forKey:KEY_CONNECT_HOST
					  group:GROUP_ACCOUNT_STATUS];
	}
	
	[super initAccount];
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];

	NSString	*encoding;

	//Default encoding
	if ((encoding = [self preferenceForKey:KEY_ICQ_ENCODING group:GROUP_ACCOUNT_STATUS])) {
		purple_account_set_string(account, "encoding", [encoding UTF8String]);
	}
	
	//Defaults to YES
	purple_account_set_bool(account, "authorization", [[self preferenceForKey:KEY_ICQ_REQUIRE_AUTH group:GROUP_ACCOUNT_STATUS] boolValue]);
	
	//Defaults to NO - web_aware will cause lots of spam for many users!
	purple_account_set_bool(account, "web_aware", [[self preferenceForKey:KEY_ICQ_WEB_AWARE group:GROUP_ACCOUNT_STATUS] boolValue]);
}

- (void)migrateSSL
{
	// SSL was forced off in the 1.4.1 update. Because "require SSL" will fail, migrate everyone to opportunistic encryption
	[self setPreference:PREFERENCE_ENCRYPTION_TYPE_OPPORTUNISTIC
				 forKey:PREFERENCE_ENCRYPTION_TYPE
				  group:GROUP_ACCOUNT_STATUS];
}

#pragma mark Contact updates

- (const char *)purpleStatusIDForStatus:(AIStatus *)statusState
							arguments:(NSMutableDictionary *)arguments
{
	const char		*statusID = NULL;
	NSString		*statusName = statusState.statusName;
	NSString		*statusMessageString = [statusState statusMessageString];
	
	if (!statusMessageString) statusMessageString = @"";
		
	switch (statusState.statusType) {
		case AIAvailableStatusType:
			if ([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT]) {
				statusID = OSCAR_STATUS_ID_FREE4CHAT;
			}
			break;

		case AIAwayStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_DND]) ||
			   ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_DND]]== NSOrderedSame))
				statusID = OSCAR_STATUS_ID_DND;
			else if (([statusName isEqualToString:STATUS_NAME_NOT_AVAILABLE]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_NOT_AVAILABLE]]== NSOrderedSame))
				statusID = OSCAR_STATUS_ID_NA;
			else if (([statusName isEqualToString:STATUS_NAME_OCCUPIED]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_OCCUPIED]]== NSOrderedSame))
				statusID = OSCAR_STATUS_ID_OCCUPIED;
			break;
		}
			
		case AIInvisibleStatusType: 
		case AIOfflineStatusType:
			break;
	}

	//If we didn't get a purple status type, request one from super
	if (statusID == NULL) statusID = [super purpleStatusIDForStatus:statusState arguments:arguments];
	
	return statusID;
}

@end
