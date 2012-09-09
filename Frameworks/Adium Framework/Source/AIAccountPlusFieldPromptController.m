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

#import <Adium/AIAccount.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIAccountPlusFieldPromptController.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <AIUtilities/AICompletingTextField.h>
#import <Adium/AIMetaContact.h>

@interface AIAccountPlusFieldPromptController ()

- (void)AI_configureTextFieldForAccount:(AIAccount *)account;

@end

#define ACCOUNT_PLUS_FIELD_GROUP	@"AccountPlusFieldWindows"

@implementation AIAccountPlusFieldPromptController

+ (id)sharedInstance {return nil;};
+ (id)createSharedInstance {return nil;};
+ (void)destroySharedInstance {};

+ (void)showPrompt
{
	AIAccountPlusFieldPromptController *sharedInstance = [self sharedInstance];
	
    if (!sharedInstance) {
        sharedInstance = [self createSharedInstance];
    }

    [[sharedInstance window] makeKeyAndOrderFront:nil];
}

+ (void)closeSharedInstance
{
	AIAccountPlusFieldPromptController *sharedInstance = [self sharedInstance];

    if (sharedInstance) {
        [sharedInstance closeWindow:nil];
    }
}

- (AIListContact *)contactFromTextField
{
	AIListContact	*contact = nil;
	NSString		*UID = nil;
	AIAccount		*account = [[popUp_service selectedItem] representedObject];

	id impliedValue = [textField_handle impliedValue];
	
	// It is not on our contact list, create a contact if possible and start a new chat, otherwise, tell the user they should be more specific.
	if ([impliedValue isKindOfClass:[NSString class]]) {
		if (account) {
			UID = [account.service normalizeUID:impliedValue removeIgnoredCharacters:YES];
			
			contact = [adium.contactController contactWithService:account.service
														  account:account 
															  UID:UID];
		} else {			
			NSRunAlertPanel(AILocalizedStringFromTableInBundle(@"Contact not found",
															   nil,
															   [NSBundle bundleForClass:[AIAccountPlusFieldPromptController class]],
															   nil),
							[NSString stringWithFormat:
							 AILocalizedStringFromTableInBundle(@"%@ is not on any account. Please select a specific account or add this contact first.",
																nil,
																[NSBundle bundleForClass:[AIAccountPlusFieldPromptController class]],
																nil), impliedValue],
							AILocalizedStringFromTableInBundle(@"OK",
															   nil,
															   [NSBundle bundleForClass:[AIAccountPlusFieldPromptController class]],
															   nil),
							nil,
							nil);
			
			return nil;
		}
	} else {
		// Contact is on our list
		contact = impliedValue;
	}
	
	return contact;
}

- (void)AI_configureTextFieldForAccount:(AIAccount *)account
{	
	// Clear the completing strings
	[textField_handle setCompletingStrings:nil];
	
	/* Configure the auto-complete view to autocomplete for contacts matching the selected account's service
	 * Don't include meta contacts which don't currently contain any valid contacts
	 * If the account is nil, we show them all
	 */
	for (AIListContact *contact in adium.contactController.allContacts) {
		if (account == nil || ([contact.service.serviceClass isEqualToString:account.service.serviceClass] &&
		    (![contact isKindOfClass:[AIMetaContact class]] || [(AIMetaContact *)contact uniqueContainedObjectsCount]))) {
			NSString *UID = contact.UID;
			[textField_handle addCompletionString:contact.formattedUID withImpliedCompletion:contact];
			[textField_handle addCompletionString:UID withImpliedCompletion:contact];
			[textField_handle addCompletionString:contact.displayName withImpliedCompletion:contact];
		}
	}	
}

/*!
 * @brief This is the key under which the last selected account is saved for this prompt
 *
 * Subclasses should override to get per-window-type saving behavior
 */
- (NSString *)lastAccountIDKey
{
	return @"General";
}

