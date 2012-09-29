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

#import "ESPurpleMSNAccountViewController.h"
#import "ESPurpleMSNAccount.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

@implementation ESPurpleMSNAccountViewController

- (NSString *)nibName{
    return @"ESPurpleMSNAccountView";
}

//Configure controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	[checkBox_HTTPConnectMethod setState:[[account preferenceForKey:KEY_MSN_HTTP_CONNECT_METHOD 
															  group:GROUP_ACCOUNT_STATUS] boolValue]];
	
	// negated preference, default => allowed
	[checkbox_allowDirectConnections setState:![[account preferenceForKey:KEY_MSN_BLOCK_DIRECT_CONNECTIONS
																   group:GROUP_ACCOUNT_STATUS] boolValue]];
}

//Save controls
- (void)saveConfiguration
{
	[account setPreference:[NSNumber numberWithBool:[checkBox_HTTPConnectMethod state]] 
					forKey:KEY_MSN_HTTP_CONNECT_METHOD group:GROUP_ACCOUNT_STATUS];
	
	[account setPreference:[NSNumber numberWithBool:![checkbox_allowDirectConnections state]]
					forKey:KEY_MSN_BLOCK_DIRECT_CONNECTIONS group:GROUP_ACCOUNT_STATUS];
	
	//Alias
	if (!account.online &&
		![[textField_alias stringValue] isEqualToString:[[NSAttributedString stringWithData:[account preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME
																											   group:GROUP_ACCOUNT_STATUS]] string]]) {
		[account setPreference:[NSNumber numberWithBool:YES]
						forKey:KEY_DISPLAY_CUSTOM_EMOTICONS
						 group:GROUP_ACCOUNT_STATUS];
		
	}

	[super saveConfiguration];
}

@end
