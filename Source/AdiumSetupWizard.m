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

#import "AdiumSetupWizard.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import "SetupWizardBackgroundView.h"
#import "BGICImportController.h"
#import <AIUtilities/AIImageAdditions.h>
#import "AIServiceMenu.h"
#import <Adium/AIService.h>
#import <AIUtilities/AIStringFormatter.h>
#import "AIHTMLDecoder.h"

#define ACCOUNT_SETUP_IDENTIFIER	@"account_setup"
#define WELCOME_IDENTIFIER			@"welcome"
#define DONE_IDENTIFIER				@"done"

enum{
	WIZARD_TAB_WELCOME = 0,
	WIZARD_TAB_ADD_ACCOUNTS = 1,
	WIZARD_TAB_DONE = 2
};

@interface AdiumSetupWizard ()
- (void)multipleImportAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)show __attribute__((ns_consumes_self));
@end

/*!
 * @class AdiumSetupWizard
 * @brief Class responsible for the first-run setup wizard
 */
@implementation AdiumSetupWizard

/*!
 * @brief Run the wizard
 */
+ (void)runWizard
{
	static AdiumSetupWizard *setupWizardWindowController = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		setupWizardWindowController = [[self alloc] initWithWindowNibName:@"SetupWizard"];
	});
	
	[setupWizardWindowController show];
}

- (void)show
{
	//Configure and show window
	[self showWindow:nil];
	[[self window] orderFront:nil];
}

/*!
 * @brief Localized some common items' titles
 */
- (void)localizeItems
{
	[button_goBack setStringValue:AILocalizedString(@"Go Back","'go back' button title")];
	[textField_passwordLabel setStringValue:AILocalizedString(@"Password:", "Label for the password field in the account preferences")];
	[textField_serviceLabel	setStringValue:AILocalizedString(@"Service:",nil)];
	
	[button_informationAboutImporting setStringValue:AILocalizedString(@"Information About Importing", "button title for more information about importing information in the setup wizard")];
	[button_alternate setStringValue:AILocalizedString(@"Skip Import","button title for skipping the import of another client in the setup wizard")];
}

/*!
 * @brief The window loaded
 */
- (void)windowDidLoad
{
	[[self window] setTitle:AILocalizedString(@"Adium Setup Assistant",nil)];

	//Ensure the first tab view item is selected
	[tabView selectTabViewItemAtIndex:WIZARD_TAB_WELCOME];
	[self tabView:tabView willSelectTabViewItem:[tabView selectedTabViewItem]];

	//Configure our background view; it should display the image transparently where our tabView overlaps it
	[backgroundView setBackgroundImage:[NSImage imageNamed:@"AdiumyButler"
												  forClass:[self class]]];
	NSRect tabViewFrame = [tabView frame];
	NSRect backgroundViewFrame = [backgroundView frame];
	tabViewFrame.origin.x -= backgroundViewFrame.origin.x;
	tabViewFrame.origin.y -= backgroundViewFrame.origin.y;
	[backgroundView setTransparentRect:tabViewFrame];
	
	[self localizeItems];
	
	[[self window] center];

	[super windowDidLoad];
}

- (IBAction)promptForMultiples:(id)sender
{
	// Since we have multiple dedicated importers in 1.1+ it's better to direct the user as needed
    
	NSAlert *multipleImportPrompt = [NSAlert alertWithMessageText:AILocalizedString(@"Have you used other chat clients?", "Title which introduces import assistants during setup")
													defaultButton:AILocalizedStringFromTable(@"Continue", @"Buttons", nil)
												  alternateButton:AILocalizedString(@"Import from iChat", "iChat is the OS X instant messaging client which ships with OS X; the name probably should not be localized")
													  otherButton:nil
										informativeTextWithFormat:AILocalizedString(@"Adium includes assistants to import your accounts, settings, and transcripts from other clients. Choose a client below to open its assistant, or press Continue to skip importing.", nil)];
	[multipleImportPrompt beginSheetModalForWindow:[self window] 
									 modalDelegate:self 
									didEndSelector:@selector(multipleImportAlertDidEnd:returnCode:contextInfo:) 
									   contextInfo:nil];	
}

- (void)multipleImportAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertAlternateReturn) {
		[BGICImportController performSelector:@selector(importIChatConfiguration)
								   withObject:nil
								   afterDelay:0.5];
		[[self window] close];
	}
}

/*!
 * @brief Perform behaviors before the window closes
 *
 * As our window is closing, we auto-release this window controller instance.
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
}

/*!
 * @brief A tab view item was completed; post-process any entered data
 */
