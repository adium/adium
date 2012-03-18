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

#import <Adium/AIContactObserverManager.h>
#import "AISegmentedControl.h"

@class AICompletingTextField;

@interface RAFBlockEditorWindowController : AIPreferencePane <AIListObjectObserver, NSTableViewDelegate, NSTableViewDataSource> {
	NSMutableArray				*listContents;
	NSArray						*accountArray;
}
@property (weak) IBOutlet NSTableView *accountTable;
@property (weak) IBOutlet NSTableView *contactTable;
@property (weak) IBOutlet NSMatrix *privacyLevel;
@property (weak) IBOutlet NSTextField *label_information;
@property (weak) IBOutlet AISegmentedControl *addRemoveContact;

@property (strong) IBOutlet NSWindow *sheet;
@property (weak) IBOutlet AICompletingTextField *addContactField;
@property (weak) IBOutlet AILocalizationButton *addContact;
@property (weak) IBOutlet AILocalizationButton *cancelSheet;
@property (weak) IBOutlet AILocalizationTextField *label_contact;
@property (weak) IBOutlet AILocalizationTextField *label_blockInformation;

+ (void)showWindow;

- (IBAction)addOrRemoveBlock:(id)sender;
- (IBAction)cancelBlockSheet:(id)sender;
- (IBAction)didBlockSheet:(id)sender;
- (IBAction)setPrivacyOption:(id)sender;

@end
