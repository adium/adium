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

#import "AIPreferenceCollectionView.h"
@class AIPreferenceCollectionView, AIHighlightingTextField;

/*!
 * @class AIPreferenceWindowController
 * @brief Adium preference window controller
 *
 * Implements the main preference window.  This controller displays the preference panes registered with the
 * preference controller sorted by category.
 */
@interface AIPreferenceWindowController : NSWindowController <NSWindowDelegate, AIPreferenceCollectionViewDelegate> {
	NSArray *generalPaneArray;
	NSArray *appearancePaneArray;
	NSArray *eventsPaneArray;
	NSArray *advancedPaneArray;
	AIPreferenceCollectionView *generalCV;
	AIPreferenceCollectionView *appearanceCV;
	AIPreferenceCollectionView *eventsCV;
	AIPreferenceCollectionView *advancedCV;
	NSArrayController *generalController;
	NSArrayController *appearanceController;
	NSArrayController *eventsController;
	NSArrayController *advancedController;
	
	SKIndexRef skIndex;
	BOOL completePosting;
	BOOL commandHandling;
	
	//Window
	NSWindow *suggestionsWindow;
	NSMutableArray *_trackingAreas;
	id _localMouseDownEventMonitor;
	id _lostFocusObserver;
	id _localMouseUpEventHandler;
	NSWindow *window;

	NSView *allPanes;
	NSMutableDictionary *panes;
	NSView *itemPrototypeView;
	NSSearchField *searchField;
	NSTextField *label_general;
	NSTextField *label_advanced;
	NSTextField *label_events;
	NSTextField *label_appearance;
	NSSegmentedControl *button_showAll;
	AIHighlightingTextField *_selectedView;
	
	NSMenu *paneMenu;
	
	NSMutableArray *AI_topLevelObjects;
}

@property (copy) NSArray *generalPaneArray;
@property (copy) NSArray *appearancePaneArray;
@property (copy) NSArray *eventsPaneArray;
@property (copy) NSArray *advancedPaneArray;
@property (assign) IBOutlet AIPreferenceCollectionView *generalCV;
@property (assign) IBOutlet AIPreferenceCollectionView *appearanceCV;
@property (assign) IBOutlet AIPreferenceCollectionView *eventsCV;
@property (assign) IBOutlet AIPreferenceCollectionView *advancedCV;
@property (assign) IBOutlet NSArrayController *generalController;
@property (assign) IBOutlet NSArrayController *appearanceController;
@property (assign) IBOutlet NSArrayController *eventsController;
@property (assign) IBOutlet NSArrayController *advancedController;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *allPanes;
@property (assign) IBOutlet NSView *itemPrototypeView;

@property (assign) IBOutlet NSSearchField *searchField;

@property (assign) IBOutlet NSTextField *label_general;
@property (assign) IBOutlet NSTextField *label_advanced;
@property (assign) IBOutlet NSTextField *label_events;
@property (assign) IBOutlet NSTextField *label_appearance;
@property (assign) IBOutlet NSSegmentedControl *button_showAll;


+ (void)openPreferenceWindow;
+ (void)openPreferenceWindowToCategoryWithIdentifier:(NSString *)identifier;
+ (void)closePreferenceWindow;

- (IBAction)showAllPanes:(id)sender;

@end
