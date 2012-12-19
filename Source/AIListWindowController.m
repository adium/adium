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

#import "AIListWindowController.h"

#import "AISCLViewPlugin.h"
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIDockControllerProtocol.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIProxyListObject.h>
#import <Adium/AIUserIcons.h>
#import <AIUtilities/AIDockingWindow.h>
#import <AIUtilities/AIEventAdditions.h>
#import <Adium/AIContactList.h>
#import <Adium/AIContactHidingController.h>

#import "AIAutoScrollView.h"
#import "AISearchFieldCell.h"

#define	KEY_HIDE_CONTACT_LIST_GROUPS			@"Hide Contact List Groups"

#define SLIDE_ALLOWED_RECT_EDGE_MASK			(AIMinXEdgeMask | AIMaxXEdgeMask) /* Screen edges on which sliding is allowde */
#define DOCK_HIDING_MOUSE_POLL_INTERVAL			0.1f /* Interval at which to check the mouse position for sliding */
#define	WINDOW_SLIDING_DELAY					0.2f /* Time after the mouse is in the right place before the window slides on screen */
#define WINDOW_ALIGNMENT_TOLERANCE				2.0f /* Threshold distance far the window from an edge to be considered on it */
#define MOUSE_EDGE_SLIDE_ON_DISTANCE			1.1f /* ??? */
#define WINDOW_SLIDING_MOUSE_DISTANCE_TOLERANCE 3.0f /* Distance the mouse must be from the window's frame to be considered outside it */

#define SNAP_DISTANCE							15.0f /* Distance beween one window's edge and another's at which they should snap together */

@interface AIListWindowController ()
- (id)initWithContactList:(id<AIContainingObject>)contactList;
+ (NSString *)nibName;
+ (void)updateScreenSlideBoundaryRect:(id)sender;
- (BOOL)shouldSlideWindowOffScreen_mousePositionStrategy;
- (void)slideWindowIfNeeded:(id)sender;
- (BOOL)shouldSlideWindowOnScreen_mousePositionStrategy;
- (void)delayWindowSlidingForInterval:(NSTimeInterval)inDelayTime;

- (void)showFilterBarWithAnimation:(BOOL)flag;
- (void)hideFilterBarWithAnimation:(BOOL)flag;
- (void)animateFilterBarWithDuration:(CGFloat)duration;

- (void)screenParametersChanged:(NSNotification *)notification;
@end

@implementation AIListWindowController

@synthesize windowAnimation, filterBarAnimation;

static NSMutableDictionary *screenSlideBoundaryRectDictionary = nil;

+ (void)initialize
{
	if ([self isEqual:[AIListWindowController class]]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateScreenSlideBoundaryRect:) 
													 name:NSApplicationDidChangeScreenParametersNotification 
												   object:nil];
		
		[self updateScreenSlideBoundaryRect:nil];
	}
}

+ (AIListWindowController *)listWindowControllerForContactList:(id<AIContainingObject>)contactList
{
	return [[self alloc] initWithContactList:contactList];
}

- (id)initWithContactList:(id<AIContainingObject>)contactList
{
	if ((self = [self initWithWindowNibName:[[self class] nibName]])) {
		preventHiding = NO;
		previousAlpha = 0;
		typeToFindEnabled = ![[NSUserDefaults standardUserDefaults] boolForKey:@"AIDisableContactListTypeToFind"];

		[NSBundle loadNibNamed:@"Filter Bar" owner:self];
		
		[self setContactList:contactList];
	}
	
	return self;	
}

- (id<AIContainingObject> )contactList
{
	return (contactListRoot ? contactListRoot : [contactListController contactList]);
}

- (AIListController *) listController
{
	return contactListController;
}

- (AIListOutlineView *)contactListView
{
	return contactListView;
}

- (void)setContactList:(id<AIContainingObject>)inContactList
{
	if (inContactList != contactListRoot) {
		contactListRoot = inContactList;
	}
}

//Our window nib name
+ (NSString *)nibName
{
    return @"";
}

- (Class)listControllerClass
{
	return [AIListController class];
}

- (void)dealloc
{
	[searchField setDelegate:nil];
	
	[filterBarAnimation stopAnimation];
	[filterBarAnimation setDelegate:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[windowAnimation stopAnimation];
	[windowAnimation setDelegate:nil];
	
	[contactListController close];
}

- (NSString *)adiumFrameAutosaveName
{
	AILogWithSignature(@"My autosave name is %@",[NSString stringWithFormat:@"Contact List:%@", [[self contactList] contentsBasedIdentifier]]);
	return [NSString stringWithFormat:@"Contact List:%@", [[self contactList] contentsBasedIdentifier]];
}

//Setup the window after it has loaded
- (void)windowDidLoad
{	
	contactListController = [[[self listControllerClass] alloc] initWithContactList:[self contactList]
																	  inOutlineView:contactListView
																	   inScrollView:scrollView_contactList 
																		   delegate:self];

	//super's windowDidLoad will restore our location, which is based upon the contactListRoot
	[super windowDidLoad];

    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];
	[[self window] useOptimizedDrawing:YES];

	minWindowSize = [[self window] minSize];
	[contactListController setMinWindowSize:minWindowSize];

	[[self window] setTitle:AILocalizedString(@"Contacts","Contact List window title")];

    //Watch for resolution and screen configuration changes
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(screenParametersChanged:) 
												 name:NSApplicationDidChangeScreenParametersNotification 
											   object:nil];
	
	// Filter bar	
	filterBarExpandedGroups = NO;
	filterBarIsVisible = NO;
	filterBarShownAutomatically = NO;
	self.filterBarAnimation = nil;
	filterBarPreviouslySelected = nil;
	[searchField setDelegate:self];
	

	//Show the contact list initially even if it is at a screen edge and supposed to slide out of view
	[self delayWindowSlidingForInterval:5];

	id<AIPreferenceController> preferenceController = adium.preferenceController;
    //Observe preference changes
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
	
	//Preference code below assumes layout is done before theme.
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_LAYOUT];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_THEME];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationDidUnhide:) 
												 name:NSApplicationDidUnhideNotification 
											   object:nil];

	//Substitute an otherwise identical copy of the search field for one of our class. We don't want to globally pose as class; we just want it here.
	[NSKeyedArchiver setClassName:@"AISearchFieldCell" forClass:[NSSearchFieldCell class]];
	[searchField setCell:[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:[searchField cell]]]];	
	[NSKeyedArchiver setClassName:@"NSSearchFieldCell" forClass:[NSSearchFieldCell class]];
	
	/* Get rid of the "x" button in the search field that would clear the search.
	 * It conflicts with the other "x" button that hides the entire bar, and clearing a few characters is probably not necessary.
	 */
	[[searchField cell] setCancelButtonCell:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidResignMain:)
												 name:NSWindowDidResignMainNotification
											   object:[self window]];
	
	//Save our frame immediately for sliding purposes
	[self setSavedFrame:[[self window] frame]];
}

