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
#import	<Adium/AIListOutlineView.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIDockControllerProtocol.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIFunctions.h>
#import <AIUtilities/AIWindowControllerAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIListBookmark.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIUserIcons.h>
#import <AIUtilities/AIDockingWindow.h>
#import <AIUtilities/AIEventAdditions.h>

#import <AIUtilities/AITigerCompatibility.h>

#define PREF_GROUP_CONTACT_LIST					@"Contact List"

#define	KEY_HIDE_CONTACT_LIST_GROUPS			@"Hide Contact List Groups"

#define SLIDE_ALLOWED_RECT_EDGE_MASK			(AIMinXEdgeMask | AIMaxXEdgeMask) /* Screen edges on which sliding is allowde */
#define DOCK_HIDING_MOUSE_POLL_INTERVAL			0.1 /* Interval at which to check the mouse position for sliding */
#define	WINDOW_SLIDING_DELAY					0.2 /* Time after the mouse is in the right place before the window slides on screen */
#define WINDOW_ALIGNMENT_TOLERANCE				2.0f /* Threshold distance far the window from an edge to be considered on it */
#define MOUSE_EDGE_SLIDE_ON_DISTANCE			1.1f /* ??? */
#define WINDOW_SLIDING_MOUSE_DISTANCE_TOLERANCE 3.0f /* Distance the mouse must be from the window's frame to be considered outside it */

#define SNAP_DISTANCE							15.0 /* Distance beween one window's edge and another's at which they should snap together */

@interface AIListWindowController (PRIVATE)
- (id)initWithContactList:(AIListObject<AIContainingObject> *)contactList;
+ (NSString *)nibName;

- (void)_configureAutoResizing;
+ (void)updateScreenSlideBoundaryRect:(id)sender;
- (BOOL)shouldSlideWindowOffScreen_mousePositionStrategy;
- (void)slideWindowIfNeeded:(id)sender;
- (BOOL)shouldSlideWindowOnScreen_mousePositionStrategy;
- (BOOL)shouldSlideWindowOnScreen_adiumActiveStrategy;
- (BOOL)shouldSlideWindowOffScreen_adiumActiveStrategy;

- (void)delayWindowSlidingForInterval:(NSTimeInterval)inDelayTime;
@end

@implementation AIListWindowController

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

//Return a new contact list window controller
+ (AIListWindowController *)listWindowController
{
    return [[[self alloc] initWithContactList:nil] autorelease];
}

+ (AIListWindowController *)listWindowControllerForContactList:(AIListObject<AIContainingObject> *)contactList
{
	return [[[self alloc] initWithContactList:contactList] autorelease];
}

- (id)initWithContactList:(AIListObject<AIContainingObject> *)contactList
{
	if ((self = [self initWithWindowNibName:[[self class] nibName]])) {
		preventHiding = NO;
		previousAlpha = 0;
		[self setContactList:contactList];
	}
	
	return self;	
}

- (AIListObject<AIContainingObject> *)contactList
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

- (void)setContactList:(AIListObject<AIContainingObject> *)inContactList
{
	if (inContactList != contactListRoot) {
		[contactListRoot release];
		contactListRoot = [inContactList retain];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[contactListController close];
	[windowLastScreen release];

	[super dealloc];
}

//
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

	//Show the contact list initially even if it is at a screen edge and supposed to slide out of view
	[self delayWindowSlidingForInterval:5];

	id<AIPreferenceController> preferenceController = [adium preferenceController];
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

	//Save our frame immediately for sliding purposes
	[self setSavedFrame:[[self window] frame]];
}

