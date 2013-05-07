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

#import "BGICImportController.h"
#import "BGICLogImportController.h"

#import "ESAIMService.h"
#import "ESDotMacService.h"
#import "ESJabberService.h"
#import "AWBonjourService.h"

#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIStatusGroup.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIStatus.h>

#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#define ICHAT_LOCATION [@"~/Documents/iChats/" stringByExpandingTildeInPath]

@interface BGICImportController ()
-(void)startLogImport;
-(void)populateAccountPicker;
-(void)deleteAllFromiChat;
-(void)importAccountsForService:(NSString *)serviceName;
-(void)importLogs;
-(void)importStatuses;
-(void)addStatusFromString:(NSString *)statusString isAway:(BOOL)shouldBeAway withGroup:(AIStatusGroup *)parentGroup;
-(void)deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end

@implementation BGICImportController

-(void)startLogImport
{
	[backButton setEnabled:NO];
	[importProgress startAnimation:importProgress];
	[importDetails setStringValue:[AILocalizedString(@"Gathering list of transcripts", nil) stringByAppendingEllipsis]];
	[loggingPanes selectTabViewItemWithIdentifier:@"import"];
	[cancelImportButton setHidden:NO];
	fullDump = [[NSFileManager defaultManager] subpathsAtPath:ICHAT_LOCATION];
	dumpCount = [fullDump count];
	dumpLoop = 0;
	currentStep--;
	cancelImport = NO;
	[self performSelector:@selector(importLogs) withObject:nil afterDelay:0.15];	
}

// loop the accounts in Adium and add them to the popup.
// This selection will be used for the log folder target (service.account in PATH_LOGS to be exact)
-(void)populateAccountPicker
{
	[accountSelectionPopup removeAllItems];
	
	if (accountsArray == nil)
		accountsArray = [[NSMutableArray alloc] init];
	else
		[accountsArray removeAllObjects];
	
	NSArray *accountsAvailable = adium.accountController.accounts;
	
	if ([accountsAvailable count] > 0) {
		[accountSelectionPopup setHidden:NO];

		for (NSInteger accountLoop = 0; accountLoop < [accountsAvailable count]; accountLoop++) {
			AIAccount *currentAccount = [accountsAvailable objectAtIndex:accountLoop];
			[accountSelectionLabel setStringValue:AILocalizedString(@"Please select an account into which to import your transcripts:", nil)];
			[accountSelectionPopup addItemWithTitle:[NSString stringWithFormat:@"%@ (%@)", currentAccount.formattedUID, currentAccount.service.serviceID]];
			[accountsArray addObject:[NSString stringWithFormat:@"%@.%@", currentAccount.service.serviceID, currentAccount.formattedUID]];
		}		
	} else {
		// no accounts are present so we'll error this phase out
		currentStep--;
		[accountSelectionLabel setStringValue:AILocalizedString(@"Importing transcripts requires at least 1 account to be present.", nil)];
		[accountSelectionPopup setHidden:YES];
		[backButton setEnabled:YES];
		[proceedButton setEnabled:YES];
	}
}

// loop through the iChat log paths and move them all to the Trash
-(void)deleteAllFromiChat
{	
	for (NSInteger deleteLoop = 0; deleteLoop < [fullDump count]; deleteLoop++) {
		NSString *logPath = [fullDump objectAtIndex:deleteLoop];
		
		if ([logPath rangeOfString:@"DS_Store"].length == 0)
			[[NSFileManager defaultManager] trashFileAtPath:[[ICHAT_LOCATION stringByAppendingPathComponent:logPath] stringByExpandingTildeInPath]];
	}	
	
	[importDetails setStringValue:AILocalizedString(@"Your iChat transcripts have been removed.", nil)];
	[proceedButton setEnabled:YES];
}

