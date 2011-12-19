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
	
	NSTabViewItem *tabItem_status;
	NSTabViewItem *tabItem_settings;
	
	AILocalizationTextField *label_inactivity;
	AILocalizationTextField *label_inactivitySet;
	AILocalizationTextField *label_iTunesFormat;
	
	NSBox *box_itunesElements;
	
	NSTokenField *tokenField_format;
	NSTokenField *tokenField_album;
	NSTokenField *tokenField_artist;
	NSTokenField *tokenField_composer;
	NSTokenField *tokenField_genre;
	NSTokenField *tokenField_status;
	NSTokenField *tokenField_title;
	NSTokenField *tokenField_year;
	
	AILocalizationTextField *label_instructions;
	AILocalizationTextField *label_album;
	AILocalizationTextField *label_artist;
	AILocalizationTextField *label_composer;
	AILocalizationTextField *label_genre;
	AILocalizationTextField *label_status;
	AILocalizationTextField *label_title;
	AILocalizationTextField *label_year;
	
	AISegmentedControl *button_addOrRemoveState;
	AILocalizationButton *button_addGroup;
	AILocalizationButton *button_editState;
	AIAutoScrollView *scrollView_stateList;
	AIAlternatingRowOutlineView *outlineView_stateList;
	AILocalizationButton *checkBox_idle;
	NSTextField *textField_idleMinutes;
	NSStepper *stepper_idleMinutes;
	AILocalizationButton *checkBox_autoAway;
	NSTextField *textField_autoAwayMinutes;
	NSStepper *stepper_autoAwayMinutes;
	NSPopUpButton *popUp_autoAwayStatusState;
	AILocalizationButton *checkBox_fastUserSwitching;
	NSPopUpButton *popUp_fastUserSwitchingStatusState;
	AILocalizationButton *checkBox_screenSaver;
	NSPopUpButton *popUp_screenSaverStatusState;
	AILocalizationButton *checkBox_showStatusWindow;
}

@property (assign) IBOutlet NSTabViewItem *tabItem_status;
@property (assign) IBOutlet NSTabViewItem *tabItem_settings;

@property (assign) IBOutlet AISegmentedControl *button_addOrRemoveState;
@property (assign) IBOutlet AILocalizationButton *button_addGroup;
@property (assign) IBOutlet AILocalizationButton *button_editState;
@property (assign) IBOutlet AIAutoScrollView *scrollView_stateList;
@property (assign) IBOutlet AIAlternatingRowOutlineView *outlineView_stateList;

@property (assign) IBOutlet AILocalizationButton *checkBox_idle;
@property (assign) IBOutlet NSTextField *textField_idleMinutes;
@property (assign) IBOutlet NSStepper *stepper_idleMinutes;

@property (assign) IBOutlet AILocalizationButton *checkBox_autoAway;
@property (assign) IBOutlet NSTextField *textField_autoAwayMinutes;
@property (assign) IBOutlet NSStepper *stepper_autoAwayMinutes;
@property (assign) IBOutlet NSPopUpButton *popUp_autoAwayStatusState;

@property (assign) IBOutlet AILocalizationButton *checkBox_fastUserSwitching;
@property (assign) IBOutlet NSPopUpButton *popUp_fastUserSwitchingStatusState;

@property (assign) IBOutlet AILocalizationButton *checkBox_screenSaver;
@property (assign) IBOutlet NSPopUpButton *popUp_screenSaverStatusState;

@property (assign) IBOutlet AILocalizationButton *checkBox_showStatusWindow;

@property (assign) IBOutlet AILocalizationTextField *label_inactivity;
@property (assign) IBOutlet AILocalizationTextField *label_inactivitySet;
@property (assign) IBOutlet NSTextField *label_iTunesFormat;

@property (assign) IBOutlet NSBox *box_itunesElements;

@property (assign) IBOutlet AILocalizationTextField *label_instructions;
@property (assign) IBOutlet AILocalizationTextField *label_album;
@property (assign) IBOutlet AILocalizationTextField *label_artist;
@property (assign) IBOutlet AILocalizationTextField *label_composer;
@property (assign) IBOutlet AILocalizationTextField *label_genre;
@property (assign) IBOutlet AILocalizationTextField *label_status;
@property (assign) IBOutlet AILocalizationTextField *label_title;
@property (assign) IBOutlet AILocalizationTextField *label_year;

@property (assign) IBOutlet NSTokenField *tokenField_format;
@property (assign) IBOutlet NSTokenField *tokenField_album;
@property (assign) IBOutlet NSTokenField *tokenField_artist;
@property (assign) IBOutlet NSTokenField *tokenField_composer;
@property (assign) IBOutlet NSTokenField *tokenField_genre;
@property (assign) IBOutlet NSTokenField *tokenField_status;
@property (assign) IBOutlet NSTokenField *tokenField_title;
@property (assign) IBOutlet NSTokenField *tokenField_year;

- (void)configureStateList;

- (IBAction)addOrRemoveState:(id)sender;
- (IBAction)editState:(id)sender;
- (IBAction)addGroup:(id)sender;

- (void)stateArrayChanged:(NSNotification *)notification;

- (IBAction)changeFormat:(id)sender;

@end