//Close the contact list window
- (void)windowWillClose:(NSNotification *)notification
{
	if ([self windowSlidOffScreenEdgeMask] != AINoEdges) {
		//Hide the window while it's still off-screen
		[[self window] setAlphaValue:0.0f];
		AILogWithSignature(@"Setting to alpha 0 while the window is offscreen");
		
		//Then move it back on screen so that we'll save the proper position in -[AIWindowController windowWillClose:]
		[self slideWindowOnScreenWithAnimation:NO];
	}
	
	// When closing the contact list while a search is in progress, reset visibility first.
	if (![[searchField stringValue] isEqualToString:@""]) {
		[searchField setStringValue:@""];
		[self filterContacts:searchField];
	}

	[super windowWillClose:notification];

	//Invalidate the dock-like hiding timer
	[slideWindowIfNeededTimer invalidate];

    //Stop observing
	[adium.preferenceController unregisterPreferenceObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

    //Tell the interface to unload our window
    NSNotificationCenter *adiumNotificationCenter = [NSNotificationCenter defaultCenter];
    [adiumNotificationCenter postNotificationName:Interface_ContactListDidResignMain object:self];
	[adiumNotificationCenter postNotificationName:Interface_ContactListDidClose object:self];
}

NSInteger levelForAIWindowLevel(AIWindowLevel windowLevel)
{
	NSInteger				level;

	switch (windowLevel) {
		case AINormalWindowLevel: level = NSNormalWindowLevel; break;
		case AIFloatingWindowLevel: level = NSFloatingWindowLevel; break;
		case AIDesktopWindowLevel: level = kCGBackstopMenuLevel; break;
		default: level = NSNormalWindowLevel; break;
	}
	
	return level;
}

- (void)setWindowLevel:(NSInteger)level
{
	[[self window] setLevel:level];
}

// A "stationary" window stays pinned to the desktop during ExposŽ
- (void)setCollectionBehaviorOfWindow:(NSWindow *)window showOnAllSpaces:(BOOL)allSpaces isStationary:(BOOL)stationary
{
	NSWindowCollectionBehavior behavior = NSWindowCollectionBehaviorDefault;

	if (allSpaces)
		behavior |= NSWindowCollectionBehaviorCanJoinAllSpaces;
	if (stationary)
		behavior |= NSWindowCollectionBehaviorStationary;

	[window setCollectionBehavior:behavior];
}

//Preferences have changed
- (void)preferencesChangedForGroup:(NSString *)group 
							   key:(NSString *)key
							object:(AIListObject *)object 
					preferenceDict:(NSDictionary *)prefDict 
						 firstTime:(BOOL)firstTime
{
	BOOL shouldRevealWindowAndDelaySliding = NO;
	
	// Make sure we're not getting an object-specific update.
	if (object != nil)
			return;

    if ([group isEqualToString:PREF_GROUP_CONTACT_LIST]) {
		windowLevel = [[prefDict objectForKey:KEY_CL_WINDOW_LEVEL] intValue];
		[self setWindowLevel:levelForAIWindowLevel(windowLevel)];

		listHasShadow = [[prefDict objectForKey:KEY_CL_WINDOW_HAS_SHADOW] boolValue];
		[[self window] setHasShadow:listHasShadow];
		
		windowHidingStyle = [[prefDict objectForKey:KEY_CL_WINDOW_HIDING_STYLE] intValue];
		slideOnlyInBackground = [[prefDict objectForKey:KEY_CL_SLIDE_ONLY_IN_BACKGROUND] boolValue];
		
		[[self window] setHidesOnDeactivate:(windowHidingStyle == AIContactListWindowHidingStyleBackground)];
		
	    showOnAllSpaces = [[prefDict objectForKey:KEY_CL_ALL_SPACES] boolValue];
		[self setCollectionBehaviorOfWindow:[self window]
							showOnAllSpaces:showOnAllSpaces
							   isStationary:(windowLevel == AIDesktopWindowLevel)];
		
		if (windowHidingStyle == AIContactListWindowHidingStyleSliding) {
			if (!slideWindowIfNeededTimer) {
				slideWindowIfNeededTimer = [NSTimer scheduledTimerWithTimeInterval:DOCK_HIDING_MOUSE_POLL_INTERVAL
																			 target:self
																		   selector:@selector(slideWindowIfNeeded:)
																		   userInfo:nil
																			repeats:YES];
			}

		} else if (slideWindowIfNeededTimer) {
            [slideWindowIfNeededTimer invalidate];
			slideWindowIfNeededTimer = nil;
		}

		[contactListController setShowTooltips:[[prefDict objectForKey:KEY_CL_SHOW_TOOLTIPS] boolValue]];
		[contactListController setShowTooltipsInBackground:[[prefDict objectForKey:KEY_CL_SHOW_TOOLTIPS_IN_BACKGROUND] boolValue]];
    }
	
	//Auto-Resizing
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		AIContactListWindowStyle	windowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
		BOOL	autoResizeHorizontally = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue];
		BOOL	autoResizeVertically = YES;
		NSInteger		forcedWindowWidth, maxWindowWidth;
		NSInteger		forcedWindowHeight, maxWindowHeight;
		
		//Determine how to handle vertical autosizing. AIAppearancePreferences must match this behavior for this to make sense.
		switch (windowStyle) {
			case AIContactListWindowStyleStandard:
			case AIContactListWindowStyleBorderless:
			case AIContactListWindowStyleGroupChat:
				//Standard and borderless don't have to vertically autosize, but they might
				autoResizeVertically = [[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE] boolValue];
				break;
			case AIContactListWindowStyleGroupBubbles:
			case AIContactListWindowStyleContactBubbles:
			case AIContactListWindowStyleContactBubbles_Fitted:
				//The bubbles styles don't show a window; force them to autosize by leaving autoResizeVertically == YES
				break;
		}
		
		/* Avoid the bouncing effect when scrolling on Lion. This looks very bad when using a borderless window.
		 * TODO: (10.7+) remove this if
		 */
		if (windowStyle != AIContactListWindowStyleStandard && [scrollView_contactList respondsToSelector:@selector(setVerticalScrollElasticity:)]) {
			[scrollView_contactList setVerticalScrollElasticity:1]; // NSScrollElasticityNone
		}

		if (autoResizeHorizontally) {
			//If autosizing, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH determines the maximum width; no forced width.
			maxWindowWidth = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] integerValue];
			forcedWindowWidth = -1;
		} else {
			if (windowStyle == AIContactListWindowStyleStandard/* || windowStyle == AIContactListWindowStyleBorderless*/) {
				//In the non-transparent non-autosizing modes, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH has no meaning
				maxWindowWidth = 10000;
				forcedWindowWidth = -1;
			} else {
				//In the transparent non-autosizing modes, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH determines the width of the window
				forcedWindowWidth = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] integerValue];
				maxWindowWidth = forcedWindowWidth;
			}
		}
		
		if (autoResizeVertically) {
			//If autosizing, KEY_LIST_LAYOUT_VERTICAL_HEIGHT determines the maximum height; no forced height.
			maxWindowHeight = [[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_HEIGHT] integerValue];
			forcedWindowHeight = -1;
		} else {
			if (windowStyle == AIContactListWindowStyleStandard/* || windowStyle == AIContactListWindowStyleBorderless*/) {
				//In the non-transparent non-autosizing modes, KEY_LIST_LAYOUT_VERTICAL_HEIGHT has no meaning
				maxWindowHeight = 10000;
				forcedWindowHeight = -1;
			} else {
				//In the transparent non-autosizing modes, KEY_LIST_LAYOUT_VERTICAL_HEIGHT determines the height of the window
				forcedWindowHeight = [[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_HEIGHT] integerValue];
				maxWindowHeight = forcedWindowHeight;
			}
		}
        
		//Show the resize indicator if either or both of the autoresizing options is NO
		[[self window] setShowsResizeIndicator:!(autoResizeVertically && autoResizeHorizontally)];
		
		/*
		 Reset the minimum and maximum sizes in case [contactListController contactListDesiredSizeChanged]; doesn't cause a sizing change
		 (and therefore the min and max sizes aren't set there).
		 */
		NSSize	thisMinimumSize = minWindowSize;
		NSSize	thisMaximumSize = NSMakeSize(maxWindowWidth, maxWindowHeight);
		NSRect	currentFrame = [[self window] frame];
		
		if (forcedWindowWidth != -1 || forcedWindowHeight != -1) {
			/*
			 If we have a forced width but we are doing no autoresizing, set our frame now so we don't have to be doing checks every time
			 contactListDesiredSizeChanged is called.
			 */
			if (!(autoResizeVertically || autoResizeHorizontally)) {
				if (forcedWindowWidth != -1)
					thisMinimumSize.width = forcedWindowWidth;
				if (forcedWindowHeight != -1)
					thisMinimumSize.height = forcedWindowHeight;
				[[self window] setFrame:NSMakeRect(currentFrame.origin.x,currentFrame.origin.y,forcedWindowWidth,currentFrame.size.height)
								display:YES
								animate:NO];
			}
		}
		
		//If vertically resizing, make the minimum and maximum heights the current height
		if (autoResizeVertically) {
			thisMinimumSize.height = currentFrame.size.height;
			thisMaximumSize.height = currentFrame.size.height;
		}
		
		//If horizontally resizing, make the minimum and maximum widths the current width
		if (autoResizeHorizontally) {
			thisMinimumSize.width = currentFrame.size.width;
			thisMaximumSize.width = currentFrame.size.width;			
		}

		/* For a standard window, inform the contact list that, if asked, it wants to be 175 pixels or more.
		 * A maximum width less than this can make the list autosize smaller, but if it has its druthers it'll be a sane
		 * size.
		 */
		[contactListView setMinimumDesiredWidth:((windowStyle == AIContactListWindowStyleStandard) ? 175 : 0)];

		[[self window] setMinSize:thisMinimumSize];
		[[self window] setMaxSize:thisMaximumSize];
		
		contactListController.autoResizeHorizontally = autoResizeHorizontally;
		contactListController.autoResizeVertically = autoResizeVertically;

		[contactListController setForcedWindowWidth:forcedWindowWidth];
		[contactListController setMaxWindowWidth:maxWindowWidth];
		
		[contactListController setForcedWindowHeight:forcedWindowHeight];
		[contactListController setMaxWindowHeight:maxWindowHeight];
		
		// let this happen at the beginning of the next runloop. The View needs to configure itself before we start forcing it to a size.
		dispatch_async(dispatch_get_main_queue(), ^{
			@autoreleasepool {
				[contactListController contactListDesiredSizeChanged];
			}
		});
		
		if (!firstTime) {
			shouldRevealWindowAndDelaySliding = YES;
		}
	}

	//Window opacity
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		CGFloat opacity = (CGFloat)[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_OPACITY] doubleValue];		
		[contactListController setBackgroundOpacity:opacity];

		/*
		 * If we're using fitted bubbles, we want the default behavior of the winodw, which is to respond to clicks on opaque areas
		 * and ignore clicks on transparent areas.  If we're using any other style, we never want to ignore clicks.
		 */
		BOOL forceWindowToCatchMouseEvents = ([[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] integerValue] != AIContactListWindowStyleContactBubbles_Fitted);
		if (forceWindowToCatchMouseEvents)
			[[self window] setIgnoresMouseEvents:NO];

		if (!firstTime) {
			shouldRevealWindowAndDelaySliding = YES;
		}
	}
	
	if ([group isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY]) {
		[contactListController setUseContactListGroups:![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue]];
	}
	
	//Layout and Theme ------------
	BOOL groupLayout = ([group isEqualToString:PREF_GROUP_LIST_LAYOUT]);
	BOOL groupTheme = ([group isEqualToString:PREF_GROUP_LIST_THEME]);
    if (groupLayout || (groupTheme && !firstTime)) { /* We don't want to execute this code twice when initializing */
		NSDictionary	*layoutDict = [adium.preferenceController preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
		NSDictionary	*themeDict = [adium.preferenceController preferencesForGroup:PREF_GROUP_LIST_THEME];

		//Layout only
		if (groupLayout) {
			NSInteger iconSize = [[layoutDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] integerValue];
			[AIUserIcons setListUserIconSize:NSMakeSize(iconSize,iconSize)];
		}
			
		//Theme only
		if (groupTheme || firstTime) {
			NSString		*imagePath = [themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_PATH];
			
			//Background Image
			if (imagePath && [imagePath length] && [[themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED] boolValue]) {
				[contactListView setBackgroundImage:[[NSImage alloc] initWithContentsOfFile:imagePath]];
			} else {
				[contactListView setBackgroundImage:nil];
			}
		}

		EXTENDED_STATUS_STYLE statusStyle = [[layoutDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_STYLE] intValue];
		EXTENDED_STATUS_POSITION statusPosition = [[layoutDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_POSITION] intValue];
		contactListController.autoResizeHorizontallyWithIdleTime = 
		 ((statusStyle == IDLE_ONLY || statusStyle == IDLE_AND_STATUS) &&
		  (statusPosition == EXTENDED_STATUS_POSITION_BESIDE_NAME || statusPosition == EXTENDED_STATUS_POSITION_BOTH));
		[contactListController contactListDesiredSizeChanged];

		//Both layout and theme
		[contactListController updateLayoutFromPrefDict:layoutDict andThemeFromPrefDict:themeDict];

		if (!firstTime) {
			shouldRevealWindowAndDelaySliding = YES;
		}
	}

	if (shouldRevealWindowAndDelaySliding) {
		[self delayWindowSlidingForInterval:2];
		[self slideWindowOnScreenWithAnimation:NO];

	} else {
		//Do a slide immediately if needed (to display as per our new preferneces)
		[self slideWindowIfNeeded:nil];
		
	}
}

