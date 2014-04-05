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

#import "SetupWizardBackgroundView.h"
#import <Adium/AIWindowController.h>
#import <Adium/AIAccount.h>

@class BGICLogImportController, AWBonjourService;

// overall manager for iChat importing
@interface BGICImportController : AIWindowController {
	IBOutlet	NSTextField					*titleField;
	IBOutlet	NSTabView					*loggingPanes;
	IBOutlet	NSTabView					*assistantPanes;
	IBOutlet	NSButton					*proceedButton;
	IBOutlet	NSButton					*backButton;
	IBOutlet	SetupWizardBackgroundView	*backgroundView;

	IBOutlet	NSButton					*importAccountsButton;
	IBOutlet	NSButton					*importStatusButton;
	IBOutlet	NSButton					*createStatusGroupsButton;
	IBOutlet	NSButton					*importLogsButton;

	IBOutlet	NSTextField					*importDetails;
	IBOutlet	NSProgressIndicator			*importProgress;
	IBOutlet	NSTextField					*accountSelectionLabel;
	IBOutlet	NSPopUpButton				*accountSelectionPopup;
	IBOutlet	NSButton					*deleteLogsButton;
	IBOutlet	NSButton					*cancelImportButton;
	
	IBOutlet	NSProgressIndicator			*importStatusProgress;
	IBOutlet	NSTextField					*importStatusDetails;
	
	IBOutlet	NSProgressIndicator			*importAccountsProgress;
	IBOutlet	NSTextField					*importAccountsDetails;
	
	IBOutlet	NSWindow					*bonjourNamePromptWindow;
	IBOutlet	NSTextField					*bonjourAccountNameField;
	
	
	BGICLogImportController	*logImporter;
	
	AWBonjourService *bonjourService;				
	
	NSInteger currentStep;

	NSString *destinationAccount;
	NSMutableArray *accountsArray;
	
	NSArray *fullDump;
	NSInteger dumpCount, dumpLoop;
	BOOL cancelImport;
	
	BOOL blockForBonjour;
	BOOL bonjourAutoLogin;
}

+ (void)importIChatConfiguration;

-(IBAction)goBack:(id)sender;
-(IBAction)proceed:(id)sender;

-(IBAction)cancelLogImport:(id)sender;
-(IBAction)deleteLogs:(id)sender;
-(IBAction)selectLogAccountDestination:(id)sender;

-(IBAction)completeBonjourCreation:(id)sender;

@end
