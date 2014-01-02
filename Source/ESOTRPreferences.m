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

#import "ESOTRPreferences.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>

#import "OTRCommon.h"

#import "AdiumOTREncryption.h"

/* Adium OTR headers */
#import "ESOTRFingerprintDetailsWindowController.h"

@interface ESOTRPreferences ()
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
@end

@implementation ESOTRPreferences
@synthesize label_privateKeys;
@synthesize label_knownFingerprints;

//Preference pane properties
- (NSString *)paneIdentifier{
	return @"OTRAdvanced";
}
- (NSString *)paneName{
    return AILocalizedString(@"OTR Encryption",nil);
}
- (NSString *)nibName{
    return @"Preferences-OTREncryption";
}
- (NSImage *)paneIcon{
	return [NSImage imageNamed:@"lock-locked" forClass:[adium class]];
}

- (void)viewDidLoad
{
	viewIsOpen = YES;

	//Account Menu
	accountMenu = [AIAccountMenu accountMenuWithDelegate:self
											  submenuType:AIAccountNoSubmenu
										   showTitleVerbs:NO];
	
	//Fingerprints
	[tableView_fingerprints setDelegate:self];
	[tableView_fingerprints setDataSource:self];
	[tableView_fingerprints setTarget:self];
	[tableView_fingerprints setDoubleAction:@selector(showFingerprint:)];
	[self updateFingerprintsList];
	
	[self updatePrivateKeyList];

	[textField_privateKey setSelectable:YES];

	[self tableViewSelectionDidChange:nil];		
}

- (void)localizePane
{
	[label_privateKeys setStringValue:AILocalizedString(@"Private Keys:", nil)];
	[label_knownFingerprints setStringValue:AILocalizedString(@"Known Fingerprints:", nil)];
	[button_forgetFingerprint setTitle:AILocalizedString(@"Delete", nil)];
	[button_showFingerprint setTitle:[AILocalizedString(@"Show", nil) stringByAppendingEllipsis]];
	[[[tableView_fingerprints tableColumnWithIdentifier:@"UID"] headerCell] setStringValue:AILocalizedString(@"Name", nil)];
	[[[tableView_fingerprints tableColumnWithIdentifier:@"Status"] headerCell] setStringValue:AILocalizedString(@"Status", nil)];
	
	// button_generate already got localized when -updatePrivateKeyList got called.
}

- (void)viewWillClose
{
	viewIsOpen = NO;
	fingerprintDictArray = nil;
	accountMenu = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
										  name:Account_ListChanged
										object:nil];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	fingerprintDictArray = nil;
	filteredFingerprintDictArray = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

/*!
 * @brief Update the fingerprint display
 *
 * Called by the OTR adapter when -otr informs us the fingerprint list changed
 */
- (void)updateFingerprintsList
{
	OtrlUserState   otrg_plugin_userstate = otrg_get_userstate();

	if (viewIsOpen && otrg_plugin_userstate) {
		ConnContext		*context;
		Fingerprint		*fingerprint;

		fingerprintDictArray = [[NSMutableArray alloc] init];
		filteredFingerprintDictArray = fingerprintDictArray;
		
		for (context = otrg_plugin_userstate->context_root; context != NULL;
			 context = context->next) {

			fingerprint = context->fingerprint_root.next;
			/* If there's no fingerprint, don't add it to the known
				* fingerprints list */
			while (fingerprint) {
				char			hash[45];
				NSDictionary	*fingerprintDict;
				NSString		*UID;
				NSString		*state, *fingerprintString;

				UID = [NSString stringWithUTF8String:context->username];
				
				if (otrl_context_is_fingerprint_trusted(fingerprint)) {
					state = AILocalizedString(@"Verified", nil);
				} else {
					state = AILocalizedString(@"Unverified",nil);
				}
				
				otrl_privkey_hash_to_human(hash, fingerprint->fingerprint);
				fingerprintString = [NSString stringWithUTF8String:hash];
				
				AIAccount *account = [adium.accountController accountWithInternalObjectID:[NSString stringWithUTF8String:context->accountname]];

				fingerprintDict = [NSDictionary dictionaryWithObjectsAndKeys:
					UID, @"UID",
					state, @"Status",
					fingerprintString, @"FingerprintString",
					[NSValue valueWithPointer:fingerprint], @"FingerprintValue",
					account, @"AIAccount",
					nil];

				[fingerprintDictArray addObject:fingerprintDict];

				fingerprint = fingerprint->next;
			}
		}
		
		[tableView_fingerprints reloadData];
	}
}