- (IBAction)performDefaultActionOnSelectedObject:(AIListObject *)selectedObject sender:(NSOutlineView *)sender
{	
    if ([selectedObject isKindOfClass:[AIListGroup class]]) {
        //Expand or collapse the group
		for (AIProxyListObject *proxyObject in selectedObject.proxyObjects) {
			if ([sender isItemExpanded:proxyObject]) {
				[sender collapseItem:proxyObject];
			} else {
				[sender expandItem:proxyObject];					
			}
		}

	} else if ([selectedObject isMemberOfClass:[AIListBookmark class]]) {
		//Hide any tooltip the contactListController is currently showing
		[contactListController hideTooltip];

		[(AIListBookmark *)selectedObject openChat];

	} else if ([selectedObject isKindOfClass:[AIListContact class]]) {
		//Hide any tooltip the contactListController is currently showing
		[contactListController hideTooltip];

		//Open a new message with the contact
		[adium.interfaceController setActiveChat:[adium.chatController openChatWithContact:(AIListContact *)selectedObject
																			onPreferredAccount:YES]];
    }
}

- (BOOL) canCustomizeToolbar
{
	return NO;
}

//Interface Container --------------------------------------------------------------------------------------------------
#pragma mark Interface Container
//Close this container
- (void)close:(id)sender
{
    //In response to windowShouldClose, the interface controller releases us.  At that point, no one would be retaining
	//this instance of AIContactListWindowController, and we would be deallocated.  The call to [self window] will
	//crash if we are deallocated.  A dirty, but functional fix is to temporarily retain ourself here.

    if ([self windowShouldClose:nil]) {
        [[self window] close];
    }
}

- (void)makeActive:(id)sender
{
	[[self window] makeKeyAndOrderFront:self];
}


//Contact list brought to front
- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:Interface_ContactListDidBecomeMain object:self];
}

//Contact list sent back
- (void)windowDidResignKey:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:Interface_ContactListDidResignMain object:self];
}

- (void)showWindowInFrontIfAllowed:(BOOL)inFront
{
	//Always show for three seconds at least if we're told to show
	[self delayWindowSlidingForInterval:3];

	//Call super to actually do the showing
	[super showWindowInFrontIfAllowed:inFront];
	
	NSWindow	*window = [self window];
	
	if ([self windowSlidOffScreenEdgeMask] != AINoEdges) {
		[self slideWindowOnScreenWithAnimation:NO];
	}
	
	windowSlidOffScreenEdgeMask = AINoEdges;
	
	currentScreen = [window screen];
	currentScreenFrame = [currentScreen frame];

	if ([[NSScreen screens] count] && 
		(currentScreen == [[NSScreen screens] objectAtIndex:0])) {
		currentScreenFrame.size.height -= [[NSApp mainMenu] menuBarHeight];
	}

	//Ensure the window is displaying at the proper level and exposŽ setting
	[self setWindowLevel:levelForAIWindowLevel(windowLevel)];	
}

- (void)setSavedFrame:(NSRect)frame
{
	oldFrame = frame;
}

- (NSRect)savedFrame
{
	return oldFrame;
}

// Auto-resizing support ------------------------------------------------------------------------------------------------
#pragma mark Auto-resizing support

