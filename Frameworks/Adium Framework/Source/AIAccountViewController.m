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

#import <Adium/AIAccountViewController.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIChat.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringFormatter.h>

#define KEY_DISABLE_TYPING_NOTIFICATIONS		@"Disable Typing Notifications"

@interface AIAccountViewController ()
- (void)localizeStrings;
@end

/*!
 * @class AIAccountViewController
 * @brief Base account view controller
 *
 * This class serves as a foundation for account code's account-specific preference views.  It provides a lot of 
 * common functionality to cut down on duplicate code, and default views that will be satisfactory for many service
 * types
 */
@implementation AIAccountViewController

+ (void)initialize
{
	if (self == [AIAccountViewController class]) {
		[self exposeBinding:@"account"];
	}
}

/*!
 * @brief Create a new account view controller
 */
+ (id)accountViewController
{
    return [[self alloc] init];
}

/*!
 * @brief Init
 */
- (id)init
{
	NSBundle		*ourBundle = [NSBundle bundleForClass:[AIAccountViewController class]];
	NSDictionary	*nameTable = [NSDictionary dictionaryWithObject:self forKey:@"NSOwner"];
	
    if ((self = [super init]))
	{
		account = nil;
		changedPrefDict = [[NSMutableDictionary alloc] init];

		//Load custom views for our subclass (If our subclass specifies a nib name)
		if ([self nibName]) {
			[NSBundle loadNibNamed:[self nibName] owner:self];
		}
		
		//Load our default views if necessary
		if (!view_setup) [ourBundle loadNibFile:@"AccountSetup" externalNameTable:nameTable withZone:nil];
		if (!view_profile) [ourBundle loadNibFile:@"AccountProfile" externalNameTable:nameTable withZone:nil];
		if (!view_options) [ourBundle loadNibFile:@"AccountOptions" externalNameTable:nameTable withZone:nil];
		if (!view_privacy) [ourBundle loadNibFile:@"AccountPrivacy" externalNameTable:nameTable withZone:nil];

		[self localizeStrings];
	}

    return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief Awake from nib
 *
 * Configure the account view controller after it's loaded from the nib
 */
- (void)awakeFromNib
{
	if (popUp_encryption) {
		[popUp_encryption setMenu:[adium.contentController encryptionMenuNotifyingTarget:nil 
																			   withDefault:NO]];
		[[popUp_encryption menu] setAutoenablesItems:NO];
	}
}


//Account specific views -----------------------------------------------------------------------------------------------
#pragma mark Account specific views
/*!
 * @brief Setup View
 *
 * Returns the account setup view.  This view is displayed on the main account preferences pane, and should contain
 * the fields which are essential.  The default view provides username and password fields.
 */
- (NSView *)setupView
{
    return view_setup;
}

/*!
 * @brief Profile View
 *
 * Returns the account profile view.  This view is for personal information that in most cases is viewable by other 
 * users.  The default view provides an alias field.
 */
- (NSView *)profileView
{
    return view_profile;
}

/*!
 * @brief Options View
 *
 * Returns the account options view.  This view is for additional settings which are not common enough to be a standard
 * part of Adium.  The default view provides login server and port settings.
 */
- (NSView *)optionsView
{
    return view_options;
}

/*!
* @brief Privacy View
 *
 * Returns the account privacy view.  This view is for privacy options.  The default view provides options for encryption
 * (which is supported at present by all Gaim-provided protocols) and for sending the Typing status.
 */
- (NSView *)privacyView
{
	return view_privacy;
}
 
/*!
 * @brief Custom nib name
 *
 * Returns the file name of the custom nib to load which contains the account code's custom setup, profile, and options
 * views.
 */
- (NSString *)nibName
{
    return @"";    
}


//Preferences ----------------------------------------------------------------------------------------------------------
#pragma mark Preferences
/*!
 * @brief Configure the account view
 *
 * Configures the account view controls for the passed account.
 */
- (void)configureForAccount:(AIAccount *)inAccount
{
	if (account != inAccount) {
		AIService *service;
		
		[self willChangeValueForKey:@"account"];
		account = inAccount;
		[self didChangeValueForKey:@"account"];
		
		service = account.service;

		//UID Label
		//Must use AILocalized...FromTableInBundle() because this class is intended to be subclasses, and if the subclass is in a different bundle, AILocalized...String fails.
		[textField_accountUIDLabel setStringValue:[[service userNameLabel] stringByAppendingString:AILocalizedStringFromTableInBundle(@":", nil, [NSBundle bundleForClass:[AIAccountViewController class]], "Colon which will be appended after a label such as 'User Name', before an input field")]];

		//UID
		NSString	*formattedUID = account.formattedUID;
		[textField_accountUID setStringValue:(formattedUID ? account.formattedUID : @"")];
		[textField_accountUID setFormatter:
			[AIStringFormatter stringFormatterAllowingCharacters:[service allowedCharactersForAccountName]
														  length:[service allowedLengthForAccountName]
												   caseSensitive:[service caseSensitive]
													errorMessage:AILocalizedStringFromTableInBundle(@"The characters you're entering are not valid for an account name on this service.", nil, [NSBundle bundleForClass:[AIAccountViewController class]], nil)]];
		[[textField_accountUID cell] setPlaceholderString:[service UIDPlaceholder]];

		//Can't change the UID while the account is online
		//XXX update this if the account connectivity changes -eds
		[textField_accountUID setEnabled:!account.online];
		
		//Password
		NSString	*savedPassword = [adium.accountController passwordForAccount:account];
		[textField_password setStringValue:[savedPassword length] ? savedPassword : @""];
		
		//Account sign up button text
		[button_signUp setTitle:[service accountSetupLabel]];
		
		//User alias (display name)
		NSString *alias = [[[account preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME group:GROUP_ACCOUNT_STATUS] attributedString] string];
		[textField_alias setStringValue:(alias ? alias : @"")];
		[[textField_alias cell] setPlaceholderString:[[[adium.preferenceController preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME group:GROUP_ACCOUNT_STATUS] attributedString] string]];
	
		//Server Host
		NSString	*host = [account preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS];
		[textField_connectHost setStringValue:([host length] ? host : @"")];
		
		//Server Port
		NSNumber	*port = [account preferenceForKey:KEY_CONNECT_PORT group:GROUP_ACCOUNT_STATUS];
		if (port) {
			[textField_connectPort setStringValue:[NSString stringWithFormat:@"%d", [port intValue]]];
		} else {
			[textField_connectPort setStringValue:@""];
		}
		
		//Check for new mail
		[checkBox_checkMail setState:[[inAccount preferenceForKey:KEY_ACCOUNT_CHECK_MAIL
															group:GROUP_ACCOUNT_STATUS] boolValue]];
		
		//Typing (inverse preference)
		[checkBox_sendTyping setState:![[inAccount preferenceForKey:KEY_DISABLE_TYPING_NOTIFICATIONS
															  group:GROUP_ACCOUNT_STATUS] boolValue]];

		//Encryption
		[popUp_encryption selectItemWithTag:[[account preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE
																		   group:GROUP_ENCRYPTION] intValue]];
	}
}

/*!
 * @brief Saves the current account view configuration
 *
 * Saves the current configuration of the account view to the account it's been configured for.  Not saving changes
 * immediately allows us to 'cancel' changes, or 'okay' changes and apply them by calling this method.
 */
- (void)saveConfiguration
{
	//UID - account; only set if the account doesn't handle setting its own UID based on a combination of fields.
	if (textField_accountUID) {
		NSString	*newUID = [textField_accountUID stringValue];
		if (![account.UID isEqualToString:newUID] ||
			![account.formattedUID isEqualToString:newUID]) {
			[account filterAndSetUID:newUID];
		}
	}

	//Connect Host - save first in case the account uses the server name for password storage.
	NSString *connectHost = [textField_connectHost stringValue];
	//Remove trailing whitespace from the host string.  This causes connection to fail for IRC.
	connectHost = [connectHost stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	[account setPreference:((connectHost && [connectHost length]) ? connectHost : nil)
					forKey:KEY_CONNECT_HOST
					 group:GROUP_ACCOUNT_STATUS];	
	
	//Password
	NSString		*password = [textField_password stringValue];
	NSString		*oldPassword = [adium.accountController passwordForAccount:account];
	
	if (password && [password length] != 0) {
		if (![password isEqualToString:oldPassword]) {
			[adium.accountController setPassword:password forAccount:account];
		}
	} else if ((oldPassword && [oldPassword length] != 0) && textField_password) {
		[adium.accountController forgetPasswordForAccount:account];
	}

	//Connect Port
	[account setPreference:([textField_connectPort intValue] ? [NSNumber numberWithInt:[textField_connectPort intValue]] : nil)
					forKey:KEY_CONNECT_PORT
					 group:GROUP_ACCOUNT_STATUS];

	//Alias
	NSString *displayName = [textField_alias stringValue];
	[account setPreference:((displayName && [displayName length]) ?
							[[NSAttributedString stringWithString:displayName] dataRepresentation] :
							nil)
					forKey:KEY_ACCOUNT_DISPLAY_NAME
					 group:GROUP_ACCOUNT_STATUS];		
	
	//Check mail	
	[account setPreference:[NSNumber numberWithBool:[checkBox_checkMail state]]
					forKey:KEY_ACCOUNT_CHECK_MAIL
					 group:GROUP_ACCOUNT_STATUS];
	
	//Typing (preference is the inverse of the displayed checkbox)
	[account setPreference:[NSNumber numberWithBool:![checkBox_sendTyping state]]
					forKey:KEY_DISABLE_TYPING_NOTIFICATIONS
					 group:GROUP_ACCOUNT_STATUS];

	//Encryption
	[account setPreference:[NSNumber numberWithInteger:[[popUp_encryption selectedItem] tag]]
					forKey:KEY_ENCRYPTED_CHAT_PREFERENCE
					 group:GROUP_ENCRYPTION];
	
	//Set all preferences in the changedPrefDict
	[account setPreferences:changedPrefDict
					inGroup:GROUP_ACCOUNT_STATUS];
}

/*!
 * @brief Invoked when a preference is changed
 *
 * This method is invoked when a preference is changed, and may be used to dynamically enable/disable controls or
 * change other aspects of the view dynamically.  It should not be used to save changes; changes should only be saved
 * from within the saveConfiguration method.
 */
- (IBAction)changedPreference:(id)sender
{
	//Empty
}

/*!
 * @brief Invoked when the account sign up button is clicked
 *
 * This method is invoked when the account sign up button is clicked. It defaults to opening the account sign up URL
 * in the default browser, but can be used to override this behaviour.
 */
- (IBAction)signUpAccount:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[account.service serviceAccountSetupURL]];
}