/*!
 * @brief Update the key list
 *
 * Called by the OTR adapter when -otr informs us the private key list changed
 */
- (void)updatePrivateKeyList
{
	if (viewIsOpen) {
		NSString		*fingerprintString = nil;
		AIAccount		*account = ([popUp_accounts numberOfItems] ? [[popUp_accounts selectedItem] representedObject] : nil);
		
		if (account) {
			const char		*accountname = [account.internalObjectID UTF8String];
			const char		*protocol = [account.service.serviceCodeUniqueID UTF8String];
			char			*fingerprint;
			OtrlUserState	otrg_plugin_userstate;
			
			if ((otrg_plugin_userstate = otrg_get_userstate())){
				char fingerprint_buf[45];
				fingerprint = otrl_privkey_fingerprint(otrg_plugin_userstate,
													   fingerprint_buf, accountname, protocol);
				
				if (fingerprint) {
					[button_generate setLocalizedString:AILocalizedString(@"Regenerate", nil)];
					fingerprintString = [NSString stringWithFormat:AILocalizedString(@"Fingerprint: %.80s",nil), fingerprint];
				} else {
					[button_generate setLocalizedString:AILocalizedString(@"Generate", nil)];
					fingerprintString = AILocalizedString(@"No private key present", "Message to show in the Encryption OTR preferences when an account is selected which does not have a private key");
				}
			}
		}

		[textField_privateKey setStringValue:(fingerprintString ?
											  fingerprintString :
											  @"")];
	}	
}

/*!
 * @brief Generate a new private key for the currently selected account
 */
- (IBAction)generate:(id)sender
{
	AIAccount	*account = ([popUp_accounts numberOfItems] ? [[popUp_accounts selectedItem] representedObject] : nil);
	
	if (account) {
		const char		*accountname = [account.internalObjectID UTF8String];
		const char		*protocol = [account.service.serviceCodeUniqueID UTF8String];
		char			*fingerprint;
		OtrlUserState	otrg_plugin_userstate;
		
		if ((otrg_plugin_userstate = otrg_get_userstate())){
			char fingerprint_buf[45];
			fingerprint = otrl_privkey_fingerprint(otrg_plugin_userstate,
												   fingerprint_buf, accountname, protocol);
			
			if (fingerprint) {
				NSAlert *deleteKeyAlert = [NSAlert alertWithMessageText:AILocalizedString(@"Are you sure you want to generate a new OTR key?", nil)
														  defaultButton:AILocalizedString(@"Cancel", nil)
														alternateButton:AILocalizedString(@"Delete", nil)
															otherButton:nil
											  informativeTextWithFormat:AILocalizedString(@"This will permanently delete your old key and all your contacts will need to verify your fingerprint again.", "Message when regenerating an OTR key")];
				if ([deleteKeyAlert runModal] == NSAlertDefaultReturn) return;
			}
		}
		
		otrg_plugin_create_privkey([account.internalObjectID UTF8String],
								   [account.service.serviceCodeUniqueID UTF8String]);
	}
}

/*!
 * @brief Show the fingerprint for the contact selected in the fingerprints NSTableView
 */
