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

#import "ESPurpleICQAccountViewController.h"
#import "ESPurpleICQAccount.h"
#import <AIUtilities/AIPopUpButtonAdditions.h>
				   
@implementation ESPurpleICQAccountViewController

- (NSString *)nibName{
    return @"ESPurpleICQAccountView";
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[popUp_encoding setMenu:[self encodingMenu]];
}


//Configure controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	[popUp_encoding selectItemWithRepresentedObject:[account preferenceForKey:KEY_ICQ_ENCODING
																		group:GROUP_ACCOUNT_STATUS]];
	[checkBox_webAware setState:[[account preferenceForKey:KEY_ICQ_WEB_AWARE
													 group:GROUP_ACCOUNT_STATUS] boolValue]];
}

//Save controls
- (void)saveConfiguration
{
    [super saveConfiguration];
	[account setPreference:[[popUp_encoding selectedItem] representedObject]
					forKey:KEY_ICQ_ENCODING
					 group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithBool:[checkBox_webAware state]]
					forKey:KEY_ICQ_WEB_AWARE
					 group:GROUP_ACCOUNT_STATUS];
}

@end
