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

#import "AIHideAccountsWindowController.h"

#import "AIAccountControllerProtocol.h"
#import <Adium/AIServiceIcons.h>
#import <AIUtilities/AIAlternatingRowTableView.h>
#import "AIAccount.h"

@implementation AIHideAccountsWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if((self = [super initWithWindowNibName:windowNibName])) {
		accounts = adium.accountController.accounts;
		array_hideAccounts = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)awakeFromNib
{
	//Register preference observer first so values will be correct for the following calls
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (object)
		return;
	
	[array_hideAccounts removeAllObjects];
	[array_hideAccounts addObjectsFromArray:[prefDict objectForKey:KEY_HIDE_ACCOUNT_CONTACTS]];

	[tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [accounts count];
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex
{
	if([aTableColumn.identifier isEqualToString:@"checkbox"]) {
		BOOL enabled = [array_hideAccounts containsObject:[[accounts objectAtIndex:rowIndex] internalObjectID]];
		return [NSNumber numberWithBool:enabled];
	} else if([aTableColumn.identifier isEqualToString:@"icon"]) {
		return [AIServiceIcons serviceIconForObject:[accounts objectAtIndex:rowIndex]
											   type:AIServiceIconLarge
										  direction:AIIconNormal];
	} else if([aTableColumn.identifier isEqualToString:@"accountName"]) {
		return [[accounts objectAtIndex:rowIndex] explicitFormattedUID];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if([aTableColumn.identifier isEqualToString:@"checkbox"]) {
		NSString *accountID = [[accounts objectAtIndex:rowIndex] internalObjectID];
		
		if ([array_hideAccounts containsObject:accountID]) {
			[array_hideAccounts removeObject:accountID];
		} else {
			[array_hideAccounts addObject:accountID];
		}
		
		[adium.preferenceController setPreference:[array_hideAccounts copy]
										   forKey:KEY_HIDE_ACCOUNT_CONTACTS
											group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	}
}

- (IBAction)done:(id)sender
{
	[NSApp endSheet:self.window];
}

@end
