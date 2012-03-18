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

#import "AIPreferencePane.h"

@class AIAutoScrollView, AIStatus, AIAlternatingRowOutlineView, AISegmentedControl;

@interface ESStatusPreferences : AIPreferencePane <NSTokenFieldDelegate> {
	NSArray		*draggingItems;
	
	BOOL		showingSubmenuItemInAutoAway;
	BOOL		showingSubmenuItemInFastUserSwitching;
	BOOL		showingSubmenuItemInScreenSaver;
}

@property (weak) IBOutlet NSTabViewItem *tabItem_status;
@property (weak) IBOutlet NSTabViewItem *tabItem_settings;

@property (weak) IBOutlet AISegmentedControl *button_addOrRemoveState;
@property (weak) IBOutlet AILocalizationButton *button_addGroup;
@property (weak) IBOutlet AILocalizationButton *button_editState;
@property (weak) IBOutlet AIAutoScrollView *scrollView_stateList;
@property (weak) IBOutlet AIAlternatingRowOutlineView *outlineView_stateList;

@property (weak) IBOutlet AILocalizationButton *checkBox_idle;
@property (weak) IBOutlet NSTextField *textField_idleMinutes;
@property (weak) IBOutlet NSStepper *stepper_idleMinutes;

@property (weak) IBOutlet AILocalizationButton *checkBox_autoAway;
@property (weak) IBOutlet NSTextField *textField_autoAwayMinutes;
@property (weak) IBOutlet NSStepper *stepper_autoAwayMinutes;
@property (weak) IBOutlet NSPopUpButton *popUp_autoAwayStatusState;

@property (weak) IBOutlet AILocalizationButton *checkBox_fastUserSwitching;
@property (weak) IBOutlet NSPopUpButton *popUp_fastUserSwitchingStatusState;

@property (weak) IBOutlet AILocalizationButton *checkBox_screenSaver;
@property (weak) IBOutlet NSPopUpButton *popUp_screenSaverStatusState;

@property (weak) IBOutlet AILocalizationButton *checkBox_showStatusWindow;

@property (weak) IBOutlet AILocalizationTextField *label_inactivity;
@property (weak) IBOutlet AILocalizationTextField *label_inactivitySet;
@property (weak) IBOutlet NSTextField *label_iTunesFormat;

@property (weak) IBOutlet NSBox *box_itunesElements;

@property (weak) IBOutlet AILocalizationTextField *label_instructions;
@property (weak) IBOutlet AILocalizationTextField *label_album;
@property (weak) IBOutlet AILocalizationTextField *label_artist;
@property (weak) IBOutlet AILocalizationTextField *label_composer;
@property (weak) IBOutlet AILocalizationTextField *label_genre;
@property (weak) IBOutlet AILocalizationTextField *label_status;
@property (weak) IBOutlet AILocalizationTextField *label_title;
@property (weak) IBOutlet AILocalizationTextField *label_year;

@property (weak) IBOutlet NSTokenField *tokenField_format;
@property (weak) IBOutlet NSTokenField *tokenField_album;
@property (weak) IBOutlet NSTokenField *tokenField_artist;
@property (weak) IBOutlet NSTokenField *tokenField_composer;
@property (weak) IBOutlet NSTokenField *tokenField_genre;
@property (weak) IBOutlet NSTokenField *tokenField_status;
@property (weak) IBOutlet NSTokenField *tokenField_title;
@property (weak) IBOutlet NSTokenField *tokenField_year;

- (void)configureStateList;

- (IBAction)addOrRemoveState:(id)sender;
- (IBAction)editState:(id)sender;
- (IBAction)addGroup:(id)sender;

- (void)stateArrayChanged:(NSNotification *)notification;

- (IBAction)changeFormat:(id)sender;

@end
