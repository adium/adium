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

#import <Adium/AIWindowController.h>

@class SetupWizardBackgroundView;

@interface AdiumSetupWizard : AIWindowController <NSTabViewDelegate> {
	IBOutlet SetupWizardBackgroundView	*backgroundView;

	IBOutlet NSButton	*button_continue;
	IBOutlet NSButton	*button_goBack;
	IBOutlet NSButton	*button_alternate;
	
	IBOutlet NSTabView	*tabView;

	//Welcome
	IBOutlet NSTextField *textField_welcome;
	IBOutlet NSTextView	 *textView_welcomeMessage;
	
	//Import
	IBOutlet NSButton		*button_informationAboutImporting;
	
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
