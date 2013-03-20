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

#import "AITwitterAccount.h"
#import "AITwitterAccountViewController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIAccountControllerProtocol.h>

#define BUTTON_TEXT_ALLOW_ACCESS		AILocalizedString(@"Allow Adium access", nil)

@interface AITwitterAccountViewController()
- (void)completedOAuthSetup;
- (void)setStatusText:(NSString *)text withColor:(NSColor *)color buttonEnabled:(BOOL)enabled buttonText:(NSString *)buttonText;
@end

@implementation AITwitterAccountViewController

/*!
 * @brief We have no privacy settings.
 */
- (NSView *)privacyView
{
	return nil;
}

/*!
 * @brief Use the Twitter account view.
 */
- (NSString *)nibName
{
    return @"AITwitterAccountView";
}

- (void)awakeFromNib
{
	NSMenu *intervalMenu = [[NSMenu alloc] init];

	[intervalMenu addItemWithTitle:AILocalizedString(@"never", "Update tweets: never")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:0]];
	
	[intervalMenu addItemWithTitle:AILocalizedString(@"every 2 minutes", "Update tweets: every 2 minutes")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:2]];

	[intervalMenu addItemWithTitle:AILocalizedString(@"every 5 minutes", "Update tweets: every 5 minutes")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:5]];
	
	[intervalMenu addItemWithTitle:AILocalizedString(@"every 10 minutes", "Update tweets every: 10 minutes")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:10]];
	
	[intervalMenu addItemWithTitle:AILocalizedString(@"every 15 minutes", "Update tweets every: 15 minutes")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:15]];
	
	[intervalMenu addItemWithTitle:AILocalizedString(@"every half-hour", "Update tweets every: half-hour")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:30]];
	
	[intervalMenu addItemWithTitle:AILocalizedString(@"every hour", "Update tweets every hour")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:60]];
	
	[intervalMenu setAutoenablesItems:YES];
	
	[popUp_updateInterval setMenu:intervalMenu];
	
	[self setStatusText:@"" withColor:nil buttonEnabled:YES buttonText:BUTTON_TEXT_ALLOW_ACCESS];
}

- (void)dealloc
{
	OAuthSetup = nil;
}

/*!
 * @brief A preference was changed
 *
 * Don't save here; merely update controls as necessary.
 */
- (IBAction)changedPreference:(id)sender
{
	[checkBox_updateGlobalIncludeReplies setEnabled:[checkBox_updateGlobalStatus state]];
	
	if(sender == button_OAuthStart) {
		void (^errorBlock)(NSError *);
		errorBlock = ^(NSError *error) {
			// Failed in some way. sad. :(
			AILog(@"There was an error authorizing with Twitter: %@", error);
			
			[self setStatusText:AILocalizedString(@"An error occured while trying to gain access. Please try again.", nil)
					  withColor:[NSColor redColor]
				  buttonEnabled:YES
					 buttonText:BUTTON_TEXT_ALLOW_ACCESS];
			
			[textField_OAuthVerifier setHidden:YES];
			[progressIndicator setHidden:YES];
			[progressIndicator stopAnimation:nil];
			
			[self completedOAuthSetup];
		};
		
		if ([textField_OAuthVerifier.stringValue isEqualToString:@""]) {
			OAuthSetup = [STTwitterOAuth twitterServiceWithConsumerName:@"Adium"
															consumerKey:[(AITwitterAccount *)account consumerKey]
														 consumerSecret:[(AITwitterAccount *)account secretKey]];
			[OAuthSetup postTokenRequest:^(NSURL *url, NSString *oauthToken) {
								// We have a request token, ask user to authorize.
								[[NSWorkspace sharedWorkspace] openURL:url];
								
								[self setStatusText:AILocalizedString(@"You must allow Adium access to your account in the browser window which just opened. When you have done so, enter the PIN code in the field above.", nil)
										  withColor:nil
									  buttonEnabled:YES
										 buttonText:AILocalizedString(@"I've allowed Adium access", nil)];
								
								[textField_OAuthVerifier setHidden:NO];
								[progressIndicator setHidden:YES];
								[progressIndicator stopAnimation:nil];
							}
						   oauthCallback:nil
							  errorBlock:errorBlock];
		} else {
			[OAuthSetup postAccessTokenRequestWithPIN:textField_OAuthVerifier.stringValue
										 successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
											 // We have an access token, hoorah!
											 
											 textField_password.stringValue = [NSString stringWithFormat:@"oauth_token=%@&oauth_token_secret=%@", oauthToken, oauthTokenSecret];
											 
											 [self setStatusText:AILocalizedString(@"Success! Adium now has access to your account. Click OK below.", nil)
													   withColor:nil
												   buttonEnabled:NO
													  buttonText:nil];
											 
											 [textField_OAuthVerifier setHidden:YES];
											 [progressIndicator setHidden:YES];
											 [progressIndicator stopAnimation:nil];
											 
											 [account setLastDisconnectionError:nil];
											 [account setValue:[NSNumber numberWithBool:YES] forProperty:@"Reconnect After Edit" notify:NotifyNever];
											 
											 [self completedOAuthSetup];
										 } errorBlock:errorBlock];
		}
	}
}

/*!
 * @brief Configure the account view
 */
- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	// Setup - OAuth
	
	AITwitterAccount *twitterAccount = (AITwitterAccount *)account;
	
	if (twitterAccount.useOAuth) {
		[tabView_authenticationType selectTabViewItem:tabViewItem_OAuth];
		
		if ([account.lastDisconnectionError isEqualToString:TWITTER_OAUTH_NOT_AUTHORIZED]) {
			[self setStatusText:TWITTER_OAUTH_NOT_AUTHORIZED
					  withColor:[NSColor redColor]
				  buttonEnabled:YES
					 buttonText:BUTTON_TEXT_ALLOW_ACCESS];
		
		} else if (account.UID && [[adium.accountController passwordForAccount:account] length]) {
			[self setStatusText:AILocalizedString(@"Adium currently has access to your account.", nil)
					  withColor:nil
				  buttonEnabled:NO
					 buttonText:BUTTON_TEXT_ALLOW_ACCESS];
		} else {
			[self setStatusText:nil
					  withColor:nil
				  buttonEnabled:YES
					 buttonText:BUTTON_TEXT_ALLOW_ACCESS];
		}
	} else {
		[tabView_authenticationType selectTabViewItem:tabViewItem_basicAuthentication];
	}
	
	[textField_OAuthVerifier setHidden:YES];
	
	// Options
	
	NSNumber *updateInterval = [account preferenceForKey:TWITTER_PREFERENCE_UPDATE_INTERVAL group:TWITTER_PREFERENCE_GROUP_UPDATES];
	[popUp_updateInterval selectItemAtIndex:[[popUp_updateInterval menu] indexOfItemWithRepresentedObject:updateInterval]];
	
	BOOL updateAfterSend = [[account preferenceForKey:TWITTER_PREFERENCE_UPDATE_AFTER_SEND group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue];
	[checkBox_updateAfterSend setState:updateAfterSend];
	
	BOOL updateGlobal = [[account preferenceForKey:TWITTER_PREFERENCE_UPDATE_GLOBAL group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue];
	[checkBox_updateGlobalStatus setState:updateGlobal];

	BOOL updateGlobalIncludesReplies = [[account preferenceForKey:TWITTER_PREFERENCE_UPDATE_GLOBAL_REPLIES group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue];
	[checkBox_updateGlobalIncludeReplies setState:updateGlobalIncludesReplies];
	
	[checkBox_updateGlobalIncludeReplies setEnabled:[checkBox_updateGlobalStatus state]];

	BOOL loadContacts = [[account preferenceForKey:TWITTER_PREFERENCE_LOAD_CONTACTS group:TWITTER_PREFERENCE_GROUP_UPDATES] boolValue];
	[checkBox_loadContacts setState:loadContacts];
	
	// Personal

	textField_name.stringValue = [account valueForProperty:@"Profile Name"] ?: @"";
	textField_url.stringValue = [account valueForProperty:@"Profile URL"] ?: @"";
	textField_location.stringValue = [account valueForProperty:@"Profile Location"] ?: @"";
	textField_description.stringValue = [account valueForProperty:@"Profile Description"] ?: @"";
	
	[textField_name setEnabled:account.online];
	[textField_url setEnabled:account.online];
	[textField_location setEnabled:account.online];
	[textField_description setEnabled:account.online];
	
	textField_APIpath.stringValue = @"";
	
	[textField_connectHost setEnabled:NO];
	[textField_APIpath setEnabled:NO];
	[checkBox_useSSL setEnabled:NO];
}

/*!
 * @brief The Update Interval combo box was changed.
 */
- (void)saveConfiguration
{
	[super saveConfiguration];
	
	OAuthSetup = nil;
	
	[account setPreference:popUp_updateInterval.selectedItem.representedObject
					forKey:TWITTER_PREFERENCE_UPDATE_INTERVAL
					 group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_updateAfterSend state]]
					forKey:TWITTER_PREFERENCE_UPDATE_AFTER_SEND
					 group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_updateGlobalStatus state]]
					forKey:TWITTER_PREFERENCE_UPDATE_GLOBAL
					 group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_updateGlobalIncludeReplies state]]
					forKey:TWITTER_PREFERENCE_UPDATE_GLOBAL_REPLIES
					 group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	[account setPreference:[NSNumber numberWithBool:[checkBox_loadContacts state]]
					forKey:TWITTER_PREFERENCE_LOAD_CONTACTS
					 group:TWITTER_PREFERENCE_GROUP_UPDATES];
	
	if (account.online) {
		[(AITwitterAccount *)account setProfileName:(textField_name.isEnabled ? textField_name.stringValue : nil)
												url:(textField_url.isEnabled ? textField_url.stringValue : nil)
										   location:(textField_location.isEnabled ? textField_location.stringValue : nil)
										description:(textField_description.isEnabled ? textField_description.stringValue : nil)];
	}
}

#pragma mark OAuth status text
- (void)setStatusText:(NSString *)text withColor:(NSColor *)color buttonEnabled:(BOOL)enabled buttonText:(NSString *)buttonText
{
	textField_OAuthStatus.stringValue = text ?: @"";
	textField_OAuthStatus.textColor = color ?: [NSColor controlTextColor];

	[button_OAuthStart setEnabled:enabled];
	
	if(buttonText) {
		button_OAuthStart.title = buttonText;
		[button_OAuthStart sizeToFit];
		[button_OAuthStart setFrameOrigin:NSMakePoint(NSMidX(button_OAuthStart.superview.frame) - NSWidth(button_OAuthStart.frame)/2.0f,
													  NSMinY(button_OAuthStart.frame))];
	}
}

- (void)completedOAuthSetup
{
	OAuthSetup = nil;
}

@end
