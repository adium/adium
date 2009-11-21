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

#import "AILaconicaAccountViewController.h"
#import "AILaconicaAccount.h"

@implementation AILaconicaAccountViewController

/*!
 * @brief Configure the account view
 */
- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	[textField_connectHost setEnabled:YES];
	
	textField_APIpath.stringValue = [account preferenceForKey:LACONICA_PREFERENCE_PATH group:LACONICA_PREF_GROUP] ?: @"";
	[textField_APIpath setEnabled:YES];

	[checkBox_useSSL setEnabled:YES];
	
	BOOL useSSL = [[account preferenceForKey:LACONICA_PREFERENCE_SSL group:LACONICA_PREF_GROUP] boolValue];
	[checkBox_useSSL setState:useSSL];

}

/*!
 * @brief The Update Interval combo box was changed.
 */
- (void)saveConfiguration
{
	// Strip out http:// or https:// in case the user entered them.
	textField_connectHost.stringValue = [textField_connectHost.stringValue stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	textField_connectHost.stringValue = [textField_connectHost.stringValue stringByReplacingOccurrencesOfString:@"https://" withString:@""];
	
	[super saveConfiguration];

	[account setPreference:textField_APIpath.stringValue
					forKey:LACONICA_PREFERENCE_PATH
					 group:LACONICA_PREF_GROUP];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_useSSL state]]
					forKey:LACONICA_PREFERENCE_SSL
					 group:LACONICA_PREF_GROUP];
	
}

@end