- (void)respondToScreenParametersChanged:(NSNotification *)notification
{
	NSWindow	*window = [self window];
	
	NSScreen	*windowScreen = [window screen];
	if (!windowScreen) {
		if ([[NSScreen screens] containsObject:windowLastScreen]) {
			windowScreen = windowLastScreen;
		} else {
			windowLastScreen = nil;
			windowScreen = [NSScreen mainScreen];
		}
	}
	
	NSRect newScreenFrame = [[screenSlideBoundaryRectDictionary objectForKey:[NSValue valueWithNonretainedObject:windowScreen]] rectValue];

	if ([self windowSlidOffScreenEdgeMask] != AINoEdges) {
		NSRect newWindowFrame = AIRectByAligningRect_edge_toRect_edge_([window frame], (NSRectEdge)[self windowSlidOffScreenEdgeMask],
																	   newScreenFrame, (NSRectEdge)[self windowSlidOffScreenEdgeMask]);
		[[self window] setFrame:newWindowFrame display:NO];

		[self delayWindowSlidingForInterval:2];
		[self slideWindowOnScreenWithAnimation:NO];
		
	}

	[contactListController contactListDesiredSizeChanged];
	
	currentScreen = [window screen];
	currentScreenFrame = newScreenFrame;
	[self setSavedFrame:[window frame]];
}

- (void)screenParametersChanged:(NSNotification *)notification
{
	/* Wait until the next run loop so the class method has definitely updated our screen sliding borders. */
	[self performSelector:@selector(respondToScreenParametersChanged:)
			   withObject:notification
			   afterDelay:0];
}

// Printing
#pragma mark Printing
- (void)adiumPrint:(id)sender
{
	[contactListView print:sender];
}

// Dock-like hiding -----------------------------------------------------------------------------------------------------
#pragma mark Dock-like hiding

+ (void)updateScreenSlideBoundaryRect:(id)sender
{
	NSArray *screens = [NSScreen screens];
	NSInteger numScreens = [screens count];
	
	screenSlideBoundaryRectDictionary = [[NSMutableDictionary alloc] initWithCapacity:numScreens];

	if (numScreens > 0) {
		//The menubar screen is a special case - the menubar is not a part of the rect we're interested in
		NSScreen	*menubarScreen = [screens objectAtIndex:0];
		NSRect		screenSlideBoundaryRect;

		screenSlideBoundaryRect = [menubarScreen frame];
		screenSlideBoundaryRect.size.height = NSMaxY([menubarScreen visibleFrame]) - NSMinY([menubarScreen frame]);
		[screenSlideBoundaryRectDictionary setObject:[NSValue valueWithRect:screenSlideBoundaryRect]
											  forKey:[NSValue valueWithNonretainedObject:menubarScreen]];

		for (NSInteger i = 1; i < numScreens; i++) {
			NSScreen *screen = [screens objectAtIndex:i];
			[screenSlideBoundaryRectDictionary setObject:[NSValue valueWithRect:[screen frame]]
												  forKey:[NSValue valueWithNonretainedObject:screen]];
		}
	}
}

/*!
 * @brief Adium unhid
 *
 * If the contact list is open but not visible when we unhide, we should always display it; it should not, however, steal focus.
 */
- (void)applicationDidUnhide:(NSNotification *)notification
{
	if (![[self window] isVisible]) {
		[self showWindowInFrontIfAllowed:NO];
	}
}

- (BOOL)windowShouldHideOnDeactivate
{
	return (windowHidingStyle == AIContactListWindowHidingStyleBackground);
}

/*!
 * @brief Called on a delay by -[self slideWindowIfNeeded:]
 *
 * This is a separate function so that the call to it may be canceled if the mouse doesn't
 * remain in position long enough.
 */
- (void)slideWindowOnScreenAfterDelay
{
	waitingToSlideOnScreen = NO;

	//If we're hiding the window (generally) but now sliding it on screen, make sure it's on top
	if (windowHidingStyle == AIContactListWindowHidingStyleSliding) {
		[self setWindowLevel:NSFloatingWindowLevel];
		[self setCollectionBehaviorOfWindow:[self window]
							showOnAllSpaces:YES
							   isStationary:YES];
		
		overrodeWindowLevel = YES;
	}
	
	[self slideWindowOnScreen];	
}

/*!
 * @brief Check what behavior the window should perform and initiate it
 *
 * Called regularly by a repeating timer to check mouse position against window position.
 */
