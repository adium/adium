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

#import "AITwitterAccountOAuthSetup.h"

@interface AITwitterAccountViewController()
- (void)completedOAuthSetup;
- (void)setStatusText:(NSString *)text withColor:(NSColor *)color buttonEnabled:(BOOL)enabled;
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
	NSMenu *intervalMenu = [[[NSMenu alloc] init] autorelease];

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
		if (OAuthSetupStep == AIOAuthStepRequestToken) {
			[OAuthSetup fetchAccessToken];
		} else {
			[OAuthSetup release];
			
			OAuthSetup = [[AITwitterAccountOAuthSetup alloc] initWithDelegate:self
																   forAccount:(AITwitterAccount *)account];
			
			[OAuthSetup beginSetup];
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
				  buttonEnabled:YES];
		
		} else if (account.UID && [[adium.accountController passwordForAccount:account] length]) {
			[self setStatusText:AILocalizedString(@"Your account is already authorized with Twitter.", nil)
					  withColor:nil
				  buttonEnabled:NO];
		} else {
			[self setStatusText:nil
					  withColor:nil
				  buttonEnabled:YES];
		}
	} else {
		[tabView_authenticationType selectTabViewItem:tabViewItem_basicAuthentication];
	}
	
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
}

/*!
 * @brief The Update Interval combo box was changed.
 */
- (void)saveConfiguration
{
	[super saveConfiguration];
	
	[OAuthSetup release]; OAuthSetup = nil;
	
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
	
	if (account.online) {
		[(AITwitterAccount *)account setProfileName:(textField_name.isEnabled ? textField_name.stringValue : nil)
												url:(textField_url.isEnabled ? textField_url.stringValue : nil)
										   location:(textField_location.isEnabled ? textField_location.stringValue : nil)
										description:(textField_description.isEnabled ? textField_description.stringValue : nil)];
	}
}

#pragma mark OAuth status text
- (void)setStatusText:(NSString *)text withColor:(NSColor *)color buttonEnabled:(BOOL)enabled
{
	textField_OAuthStatus.stringValue = text ?: @"";
	textField_OAuthStatus.textColor = color ?: [NSColor controlTextColor];
	[button_OAuthStart setEnabled:enabled];
}

#pragma mark OAuth setup delegate

- (void)OAuthSetup:(AITwitterAccountOAuthSetup *)setup
	 changedToStep:(AIOAuthSetupStep)setupStep
		 withToken:(OAToken *)token
	  responseBody:(NSString *)responseBody
{
	AILocalizedString(@"Step %u", setupStep);
	
	OAuthSetupStep = setupStep;
	
	switch (OAuthSetupStep) {
		case AIOAuthStepStart:
			// Just starting, fetching a request token
			[self setStatusText:[NSString stringWithFormat:AILocalizedString(@"Connecting to %@ for access.", nil), account.host]
					  withColor:nil
				  buttonEnabled:YES];
			break;
			
		case AIOAuthStepRequestToken:
			// We have a request token, ask user to authorize.
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?oauth_token=%@",
																		 ((AITwitterAccount *)account).tokenAuthorizeURL,
																		 token.key]]];

			[self setStatusText:AILocalizedString(@"Your must authorize your account for access in Adium. When you have done so, click the 'Completed' button above.", nil)
					  withColor:nil
				  buttonEnabled:YES];
			
			button_OAuthStart.title = AILocalizedString(@"Completed", nil);
			
			break;
			
		case AIOAuthStepAccessToken:
			// We have an access token, hoorah!
			textField_password.stringValue = responseBody;
			
			[self setStatusText:AILocalizedString(@"Success! Your account is now authorized. You may connect at will.", nil)
					  withColor:nil
				  buttonEnabled:NO];

			[self completedOAuthSetup];			
			
			break;
			
		case AIOAuthStepFailure:
			// Failed in some way. sad. :(

			[self setStatusText:AILocalizedString(@"An error occured when trying to gain access. Please try again.", nil)
					  withColor:[NSColor redColor]
				  buttonEnabled:YES];
			
			button_OAuthStart.title = AILocalizedString(@"Authorize Account", nil);
			
			[self completedOAuthSetup];
			
			break;
	}
}

- (void)completedOAuthSetup
{
	[OAuthSetup release]; OAuthSetup = nil;
	OAuthSetupStep = AIOAuthStepFailure;	
}

@end