- (void)_restoreLastAccountIfPossible
{
	NSString *accountID = [adium.preferenceController preferenceForKey:[NSString stringWithFormat:@"AccountPlusFieldLastAccountID:%@", [self lastAccountIDKey]]
																   group:ACCOUNT_PLUS_FIELD_GROUP];
	AIAccount *account = [adium.accountController accountWithInternalObjectID:accountID];
	NSInteger accountIndex = (account ? [[popUp_service menu] indexOfItemWithRepresentedObject:account] : -1);

	if (accountIndex != -1) {
		[popUp_service selectItemAtIndex:accountIndex];
	}
}

- (void)_saveConfiguredAccount
{
	[adium.preferenceController setPreference:[[[popUp_service selectedItem] representedObject] internalObjectID]
										 forKey:[NSString stringWithFormat:@"AccountPlusFieldLastAccountID:%@", [self lastAccountIDKey]]
											 group:ACCOUNT_PLUS_FIELD_GROUP];
}

- (IBAction)okay:(id)sender
{
	[self _saveConfiguredAccount];
}

#pragma mark Private

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	self = [super initWithWindowNibName:windowNibName];    

    return self;
}

// Setup the window before it is displayed
- (void)windowDidLoad
{
	// Controls
	[button_cancel setLocalizedString:
	 AILocalizedStringFromTableInBundle(@"Cancel",
										nil,
										[NSBundle bundleForClass:[AIAccountPlusFieldPromptController class]],
										nil)];
	[textField_handle setMinStringLength:2];
	
	// Account menu
	accountMenu = [AIAccountMenu accountMenuWithDelegate:self
											  submenuType:AIAccountNoSubmenu
										   showTitleVerbs:NO];
	[self _restoreLastAccountIfPossible];
	[self AI_configureTextFieldForAccount:[[popUp_service selectedItem] representedObject]];
	[self controlTextDidChange:nil];

    // Center the window
    [[self window] center];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[[self class] destroySharedInstance];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if (!aNotification || [aNotification object] == textField_handle) {
		[button_okay setEnabled:([[textField_handle stringValue] length] > 0)];
	}

	if ([[AIAccountPlusFieldPromptController superclass] instancesRespondToSelector:@selector(controlTextDidChange:)]) {
		[super controlTextDidChange:aNotification];
	}
}

#pragma mark Account menu

// Account menu delegate
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems
{
	[popUp_service setMenu:[inAccountMenu menu]];
}	

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount
{
	[self AI_configureTextFieldForAccount:inAccount];
}

- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount
{
	return inAccount.online;
}

- (NSMenuItem *)accountMenuSpecialMenuItem:(AIAccountMenu *)inAccountMenu
{
	NSMenuItem *anyItem = nil;
	int numberOfOnlineAccounts = 0;
	
	for (AIAccount *account in adium.accountController.accounts) {
		if ([self accountMenu:inAccountMenu shouldIncludeAccount:account]) {
			numberOfOnlineAccounts += 1;
			if (numberOfOnlineAccounts > 1) {
				anyItem = [[NSMenuItem alloc] initWithTitle:
							AILocalizedStringFromTableInBundle(@"Any",
															   nil,
															   [NSBundle bundleForClass:[AIAccountPlusFieldPromptController class]],
															   nil)
													  action:nil
											   keyEquivalent:@""];
				break;
			}
		}
	}
	
	return anyItem;
}

// Select the last used account / Available online account
- (void)_selectLastUsedAccountInAccountMenu:(AIAccountMenu *)inAccountMenu
{
	// First online account in our list
	AIAccount    *preferredAccount;
	for (preferredAccount in adium.accountController.accounts) {
		if (preferredAccount.online)
			break;
	}
	
	NSMenuItem	*menuItem = [inAccountMenu menuItemForAccount:preferredAccount];
	
	if (menuItem) {
		[popUp_service selectItem:menuItem];
		[self AI_configureTextFieldForAccount:preferredAccount];
	}
}	
	
@end