- (void)slideWindowIfNeeded:(id)sender
{
	if ([self shouldSlideWindowOnScreen]) {
		if (!waitingToSlideOnScreen) {
			[self performSelector:@selector(slideWindowOnScreenAfterDelay)
					   withObject:nil
					   afterDelay:WINDOW_SLIDING_DELAY];
			waitingToSlideOnScreen = YES;
		}
	} else {
		if (waitingToSlideOnScreen) {
			/* If we were waiting to slide on screen but the mouse moved out of position too soon,
			 * cancel the selector which would slide us on screen.
			 */
			waitingToSlideOnScreen = NO;
			[[self class] cancelPreviousPerformRequestsWithTarget:self
														 selector:@selector(slideWindowOnScreenAfterDelay)
														   object:nil];
		}

		if ([self shouldSlideWindowOffScreen]) {
			AIRectEdgeMask adjacentEdges = [self slidableEdgesAdjacentToWindow];
			
			if (adjacentEdges & (AIMinXEdgeMask | AIMaxXEdgeMask)) {
				[self slideWindowOffScreenEdges:(adjacentEdges & (AIMinXEdgeMask | AIMaxXEdgeMask))];
			} else {
				[self slideWindowOffScreenEdges:adjacentEdges];
			}
			
			/* If we're hiding the window (generally) but now sliding it off screen, set it to kCGBackstopMenuLevel and don't
			 * let it participate in exposŽ.
			 */
			if (overrodeWindowLevel &&
				windowHidingStyle == AIContactListWindowHidingStyleSliding) {
				[self setWindowLevel:kCGBackstopMenuLevel];
				
				[[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
				
				overrodeWindowLevel = YES;
			}
			
		} else if (overrodeWindowLevel &&
				   ([self slidableEdgesAdjacentToWindow] == AINoEdges) &&
				   ([self windowSlidOffScreenEdgeMask] == AINoEdges)) {
			/* If the window level was overridden at some point and now we:
			 *   1. Are on screen AND
			 *   2. No longer have any edges eligible for sliding
			 * we should restore our window level.
			 */
			[self setWindowLevel:levelForAIWindowLevel(windowLevel)];
			
			[[self window] setCollectionBehavior:showOnAllSpaces ? NSWindowCollectionBehaviorCanJoinAllSpaces : NSWindowCollectionBehaviorDefault];
			
			overrodeWindowLevel = NO;
		}
	}
}

- (BOOL)shouldSlideWindowOnScreen
{
	BOOL shouldSlide = NO;
	
	if (([self windowSlidOffScreenEdgeMask] != AINoEdges) &&
		![NSApp isHidden]) {
		if (slideOnlyInBackground && [NSApp isActive]) {
			//We only slide while in the background, and the app is not in the background. Slide on screen.
			shouldSlide = YES;

		} else if (windowHidingStyle == AIContactListWindowHidingStyleSliding) {
			//Slide on screen if the mouse position indicates we should
			shouldSlide = [self shouldSlideWindowOnScreen_mousePositionStrategy];
		} else {
			//It's slid off-screen... and it's not supposed to be sliding at all.  Slide back on screen!
			shouldSlide = YES;
		}
	}
	return shouldSlide;
}

- (BOOL)shouldSlideWindowOffScreen
{
	BOOL shouldSlide = NO;
	
	if ((windowHidingStyle == AIContactListWindowHidingStyleSliding) &&
		!preventHiding &&
		([self windowSlidOffScreenEdgeMask] == AINoEdges) &&
		(!(slideOnlyInBackground && [NSApp isActive]))) {
		shouldSlide = [self shouldSlideWindowOffScreen_mousePositionStrategy];
	}

	return shouldSlide;
}

// slide off screen if the window is aligned to a screen edge and the mouse is not in the strip of screen 
// you'd get by translating the window along the screen edge.  This is the dock's behavior.
- (BOOL)shouldSlideWindowOffScreen_mousePositionStrategy
{
	BOOL shouldSlideOffScreen = NO;
	
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	NSPoint mouseLocation = [NSEvent mouseLocation];
	
	AIRectEdgeMask slidableEdgesAdjacentToWindow = [self slidableEdgesAdjacentToWindow];
	NSRectEdge screenEdge;
	for (screenEdge = 0; screenEdge < 4; screenEdge++) {		
		if (slidableEdgesAdjacentToWindow & (1 << screenEdge)) {
			CGFloat distanceMouseOutsideWindow = AISignedExteriorDistanceRect_edge_toPoint_(windowFrame, AIOppositeRectEdge_(screenEdge), mouseLocation);
			if (distanceMouseOutsideWindow > WINDOW_SLIDING_MOUSE_DISTANCE_TOLERANCE)
				shouldSlideOffScreen = YES;
		}
	}
	
	/* Don't allow the window to slide off if the user is dragging
	 * This method is hacky and does not completely work.  is there a way to detect if the mouse is down?
	 */
	NSEventType currentEventType = [[NSApp currentEvent] type];
	if (currentEventType == NSLeftMouseDragged ||
		currentEventType == NSRightMouseDragged ||
		currentEventType == NSOtherMouseDragged ||
		currentEventType == NSPeriodic) {
		shouldSlideOffScreen = NO;
	}	
	
	return shouldSlideOffScreen;
}

// note: may be inaccurate when mouse is up against an edge 
- (NSScreen *)screenForPoint:(NSPoint)point
{
	for (NSScreen *pointScreen in [NSScreen screens]) {
		if (NSPointInRect(point, NSInsetRect([pointScreen frame], -1, -1)))
			return pointScreen;
	}
	return nil;
}	

- (NSRect)squareRectWithCenter:(NSPoint)point sideLength:(CGFloat)sideLength
{
	return NSMakeRect(point.x - sideLength*0.5f, point.y - sideLength*0.5f, sideLength, sideLength);
}

- (BOOL)pointIsInScreenCorner:(NSPoint)point
{
	BOOL inCorner = NO;
	NSScreen *menubarScreen = [[NSScreen screens] objectAtIndex:0];
	CGFloat menubarHeight = NSMaxY([menubarScreen frame]) - NSMaxY([menubarScreen visibleFrame]); // breaks if the dock is at the top of the screen (i.e. if the user is insane)
	
	NSRect screenFrame = [[self screenForPoint:point] frame];
	NSPoint lowerLeft  = screenFrame.origin;
	NSPoint upperRight = NSMakePoint(NSMaxX(screenFrame), NSMaxY(screenFrame));
	NSPoint lowerRight = NSMakePoint(upperRight.x, lowerLeft.y);
	NSPoint upperLeft  = NSMakePoint(lowerLeft.x, upperRight.y);
	
	CGFloat sideLength = menubarHeight * 2.0f;
	inCorner = (NSPointInRect(point, [self squareRectWithCenter:lowerLeft sideLength:sideLength])
				|| NSPointInRect(point, [self squareRectWithCenter:lowerRight sideLength:sideLength])
				|| NSPointInRect(point, [self squareRectWithCenter:upperLeft sideLength:sideLength])
				|| NSPointInRect(point, [self squareRectWithCenter:upperRight sideLength:sideLength]));
	
	return inCorner;
}

/*!
 * @brief Should the window be slid on screen given the mouse's position?
 *
 * This method will never return YES of the cl is slid into a corner, which shouldn't happen, or if the mouse is in a corner.
 *
 * @result YES if the mouse is against all edges of the screen where we previously slid the window and not in a corner.
 */
- (BOOL)shouldSlideWindowOnScreen_mousePositionStrategy
{
	if ([self windowSlidOffScreenEdgeMask] != AINoEdges) {
		NSPoint mouseLocation = [NSEvent mouseLocation];
		//Initially, assume the mouse is not in an appropriate position
		BOOL	mouseNearSlideOffEdges = NO;

		NSRectEdge	screenEdge;
		NSRect		screenSlideBoundaryRect = [[screenSlideBoundaryRectDictionary objectForKey:[NSValue valueWithNonretainedObject:windowLastScreen]] rectValue];
		/* Only look at the screen in which the mouse currently resides.
		 * The mouse may be in no screen if it is over the menu bar.
		 */
		if (NSPointInRect(mouseLocation, screenSlideBoundaryRect)) {
			//Check each edge
			for (screenEdge = 0; screenEdge < 4; screenEdge++) {
				//But we only care about an edge off of which the window has slid
				if (windowSlidOffScreenEdgeMask & (1 << screenEdge)) {
					CGFloat mouseOutsideSlideBoundaryRectDistance = AISignedExteriorDistanceRect_edge_toPoint_(screenSlideBoundaryRect,
																											   screenEdge,
																											   mouseLocation);
					//The mouse must be within MOUSE_EDGE_SLIDE_ON_DISTANCE of every slid-off edge to bring the window back on-screen
					if(mouseOutsideSlideBoundaryRectDistance < -MOUSE_EDGE_SLIDE_ON_DISTANCE) {
						mouseNearSlideOffEdges = NO;
						break;
					} else {
						mouseNearSlideOffEdges = YES;							
					}
				}
			}
		}

		return mouseNearSlideOffEdges && ![self pointIsInScreenCorner:mouseLocation];

	} else {
		return NO;
	}
}

#pragma mark Dock-like hiding

- (NSScreen *)windowLastScreen
{
	return windowLastScreen;
}

- (BOOL)animationShouldStart:(NSAnimation *)animation
{
	if(![animation isEqual:windowAnimation])
		return YES;
	
	//Whenever an animation starts, we should be using the normal shadow setting
	[[self window] setHasShadow:listHasShadow];
	
	//Don't let docking interfere with the animation
	if ([[self window] respondsToSelector:@selector(setDockingEnabled:)])
		[(id)[self window] setDockingEnabled:NO];
	
	if (windowSlidOffScreenEdgeMask == AINoEdges) {
		[[self window] setAlphaValue:previousAlpha];
		AILogWithSignature(@"Set window to previous alpha of %f", previousAlpha);
	}

	return YES;
}

- (void)animationDidEnd:(NSAnimation*)animation
{
	if([animation isEqual:windowAnimation]) {
		//Restore docking behavior	
		if ([[self window] respondsToSelector:@selector(setDockingEnabled:)])
			[(id)[self window] setDockingEnabled:YES];
		
		if (windowSlidOffScreenEdgeMask == AINoEdges) {
			//When the window is offscreen, its horizontal autosizing can't occur. Size it now.
			[contactListController contactListDesiredSizeChanged];

		} else {
			//Offscreen windows should be told not to cast a shadow
			[[self window] setHasShadow:NO];	

			previousAlpha = [[self window] alphaValue];
			[[self window] setAlphaValue:0.0f];
			AILogWithSignature(@"Previous alpha is now %f; window set to alpha 0.0 ", previousAlpha);
		}
		
		self.windowAnimation = nil;
	}
	
	if (animation == filterBarAnimation) {
		if (filterBarIsVisible) {
			// If the filter bar is already visible, remove it from its superview.
			[filterBarView removeFromSuperview];
			
			// Set the first responder back to the contact list view.
			[[self window] makeFirstResponder:contactListView];
			
			[contactListView selectItemsInArray:filterBarPreviouslySelected];
			
			// Since this wasn't a user-initiated selection change, we need to post a notification for it.
			[[NSNotificationCenter defaultCenter] postNotificationName:Interface_ContactSelectionChanged
																object:nil];
			
			filterBarPreviouslySelected = nil;
			
			filterBarIsVisible = NO;
		} else {
			// If the filter bar wasn't visible, make it the first responder.
			[[self window] makeFirstResponder:searchField]; 
			
			// Set the filter bar as the next responder so the chain works for things like the info inspector
			[filterBarView setNextResponder:contactListView];
			
			// Bring the contact list to front, in case the find command was triggered from another window like the info inspector
			[[self window] makeKeyAndOrderFront:nil];
			
			filterBarPreviouslySelected = [contactListView arrayOfSelectedItems];
			
			filterBarIsVisible = YES;
		}
		
		// Let the contact list controller know that our size has changed.
		[contactListController contactListDesiredSizeChanged];
		
		// We're no longer animating.
		self.filterBarAnimation = nil;
	}
}

- (BOOL)keepListOnScreenWhenSliding
{
	return NO;
}

/*!
 * @brief Slide the window to a given point
 *
 * windowSlidOffScreenEdgeMask must already be set to the resulting offscreen mask (or 0 if the window is sliding on screen)
 *
 * A standard window (titlebar window) will crash if told to setFrame completely offscreen. Also, using our own movement we can more precisely
 * control the movement speed and acceleration.
 */
- (void)slideWindowToPoint:(NSPoint)targetPoint
{	
	NSWindow				*myWindow = [self window];
	NSScreen				*windowScreen;

	windowScreen = [myWindow screen];
	if (!windowScreen) windowScreen = [self windowLastScreen];
	if (!windowScreen) windowScreen = [NSScreen mainScreen];
	
	NSRect	frame = [myWindow frame];
	CGFloat yOff = (targetPoint.y + NSHeight(frame)) - NSMaxY([windowScreen frame]);
	if (windowScreen == [[NSScreen screens] objectAtIndex:0]) yOff -= [[NSApp mainMenu] menuBarHeight];
	if (yOff > 0) targetPoint.y -= yOff;
	
	frame.origin = targetPoint;
	
	if ((windowSlidOffScreenEdgeMask != AINoEdges) &&
		[self keepListOnScreenWhenSliding]) {
		switch (windowSlidOffScreenEdgeMask) {
			case AIMinXEdgeMask:
				frame.origin.x += 1;
				break;
			case AIMaxXEdgeMask:
				frame.origin.x -= 1;
				break;
			case AIMaxYEdgeMask:
				frame.origin.y -= 1;
				break;
			case AIMinYEdgeMask:
				frame.origin.y += 1;
				break;
			case AINoEdges:
				//We'll never get here
				break;
		}
	}
	
	if (windowAnimation) {
		[windowAnimation stopAnimation];
		self.windowAnimation = nil;
	}

	self.windowAnimation = [[NSViewAnimation alloc] initWithViewAnimations:
							 [NSArray arrayWithObject:
							  [NSDictionary dictionaryWithObjectsAndKeys:
							   myWindow, NSViewAnimationTargetKey,
							   [NSValue valueWithRect:frame], NSViewAnimationEndFrameKey,
							   nil]]];
	[windowAnimation setFrameRate:0.0f];
	[windowAnimation setDuration:0.25f];
	[windowAnimation setDelegate:self];
	[windowAnimation setAnimationBlockingMode:NSAnimationNonblocking];
	[windowAnimation startAnimation];
}

- (void)moveWindowToPoint:(NSPoint)inOrigin
{
	[[self window] setFrameOrigin:inOrigin];

	if (windowSlidOffScreenEdgeMask == AINoEdges) {
		/* When the window is offscreen, there are no constraints on its size, for example it will grow downwards as much as
		* it needs to to accomodate new rows.  Now that it's onscreen, there are constraints.
		*/
		[contactListController contactListDesiredSizeChanged];
		[[self window] setAlphaValue:previousAlpha];
		AILogWithSignature(@"Set window to previous alpha of %f", previousAlpha);
	}
}

static BOOL AIScreenRectEdgeAdjacentToAnyOtherScreen(NSRectEdge edge, NSScreen *screen)
{
	NSArray  *screens = [NSScreen screens];
	NSUInteger numScreens = [screens count];
	if (numScreens > 1) {
		NSRect	screenSlideBoundaryRect = [[screenSlideBoundaryRectDictionary objectForKey:[NSValue valueWithNonretainedObject:screen]] rectValue];
		NSRect	shiftedScreenFrame = screenSlideBoundaryRect;
		BOOL	isAdjacent = NO;
		
		switch(edge) {
			case NSMinXEdge:
				shiftedScreenFrame.origin.x -= 1;
				break;
			case NSMinYEdge:
				shiftedScreenFrame.origin.y -= 1;
				break;
			case NSMaxXEdge:
				shiftedScreenFrame.size.width += 1;
				break;
			case NSMaxYEdge:
				shiftedScreenFrame.size.height += 1;
				break;
		}

		for (NSInteger i = 0; i < numScreens; i++) {
			NSScreen *otherScreen = [screens objectAtIndex:i];
			if (otherScreen != screen) {
				if (NSIntersectsRect([otherScreen frame], shiftedScreenFrame)) {
					isAdjacent = YES;
					break;
				}
			}	
		}

		return isAdjacent;
		
	} else {
		return NO;
	}
}

/*!
 * @brief Find the mask specifying what edges are potentially slidable for our window
 *
 * @result AIRectEdgeMask, which is 0 if no edges are slidable
 */
- (AIRectEdgeMask)slidableEdgesAdjacentToWindow
{
	AIRectEdgeMask slidableEdges = 0;

	NSWindow *window = [self window];
	NSRect	 windowFrame = [window frame];	
	NSScreen *windowScreen = [window screen];
	NSRect	 screenSlideBoundaryRect = [[screenSlideBoundaryRectDictionary objectForKey:[NSValue valueWithNonretainedObject:windowScreen]] rectValue];

	NSRectEdge edge;
	for (edge = 0; edge < 4; edge++) {
		if ((SLIDE_ALLOWED_RECT_EDGE_MASK & (1 << edge)) &&
			(AIRectIsAligned_edge_toRect_edge_tolerance_(windowFrame,
														 edge,
														 screenSlideBoundaryRect,
														 edge,
														 WINDOW_ALIGNMENT_TOLERANCE)) &&
			(!AIScreenRectEdgeAdjacentToAnyOtherScreen(edge, windowScreen))) { 
			slidableEdges |= (1 << edge);
		}
	}
	
	return slidableEdges;
}

- (void)slideWindowOffScreenEdges:(AIRectEdgeMask)rectEdgeMask
{
	NSWindow	*window;
	NSRect		newWindowFrame;
	NSRectEdge	edge;

	if (rectEdgeMask == AINoEdges)
		return;

	window = [self window];
	newWindowFrame = [window frame];

	[self setSavedFrame:newWindowFrame];

	windowLastScreen = [window screen];

	NSRect screenSlideBoundaryRect = [[screenSlideBoundaryRectDictionary objectForKey:[NSValue valueWithNonretainedObject:windowLastScreen]] rectValue];

	for (edge = 0; edge < 4; edge++) {
		if (rectEdgeMask & (1 << edge)) {
			newWindowFrame = AIRectByAligningRect_edge_toRect_edge_(newWindowFrame,
																	AIOppositeRectEdge_(edge),
																	screenSlideBoundaryRect,
																	edge);
		}
	}

	windowSlidOffScreenEdgeMask |= rectEdgeMask;

	[self slideWindowToPoint:newWindowFrame.origin];
}

- (void)slideWindowOnScreenWithAnimation:(BOOL)animate
{
	if ([self windowSlidOffScreenEdgeMask] != AINoEdges) {
		NSWindow	*window = [self window];
		
		animate = animate && !NSEqualRects(window.frame, oldFrame);
		
		//Restore shadow and frame if we're appearing from having slid off-screen
		[window setHasShadow:[[adium.preferenceController preferenceForKey:KEY_CL_WINDOW_HAS_SHADOW
																	   group:PREF_GROUP_CONTACT_LIST] boolValue]];			
		[window orderFront:nil];
		
		[contactListController contactListWillSlideOnScreen];

		windowSlidOffScreenEdgeMask = AINoEdges;
		
		if (animate) {
			[self slideWindowToPoint:oldFrame.origin];
		} else {
			[self moveWindowToPoint:oldFrame.origin];
		}
		
		windowLastScreen = nil;
	}
}

- (void)slideWindowOnScreen
{
	[self slideWindowOnScreenWithAnimation:YES];
}

- (void)setPreventHiding:(BOOL)newPreventHiding {
	preventHiding = newPreventHiding;
}

- (void)endWindowSlidingDelay
{
	[self setPreventHiding:NO];
}

- (void)delayWindowSlidingForInterval:(NSTimeInterval)inDelayTime
{
	[self setPreventHiding:YES];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(endWindowSlidingDelay)
											   object:nil];
	[self performSelector:@selector(endWindowSlidingDelay)
			   withObject:nil
			   afterDelay:inDelayTime];
}

- (AIRectEdgeMask)windowSlidOffScreenEdgeMask
{
	return windowSlidOffScreenEdgeMask;
}

// Snap Groups Together------------------------------------------------------------------------------------------------
#pragma mark Snap Groups Together

/*!
 * @brief If window did move and is not docked then snap it to other windows
 */
- (void)windowDidMove:(NSNotification *)notification
{
	BOOL suppressSnapping = [NSEvent shiftKey];

	attachToBottom = nil;
	
	if (windowSlidOffScreenEdgeMask == AINoEdges && !suppressSnapping)
		[self snapToOtherWindows];
}

/*!
 * @brief Captures mouse up event to check that if the window snapped underneath
 * another window they are merged together
 */
- (void)mouseUp:(NSEvent *)event {
	if (attachToBottom) {
		AIContactList *from = (AIContactList *)[self contactList];
		AIContactList *to = (AIContactList *)[attachToBottom contactList];
		
		for (AIListGroup *group in from) {
			[adium.contactController moveGroup:group fromContactList:from toContactList:to];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DetachedContactListIsEmpty
												  object:from
												userInfo:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"Contact_ListChanged"
												  object:to
												userInfo:nil]; 
	}
	
	[super mouseUp:event];
}

/*!
 * @brief Snaps window to windows next to it
 */
- (void)snapToOtherWindows
{	
	NSWindow *myWindow = [self window];
	NSArray *windows = [[NSApplication sharedApplication] windows];
	
	NSWindow *window;
	
	NSRect currentFrame = [myWindow frame];
	NSPoint suggested = currentFrame.origin;
	
	// Check to snap to each guide
	for (window in windows) {
		// No snapping to itself and it must be within a snapping distance to other windows
		if ((window != myWindow) &&
			[window delegate] && [window isVisible] && 
			[[window delegate] conformsToProtocol:@protocol(AIInterfaceContainer)]) {
			/* Note: [window delegate] may be invalid if the window is in the middle of closing.
			 * Checking if it's visible should hopefully cover that case.
			 */
			suggested = [self snapTo:window with:currentFrame saveTo:suggested];
		}
	}

	[[self window] setFrameOrigin:suggested];
}


/*!
 * @brief Check that window is inside snappable region of other window
 */
static BOOL isInRangeOfRect(NSRect sourceRect, NSRect targetRect)
{
	return NSIntersectsRect(NSInsetRect(sourceRect, -SNAP_DISTANCE, -SNAP_DISTANCE), targetRect);
}

/*!
 * @brief Check if points are close enough to be snapped together
 */
static BOOL canSnap(CGFloat a, CGFloat b)
{
	return (AIfabs(a - b) <= SNAP_DISTANCE);
}

- (NSPoint)snapTo:(NSWindow*)neighborWindow with:(NSRect)currentRect saveTo:(NSPoint)location{
	NSRect neighbor = [neighborWindow frame];
	NSPoint spacing = [self windowSpacing];
	NSUInteger overlap = 0;
	NSUInteger bottom = 0;
	
	if (!NSEqualRects(neighbor,currentRect) && isInRangeOfRect(currentRect, neighbor)) {
		// X Snapping
		if (canSnap(NSMaxX(currentRect), NSMinX(neighbor))) {
			location.x = NSMinX(neighbor) - NSWidth(currentRect) - spacing.x;
		} else if (canSnap(NSMinX(currentRect), NSMaxX(neighbor))) {
			location.x = NSMaxX(neighbor) + spacing.x;
		} else if (canSnap(NSMinX(currentRect), NSMinX(neighbor))) {
			location.x = NSMinX(neighbor);
			overlap++;
			bottom++;
		}
		
		// Y Snapping
		if (canSnap(NSMaxY(neighbor), NSMaxY(currentRect))) {
			location.y = NSMaxY(neighbor) - NSHeight(currentRect);
			overlap++;
		} else if (canSnap(NSMinY(neighbor), NSMaxY(currentRect))) {
			location.y = NSMinY(neighbor) - NSHeight(currentRect) - spacing.y;
			bottom++;
		} else if (canSnap(NSMaxY(neighbor), NSMinY(currentRect))) {
			location.y = NSMaxY(neighbor) + spacing.y;
		} else if (canSnap(NSMinY(neighbor), NSMinY(currentRect))) {
			location.y = NSMinY(neighbor);
			overlap++;
		}
		
	}	
	
	// If we snapped on top of neighbor
	if (overlap == 2)
		return currentRect.origin;

	// Save window that we could possible attach to
	if (bottom == 2)
		attachToBottom = (AIListWindowController *)[neighborWindow delegate];
	
	return location;
}


/*!
 * @brief Gets space that windows should be apart by based on current window style
 */
- (NSPoint)windowSpacing {
	AIContactListWindowStyle style = [[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE
														  group:PREF_GROUP_APPEARANCE] intValue];
	CGFloat space = (CGFloat)[[adium.preferenceController preferenceForKey:@"Group Top Spacing" 
														  group:@"List Layout"] doubleValue];
	
	switch (style) {
		case AIContactListWindowStyleStandard:
		case AIContactListWindowStyleBorderless:
		case AIContactListWindowStyleGroupChat:
			return NSMakePoint(0,0);
		case AIContactListWindowStyleGroupBubbles:
		case AIContactListWindowStyleContactBubbles:
		case AIContactListWindowStyleContactBubbles_Fitted:
			return NSMakePoint(space,space-WINDOW_ALIGNMENT_TOLERANCE);
	}
	return NSMakePoint(0,0);
}

#pragma mark Filtering
/*!
 * @brief Toggles the find bar on, or brings it into focus if it is already visible
 */
- (void)toggleFindPanel:(id)sender;
{
	if (filterBarIsVisible) {
		[[self window] makeFirstResponder:searchField]; 
		
	} else if ([contactListView numberOfRows] > 0) {
		filterBarShownAutomatically = NO;
		[self showFilterBarWithAnimation:YES];
		
	} else {
		NSBeep();
	}
}

/*!
 * @brief Hide the filter bar
 */
- (IBAction)hideFilterBar:(id)sender;
{
	[self hideFilterBarWithAnimation:YES];
}

/*!
 * @brief Show the filter bar
 *
 * @param useAnimation If YES, the filter bar will scroll into view, otherwise it appears immediately
 */
- (void)showFilterBarWithAnimation:(BOOL)useAnimation
{
	if (filterBarIsVisible || filterBarAnimation)
		return;
	
	// While the filter bar is shown, temporarily disable automatic horizontal resizing
	contactListController.autoResizeHorizontally = NO;
	
	// Disable contact list animation while the filter bar is shown
	[contactListView setEnableAnimation:NO];
	
	// Animate the filter bar into view	
	[self animateFilterBarWithDuration:(useAnimation ? 0.15f : 0.0f)];
}

/*!
 * @brief Hide the filter bar
 *
 * @param useAnimation If YES, the filter bar will scroll out of view, otherwise it disappears immediately
 */
- (void)hideFilterBarWithAnimation:(BOOL)useAnimation
{
	if (!filterBarIsVisible || filterBarAnimation)
		return;
	
	// Clear the search field so that visibility is reset
	[searchField setStringValue:@""];
	[self filterContacts:searchField];
	
	// Restore the default settings which we temporarily disabled previously
	contactListController.autoResizeHorizontally = [[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE group:PREF_GROUP_APPEARANCE] boolValue];
	
	[contactListView setEnableAnimation:[[adium.preferenceController preferenceForKey:KEY_CL_ANIMATE_CHANGES
										  group:PREF_GROUP_CONTACT_LIST] boolValue]];
	
	// Animate the filter bar out of view
	[self animateFilterBarWithDuration:(useAnimation ? 0.15f : 0.0f)];
}

/*!
 * @brief Animates the filter bar in and out of view
 *
 * @param duration The duration the animation will last
 */
- (void)animateFilterBarWithDuration:(CGFloat)duration
{
	NSView *targetView = ([contactListView enclosingScrollView] ? (NSView *)[contactListView enclosingScrollView] : contactListView);
	NSRect targetFrame = [targetView frame];
	NSDictionary *targetViewDict, *filterBarDict;
	
	// Contact list resizing
	if (filterBarIsVisible) {
		targetFrame.size.height = NSHeight(targetFrame) + NSHeight([filterBarView bounds]);
		
	} else {
		/* We can only have a height less than the filter bar view if we are autosizing vertically, as
		 * there is a minimum height otherwise which is larger.  We can therefore increase our window size to allow space
		 * for the filter bar with impunity and without undoing this when hiding the bar, as the autosizing of the contact
		 * list will get us back to the right size later.
		 */
		if (NSHeight(targetFrame) < (NSHeight([filterBarView bounds]) * 2)) {
			NSRect windowFrame = [[targetView window] frame];
			
			[[targetView window] setFrame:NSMakeRect(NSMinX(windowFrame), NSMinY(windowFrame) - NSHeight([filterBarView bounds]),
													 NSWidth(windowFrame), NSHeight(windowFrame) + NSHeight([filterBarView bounds]))
								  display:YES
								  animate:NO];
			
			targetFrame = [targetView frame];
		}
		
		targetFrame.size.height = NSHeight(targetFrame) - NSHeight([filterBarView bounds]);
	}
	
	/* Setting a frame's height to 0 can permanently destroy its ability to display properly.
	 * This is the case with an NSOutlineView. If our contact list was invisibile (because no contacts
	 * were visible), create a 1 pixel border rather than traumatizing it for life.
	 */
	if (targetFrame.size.height == 0)
		targetFrame.size.height = 1;
    
    // Filter bar resizing
    NSRect barTargetFrame = contactListView.enclosingScrollView.frame;
    if (filterBarIsVisible) {
        barTargetFrame.size.height = NSHeight(barTargetFrame) + NSHeight(filterBarView.bounds);
    } else {
        barTargetFrame.size.height = NSHeight(barTargetFrame) - NSHeight(filterBarView.bounds);
    }
	
	if (!filterBarIsVisible) {
		// If the filter bar isn't already visible        
		[filterBarView setFrame:NSMakeRect(NSMinX(barTargetFrame),
										   NSHeight([contactListView frame]),
										   NSWidth(barTargetFrame),
										   NSHeight([filterBarView bounds]))];
        
		// Attach the filter bar to the window
		[[[self window] contentView] addSubview:filterBarView];
	}
	
	filterBarDict = [NSDictionary dictionaryWithObjectsAndKeys:filterBarView, NSViewAnimationTargetKey,
					 [NSValue valueWithRect:NSMakeRect(NSMinX(barTargetFrame), NSHeight(barTargetFrame),
													   NSWidth(barTargetFrame), NSHeight([filterBarView bounds]))], NSViewAnimationEndFrameKey, nil];
	
	targetViewDict = [NSDictionary dictionaryWithObjectsAndKeys:targetView, NSViewAnimationTargetKey,
					  [NSValue valueWithRect:targetFrame], NSViewAnimationEndFrameKey, nil];
	
	self.filterBarAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:
																				targetViewDict,
																				filterBarDict,
																				nil]];
	[filterBarAnimation setDuration:duration];
	[filterBarAnimation setAnimationBlockingMode:NSAnimationBlocking];
	[filterBarAnimation setDelegate:self];
	
	// Start the animation
	[filterBarAnimation startAnimation];
}

