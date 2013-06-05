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

#import "ESIRCAccountViewController.h"
#import "ESIRCAccount.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>

@implementation ESIRCAccountViewController

- (NSString *)nibName{
    return @"ESIRCAccountView";
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[popUp_encoding setMenu:[self encodingMenu]];
}

- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	// Encoding
	[popUp_encoding selectItemWithRepresentedObject:[account preferenceForKey:KEY_IRC_ENCODING
																		group:GROUP_ACCOUNT_STATUS]];
	
	// Connection SSL
	[checkbox_useSSL setState:[[account preferenceForKey:KEY_IRC_USE_SSL group:GROUP_ACCOUNT_STATUS] boolValue]];

	// Disable the server field when online, since this will change our Purple account name
	[textField_connectHost setEnabled:!account.online];
	
	// Execute commands
	NSString *commands = [account preferenceForKey:KEY_IRC_COMMANDS group:GROUP_ACCOUNT_STATUS] ?: @"";
	[textView_commands.textStorage setAttributedString:[NSAttributedString stringWithString:commands]];
	
	// Username
	NSString *username = [account preferenceForKey:KEY_IRC_USERNAME group:GROUP_ACCOUNT_STATUS] ?: @"";
	[textField_username setStringValue:username];
	[textField_username.cell setPlaceholderString:((ESIRCAccount *)account).defaultUsername];
	
	// Realname
	NSString *realname = [account preferenceForKey:KEY_IRC_REALNAME group:GROUP_ACCOUNT_STATUS] ?: @"";
	[textField_realname setStringValue:realname];
	[textField_realname.cell setPlaceholderString:((ESIRCAccount *)account).defaultRealname];
	
	// SASL
	[checkbox_useSASL setState:[[account preferenceForKey:KEY_IRC_USE_SASL group:GROUP_ACCOUNT_STATUS] boolValue]];
	
	[checkbox_insecurePlain setState:[[account preferenceForKey:KEY_IRC_INSECURE_SASL_PLAIN group:GROUP_ACCOUNT_STATUS] boolValue]];
}

- (void)saveConfiguration
{
	[super saveConfiguration];
	
	// Encoding
	[account setPreference:[[popUp_encoding selectedItem] representedObject]
					forKey:KEY_IRC_ENCODING
					 group:GROUP_ACCOUNT_STATUS];
	
	// Connection SSL
	[account setPreference:[NSNumber numberWithBool:[checkbox_useSSL state]]
					forKey:KEY_IRC_USE_SSL
					 group:GROUP_ACCOUNT_STATUS];
	
	// Execute commands
	[account setPreference:textView_commands.textStorage.string forKey:KEY_IRC_COMMANDS group:GROUP_ACCOUNT_STATUS];
	
	// Username
	[account setPreference:(textField_username.stringValue.length ? textField_username.stringValue : nil)
					forKey:KEY_IRC_USERNAME
					 group:GROUP_ACCOUNT_STATUS];
	
	// Realname
	[account setPreference:(textField_realname.stringValue.length ? textField_realname.stringValue : nil)
					forKey:KEY_IRC_REALNAME
					 group:GROUP_ACCOUNT_STATUS];
	
	// Connection SASL
	[account setPreference:[NSNumber numberWithBool:[checkbox_useSASL state]]
					forKey:KEY_IRC_USE_SASL
					 group:GROUP_ACCOUNT_STATUS];
	
	[account setPreference:[NSNumber numberWithBool:[checkbox_insecurePlain state]]
					forKey:KEY_IRC_INSECURE_SASL_PLAIN
					 group:GROUP_ACCOUNT_STATUS];
	
}	

@end
