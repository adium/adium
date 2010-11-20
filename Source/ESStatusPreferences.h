//
//  ESStatusPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 2/26/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "AIPreferencePane.h"

@class AIAutoScrollView, AIStatus, AIAlternatingRowOutlineView;

@interface ESStatusPreferences : AIPreferencePane {
	//Status state tableview
	IBOutlet	NSButton			*button_editState;
	IBOutlet	NSButton			*button_addGroup;
	IBOutlet	NSSegmentedControl	*button_addOrRemoveState;

	IBOutlet	AIAlternatingRowOutlineView		*outlineView_stateList;
	IBOutlet	AIAutoScrollView				*scrollView_stateList;
	
	NSArray				*draggingItems;
	
	//Other controls
	IBOutlet	NSButton		*checkBox_idle;
	IBOutlet	NSTextField		*textField_idleMinutes;
	IBOutlet    NSStepper       *stepper_idleMinutes;

	IBOutlet	NSButton		*checkBox_autoAway;
	IBOutlet	NSPopUpButton	*popUp_autoAwayStatusState;
	IBOutlet	NSTextField		*textField_autoAwayMinutes;
	IBOutlet    NSStepper       *stepper_autoAwayMinutes;
	BOOL						showingSubmenuItemInAutoAway;

	IBOutlet	NSButton		*checkBox_fastUserSwitching;
	IBOutlet	NSPopUpButton	*popUp_fastUserSwitchingStatusState;
	BOOL						showingSubmenuItemInFastUserSwitching;

	IBOutlet	NSButton		*checkBox_screenSaver;
	IBOutlet	NSPopUpButton	*popUp_screenSaverStatusState;
	BOOL						showingSubmenuItemInScreenSaver;
	
	IBOutlet	NSButton		*checkBox_showStatusWindow;
}

- (void)configureStateList;

- (IBAction)addOrRemoveState:(id)sender;
- (IBAction)editState:(id)sender;
- (IBAction)addGroup:(id)sender;

- (void)stateArrayChanged:(NSNotification *)notification;

@end