- (BOOL)didCompleteTabViewItemWithIdentifier:(NSString *)identifier
{
	BOOL success = YES;

	if ([identifier isEqualToString:ACCOUNT_SETUP_IDENTIFIER]) {
		NSString	*UID = [textField_username stringValue];

		if (UID && [UID length]) {
			AIService	*service = [[popUp_services selectedItem] representedObject];
			AIAccount	*account = [adium.accountController createAccountWithService:service
																				   UID:UID];
			
			//Save the password
			NSString		*password = [textField_password stringValue];
			
			if (password && [password length] != 0) {
				[adium.accountController setPassword:password forAccount:account];
			}
			AILog(@"AdiumSetupWizard: Creating account %@ on service %@",account,service);
			//New accounts need to be added to our account list once they're configured
			[adium.accountController addAccount:account];
			
			//Put new accounts online by default
			[account setShouldBeOnline:YES];
			
			addedAnAccount = YES;

		} else {
			//Successful without having a UID entered if they already added at least one account; unsuccessful otherwise.
			success = addedAnAccount;
		}
	}
	
	return success;
}

/*!
 * @brief The Continue button, which is also the Done button, was pressed
 */
- (IBAction)nextTab:(id)sender
{
	NSTabViewItem *currentTabViewItem = [tabView selectedTabViewItem];
	if ([self didCompleteTabViewItemWithIdentifier:[currentTabViewItem identifier]]) {
		if ([tabView indexOfTabViewItem:currentTabViewItem] == WIZARD_TAB_DONE) {
			//Done
			[self  close];
		} else {
			//Go to the next tab view item
			[tabView selectNextTabViewItem:self];		
		}
	} else {
		NSBeep();
	}
}

/*!
 * @brief The Back button was pressed
 */
- (IBAction)previousTab:(id)sender
{
    [tabView selectPreviousTabViewItem:self];
}

/*!
 * @brief The alternate (third) button was pressed; its behavior will vary by tab view item
 */
- (IBAction)pressedAlternateButton:(id)sender
{
	NSTabViewItem	*currentTabViewItem = [tabView selectedTabViewItem];
	NSString		*identifier = [currentTabViewItem identifier];

	if ([identifier isEqualToString:ACCOUNT_SETUP_IDENTIFIER]) {
		//Configure the account
		if ([self didCompleteTabViewItemWithIdentifier:identifier]) {
			//Reconfigure
			[self tabView:tabView willSelectTabViewItem:currentTabViewItem];
		} else {
			NSBeep();
		}
	}
}

/*!
 * @brief Set up the Account Setup tab for a given service
 */
- (void)configureAccountSetupForService:(AIService *)service
{
	//UID Label
	[textField_usernameLabel setStringValue:[[service userNameLabel] stringByAppendingString:AILocalizedString(@":", "Colon which will be appended after a label such as 'User Name', before an input field")]];

	//UID formatter and placeholder
	[textField_username setFormatter:
		[AIStringFormatter stringFormatterAllowingCharacters:[service allowedCharactersForAccountName]
													  length:[service allowedLengthForAccountName]
											   caseSensitive:[service caseSensitive]
												errorMessage:AILocalizedString(@"The characters you're entering are not valid for an account name on this service.", nil)]];
	[[textField_username cell] setPlaceholderString:[service UIDPlaceholder]];
	
	BOOL showPasswordField = ![service supportsPassword];
	[textField_passwordLabel setHidden:showPasswordField];
	[textField_password setHidden:showPasswordField];
}

/*!
 * @brief The tab view is about to select a tab view item
 */
