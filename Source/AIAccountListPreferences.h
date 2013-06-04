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

#import <Adium/AIPreferencePane.h>
#import <Adium/AIContactObserverManager.h>
#import <Adium/AIAccountMenu.h>
#import <AIUtilities/AISegmentedControl.h>

@class AIAccountController, AIAccount, AIAutoScrollView, AIImageViewWithImagePicker;

@interface AIAccountListPreferences : AIPreferencePane <AIListObjectObserver, AIAccountMenuDelegate, NSTableViewDelegate> {
	//Account list
    IBOutlet		NSScrollView			*scrollView_accountList;
    IBOutlet		NSTableView				*tableView_accountList;
	IBOutlet		AISegmentedControl		*button_addOrRemoveAccount;
	IBOutlet		NSButton				*button_editAccount;
	IBOutlet		NSTextField				*textField_overview;

    //Account List
    NSArray							*accountArray;
    NSArray							*tempDragAccounts;

	AIAccountMenu					*accountMenu_options;
	AIAccountMenu					*accountMenu_status;
	
	NSMutableDictionary				*requiredHeightDict;
	
	NSTimer							*reconnectTimeUpdater;
}

- (IBAction)addOrRemoveAccount:(id)sender;
- (void)deleteAccount;
- (void)editAccount:(AIAccount *)inAccount;
- (IBAction)editSelectedAccount:(id)sender;
- (void)updateAccountOverview;
- (void)updateControlAvailability;
- (NSString *)statusMessageForAccount:(AIAccount *)account;
- (NSMenu *)menuForRow:(NSInteger) row;
- (NSMenu *)menuForRowIndexes:(NSIndexSet *)indexes;

@end
