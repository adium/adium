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

#import <Adium/AIAccountControllerProtocol.h>
#import "AIAccountProxySettings.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIAccount.h>

@interface AIAccountProxySettings ()
- (void)configureControlDimming;
- (void)updatePasswordField;

- (NSMenu *)_proxyMenu;
- (NSMenuItem *)_proxyMenuItemWithTitle:(NSString *)title tag:(NSInteger)tag;
@end

@implementation AIAccountProxySettings

+ (void)initialize
{
	if (self == [AIAccountProxySettings class]) {
		[self exposeBinding:@"showProxyDetailsControls"];
	}
}

/*!
 * @brief Init our account proxy settings
 *
 * Loads AccountProxy.nib and sets up menus
 */
- (id)init
{
	if ((self = [super init])) {
		//Load our view
		[NSBundle loadNibNamed:@"AccountProxy" owner:self];

		//Setup our menu
		[popUpButton_proxy setMenu:[self _proxyMenu]];
	}

	return self;
}

/*!
 * @brief Our view
 */
- (NSView *)view
{
	return view_accountProxy;
}

/*!
 * @brief Toggle proxy
 *
 * Called when proxy usage is turned on or off
 */
- (IBAction)toggleProxy:(id)sender
{
	[self configureControlDimming];
}

/*!
 * @brief Change proxy type
 *
 * Called when the proxy type is changed
 */
- (void)changeProxyType:(id)sender
{
	[self configureControlDimming];
}

/*!
 * @brief Configure the proxy view for the passed account
 *
 * @param inAccount The account for which to configure
 */
- (void)configureForAccount:(AIAccount *)inAccount
{
	if (account != inAccount) {
		account = inAccount;

		//Enabled & Type
		[checkBox_useProxy setState:[[account preferenceForKey:KEY_ACCOUNT_PROXY_ENABLED
														 group:GROUP_ACCOUNT_STATUS] boolValue]];
		[popUpButton_proxy selectItemWithTag:[[account preferenceForKey:KEY_ACCOUNT_PROXY_TYPE
																			group:GROUP_ACCOUNT_STATUS] integerValue]];
		
		//Host & Port
		NSString	*proxyHost = [account preferenceForKey:KEY_ACCOUNT_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
		[textField_proxyHostName setStringValue:(proxyHost ? proxyHost : @"")];
		
		NSString	*proxyPort = [account preferenceForKey:KEY_ACCOUNT_PROXY_PORT group:GROUP_ACCOUNT_STATUS];
		[textField_proxyPortNumber setStringValue:(proxyPort ? proxyPort : @"")];
		
		//Username
		NSString	*proxyUser = [account preferenceForKey:KEY_ACCOUNT_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS];
		[textField_proxyUserName setStringValue:(proxyUser ? proxyUser : @"")];

		[self updatePasswordField];
		[self configureControlDimming];
	}
}

/*!
 * @brief Save current control values
 */
- (void)saveConfiguration
{
	NSString	*proxyHostName = [textField_proxyHostName stringValue];
	NSString	*proxyUserName = [textField_proxyUserName stringValue];

	//Password
	if (![proxyUserName isEqualToString:[account preferenceForKey:KEY_ACCOUNT_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS]] ||
	   ![proxyHostName isEqualToString:[account preferenceForKey:KEY_ACCOUNT_PROXY_HOST group:GROUP_ACCOUNT_STATUS]]) {
		
		[adium.accountController setPassword:[textField_proxyPassword stringValue]
								forProxyServer:proxyHostName
									  userName:proxyUserName];
	}

	//Enabled & Type
	[account setPreference:[NSNumber numberWithInteger:[checkBox_useProxy state]]
					forKey:KEY_ACCOUNT_PROXY_ENABLED group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithInteger:[[popUpButton_proxy selectedItem] tag]]
					forKey:KEY_ACCOUNT_PROXY_TYPE group:GROUP_ACCOUNT_STATUS];
	
	//Host & Port
	[account setPreference:[textField_proxyHostName stringValue]
					forKey:KEY_ACCOUNT_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[textField_proxyPortNumber stringValue]
					forKey:KEY_ACCOUNT_PROXY_PORT group:GROUP_ACCOUNT_STATUS];
	
	//Username
	[account setPreference:[textField_proxyUserName stringValue]
					forKey:KEY_ACCOUNT_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS];
}

/*!
 * @brief Update password field
 */
