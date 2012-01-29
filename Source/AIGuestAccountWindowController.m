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

#import "AIGuestAccountWindowController.h"
#import "AIEditAccountWindowController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import "AIServiceMenu.h"
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIStringFormatter.h>

@interface AIGuestAccountWindowController ()
- (IBAction)selectServiceType:(id)sender;
@end

static AIGuestAccountWindowController *sharedGuestAccountWindowController = nil;

@implementation AIGuestAccountWindowController
+ (void)showGuestAccountWindow
{
	//Create the window
	if (!sharedGuestAccountWindowController) {
		sharedGuestAccountWindowController = [[self alloc] initWithWindowNibName:@"GuestAccountWindow"];
	}

	[[sharedGuestAccountWindowController window] makeKeyAndOrderFront:nil];
}

- (NSString *)adiumFrameAutosaveName
{
	return @"GuestAccountWindow";
}

- (void)awakeFromNib
{
	[[self window] setTitle:AILocalizedString(@"Connect Guest Account", "Title for the window shown when adding a guest (temporary) account")];
}

- (void)dealloc
{
	[account release];
	
	[super dealloc];
}

- (void)windowDidLoad
{
	[super windowDidLoad];

	[popUp_service setMenu:[AIServiceMenu menuOfServicesWithTarget:self
												activeServicesOnly:NO
												   longDescription:YES
															format:nil]];
	[self selectServiceType:nil];
	[label_password setLocalizedString:AILocalizedString(@"Password:", nil)];
	[label_service setLocalizedString:AILocalizedString(@"Service:", nil)];
	[button_okay setLocalizedString:AILocalizedString(@"Connect", nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel", nil)];
	[button_advanced setLocalizedString:[AILocalizedString(@"Advanced", nil) stringByAppendingEllipsis]];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[sharedGuestAccountWindowController autorelease]; sharedGuestAccountWindowController = nil;
}

- (AIService *)service
{
	return [[popUp_service selectedItem] representedObject];
}

- (NSString *)UID
{
	NSString *UID = [textField_name stringValue];
	
	//Use the default user name if possible, if no UID is specified
	if (!UID || ![UID length]) UID = [self.service defaultUserName];

	return UID;
}

- (AIAccount *)account
{
	if (!account) {
		account = [[adium.accountController createAccountWithService:self.service
																   UID:self.UID] retain];
	} else {
		if ((self.service != account.service) ||
			(![self.UID isEqualToString:account.UID])) {
			[account release];

			account = [[adium.accountController createAccountWithService:self.service
																	   UID:self.UID] retain];
		}
	}
	
	return account;
}

- (IBAction)selectServiceType:(id)sender
{
	AIService *service = self.service;
	[label_name setStringValue:[[service userNameLabel] stringByAppendingString:AILocalizedString(@":", "Colon which will be appended after a label such as 'User Name', before an input field")]];
	
	[textField_name setFormatter:
		[AIStringFormatter stringFormatterAllowingCharacters:[service allowedCharactersForAccountName]
													  length:[service allowedLengthForAccountName]
											   caseSensitive:[service caseSensitive]
												errorMessage:AILocalizedString(@"The characters you're entering are not valid for an account name on this service.", nil)]];
	
	NSString *placeholder = [service defaultUserName];
	if (!placeholder || ![placeholder length]) placeholder = [service UIDPlaceholder];
	[[textField_name cell] setPlaceholderString:(placeholder ? placeholder : @"")];
}

- (IBAction)okay:(id)sender
{
	AIAccount	*theAccount = self.account;
	[theAccount setIsTemporary:YES];
	
	[adium.accountController addAccount:theAccount];
	[theAccount setPasswordTemporarily:[textField_password stringValue]];

	//Connect the account
	[theAccount setPreference:[NSNumber numberWithBool:YES] forKey:@"isOnline" group:GROUP_ACCOUNT_STATUS];
	
	[[self window] performClose:nil];
}

- (IBAction)displayAdvanced:(id)sender
{
	AIEditAccountWindowController *editAccountWindowController = [[AIEditAccountWindowController alloc] initWithAccount:self.account
																										notifyingTarget:self];
	[editAccountWindowController showOnWindow:[self window]];
}

- (void)editAccountSheetDidEndForAccount:(AIAccount *)inAccount withSuccess:(BOOL)inSuccess
{
	//If the AIEditAccountWindowController changes the account object, update to follow suit
	if (inAccount != account) {
		[account release];
		account = [inAccount retain];
	}
	
	//Make sure our UID is still accurate
	if (![inAccount.UID isEqualToString:self.UID]) {
		[textField_name setStringValue:inAccount.UID];
	}
}

@end