-(void)importAccountsForService:(NSString *)serviceName
{
	// com.apple.iChat.AIM.plist -> accounts on AIM
	NSDictionary *rawPrefsFile = [NSDictionary dictionaryWithContentsOfFile:[[NSString stringWithFormat:@"~/Library/Preferences/com.apple.iChat.%@.plist", serviceName] stringByExpandingTildeInPath]];
	NSArray *accountsFromRaw = [[rawPrefsFile valueForKey:@"Accounts"] allValues];
	
	// we'll grab these momentarily and use judiciously afterwards, Bonjour is external to this to method, unlike the others
	ESAIMService *aimService = nil;
	ESDotMacService *macService = nil;
	ESJabberService *jabberService = nil;	
	
#warning iChat Import needs to be updated for MobileMe
	for (AIService *service in adium.accountController.services) {
		if ([service.serviceID isEqual:@"AIM"])
			aimService = (ESAIMService *)service;
		else if ([service.serviceID isEqual:@"Mac"])
			macService = (ESDotMacService *)service;
		else if ([service.serviceID isEqual:@"Jabber"])
			jabberService = (ESJabberService *)service;
		else if ([service.serviceID isEqual:@"Bonjour"])
			bonjourService = (AWBonjourService *)service;
	}	
	
	for (NSInteger accountLoop = 0; accountLoop < [accountsFromRaw count]; accountLoop++) {
		if (![serviceName isEqual:@"SubNet"]) {
			NSDictionary *currentAccount = [accountsFromRaw objectAtIndex:accountLoop];
			
			NSString *accountName = [currentAccount objectForKey:@"LoginAs"];
			
			AIAccount *newAcct = [adium.accountController createAccountWithService:
				([serviceName isEqual:@"Jabber"] ? (AIService *)jabberService : ([accountName rangeOfString:@"mac.com"].length > 0 ? (AIService *)macService : (AIService *)aimService))
																				 UID:accountName];
			if (newAcct == nil)
				continue;
			
			NSNumber *autoLogin = [currentAccount objectForKey:@"AutoLogin"];
			[newAcct setPreference:autoLogin
							forKey:@"isOnline"
							 group:GROUP_ACCOUNT_STATUS];
			
			NSString *serverHost = [currentAccount objectForKey:@"ServerHost"];
			if ([serverHost length] > 0)
				[newAcct setPreference:serverHost
								forKey:KEY_CONNECT_HOST
								 group:GROUP_ACCOUNT_STATUS];	
			
			NSNumber *serverPort = [currentAccount objectForKey:@"ServerPort"];
			if (serverPort)
				[newAcct setPreference:serverPort
								forKey:KEY_CONNECT_PORT
								 group:GROUP_ACCOUNT_STATUS];
			
			[adium.accountController addAccount:newAcct];

		} else {
			blockForBonjour = YES;			
			
			// iChat stores only the fact that the Default (username) account should be used and whether to auto-login
			NSDictionary *currentAccount = [accountsFromRaw objectAtIndex:accountLoop];
			bonjourAutoLogin = [[currentAccount objectForKey:@"AutoLogin"] boolValue];

			// Adium, however, has a more flexible Bonjour account configuration and we have to take this into account.
			[NSApp beginSheet:bonjourNamePromptWindow modalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
			
		}
	}
}

-(void)importLogs 
{
	if (dumpLoop == 0) {
		[importProgress setIndeterminate:NO];
		[importProgress setMaxValue:dumpCount];
		[importProgress setMinValue:0];
		[deleteLogsButton setHidden:YES];
		[cancelImportButton setHidden:NO];
	}
	
	if (dumpLoop >= dumpCount) {
		[importProgress setIndeterminate:YES];
		[importProgress stopAnimation:importProgress];
		[importDetails setStringValue:AILocalizedString(@"Transcript importing complete.", nil)];
		[importProgress setHidden:YES];
		[proceedButton setEnabled:YES];
		[deleteLogsButton setHidden:NO];
		[backButton setEnabled:YES];
		[cancelImportButton setHidden:YES];

	} else {
		NSString *logPath = [fullDump objectAtIndex:dumpLoop];
		
		if (!logImporter) logImporter = [[BGICLogImportController alloc] initWithDestination:destinationAccount];
		
		[importProgress setDoubleValue:dumpLoop];
		[importDetails setStringValue:[NSString stringWithFormat:[AILocalizedString(@"Now importing transcript %ld of %ld: %@", "%ld will be a number; %@ is a name")  stringByAppendingEllipsis],
									   dumpLoop, dumpCount, [logPath stringByDeletingPathExtension]]];
		
		if ([logPath rangeOfString:@"DS_Store"].location == NSNotFound) {
			// pass the current log's path over and let the log conversion class do it's work
			[logImporter createNewLogForPath:[[ICHAT_LOCATION stringByAppendingPathComponent:logPath] stringByExpandingTildeInPath]];
		}
	}

	if (dumpLoop < dumpCount && cancelImport == NO) {
		[self performSelector:@selector(importLogs) withObject:nil afterDelay:0.10];
	}
		
	if (cancelImport) {
		[importDetails setStringValue:[NSString stringWithFormat:AILocalizedString(@"Transcript importing cancelled. %ld of %ld transcripts already imported.", nil),
									   dumpLoop, dumpCount]];
		[importProgress setIndeterminate:YES];
		[importProgress stopAnimation:importProgress];
		[importProgress setHidden:YES];
		[cancelImportButton setHidden:YES];
		[backButton setEnabled:YES];
		[proceedButton setEnabled:YES];
	}
	
	dumpLoop++;
}

-(void)importStatuses
{
	// iChat (on 10.4 at least) stores custom statuses in a couple of arrays in it's plist
	NSDictionary *ichatPrefs = [NSDictionary dictionaryWithContentsOfFile:[@"~/Library/Preferences/com.apple.iChat.plist" stringByExpandingTildeInPath]];
		
	// loop through the availables and add them
	NSArray *customAvailable = [ichatPrefs objectForKey:@"CustomAvailableMessages"];
	
	[importStatusDetails setStringValue:[NSString stringWithFormat:[AILocalizedString(@"Now importing %lu 'Available' messages", nil) stringByAppendingEllipsis],
										 [customAvailable count]]];
	
	AIStatusGroup *availableGroup = nil;
	
	// optionally create a status group for collecting them together
	if ([createStatusGroupsButton state] == NSOnState) {
		availableGroup = [AIStatusGroup statusGroup];
		[availableGroup setTitle:AILocalizedString(@"iChat Available Messages", nil)];
		[availableGroup setStatusType:AIAvailableStatusType];
		// add to the set
		[[adium.statusController rootStateGroup] addStatusItem:availableGroup atIndex:-1];
	}

	for (NSInteger availableLoop = 0; availableLoop < [customAvailable count]; availableLoop++) {
		[self addStatusFromString:[customAvailable objectAtIndex:availableLoop] isAway:NO withGroup:availableGroup];
	}
	
	AIStatusGroup *awayGroup = nil;
	
	// optionally create a status group for collecting them together
	if ([createStatusGroupsButton state] == NSOnState) {
		awayGroup = [AIStatusGroup statusGroup];
		[awayGroup setTitle:AILocalizedString(@"iChat Away Messages", nil)];
		[awayGroup setStatusType:AIAwayStatusType];
		// add to the set
		[[adium.statusController rootStateGroup] addStatusItem:awayGroup atIndex:-1];
	}	

	// loop through the aways and add them
	NSArray *customAways = [ichatPrefs objectForKey:@"CustomAwayMessages"];
	
	[importStatusDetails setStringValue:[NSString stringWithFormat:[AILocalizedString(@"Now importing %lu 'Away' messages", nil) stringByAppendingEllipsis],
										 [customAways count]]];

	for (NSInteger awayLoop = 0; awayLoop < [customAways count]; awayLoop++) {
		[self addStatusFromString:[customAways objectAtIndex:awayLoop] isAway:YES withGroup:awayGroup];
	}
		
	[importStatusDetails setStringValue:AILocalizedString(@"Status importing is now complete.", nil)];
	[importStatusProgress stopAnimation:importStatusProgress];
	[backButton setEnabled:YES];
}

// the only difference between imported statuses is their type and reply behavior (optionally can be added to a group)
-(void)addStatusFromString:(NSString *)statusString isAway:(BOOL)shouldBeAway withGroup:(AIStatusGroup *)parentGroup
{
	AIStatus *newStatus = [AIStatus statusOfType:(shouldBeAway ? AIAwayStatusType : AIAvailableStatusType)];
	[newStatus setTitle:statusString];
	[newStatus setStatusMessage:[[NSAttributedString alloc] initWithString:statusString]];
	[newStatus setAutoReplyIsStatusMessage:(shouldBeAway ? YES : NO)];
	[newStatus setShouldForceInitialIdleTime:NO];
	
	// optionally add to a status group
	if (parentGroup == nil) {
		[adium.statusController addStatusState:newStatus];	
	} else {
		[parentGroup addStatusItem:newStatus atIndex:-1];
	}
}

+ (void)importIChatConfiguration
{
	//This is a leak.
	BGICImportController *ichatCon = [[BGICImportController alloc] initWithWindowNibName:@"ICImport"];
	[ichatCon showWindow:ichatCon];	
}

-(void)awakeFromNib {
	currentStep = 0;
	
	//Configure our background view; it should display the image transparently where our tabView overlaps it
	[backgroundView setBackgroundImage:[NSImage imageNamed:@"AdiumyButler"]];
	NSRect tabViewFrame = [assistantPanes frame];
	NSRect backgroundViewFrame = [backgroundView frame];
	tabViewFrame.origin.x -= backgroundViewFrame.origin.x;
	tabViewFrame.origin.y -= backgroundViewFrame.origin.y;
	[backgroundView setTransparentRect:tabViewFrame];	

	[importAccountsButton setState:NSOnState];
	[importStatusButton setState:NSOnState];
	[createStatusGroupsButton setState:NSOnState];
	[importLogsButton setState:NSOnState];

	[[self window] center];
	
	[assistantPanes selectTabViewItemWithIdentifier:@"start"];
	[backButton setEnabled:NO];
}

-(IBAction)openHelp:(id)sender
{
#warning This help anchor is necessary and needs a corresponding page in the book + the index needs regenerated.
	NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"ichatImport"  inBook:locBookName];
}