/*!
 * @brief Called when the window loses focus
 */
- (void)windowDidResignMain:(NSNotification *)sender
{
	/* If the filter bar was shown by type-to-find (but not by command-F), and the window is no longer main,
	 * assume the user is done and hide the filter bar.
	 */
	if (filterBarIsVisible && filterBarShownAutomatically)
		[self hideFilterBarWithAnimation:NO];
}

/*!
 * @brief Forward typing events from the contact list to the filter bar
 */
- (BOOL)forwardKeyEventToFindPanel:(NSEvent *)theEvent;
{
	if (!typeToFindEnabled)
		return NO;

	//if we were not searching something before, we need to show the filter bar first without animation
	NSString	*charString = [theEvent charactersIgnoringModifiers];
	unichar		pressedChar = 0;
	
	//Get the pressed character
	if ([charString length] == 1) pressedChar = [charString characterAtIndex:0];
	
#define NSEscapeFunctionKey 27
	/* Hitting escape once should clear any existing selection. Keys with functional modifiers pressed should not be passed.
	 * Home and End should be passed to the find panel only  if it is already visible.
	 */
	if (((pressedChar == NSEscapeFunctionKey) && ([contactListView selectedRow] != -1 || !filterBarIsVisible)) ||
		(([theEvent modifierFlags] & NSCommandKeyMask) || ([theEvent modifierFlags] & NSAlternateKeyMask) || ([theEvent modifierFlags] & NSControlKeyMask)) ||
		((pressedChar == NSPageUpFunctionKey) || (pressedChar == NSPageDownFunctionKey) || (pressedChar == NSMenuFunctionKey)) ||
		(!filterBarIsVisible && ((pressedChar == NSHomeFunctionKey) || (pressedChar == NSEndFunctionKey)))) {
		return NO;
		
	} else {
		if (!filterBarIsVisible) {
			[self toggleFindPanel:nil];
			filterBarShownAutomatically = YES;
		}
		
		[[self window] makeFirstResponder:searchField];
		[[[self window] fieldEditor:YES forObject:searchField] keyDown:theEvent];
		
		return YES;
	}
}

