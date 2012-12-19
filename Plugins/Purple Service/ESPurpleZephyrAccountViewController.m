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

#import "ESPurpleZephyrAccountViewController.h"
#import "ESPurpleZephyrAccount.h"

@implementation ESPurpleZephyrAccountViewController

- (NSString *)nibName{
    return @"ESPurpleZephyrAccountView";
}

/*!
 * @brief Update control enabledness based on current state.
 */
- (void)updateControlAvailability
{
    BOOL selection = ([tableView_servers selectedRow] != -1);
	[button_addOrRemoveServer setEnabled:selection forSegment:1];
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];

	[checkBox_exportAnyone setState:[[account preferenceForKey:KEY_ZEPHYR_EXPORT_ANYONE group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_exportSubs setState:[[account preferenceForKey:KEY_ZEPHYR_EXPORT_SUBS group:GROUP_ACCOUNT_STATUS] boolValue]];

	[checkBox_launchZhm setState:[[account preferenceForKey:KEY_ZEPHYR_LAUNCH_ZHM group:GROUP_ACCOUNT_STATUS] boolValue]];

	[textField_exposure setStringValue:[account preferenceForKey:KEY_ZEPHYR_EXPOSURE group:GROUP_ACCOUNT_STATUS]];
	[textField_encoding setStringValue:[account preferenceForKey:KEY_ZEPHYR_ENCODING group:GROUP_ACCOUNT_STATUS]];

    [self updateControlAvailability];
}

- (IBAction)changedPreference:(id)sender
{	
	if (sender == checkBox_exportAnyone) {
		[account setPreference:[NSNumber numberWithBool:[sender state]]
						forKey:KEY_ZEPHYR_EXPORT_ANYONE
						 group:GROUP_ACCOUNT_STATUS];

	} else if (sender == checkBox_exportSubs) {
		[account setPreference:[NSNumber numberWithBool:[sender state]]
						forKey:KEY_ZEPHYR_EXPORT_SUBS
						 group:GROUP_ACCOUNT_STATUS];

	} else if (sender == checkBox_launchZhm) {
		[account setPreference:[NSNumber numberWithBool:[sender state]]
						forKey:KEY_ZEPHYR_LAUNCH_ZHM
						 group:GROUP_ACCOUNT_STATUS];

	} else if (sender == textField_exposure) {
		NSString *exposure = [sender stringValue];
		[account setPreference:([exposure length] ? exposure : nil)
						forKey:KEY_ZEPHYR_EXPOSURE
						 group:GROUP_ACCOUNT_STATUS];

	} else if (sender == textField_encoding) {
		NSString *encoding = [sender stringValue];

		[account setPreference:([encoding length] ? encoding : nil)
						forKey:KEY_ZEPHYR_ENCODING
						 group:GROUP_ACCOUNT_STATUS];

	} else {
		[super changedPreference:sender];
	}
}

// We are the data source for the table we use to show server names
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSArray *ray = [account preferenceForKey:KEY_ZEPHYR_SERVERS group:GROUP_ACCOUNT_STATUS];
    NSParameterAssert(rowIndex >= 0 && rowIndex < [ray count]);

    return [ray objectAtIndex:rowIndex];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSMutableArray *ray = [[account preferenceForKey:KEY_ZEPHYR_SERVERS group:GROUP_ACCOUNT_STATUS] mutableCopy];
    NSParameterAssert(rowIndex >= 0 && rowIndex < [ray count]);

    [ray replaceObjectAtIndex:rowIndex withObject:anObject];

    [account setPreference:ray
                    forKey:KEY_ZEPHYR_SERVERS
                     group:GROUP_ACCOUNT_STATUS];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[account preferenceForKey:KEY_ZEPHYR_SERVERS group:GROUP_ACCOUNT_STATUS] count];
}

- (IBAction)addOrRemoveRowToServerList:(id)sender {
	NSInteger selectedSegment = [sender selectedSegment];
	
	switch (selectedSegment) {
		case 0:
			[self addRowToServerList];
			break;
		case 1:
			[self removeSelectedRowFromServerList];
			break;
	}
}

/*!
 * @brief Add a new server to the list of servers.
 */
- (void)addRowToServerList {
    NSArray *ray = [account preferenceForKey:KEY_ZEPHYR_SERVERS group:GROUP_ACCOUNT_STATUS];

    [account setPreference:[ray arrayByAddingObject:@""]
                    forKey:KEY_ZEPHYR_SERVERS
                     group:GROUP_ACCOUNT_STATUS];

    [tableView_servers reloadData];
    [tableView_servers selectRowIndexes:[NSIndexSet indexSetWithIndex:[ray count]] byExtendingSelection:NO];
    [tableView_servers editColumn:0 row:[ray count] withEvent:nil select:YES];
}

/*!
 * @brief Remove the selected row from the list of servers.
 */
- (void)removeSelectedRowFromServerList {
    NSInteger idx = [tableView_servers selectedRow];
    if (idx != -1) {
        NSMutableArray *ray = [[account preferenceForKey:KEY_ZEPHYR_SERVERS group:GROUP_ACCOUNT_STATUS] mutableCopy];
        
        [ray removeObjectAtIndex:idx];
        
        [account setPreference:ray
                        forKey:KEY_ZEPHYR_SERVERS
                         group:GROUP_ACCOUNT_STATUS];
        [tableView_servers reloadData];
    }
}

/*!
 * @brief Selection change
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateControlAvailability];
}

@end
