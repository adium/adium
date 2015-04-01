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

#import "AIPurpleGTalkAccountViewController.h"
#import "AIPurpleGTalkAccount.h"


@implementation AIPurpleGTalkAccountViewController

- (NSString *)nibName{
	return @"ESPurpleGTalkAccountView";
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[checkBox_checkMail setEnabled:YES];
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	[textField_connectServer setStringValue:@"talk.google.com"];
	
	if (account.online) {
		[button_requestAccess setEnabled:FALSE];
	}
}

- (void)saveConfiguration
{
	[super saveConfiguration];
	
	//Connection security
	[account setPreference:[NSNumber numberWithBool:FALSE]
					forKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithBool:TRUE]
					forKey:KEY_JABBER_REQUIRE_TLS group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithBool:TRUE]
					forKey:KEY_JABBER_VERIFY_CERTS group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithBool:FALSE]
					forKey:KEY_JABBER_ALLOW_PLAINTEXT group:GROUP_ACCOUNT_STATUS];
	
	[account setPreference:textField_code.stringValue
					forKey:KEY_GTALK_CODE group:GROUP_ACCOUNT_STATUS];
}

- (IBAction)requestAccess:(id)sender {
	NSString *urlString = @"https://accounts.google.com/o/oauth2/auth?"
	@"scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fgoogletalk%20https://www.googleapis.com/auth/userinfo.email"
	@"&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
	@"&response_type=code"
	@"&client_id=" ADIUM_GTALK_CLIENT_ID;
	
	if (account.UID) {
		urlString = [urlString stringByAppendingFormat:@"&login_hint=%@", account.UID];
	}
	
	NSURL *url = [NSURL URLWithString:urlString];
	
	[[NSWorkspace sharedWorkspace] openURL:url];
	
	[label_code setHidden:FALSE];
	[textField_code setHidden:FALSE];
	
	[button_requestAccess setHidden:TRUE];
}

@end
