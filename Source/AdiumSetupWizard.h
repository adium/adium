//
//  AdiumSetupWizard.h
//  Adium
//
//  Created by Evan Schoenberg on 12/4/05.

#import <Adium/AIWindowController.h>

@class SetupWizardBackgroundView;

@interface AdiumSetupWizard : AIWindowController {
	IBOutlet SetupWizardBackgroundView	*backgroundView;

	IBOutlet NSButton	*button_continue;
	IBOutlet NSButton	*button_goBack;
	IBOutlet NSButton	*button_alternate;
	IBOutlet NSProgressIndicator	*progress_processing;
	
	IBOutlet NSTabView	*tabView;

	//Welcome
	IBOutlet NSTextField *textField_welcome;
	IBOutlet NSTextView	 *textView_welcomeMessage;
	
	//Import
	IBOutlet NSTextField	*textField_import;
	IBOutlet NSTextView		*textView_importMessage;
	IBOutlet NSButton		*button_informationAboutImporting;
	BOOL					canImport;
	
	//Account Setup
	IBOutlet NSTextField	*textField_addAccount;
	IBOutlet NSTextView		*textView_addAccountMessage;
	IBOutlet NSPopUpButton	*popUp_services;
	IBOutlet NSTextField	*textField_serviceLabel;
	IBOutlet NSTextField	*textField_usernameLabel;
	IBOutlet NSTextField	*textField_username;
	IBOutlet NSTextField	*textField_passwordLabel;
	IBOutlet NSTextField	*textField_password;
	BOOL					setupAccountTabViewItem;
	BOOL					addedAnAccount;

	//All Done
	IBOutlet NSTextField	*textField_done;
	IBOutlet NSTextView		*textView_doneMessage;
}

+ (void)runWizard;
- (IBAction)nextTab:(id)sender;
- (IBAction)previousTab:(id)sender;
- (IBAction)pressedAlternateButton:(id)sender;
- (IBAction)promptForMultiples:(id)sender;

@end