/*!
 * @brief Process text commands while on the search field
 */
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	// Only process commands when we're in the search field.
	if (control != searchField)
		return NO;
	
	if (command == @selector(insertNewline:)) {
		// If we have a search term, open a chat with the first contact
		if (![[textView string] isEqualToString:@""])
			[self performDefaultActionOnSelectedObject:[contactListView firstVisibleListContact]
												sender:contactListView];
		// Hide the filter bar
		[self hideFilterBarWithAnimation:YES];		
	} else if(command == @selector(moveDown:)) {
		// The down arrow functions to move into the contact list view
		[[self window] makeFirstResponder:contactListView];		
	} else if(command == @selector(cancelOperation:)) {
		// Escape hides the filter bar.
		[self hideFilterBarWithAnimation:YES];
	} else {
		// If we didn't process a command, return NO.
		return NO;
	}
	
	// We processed a command, return YES.
	return YES;
}

- (void)expandGroupsForFiltering:(BOOL)state
{
	BOOL modified = NO;
	for (AIListObject *listObject in [self.contactList containedObjects]) {
		if ([listObject isKindOfClass:[AIListGroup class]] &&
			((!state && [listObject boolValueForProperty:@"ExpandedByFiltering"]) ||
			(state && [(AIListGroup *)listObject isExpanded] == NO))) {
			[listObject setValue:[NSNumber numberWithBool:state] forProperty:@"ExpandedByFiltering" notify:NotifyNever];
			modified = YES;
		}
	}
	
	filterBarExpandedGroups = state;
	
	if (modified)
		[contactListView reloadData];
}