- (void)updatePasswordField
{
	NSString	*proxyHostName = [textField_proxyHostName stringValue];
	NSString	*proxyUserName = [textField_proxyUserName stringValue];
	
	if (proxyHostName && proxyUserName) {
		NSString *proxyPassword = [adium.accountController passwordForProxyServer:proxyHostName
																		   userName:proxyUserName];
		[textField_proxyPassword setStringValue:(proxyPassword ? proxyPassword : @"")];
	}
}	

/*!
 * @brief User changed proxy preference
 *
 * We set to nil instead of the @"" a stringValue would return because we want to return to the global (default) value
 * if the user clears the field.
 */
- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSTextField *sender = [aNotification object];
	
	if (sender == textField_proxyHostName) {
		
	} else if (sender == textField_proxyPortNumber) {
		[account setPreference:[NSNumber numberWithInteger:[textField_proxyPortNumber integerValue]]
						forKey:KEY_ACCOUNT_PROXY_PORT
						 group:GROUP_ACCOUNT_STATUS];
		
	} else if (sender == textField_proxyUserName) {
		NSString	*userName = [textField_proxyUserName stringValue];
		
		//If the username changed, save the new username and clear the password field
		if (![userName isEqualToString:[account preferenceForKey:KEY_ACCOUNT_PROXY_USERNAME 
														  group:GROUP_ACCOUNT_STATUS]]) {
			[account setPreference:userName
							forKey:KEY_ACCOUNT_PROXY_USERNAME
							 group:GROUP_ACCOUNT_STATUS];
			
			//Update the password field
			[textField_proxyPassword setStringValue:@""];
			[textField_proxyPassword setEnabled:(userName && [userName length])];
		}
	}
}

- (BOOL)showProxyDetailsControls
{
	AdiumProxyType	proxyType = (AdiumProxyType)[[popUpButton_proxy selectedItem] tag];
	BOOL			usingSystemwide = (proxyType == Adium_Proxy_Default_SOCKS5 ||
									   proxyType == Adium_Proxy_Default_HTTP || 
									   proxyType == Adium_Proxy_Default_SOCKS4);

	return !usingSystemwide;
}

/*!
 * @brief Configure dimming of proxy controls
 */
- (void)configureControlDimming
{
	AdiumProxyType	proxyType = (AdiumProxyType)[[popUpButton_proxy selectedItem] tag];
	BOOL			proxyEnabled = [checkBox_useProxy state];
	BOOL			usingSystemwide = (proxyType == Adium_Proxy_Default_SOCKS5 ||
									   proxyType == Adium_Proxy_Default_HTTP || 
									   proxyType == Adium_Proxy_Default_SOCKS4);
	
	[popUpButton_proxy setEnabled:proxyEnabled];
	[textField_proxyHostName setEnabled:(proxyEnabled && !usingSystemwide)];
	[textField_proxyPortNumber setEnabled:(proxyEnabled && !usingSystemwide)];
	[textField_proxyUserName setEnabled:(proxyEnabled && !usingSystemwide)];
	[textField_proxyPassword setEnabled:(proxyEnabled && !usingSystemwide)];
	
	[self willChangeValueForKey:@"showProxyDetailsControls"];
	[self didChangeValueForKey:@"showProxyDetailsControls"];
}


//Proxy type menu ------------------------------------------------------------------------------------------------------
#pragma mark Proxy type menu
/*!
 * @brief Build the proxy type menu
 *
 * @result An NSMenu of supported proxy settings
 */
- (NSMenu *)_proxyMenu
{
    NSMenu			*proxyMenu = [[NSMenu alloc] init];
	
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"Systemwide SOCKS4 Settings",nil) tag:Adium_Proxy_Default_SOCKS4]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"Systemwide SOCKS5 Settings",nil) tag:Adium_Proxy_Default_SOCKS5]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:AILocalizedString(@"Systemwide HTTP Settings",nil) tag:Adium_Proxy_Default_HTTP]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:@"SOCKS4" tag:Adium_Proxy_SOCKS4]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:@"SOCKS5" tag:Adium_Proxy_SOCKS5]];
	[proxyMenu addItem:[self _proxyMenuItemWithTitle:@"HTTP" tag:Adium_Proxy_HTTP]];
	
	return proxyMenu;
}

/*!
 * @brief Create a proxy menu menuItem
 *
 * Convenience method for _proxyMenu
 */
- (NSMenuItem *)_proxyMenuItemWithTitle:(NSString *)title tag:(NSInteger)tag
{
	NSMenuItem		*menuItem;
    
    menuItem = [[NSMenuItem alloc] initWithTitle:title
																	target:self
																	action:@selector(changeProxyType:)
															 keyEquivalent:@""];
    [menuItem setTag:tag];
	
	return menuItem;
}

@end