- (void)tabView:(NSTabView *)inTabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	NSString *identifier = [tabViewItem identifier];

	//The continue button is only initially enabled if the user has added at least one account
	[button_continue setEnabled:YES];

	if ([identifier isEqualToString:ACCOUNT_SETUP_IDENTIFIER]) {
		//Set the services menu if it hasn't already been set
		if (!setupAccountTabViewItem) {
			[popUp_services setMenu:[AIServiceMenu menuOfServicesWithTarget:self
														 activeServicesOnly:NO
															longDescription:YES
																	 format:nil]];
			
			[textField_addAccount setStringValue:AILocalizedString(@"Add an Instant Messaging Account",nil)];
			[textView_addAccountMessage setDrawsBackground:NO];
			[[textView_addAccountMessage enclosingScrollView] setDrawsBackground:NO];
			
			NSAttributedString *accountMessage = [AIHTMLDecoder decodeHTML:
				AILocalizedString(@"<HTML>To chat with your friends, family, and coworkers, you must have an instant messaging account on the same service they do. Choose a service, name, and password below; if you don't have an account yet, click <A HREF=\"http://trac.adium.im/wiki/CreatingAnAccount#Sigingupforanaccount\">here</A> for more information.\n\nAdium supports as many accounts as you want to add; you can always add more in the Accounts pane of the Adium Preferences.</HTML>", nil)
													 withDefaultAttributes:[[textView_addAccountMessage textStorage] attributesAtIndex:0
																														effectiveRange:NULL]];
			[[textView_addAccountMessage textStorage] setAttributedString:accountMessage];
			setupAccountTabViewItem = YES;
		}

		AIService *service = [[popUp_services selectedItem] representedObject];
		[textField_username setStringValue:@""];
		[[self window] makeFirstResponder:textField_username];

		[textField_password setStringValue:@""];

		//The continue button is only initially enabled if the user has added at least one account
		[button_continue setEnabled:addedAnAccount];
		[button_alternate setStringValue:AILocalizedString(@"Add Another","button title for adding another account in the setup wizard")];
		[button_alternate setEnabled:NO];

		[self configureAccountSetupForService:service];

	} else if ([identifier isEqualToString:WELCOME_IDENTIFIER]) {
		[textView_welcomeMessage setDrawsBackground:NO];
		[[textView_welcomeMessage enclosingScrollView] setDrawsBackground:NO];
		NSAttributedString *welcomeMessage = [AIHTMLDecoder decodeHTML:
			AILocalizedString(@"<HTML>Adium is <i>your</i> instant messaging solution.<br><br>Chat with whomever you want, whenever you want, however you want.  Multiple messaging services or accounts? Just one account? Work? Play? Both? No problem; Adium has you covered.<br><br>Adium is fast, free, and fun, with an interface you'll love to use day in and day out. :)<br><br>This assistant will help you set up your instant messaging accounts and get started chatting.<br><br>Click <b>Continue</b> and the duck will take it from here.</HTML>",nil)
												 withDefaultAttributes:[[textView_addAccountMessage textStorage] attributesAtIndex:0
																													effectiveRange:NULL]];
		//Turn that smiley into an emoticon :)
		welcomeMessage = [adium.contentController filterAttributedString:welcomeMessage
														   usingFilterType:AIFilterDisplay
																 direction:AIFilterIncoming
																   context:nil];
		[[textView_welcomeMessage textStorage] setAttributedString:welcomeMessage];

		[textField_welcome setStringValue:AILocalizedString(@"Welcome to Adium!",nil)];
		
	} else if ([identifier isEqualToString:DONE_IDENTIFIER]) {
		[textView_doneMessage setDrawsBackground:NO];
		[[textView_doneMessage enclosingScrollView] setDrawsBackground:NO];
		[textView_doneMessage setString:AILocalizedString(@"Adium is now ready for you. \n\nThe Status indicator at the top of your Contact List and in the Status menu lets you determine whether others see you as Available or Away or, alternately, if you are Offline. Select Custom to type your own status message.\n\nDouble-click a name in your Contact List to begin a conversation.  You can add contacts to your Contact List via the Contact menu.\n\nWant to customize your Adium experience? Check out the Adium Preferences and Xtras Manager via the Adium menu.\n\nEnjoy! Click Done to begin using Adium.", nil)],

		[textField_done setStringValue:AILocalizedString(@"Congratulations!","Header line in the last pane of the Adium setup wizard")];
	}

	//Hide go back on the first tab
	[button_goBack setEnabled:([tabView indexOfTabViewItem:tabViewItem] != WIZARD_TAB_WELCOME)];
	
	[button_alternate setHidden:![identifier isEqualToString:ACCOUNT_SETUP_IDENTIFIER]];

	//Set the done / continue button properly
	if ([tabView indexOfTabViewItem:tabViewItem] == WIZARD_TAB_DONE) {
		[button_continue setStringValue:AILocalizedString(@"Done","'done' button title")];

	} else {
		[button_continue setStringValue:AILocalizedString(@"Continue","'done' button title")];
	}
}

/*!
 * @brief The selected service in the account configuration tab view item was changed
 */
- (IBAction)selectServiceType:(id)sender
{
	[self configureAccountSetupForService:[[popUp_services selectedItem] representedObject]];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == textField_username) {
		BOOL shouldEnable = ([[textField_username stringValue] length] > 0);
		//Allow continuing if they have typed something or they already added an account
		[button_continue setEnabled:(shouldEnable || addedAnAccount)];

		//Allow adding another only if they have typed something
		[button_alternate setEnabled:shouldEnable];
		
	}
}

@end
