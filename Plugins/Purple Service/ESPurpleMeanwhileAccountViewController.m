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

#import "ESPurpleMeanwhileAccountViewController.h"
#import "ESPurpleMeanwhileAccount.h"

@implementation ESPurpleMeanwhileAccountViewController

- (NSString *)nibName{
    return @"ESPurpleMeanwhileAccountView";
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	[checkBox_fakeClientId setState:[[account preferenceForKey:KEY_MEANWHILE_FAKE_CLIENT_ID group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_forceLogin setState:[[account preferenceForKey:KEY_MEANWHILE_FORCE_LOGIN group:GROUP_ACCOUNT_STATUS] boolValue]];	
}

//Save controls
- (void)saveConfiguration
{
    [super saveConfiguration];
	
	//Connection security
	[account setPreference:[NSNumber numberWithBool:[checkBox_fakeClientId state]]
					forKey:KEY_MEANWHILE_FAKE_CLIENT_ID group:GROUP_ACCOUNT_STATUS];
	//Connection security
	[account setPreference:[NSNumber numberWithBool:[checkBox_forceLogin state]]
					forKey:KEY_MEANWHILE_FORCE_LOGIN group:GROUP_ACCOUNT_STATUS];	
}

@end