// this action is currently defined as returning to the start of the assistant, unchecking all and noting completed actions
-(IBAction)goBack:(id)sender
{
	currentStep = 0;
	
	[backButton setEnabled:NO];
	[proceedButton setEnabled:YES];
	[proceedButton setTitle:AILocalizedStringFromTable(@"Continue", @"Buttons", nil)]; // in case we are on the last step
	
	[importAccountsButton setState:NSOffState];
	[importStatusButton setState:NSOffState];
	[importLogsButton setState:NSOffState];
	[createStatusGroupsButton setState:NSOffState];
	
	[assistantPanes selectTabViewItemWithIdentifier:@"start"];
}

-(IBAction)proceed:(id)sender 
{
	BOOL doneSomething = NO;
	
	// when first clicked we'll determine how the workflow proceeds
	if ([[[assistantPanes selectedTabViewItem] identifier] isEqual:@"start"]) {
		// we want to increase the number of steps for each option selected
		if ([importAccountsButton state] == NSOnState)
			currentStep++;
		if ([importStatusButton state] == NSOnState)
			currentStep++;
		if ([importLogsButton state] == NSOnState)
			currentStep++;
	}
	
	if (currentStep == -1) {
		doneSomething = YES;
		currentStep++; // return to 0
		[self closeWindow:self];
	}

	if ([importAccountsButton state] == NSOnState && currentStep > 0 && !doneSomething) {
		doneSomething = YES;
		[backButton setEnabled:NO];
		[importAccountsProgress startAnimation:importAccountsProgress];
		[importAccountsDetails setStringValue:[AILocalizedString(@"Now importing all your accounts from iChat", nil) stringByAppendingEllipsis]];
		[titleField setStringValue:[AILocalizedString(@"Importing Accounts and Settings",nil) stringByAppendingEllipsis]];
		[assistantPanes selectTabViewItemWithIdentifier:@"accounts"];
		[importAccountsButton setState:NSOffState]; // reset so we don't do this again
		currentStep--;
		// do what's necessary to import here
		[self importAccountsForService:@"AIM"];
		[self importAccountsForService:@"Jabber"];
		[self importAccountsForService:@"SubNet"]; // SubNet is where iChat stores Bonjour accounts
		if (!blockForBonjour) {
			[importAccountsDetails setStringValue:AILocalizedString(@"Your accounts have been successfully imported.", nil)];
			[importAccountsProgress stopAnimation:importAccountsProgress];
			[backButton setEnabled:YES];
		}
	}

	if ([importStatusButton state] == NSOnState && currentStep > 0 && !doneSomething) {
		doneSomething = YES;
		[backButton setEnabled:NO];
		[importStatusProgress startAnimation:importStatusProgress];
		[importStatusDetails setStringValue:[AILocalizedString(@"Preparing to import your custom status messages", nil)  stringByAppendingEllipsis]];
		[titleField setStringValue:[AILocalizedString(@"Importing Statuses", nil) stringByAppendingEllipsis]];
		[assistantPanes selectTabViewItemWithIdentifier:@"statuses"];
		[importStatusButton setState:NSOffState]; // reset so we don't do this again
		currentStep--;
		[self performSelector:@selector(importStatuses) withObject:nil afterDelay:0.3];
	}
	
	if ([importLogsButton state] == NSOnState && currentStep > 0  && !doneSomething) {
		[proceedButton setEnabled:NO];
		[self populateAccountPicker];
		[titleField	setStringValue:[AILocalizedString(@"Importing iChat Transcripts", nil) stringByAppendingEllipsis]];
		[loggingPanes selectTabViewItemWithIdentifier:@"select"];
		[assistantPanes selectTabViewItemWithIdentifier:@"logs"];
		[importLogsButton setState:NSOffState]; // reset so we don't do this again
	} else if (currentStep == 0  && !doneSomething) {
		[backButton setEnabled:YES];
		[titleField	setStringValue:AILocalizedString(@"Import Finished", nil)];
		[assistantPanes selectTabViewItemWithIdentifier:@"end"];
		[proceedButton setTitle:AILocalizedString(@"Done", nil)];
		currentStep--;
	}
}