- (IBAction)showFingerprint:(id)sender
{
	NSInteger selectedRow = [tableView_fingerprints selectedRow];
	if (selectedRow != -1) {
		NSDictionary	*fingerprintDict = [filteredFingerprintDictArray objectAtIndex:selectedRow];
		[ESOTRFingerprintDetailsWindowController showDetailsForFingerprintDict:fingerprintDict];
	}
}

/*!
 * @brief Delete the fingerprint for the contact selected in the fingerprints NSTableView
 */

- (IBAction)forgetFingerprint:(id)sender
{
	NSInteger selectedRow = [tableView_fingerprints selectedRow];
	if (selectedRow >= 0) {
		NSDictionary *fingerprintDict = [filteredFingerprintDictArray objectAtIndex:selectedRow];
		Fingerprint	*fingerprint = [[fingerprintDict objectForKey:@"FingerprintValue"] pointerValue];
		
		otrg_ui_forget_fingerprint(fingerprint);
	}
}

- (IBAction)filter:(id)sender
{
	AILogWithSignature(@"Filtering");
	NSString *needle = [field_filter stringValue];
	
	if (needle.length == 0) {
		filteredFingerprintDictArray = fingerprintDictArray;
		
		[tableView_fingerprints reloadData];
		
		return;
	}

	filteredFingerprintDictArray = [NSMutableArray array];
	
	for (NSDictionary *dict in fingerprintDictArray) {
		if ([[dict objectForKey:@"UID"] rangeOfString:needle
											  options:NSCaseInsensitiveSearch
												range:NSMakeRange(0, [[dict objectForKey:@"UID"] length])
											   locale:nil].location != NSNotFound) {
			[filteredFingerprintDictArray addObject:dict];
			continue;
		}
		if ([[dict objectForKey:@"Status"] rangeOfString:needle
												 options:NSCaseInsensitiveSearch
												   range:NSMakeRange(0, [[dict objectForKey:@"Status"] length])
												  locale:nil].location != NSNotFound) {
			[filteredFingerprintDictArray addObject:dict];
			continue;
		}
		if ([[dict objectForKey:@"FingerprintString"] rangeOfString:needle
															options:NSCaseInsensitiveSearch
															  range:NSMakeRange(0, [[dict objectForKey:@"FingerprintString"] length])
															 locale:nil].location != NSNotFound) {
			[filteredFingerprintDictArray addObject:dict];
			continue;
		}
	}
	
	[tableView_fingerprints reloadData];
}

//Fingerprint tableview ------------------------------------------------------------------------------------------------
#pragma mark Fingerprint tableview
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [filteredFingerprintDictArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ((rowIndex >= 0) && (rowIndex < [filteredFingerprintDictArray count])) {
		NSString		*identifier = [aTableColumn identifier];
		NSDictionary	*fingerprintDict = [filteredFingerprintDictArray objectAtIndex:rowIndex];
		
		if ([identifier isEqualToString:@"UID"]) {
			return [fingerprintDict objectForKey:@"UID"];
			
		} else if ([identifier isEqualToString:@"Status"]) {
			return [fingerprintDict objectForKey:@"Status"];
			
		}
	}

	return @"";
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger selectedRow = [tableView_fingerprints selectedRow];
	[button_showFingerprint setEnabled:(selectedRow != -1)];
	[button_forgetFingerprint setEnabled:(selectedRow != -1)];
}


//Account menu ---------------------------------------------------------------------------------------------------------
#pragma mark Account menu
/*!
 * @brief Account menu delegate
 */ 
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems {
	[popUp_accounts setMenu:[inAccountMenu menu]];

	BOOL hasItems = ([[popUp_accounts menu] numberOfItems] > 0);
	[popUp_accounts setEnabled:hasItems];
	[button_generate setEnabled:hasItems];
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount {
	[self updatePrivateKeyList];
}

- (NSControlSize)controlSizeForAccountMenu:(AIAccountMenu *)inAccountMenu
{
	return NSSmallControlSize;
}

@end
