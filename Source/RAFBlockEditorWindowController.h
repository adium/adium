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
#import <Adium/AIContactObserverManager.h>
#import <Adium/AIAccountMenu.h>

@class AIListContact, AIAccount, AICompletingTextField;

@interface RAFBlockEditorWindowController : AIWindowController <AIListObjectObserver, AIAccountMenuDelegate> {
	IBOutlet NSWindow			*window;
	IBOutlet NSTableView		*table;

	IBOutlet NSWindow			*sheet;
	IBOutlet NSPopUpButton		*popUp_sheetAccounts;
	IBOutlet AICompletingTextField		*field;
	IBOutlet NSButton			*blockButton;
	IBOutlet NSButton			*cancelButton;
	IBOutlet NSTextField		*label_account;
	IBOutlet NSTextField		*label_privacyLevel;
	
	IBOutlet NSTextField		*accountText;
	IBOutlet NSTextField		*buddyText;
	IBOutlet NSTableColumn		*buddyCol;
	IBOutlet NSTableColumn		*accountCol;
	BOOL						accountColumnsVisible;
	
	IBOutlet NSPopUpButton		*stateChooser;
	IBOutlet NSPopUpButton		*popUp_accounts;
	IBOutlet NSTextField		*accountCaption;
	
	IBOutlet NSTabView			*tabView_contactList;
	
	NSMutableArray				*listContents;
	NSMutableArray				*listContentsAllAccounts;
	NSMutableDictionary			*accountStates;
	
	AIAccountMenu				*accountMenu;
	AIAccountMenu				*sheetAccountMenu;
	
	NSArray *dragItems;
}

+ (void)showWindow;

- (IBAction)addOrRemoveBlock:(id)sender;
- (IBAction)cancelBlockSheet: (id)sender;
- (IBAction)didBlockSheet: (id)sender;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

- (NSMutableArray*)listContents;
- (void)setListContents:(NSArray*)newList;
- (IBAction)setPrivacyOption:(id)sender;

@end