//Close the contact list window
- (void)windowWillClose:(NSNotification *)notification
{
	if ([self windowSlidOffScreenEdgeMask] != AINoEdges) {
		//Hide the window while it's still off-screen
		[[self window] setAlphaValue:0.0];
		AILogWithSignature(@"Setting to alpha 0 while the window is offscreen");
		
		//Then move it back on screen so that we'll save the proper position in -[AIWindowController windowWillClose:]
		[self slideWindowOnScreenWithAnimation:NO];
	}

	[super windowWillClose:notification];

	//Invalidate the dock-like hiding timer
	[slideWindowIfNeededTimer invalidate]; [slideWindowIfNeededTimer release];

    //Stop observing
	[[adium preferenceController] unregisterPreferenceObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

    //Tell the interface to unload our window
    NSNotificationCenter *adiumNotificationCenter = [adium notificationCenter];
    [adiumNotificationCenter postNotificationName:Interface_ContactListDidResignMain object:self];
	[adiumNotificationCenter postNotificationName:Interface_ContactListDidClose object:self];
}

int levelForAIWindowLevel(AIWindowLevel windowLevel)
{
	int				level;

	switch (windowLevel) {
		case AINormalWindowLevel: level = NSNormalWindowLevel; break;
		case AIFloatingWindowLevel: level = NSFloatingWindowLevel; break;
		case AIDesktopWindowLevel: level = kCGBackstopMenuLevel; break;
		default: level = NSNormalWindowLevel; break;
	}
	
	return level;
}

- (void)setWindowLevel:(int)level
{
	AILogWithSignature(@"Setting to %i", level);
	[[self window] setLevel:level];
	if (![NSApp isOnLeopardOrBetter]) {
		[[self window] setIgnoresExpose:(level == kCGBackstopMenuLevel)]; //Ignore expose while on the desktop
	}
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
		if ([NSApp isOnLeopardOrBetter]) {
			if (showOnAllSpaces)
				[[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
			else
				[[self window] setCollectionBehavior:NSWindowCollectionBehaviorDefault];
		}

		if (windowHidingStyle == AIContactListWindowHidingStyleSliding) {
			if (!slideWindowIfNeededTimer) {
				slideWindowIfNeededTimer = [[NSTimer scheduledTimerWithTimeInterval:DOCK_HIDING_MOUSE_POLL_INTERVAL
																			 target:self
																		   selector:@selector(slideWindowIfNeeded:)
																		   userInfo:nil
																			repeats:YES] retain];
			}

		} else if (slideWindowIfNeededTimer) {
            [slideWindowIfNeededTimer invalidate];
			[slideWindowIfNeededTimer release]; slideWindowIfNeededTimer = nil;
		}

		[contactListController setShowTooltips:[[prefDict objectForKey:KEY_CL_SHOW_TOOLTIPS] boolValue]];
		[contactListController setShowTooltipsInBackground:[[prefDict objectForKey:KEY_CL_SHOW_TOOLTIPS_IN_BACKGROUND] boolValue]];
    }
	
	//Auto-Resizing
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		AIContactListWindowStyle	windowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
		BOOL	autoResizeHorizontally = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue];
		BOOL	autoResizeVertically = YES;
		int		forcedWindowWidth, maxWindowWidth;
		
		//Determine how to handle vertical autosizing. AIAppearancePreferences must match this behavior for this to make sense.
		switch (windowStyle) {
			case AIContactListWindowStyleStandard:
			case AIContactListWindowStyleBorderless:
				//Standard and borderless don't have to vertically autosize, but they might
				autoResizeVertically = [[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE] boolValue];
				break;
			case AIContactListWindowStyleGroupBubbles:
			case AIContactListWindowStyleContactBubbles:
			case AIContactListWindowStyleContactBubbles_Fitted:
				//The bubbles styles don't show a window; force them to autosize by leaving autoResizeVertically == YES
				break;
		}			

		if (autoResizeHorizontally) {
			//If autosizing, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH determines the maximum width; no forced width.
			maxWindowWidth = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] intValue];
			forcedWindowWidth = -1;
		} else {
			if (windowStyle == AIContactListWindowStyleStandard/* || windowStyle == AIContactListWindowStyleBorderless*/) {
				//In the non-transparent non-autosizing modes, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH has no meaning
				maxWindowWidth = 10000;
				forcedWindowWidth = -1;
			} else {
				//In the transparent non-autosizing modes, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH determines the width of the window
				forcedWindowWidth = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] intValue];
				maxWindowWidth = forcedWindowWidth;
			}
		}
		
		//Show the resize indicator if either or both of the autoresizing options is NO
		[[self window] setShowsResizeIndicator:!(autoResizeVertically && autoResizeHorizontally)];
		
		/*
		 Reset the minimum and maximum sizes in case [contactListController contactListDesiredSizeChanged]; doesn't cause a sizing change
		 (and therefore the min and max sizes aren't set there).
		 */
		NSSize	thisMinimumSize = minWindowSize;
		NSSize	thisMaximumSize = NSMakeSize(maxWindowWidth, 10000);
		NSRect	currentFrame = [[self window] frame];
		
		if (forcedWindowWidth != -1) {
			/*
			 If we have a forced width but we are doing no autoresizing, set our frame now so we don't have to be doing checks every time
			 contactListDesiredSizeChanged is called.
			 */
			if (!(autoResizeVertically || autoResizeHorizontally)) {
				thisMinimumSize.width = forcedWindowWidth;
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
		
		[contactListController setAutoresizeHorizontally:autoResizeHorizontally];
		[contactListController setAutoresizeVertically:autoResizeVertically];
		[contactListController setForcedWindowWidth:forcedWindowWidth];
		[contactListController setMaxWindowWidth:maxWindowWidth];
		
		[contactListController contactListDesiredSizeChanged];
		
		if (!firstTime) {
			shouldRevealWindowAndDelaySliding = YES;
		}
	}

	//Window opacity
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		float opacity = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_OPACITY] floatValue];		
		[contactListController setBackgroundOpacity:opacity];

		/*
		 * If we're using fitted bubbles, we want the default behavior of the winodw, which is to respond to clicks on opaque areas
		 * and ignore clicks on transparent areas.  If we're using any other style, we never want to ignore clicks.
		 */
		BOOL forceWindowToCatchMouseEvents = ([[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue] != AIContactListWindowStyleContactBubbles_Fitted);
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
		NSDictionary	*layoutDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
		NSDictionary	*themeDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_THEME];

		//Layout only
		if (groupLayout) {
			int iconSize = [[layoutDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] intValue];
			[AIUserIcons setListUserIconSize:NSMakeSize(iconSize,iconSize)];
		}
			
		//Theme only
		if (groupTheme || firstTime) {
			NSString		*imagePath = [themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_PATH];
			
			//Background Image
			if (imagePath && [imagePath length] && [[themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED] boolValue]) {
				[contactListView setBackgroundImage:[[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease]];
			} else {
				[contactListView setBackgroundImage:nil];
			}
		}

		EXTENDED_STATUS_STYLE statusStyle = [[layoutDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_STYLE] intValue];
		EXTENDED_STATUS_POSITION statusPosition = [[layoutDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_POSITION] intValue];
		[contactListController setAutoresizeHorizontallyWithIdleTime:
		 ((statusStyle == IDLE_ONLY || statusStyle == IDLE_AND_STATUS) &&
		  (statusPosition == EXTENDED_STATUS_POSITION_BESIDE_NAME || statusPosition == EXTENDED_STATUS_POSITION_BOTH))];
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
        if ([sender isItemExpanded:selectedObject]) {
            [sender collapseItem:selectedObject];
        } else {
            [sender expandItem:selectedObject];
        }

	} else if ([selectedObject isMemberOfClass:[AIListBookmark class]]) {
		//Hide any tooltip the contactListController is currently showing
		[contactListController hideTooltip];

		[(AIListBookmark *)selectedObject openChat];

	} else if ([selectedObject isKindOfClass:[AIListContact class]]) {
		//Hide any tooltip the contactListController is currently showing
		[contactListController hideTooltip];

		//Open a new message with the contact
		[[adium interfaceController] setActiveChat:[[adium chatController] openChatWithContact:(AIListContact *)selectedObject
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
    [self retain];

    if ([self windowShouldClose:nil]) {
        [[self window] close];
    }

    [self release];
}

- (void)makeActive:(id)sender
{
	[[self window] makeKeyAndOrderFront:self];
}


//Contact list brought to front
- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidBecomeMain object:self];
}

