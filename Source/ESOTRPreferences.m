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
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import "AIAccountMenu.h"
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

//Preference pane properties
- (NSString *)label
{
    return AILocalizedString(@"Encryption",nil);
}
- (NSString *)nibName
{
    return @"OTRPrefs";
}
- (NSImage *)image
{
	return [NSImage imageNamed:@"Lock_Locked State" forClass:[adium class]];
}

- (void)viewDidLoad
{
	viewIsOpen = YES;

	//Account Menu
	accountMenu = [[AIAccountMenu accountMenuWithDelegate:self
											  submenuType:AIAccountNoSubmenu
										   showTitleVerbs:NO] retain];
	
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

- (void)viewWillClose
{
	viewIsOpen = NO;
	[fingerprintDictArray release]; fingerprintDictArray = nil;
	[accountMenu release]; accountMenu = nil;
	
	[adium.notificationCenter removeObserver:self
										  name:Account_ListChanged
										object:nil];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[fingerprintDictArray release]; fingerprintDictArray = nil;
	[adium.notificationCenter removeObserver:self];

	[super dealloc];
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

		[fingerprintDictArray release];
		fingerprintDictArray = [[NSMutableArray alloc] init];
		
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
				
				if (context->msgstate == OTRL_MSGSTATE_ENCRYPTED &&
					context->active_fingerprint != fingerprint) {
					state = AILocalizedString(@"Unused","Word to describe an encryption fingerprint which is not currently being used");
				} else {
					TrustLevel trustLevel = otrg_plugin_context_to_trust(context);
					
					switch (trustLevel) {
						case TRUST_NOT_PRIVATE:
							state = AILocalizedString(@"Not private",nil);
							break;
						case TRUST_UNVERIFIED:
							state = AILocalizedString(@"Unverified",nil);
							break;
						case TRUST_PRIVATE:
							state = AILocalizedString(@"Private",nil);
							break;
						case TRUST_FINISHED:
							state = AILocalizedString(@"Finished",nil);
							break;
						default:
							state = @"";
							break;
					}
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
			const char		*accountname = [[account internalObjectID] UTF8String];
			const char		*protocol = [[[account service] serviceCodeUniqueID] UTF8String];
			char			*fingerprint;
			OtrlUserState	otrg_plugin_userstate;
			
			if ((otrg_plugin_userstate = otrg_get_userstate())){
				char fingerprint_buf[45];
				fingerprint = otrl_privkey_fingerprint(otrg_plugin_userstate,
													   fingerprint_buf, accountname, protocol);
				
				if (fingerprint) {
					fingerprintString = [NSString stringWithFormat:AILocalizedString(@"Fingerprint: %.80s",nil), fingerprint];
				} else {
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
	
	otrg_plugin_create_privkey([[account internalObjectID] UTF8String],
							   [[[account service] serviceCodeUniqueID] UTF8String]);
}

/*!
 * @brief Show the fingerprint for the contact selected in the fingerprints NSTableView
 */
- (IBAction)showFingerprint:(id)sender
{
	NSInteger selectedRow = [tableView_fingerprints selectedRow];
	if (selectedRow != -1) {
		NSDictionary	*fingerprintDict = [fingerprintDictArray objectAtIndex:selectedRow];
		[ESOTRFingerprintDetailsWindowController showDetailsForFingerprintDict:fingerprintDict];
	}
}

//Fingerprint tableview ------------------------------------------------------------------------------------------------
#pragma mark Fingerprint tableview
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [fingerprintDictArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ((rowIndex >= 0) && (rowIndex < [fingerprintDictArray count])) {
		NSString		*identifier = [aTableColumn identifier];
		NSDictionary	*fingerprintDict = [fingerprintDictArray objectAtIndex:rowIndex];
		
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