/*!
 * @brief Dictionary mapping Adium preference keys to exposed binding keys
 *
 * The objects of the dictionary should be Adium preference keys
 * The keys of the dictionary should be exposed binding keys
 *
 * Subclasses must include the contents of super's dictionary in their return value.
 *
 * The contents of this dictionary will be used to automatically retrieve and save account-specific preferences
 * in the GROUP_ACCOUNT_STATUS group to/from controls bound to the owner's keypath as keyed by the dictionary.
 */
- (NSDictionary *)keyToKeyDict
{
	return [NSDictionary dictionary];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	NSString *prefKey = [[self keyToKeyDict] objectForKey:key];
	if (prefKey) {
		//If this is a key for which we have an Adium preferences mapping, set the value for saving in saveConfiguration
		[self willChangeValueForKey:key];
		[changedPrefDict setValue:value forKey:prefKey];
		[self didChangeValueForKey:key];

	} else {
		[super setValue:value forKey:key];
	}
}

- (id)valueForKey:(NSString *)key
{
	NSString *prefKey = [[self keyToKeyDict] objectForKey:key];
	if (prefKey) {
		//If this is a key for which we have an Adium preferences mapping, retrieve the current value
		id value = [changedPrefDict objectForKey:prefKey];
		if (!value) value = [account preferenceForKey:prefKey group:GROUP_ACCOUNT_STATUS];
		return value;
	} else {
		return [super valueForKey:key];
	}
}