//Contact list sent back
- (void)windowDidResignKey:(NSNotification *)notification
{
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidResignMain object:self];
}

//
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

	//Ensure the window is displaying at the proper level and exposé setting
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
			[windowLastScreen release]; windowLastScreen = nil;
			windowScreen = [NSScreen mainScreen];
		}
	}
	
	NSRect newScreenFrame = [[screenSlideBoundaryRectDictionary objectForKey:[NSValue valueWithNonretainedObject:windowScreen]] rectValue];

	if ([self windowSlidOffScreenEdgeMask] != AINoEdges) {
		NSRect newWindowFrame = AIRectByAligningRect_edge_toRect_edge_([window frame], [self windowSlidOffScreenEdgeMask],
																	   newScreenFrame, [self windowSlidOffScreenEdgeMask]);
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
	int numScreens = [screens count];
	
	[screenSlideBoundaryRectDictionary release];
	screenSlideBoundaryRectDictionary = [[NSMutableDictionary alloc] initWithCapacity:numScreens];

	if (numScreens > 0) {
		//The menubar screen is a special case - the menubar is not a part of the rect we're interested in
		NSScreen	*menubarScreen = [screens objectAtIndex:0];
		NSRect		screenSlideBoundaryRect;

		screenSlideBoundaryRect = [menubarScreen frame];
		screenSlideBoundaryRect.size.height = NSMaxY([menubarScreen visibleFrame]) - NSMinY([menubarScreen frame]);
		[screenSlideBoundaryRectDictionary setObject:[NSValue valueWithRect:screenSlideBoundaryRect]
											  forKey:[NSValue valueWithNonretainedObject:menubarScreen]];

		for (int i = 1; i < numScreens; i++) {
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
		
		if ([NSApp isOnLeopardOrBetter])
			[[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
		
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
			 * let it participate in expose.
			 */
			if (overrodeWindowLevel &&
				windowHidingStyle == AIContactListWindowHidingStyleSliding) {
				[self setWindowLevel:kCGBackstopMenuLevel];
				
				if ([NSApp isOnLeopardOrBetter])
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
			
			if ([NSApp isOnLeopardOrBetter]) {
				if (showOnAllSpaces)
					[[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
				else
					[[self window] setCollectionBehavior:NSWindowCollectionBehaviorDefault];
			}
			
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
			float distanceMouseOutsideWindow = AISignedExteriorDistanceRect_edge_toPoint_(windowFrame, AIOppositeRectEdge_(screenEdge), mouseLocation);
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
	NSScreen *pointScreen = nil;
	
	NSEnumerator *screenEnumerator = [[NSScreen screens] objectEnumerator];
	NSScreen *screen;
	while ((screen = [screenEnumerator nextObject]) != nil) {
		if (NSPointInRect(point, NSInsetRect([screen frame], -1, -1))) {
			pointScreen = screen;
			break;
		}		
	}
	
	return pointScreen;
}	

- (NSRect)squareRectWithCenter:(NSPoint)point sideLength:(float)sideLength
{
	return NSMakeRect(point.x - sideLength*0.5f, point.y - sideLength*0.5f, sideLength, sideLength);
}

- (BOOL)pointIsInScreenCorner:(NSPoint)point
{
	BOOL inCorner = NO;
	NSScreen *menubarScreen = [[NSScreen screens] objectAtIndex:0];
	float menubarHeight = NSMaxY([menubarScreen frame]) - NSMaxY([menubarScreen visibleFrame]); // breaks if the dock is at the top of the screen (i.e. if the user is insane)
	
	NSRect screenFrame = [[self screenForPoint:point] frame];
	NSPoint lowerLeft  = screenFrame.origin;
	NSPoint upperRight = NSMakePoint(NSMaxX(screenFrame), NSMaxY(screenFrame));
	NSPoint lowerRight = NSMakePoint(upperRight.x, lowerLeft.y);
	NSPoint upperLeft  = NSMakePoint(lowerLeft.x, upperRight.y);
	
	float sideLength = menubarHeight * 2.0f;
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
	
		NSEnumerator *enumerator = [screenSlideBoundaryRectDictionary objectEnumerator];
		NSValue		 *screenSlideBoundaryRectValue;
		while ((screenSlideBoundaryRectValue = [enumerator nextObject])) {
			NSRectEdge	screenEdge;
			NSRect		screenSlideBoundaryRect = [screenSlideBoundaryRectValue rectValue];
			/* Only look at the screen in which the mouse currently resides.
			 * The mouse may be in no screen if it is over the menu bar.
			 */
			if (NSPointInRect(mouseLocation, screenSlideBoundaryRect)) {
				//Check each edge
				for (screenEdge = 0; screenEdge < 4; screenEdge++) {
					//But we only care about an edge off of which the window has slid
					if (windowSlidOffScreenEdgeMask & (1 << screenEdge)) {
						float mouseOutsideSlideBoundaryRectDistance = AISignedExteriorDistanceRect_edge_toPoint_(screenSlideBoundaryRect,
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

			if (mouseNearSlideOffEdges) break;
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
	if(![animation isEqual:windowAnimation])
		return;
	
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
		[[self window] setAlphaValue:0.0];
		AILogWithSignature(@"Previous alpha is now %f; window set to alpha 0.0 ", previousAlpha);
	}
	
	[windowAnimation release]; windowAnimation = nil;
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
	float yOff = (targetPoint.y + NSHeight(frame)) - NSMaxY([windowScreen frame]);
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
		[windowAnimation release];
	}

	windowAnimation = [[NSViewAnimation alloc] initWithViewAnimations:
		[NSArray arrayWithObject:
			[NSDictionary dictionaryWithObjectsAndKeys:
				myWindow, NSViewAnimationTargetKey,
				[NSValue valueWithRect:frame], NSViewAnimationEndFrameKey,
				nil]]];
	[windowAnimation setFrameRate:0.0];
	[windowAnimation setDuration:0.25];
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
	unsigned numScreens = [screens count];
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

		for (int i = 0; i < numScreens; i++) {
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

	[windowLastScreen release];
	windowLastScreen = [[window screen] retain];

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
		NSRect		windowFrame = [window frame];
		
		if (!NSEqualRects(windowFrame, oldFrame)) {
			//Restore shadow and frame if we're appearing from having slid off-screen
			[window setHasShadow:[[[adium preferenceController] preferenceForKey:KEY_CL_WINDOW_HAS_SHADOW
																		   group:PREF_GROUP_CONTACT_LIST] boolValue]];			
			[window orderFront:nil]; 
			[contactListController contactListWillSlideOnScreen];

			windowSlidOffScreenEdgeMask = AINoEdges;

			if (animate) {
				[self slideWindowToPoint:oldFrame.origin];
			} else {
				[self moveWindowToPoint:oldFrame.origin];
			}
			
			[windowLastScreen release];	windowLastScreen = nil;
		}
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
		AIListGroup *from = (AIListGroup *)[self contactList];
		AIListGroup *to = (AIListGroup *)[attachToBottom contactList];
		
		[from moveAllGroupsFrom:from to:to];
		
		[[adium notificationCenter] postNotificationName:DetachedContactListIsEmpty
												  object:from
												userInfo:nil];
		[[adium notificationCenter] postNotificationName:@"Contact_ListChanged"
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
	NSEnumerator *enumerator = [windows objectEnumerator];
	
	NSWindow *window;
	
	NSRect currentFrame = [myWindow frame];
	NSPoint suggested = currentFrame.origin;
	
	// Check to snap to each guide
	while ((window = [enumerator nextObject])) {
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
static BOOL canSnap(float a, float b)
{
	return (abs(a - b) <= SNAP_DISTANCE);
}

- (NSPoint)snapTo:(NSWindow*)neighborWindow with:(NSRect)currentRect saveTo:(NSPoint)location{
	NSRect neighbor = [neighborWindow frame];
	NSPoint spacing = [self windowSpacing];
	unsigned overlap = 0;
	unsigned bottom = 0;
	
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
		attachToBottom = [neighborWindow delegate];
	
	return location;
}


/*!
 * @brief Gets space that windows should be apart by based on current window style
 */
- (NSPoint)windowSpacing {
	AIContactListWindowStyle style = [[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE
														  group:PREF_GROUP_APPEARANCE] intValue];
	int space = [[[adium preferenceController] preferenceForKey:@"Group Top Spacing" 
														  group:@"List Layout"] intValue];
	
	switch (style) {
		case AIContactListWindowStyleStandard:
		case AIContactListWindowStyleBorderless:
			return NSMakePoint(0,0);
		case AIContactListWindowStyleGroupBubbles:
		case AIContactListWindowStyleContactBubbles:
		case AIContactListWindowStyleContactBubbles_Fitted:
			return NSMakePoint(space,space-WINDOW_ALIGNMENT_TOLERANCE);
	}
	return NSMakePoint(0,0);
}

@end
