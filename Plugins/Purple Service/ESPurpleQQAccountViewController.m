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

#import "ESPurpleQQAccountViewController.h"
#import "ESPurpleQQAccount.h"

#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>

@interface ESPurpleQQAccountViewController()
- (NSMenu *)clientVersionMenu;
@end

@implementation ESPurpleQQAccountViewController
- (NSString *)nibName{
    return @"PurpleQQAccountView";
}

/*!
 * @brief Awake from nib
 */
- (void)awakeFromNib
{
	[super awakeFromNib];
	[popUp_clientVersion setMenu:[self clientVersionMenu]];
}


//Configure controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];

	[checkBox_useTCP setState:[[account preferenceForKey:KEY_QQ_USE_TCP 
												   group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_useTCP setLocalizedString:AILocalizedString(@"Connect using TCP", nil)];

	[label_connection setLocalizedString:AILocalizedString(@"Connection:", nil)];
	
	[label_clientVersion setLocalizedString:AILocalizedString(@"Client Version:", nil)];
	
	[popUp_clientVersion selectItemWithRepresentedObject:[inAccount preferenceForKey:KEY_QQ_CLIENT_VERSION
																			   group:GROUP_ACCOUNT_STATUS]];
}

//Save controls
- (void)saveConfiguration
{
	[account setPreference:[NSNumber numberWithBool:[checkBox_useTCP state]] 
					forKey:KEY_QQ_USE_TCP group:GROUP_ACCOUNT_STATUS];
	
	[account setPreference:[[popUp_clientVersion selectedItem] representedObject]
					forKey:KEY_QQ_CLIENT_VERSION
					 group:GROUP_ACCOUNT_STATUS];

	[super saveConfiguration];
}

- (NSMenu *)clientVersionMenu
{
	NSMenu			*clientVersionMenu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	NSDictionary	*clientVersionDict = [NSDictionary dictionaryWithObjectsAndKeys:
										  @"2008", @"qq2008",
										  @"2007", @"qq2007",
										  @"2005", @"qq2005",
										  nil];
	
	for (NSString *prefix in clientVersionDict.allKeys) {
		[clientVersionMenu addItemWithTitle:[clientVersionDict objectForKey:prefix]
									 target:nil
									 action:nil
							  keyEquivalent:@""
						  representedObject:prefix];
	}

	return [clientVersionMenu autorelease];
}

@end