#pragma mark Localization
- (void)localizeStrings
{
	[label_password setStringValue:AILocalizedStringFromTableInBundle(@"Password:", nil, [NSBundle bundleForClass:[AIAccountViewController class]], "Label for the password field in the account preferences")];
	[label_typing setStringValue:AILocalizedStringFromTableInBundle(@"Typing:", nil, [NSBundle bundleForClass:[AIAccountViewController class]], "Label beside the 'let others know when you are typing' checkbox in the account preferences")];
	[checkBox_sendTyping setStringValue:AILocalizedStringFromTableInBundle(@"Let others know when you are typing", nil, [NSBundle bundleForClass:[AIAccountViewController class]], "Text of the typing preference checkbox in the account preferneces")];
	[label_encryption setStringValue:AILocalizedStringFromTableInBundle(@"Encryption:", nil, [NSBundle bundleForClass:[AIAccountViewController class]], "Label besides the encryption preference menu")];
	[label_alias setStringValue:AILocalizedStringFromTableInBundle(@"Alias:", nil, [NSBundle bundleForClass:[AIAccountViewController class]], nil)];
	[label_port setStringValue:AILocalizedStringFromTableInBundle(@"Port:", nil, [NSBundle bundleForClass:[AIAccountViewController class]], "Label for the port field in the account preferences")];
	[label_server setStringValue:AILocalizedStringFromTableInBundle(@"Login Server:", nil, [NSBundle bundleForClass:[AIAccountViewController class]], "Label for the login server field in the account preferences")];
}

@end
