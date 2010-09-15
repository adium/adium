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

#import "AIPurpleOscarAccountViewController.h"
#import "CBPurpleAccount.h"
#import "CBPurpleOscarAccount.h"
#import <Adium/AIAccount.h>

@implementation AIPurpleOscarAccountViewController

/*!
 * @brief Configure controls
 */
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	[checkBox_proxyServer setState:[[account preferenceForKey:PREFERENCE_FT_PROXY_SERVER group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_SSL setState:[[account preferenceForKey:PREFERENCE_SSL_CONNECTION group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkbox_multipleLogins setState:[[account preferenceForKey:PREFERENCE_ALLOW_MULTIPLE_LOGINS group:GROUP_ACCOUNT_STATUS] boolValue]];
}

/*!
 * @brief Save controls
 */
- (void)saveConfiguration
{
    [super saveConfiguration];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_proxyServer state]]
					forKey:PREFERENCE_FT_PROXY_SERVER
					 group:GROUP_ACCOUNT_STATUS];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_SSL state]]
					forKey:PREFERENCE_SSL_CONNECTION
					 group:GROUP_ACCOUNT_STATUS];
	
	[account setPreference:[NSNumber numberWithBool:[checkbox_multipleLogins state]]
					forKey:PREFERENCE_ALLOW_MULTIPLE_LOGINS
					 group:GROUP_ACCOUNT_STATUS];
}

@end
