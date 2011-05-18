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

/*
 *	NOTE TO FUTURE MERGE
 *	Something was happening when the two commented out imports were left in place.
 *	I took it out and added the @protocol line below and everything worked fine. This
 *	will surely be a problem in the future merger though.
 */

#import "AIListController.h"
#import <Adium/AIWindowController.h>
#import <AIUtilities/AIFunctions.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AIAnimatingListOutlineView.h"
#import <AIUtilities/AIRolloverButton.h>
#import "AIFilterBarView.h"

typedef enum {
	AIContactListWindowHidingStyleNone = 0,
	AIContactListWindowHidingStyleBackground,
	AIContactListWindowHidingStyleSliding
} AIContactListWindowHidingStyle;

#define KEY_CL_WINDOW_HIDING_STYLE			@"Window Hiding Style"
#define KEY_CL_SLIDE_ONLY_IN_BACKGROUND		@"Hide By Sliding Only in Background"

#define PREF_GROUP_CONTACT_LIST_DISPLAY		@"Contact List Display"
#define KEY_DUAL_RESIZE_VERTICAL			@"Autoresize Vertical"
#define KEY_DUAL_RESIZE_HORIZONTAL			@"Autoresize Horizontal"

#define KEY_CL_ALL_SPACES					@"Show Contact List On All Spaces"

@protocol AIContactListViewController, AIInterfaceContainer;

@interface AIListWindowController : AIWindowController <AIInterfaceContainer, AIListControllerDelegate, AIRolloverButtonDelegate, NSTextFieldDelegate, NSAnimationDelegate, NSWindowDelegate> {
	BOOL                                borderless;
	
	NSSize								minWindowSize;
	IBOutlet AIAutoScrollView			*scrollView_contactList;
    IBOutlet AIAnimatingListOutlineView	*contactListView;
	AIListController					*contactListController;
	AIListObject<AIContainingObject>	*contactListRoot;
	
	AIContactListWindowHidingStyle		windowHidingStyle;
	AIWindowLevel						windowLevel;
	BOOL								slideOnlyInBackground;
	// refers to the GUI preference.  Sometimes this is expressed as dock-like 
	// sliding instead, sometimes as orderOut:-type hiding.
	BOOL								windowShouldBeVisibleInBackground; 
	BOOL								showOnAllSpaces;

	// used by the "show contact list" event behavior to prevent the contact list
	// from hiding during the amount of time it is to be shown
	BOOL								preventHiding;
	BOOL								overrodeWindowLevel;
	NSInteger							previousWindowLevel;

	//this needs to be stored because we turn the shadow off when the window slides offscreen
	BOOL								listHasShadow; 
	
	BOOL								permitSlidingInForeground;
	AIRectEdgeMask						windowSlidOffScreenEdgeMask;
	NSScreen							*windowLastScreen;
	NSTimer								*slideWindowIfNeededTimer;
	BOOL								waitingToSlideOnScreen;

	NSRect								oldFrame;
	NSScreen							*currentScreen;
	NSRect								currentScreenFrame;
	
	NSViewAnimation						*windowAnimation;
	CGFloat								previousAlpha;
	
	AIListWindowController				*attachToBottom;
	
	// Filter bar
	BOOL									filterBarExpandedGroups;
	BOOL									filterBarIsVisible;
	BOOL									filterBarShownAutomatically;
	NSViewAnimation							*filterBarAnimation;
	NSArray									*filterBarPreviouslySelected;
	BOOL									typeToFindEnabled;
	
	IBOutlet	AIFilterBarView				*filterBarView;
	IBOutlet	NSSearchField				*searchField;
	IBOutlet	AIRolloverButton			*button_cancelFilterBar;
}

// Create additional windows
+ (AIListWindowController *)listWindowControllerForContactList:(id<AIContainingObject>)contactList;

- (AIListController *)listController;
- (AIListOutlineView *)contactListView;
- (id<AIContainingObject>) contactList;
- (void)setContactList:(id<AIContainingObject>)contactList;
- (void)close:(id)sender;

// Dock-like hiding
- (void)slideWindowOnScreenWithAnimation:(BOOL)flag;
- (BOOL)shouldSlideWindowOnScreen;
- (BOOL)shouldSlideWindowOffScreen;

- (AIRectEdgeMask)slidableEdgesAdjacentToWindow;
- (void)slideWindowOffScreenEdges:(AIRectEdgeMask)rectEdgeMask;
- (void)slideWindowOnScreen;
- (void)setPreventHiding:(BOOL)newPreventHiding;
- (BOOL)windowShouldHideOnDeactivate;
- (AIRectEdgeMask)windowSlidOffScreenEdgeMask;
- (void)moveWindowToPoint:(NSPoint)inOrigin;
- (NSScreen *)windowLastScreen;
- (NSRect)savedFrame;
- (void)setSavedFrame:(NSRect)frame;

- (BOOL)animationShouldStart:(NSAnimation *)animation;
- (void)animationDidEnd:(NSAnimation*)animation;

@property (nonatomic, retain) NSViewAnimation *windowAnimation;

// Window snapping
- (void)snapToOtherWindows;
- (NSPoint)snapTo:(NSWindow *)neighborWindow with:(NSRect)window saveTo:(NSPoint)location;
- (NSPoint)windowSpacing;


	void manualWindowMoveToPoint(NSWindow *inWindow,
								 NSPoint targetPoint,
								 AIRectEdgeMask windowSlidOffScreenEdgeMask,
								 BOOL keepOnScreen);

// Contact Filtering

- (void)toggleFindPanel:(id)sender;
- (IBAction)hideFilterBar:(id)sender;
- (IBAction)filterContacts:(id)sender;

- (void)showFilterBarWithAnimation:(BOOL)useAnimation;
- (void)hideFilterBarWithAnimation:(BOOL)useAnimation;

@property (nonatomic, retain ) NSViewAnimation *filterBarAnimation;

@end