-(IBAction)completeBonjourCreation:(id)sender
{
	AIAccount *newAcct = [adium.accountController createAccountWithService:bonjourService
																		 UID:[bonjourAccountNameField stringValue]];
	if (newAcct) {								
		[newAcct setPreference:[NSNumber numberWithBool:bonjourAutoLogin]
						forKey:@"isOnline"
						 group:GROUP_ACCOUNT_STATUS];
		
		[adium.accountController addAccount:newAcct];		
	}
				
	[NSApp endSheet:bonjourNamePromptWindow];
	[bonjourNamePromptWindow orderOut:bonjourNamePromptWindow];
	[backButton setEnabled:YES];
	[importAccountsDetails setStringValue:AILocalizedString(@"Your accounts have been successfully imported.", nil)];
	[importAccountsProgress stopAnimation:importAccountsProgress];
	blockForBonjour = NO;
}

-(IBAction)selectLogAccountDestination:(id)sender
{
	destinationAccount = [accountsArray objectAtIndex:[sender indexOfSelectedItem]];
	[self performSelector:@selector(startLogImport) withObject:nil afterDelay:0.7]; // immediate == scary :)
}

// we need only set the cancel flag appropriately and the recursive importLogs will handle on its next pass
-(IBAction)cancelLogImport:(id)sender
{
	[importDetails setStringValue:[AILocalizedString(@"Cancelling transcript import", nil) stringByAppendingEllipsis]];
	cancelImport = YES;
}

-(IBAction)deleteLogs:(id)sender
{
	NSAlert *warningBeforehand = [NSAlert alertWithMessageText:AILocalizedString(@"Are you sure you want to delete all of your iChat Transcripts?", nil)
												 defaultButton:AILocalizedStringFromTable(@"Delete", @"Buttons", nil)
											   alternateButton:AILocalizedStringFromTable(@"Cancel", @"Buttons", nil)
												   otherButton:nil 
									 informativeTextWithFormat:AILocalizedString(@"All of the iChat transcripts that were imported into Adium will be moved to the Trash.", nil)];
	[warningBeforehand beginSheetModalForWindow:[self window] 
								  modalDelegate:self
								 didEndSelector:@selector(deleteAlertDidEnd:returnCode:contextInfo:) 
									contextInfo:nil];
}

- (void)deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		[importDetails setStringValue:[AILocalizedString(@"Deleting iChat Transcripts", nil) stringByAppendingEllipsis]];
		[deleteLogsButton setHidden:YES];
		[proceedButton setEnabled:NO];
		[self performSelector:@selector(deleteAllFromiChat) withObject:nil afterDelay:0.3];
	}
}

@end