/*!
 * @brief Filter contacts from the search field
 *
 * This method will expand or contract groups as necessary, as well as handle forwarding the search term to
 * the contact hiding controller.
 */
- (IBAction)filterContacts:(id)sender;
{
	if (![sender isKindOfClass:[NSSearchField class]])
		return;
	
	if (filterBarExpandedGroups && [[sender stringValue] isEqualToString:@""])
		[self expandGroupsForFiltering:NO];
	
	if ([[AIContactHidingController sharedController] filterContacts:[sender stringValue]]) {
		// Select the first contact; we're guaranteed at least one visible contact.
		[contactListView selectRowIndexes:[NSIndexSet indexSetWithIndex:[contactListView indexOfFirstVisibleListContact]]
					 byExtendingSelection:NO];
		
		// Since this wasn't a user-initiated selection change, we need to post a notification for it.
		[[NSNotificationCenter defaultCenter] postNotificationName:Interface_ContactSelectionChanged
															object:nil];
		
		[[searchField cell] setTextColor:nil backgroundColor:nil];
		
	} else {
		//White on light red (like Firefox!)
		[[searchField cell] setTextColor:[NSColor whiteColor] backgroundColor:[NSColor colorWithCalibratedHue:0.983f
																								   saturation:0.43f
																								   brightness:0.99f
																										alpha:1.0f]];
	}
	
	if (!filterBarExpandedGroups && ![[sender stringValue] isEqualToString:@""])
		[self expandGroupsForFiltering:YES];
}

/*!
 * @brief Delegate method for the search field's close button
 */
- (void)rolloverButton:(AIRolloverButton *)inButton mouseChangedToInsideButton:(BOOL)isInside
{
	[button_cancelFilterBar setImage:[NSImage imageNamed:(isInside ? @"FTProgressStopRollover" : @"FTProgressStop")
												forClass:[self class]]];
}

@end
