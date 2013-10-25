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
