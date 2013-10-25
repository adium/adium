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
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIWindowControllerAdditions.h>

@interface AIWindowController ()
+ (void)updateScreenBoundariesRect:(id)sender;
@end

/*!
 * @class AIWindowController
 * @brief Base class for window controllers
 *
 * This base class provides some essentials for window controllers to cut down on duplicate code.  It currently
 * handles window frame saving and restoration, establishes a local 'adium' references, and provides methods
 * which every good window controller cannot be without.
 */
@implementation AIWindowController

+ (void)initialize
{
	if ([self isEqual:[AIWindowController class]]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateScreenBoundariesRect:) 
													 name:NSApplicationDidChangeScreenParametersNotification 
												   object:nil];
		
		[self updateScreenBoundariesRect:nil];
	}
}

static NSRect screenBoundariesRect = { {0.0f, 0.0f}, {0.0f, 0.0f} };
+ (void)updateScreenBoundariesRect:(id)sender
{
	NSArray *screens = [NSScreen screens];
	NSUInteger numScreens = [screens count];
	
	if (numScreens > 0) {
		//The menubar screen is a special case - the menubar is not a part of the rect we're interested in
		NSScreen *menubarScreen = [screens objectAtIndex:0];
		screenBoundariesRect = [menubarScreen frame];
		screenBoundariesRect.size.height = NSMaxY([menubarScreen visibleFrame]) - NSMinY([menubarScreen frame]);
		for (int i = 1; i < numScreens; i++) {
			screenBoundariesRect = NSUnionRect(screenBoundariesRect, [[screens objectAtIndex:i] frame]);
		}
	}
}

/*!
 * @brief Initialize
 */
- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
	}
	
    return self;
}

/*!
 * @brief Create a frame from a saved string, taking into account the window's properties
 *
 * Maximum and minimum sizes are respected, the toolbar is taken into account, and the result has all integer values.
 *
 * @result The rect. If frameString would create an invalid rect (width <= 0 or height <= 0), NSZeroRect is returned.
 */
- (NSRect)savedFrameFromString:(NSString *)frameString
{
	NSRect		windowFrame = NSRectFromString(frameString);
	NSSize		minFrameSize = [[self window] minSize];
	NSSize		maxFrameSize = [[self window] maxSize];
	
	//Respect the min and max sizes
	if (windowFrame.size.width < minFrameSize.width) windowFrame.size.width = minFrameSize.width;
	if (windowFrame.size.height < minFrameSize.height) windowFrame.size.height = minFrameSize.height;
	if (windowFrame.size.width > maxFrameSize.width) windowFrame.size.width = maxFrameSize.width;
	if (windowFrame.size.height > maxFrameSize.height) windowFrame.size.height = maxFrameSize.height;
	
	//Don't allow the window to shrink smaller than its toolbar
	NSRect 		contentFrame = [NSWindow contentRectForFrameRect:windowFrame
													   styleMask:[[self window] styleMask]];
	if (contentFrame.size.height < [[self window] toolbarHeight]) {
		windowFrame.size.height += [[self window] toolbarHeight] - contentFrame.size.height;
	}
	
	//Make sure the window is visible on-screen
	if (NSMaxX(windowFrame) < NSMinX(screenBoundariesRect)) windowFrame.origin.x = NSMinX(screenBoundariesRect);
	if (NSMinX(windowFrame) > NSMaxX(screenBoundariesRect)) windowFrame.origin.x = NSMaxX(screenBoundariesRect) - NSWidth(windowFrame);
	if (NSMaxY(windowFrame) < NSMinY(screenBoundariesRect)) windowFrame.origin.y = NSMinY(screenBoundariesRect);
	if (NSMinY(windowFrame) > NSMaxY(screenBoundariesRect)) windowFrame.origin.y = NSMaxY(screenBoundariesRect) - NSHeight(windowFrame);
	
	
	return NSIntegralRect(windowFrame);
}

/*!
 * @brief Create a key which is specific for our current screen configuration
 *
 * The resulting key includes the starting key plus the size/orientation layout of all screens.
 * This allows saving a separate, unique saved frame for each new combination of monitor resolutions and relative positions.
 */
- (NSString *)multiscreenKeyWithAutosaveName:(NSString *)key
{
	NSMutableString	*multiscreenKey = [key mutableCopy];
	
	for (NSScreen *screen in [NSScreen screens])
		[multiscreenKey appendFormat:@"-%@", NSStringFromRect([screen frame])];
	
	return [multiscreenKey autorelease];
}

/*!
 * @brief Return a string which represents the saved frame for this window
 *
 * This will use [self adiumFrameAutosaveName] and a window-configuration dependent identifier to determine the
 * preference to be used.
 *
 * Subclasses have no business overriding this method.  See adiumFrameAutosaveName for the right place to determine the name
 * under which the frame is stored.
 *
 * @result A string suitable for passing to -[self savedFrameFromString:], or nil if no preference has been stored
 */
- (NSString *)savedFrameString
{
	NSString	*key = [self adiumFrameAutosaveName];
	NSString	*frameString = nil;

	if (key) {
		//Unique key for each number and size of screens
		frameString = [adium.preferenceController preferenceForKey:[self multiscreenKeyWithAutosaveName:key]
															   group:PREF_GROUP_WINDOW_POSITIONS];

		if (!frameString) {
			//Fall back on the old number-of-screens key
			frameString = [adium.preferenceController preferenceForKey:[NSString stringWithFormat:@"%@-%i",key,[[NSScreen screens] count]]
																   group:PREF_GROUP_WINDOW_POSITIONS];
			if (!frameString) {
				//Fall back on the single screen preference if necessary (this is effectively a preference upgrade).
				frameString = [adium.preferenceController preferenceForKey:key
																	   group:PREF_GROUP_WINDOW_POSITIONS];
			}
		}
	}
	
	return frameString;
}

/*!
 * @brief Configure the window after it loads
 *
 * Here we restore the window's saved position and size before it's displayed on screen.
 */
- (void)windowDidLoad
{
	NSString *frameString = [self savedFrameString];
	if (frameString) {
		NSRect savedFrame = [self savedFrameFromString:frameString];
		if (!NSIsEmptyRect(savedFrame)) {
			[[self window] setFrame:savedFrame display:NO];
		}
	}
}

/*!
 * @brief Show the window, possibly in front of other windows if inFront is YES
 *
 * Will not show the window in front if the currently-key window controller returns
 * NO to <code>shouldResignKeyWindowWithoutUserInput</code>. 
 * @see AIWindowControllerAdditions::shouldResignKeyWindowWithoutUserInput
 */
- (void)showWindowInFrontIfAllowed:(BOOL)inFront
{
	id currentKeyWindowController = [[NSApp keyWindow] windowController];
	if (currentKeyWindowController && ![currentKeyWindowController shouldResignKeyWindowWithoutUserInput]) {
		//Prevent window from showing in front if key window controller disallows it
		inFront = NO;
	}
	if (inFront) {
		[self showWindow:nil];
	} else {
		[[self window] orderWindow:NSWindowBelow relativeTo:[[NSApp mainWindow] windowNumber]];
	}
}



/*!
 * @brief Close the window
 */
- (IBAction)closeWindow:(id)sender
{
    if ([self windowShouldClose:nil]) {
		if ([[self window] isSheet]) {
			[NSApp endSheet:[self window]];
		} else {
			[[self window] close];
		}
	}
}

/*!
 * @brief Called before the window closes. This will not be called when the application quits.
 *
 * This is called before the window closes.  By default we always allow closing of our window, so YES is always
 * returned from this method.
 */
- (BOOL)windowShouldClose:(id)sender
{
	return YES;
}

static CGFloat ToolbarHeightForWindow(NSWindow *window)
{
    NSToolbar *toolbar;
    CGFloat toolbarHeight = 0.0f;
    NSRect windowFrame;

    toolbar = [window toolbar];

    if (toolbar && [toolbar isVisible]) {
        windowFrame = [NSWindow contentRectForFrameRect:[window frame]
											  styleMask:[window styleMask]];
        toolbarHeight = NSHeight(windowFrame) - NSHeight([[window contentView] frame]);
    }

    return toolbarHeight;
}

/*!
 * @brief Return a string representation of the saved frame
 *
 * This is a fixed implementation of 10.5's -[NSWindow stringWithSavedFrame].  The built-in stringWithSavedFrame method
 * performs some odd behavior when the window overlaps the dock and has a toolbar visible, moving it up by the height
 * of the toolbar.
 */
- (NSString *)stringWithSavedFrame
{
	NSWindow *window = [self window];
	NSRect frame = [window frame];
	NSRect screenFrame = [[window screen] frame];
	CGFloat toolbarHeight = ToolbarHeightForWindow(window);

	//The window starts off without a toolbar, so we need to save its size as such
	frame.size.height -= toolbarHeight;

	/* If the window's origin overlaps the dock at the bottom of the screen, we don't want to adjust its origin
	 * since NSToolbar takes the dock into account as it moves the window when added to it initially. Otherwise,
	 * we need to shift the origin to make up for the change in height. This is the bit that 10.5's -[NSWindow stringWithSavedFrame]
	 * gets wrong.
	 */
	if (NSMinY(frame) > NSMinY([[window screen] visibleFrame]))
		frame.origin.y += toolbarHeight;

	return [NSString stringWithFormat:@"%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f",
			NSMinX(frame), NSMinY(frame), NSWidth(frame), NSHeight(frame),
			NSMinX(screenFrame), NSMinY(screenFrame), NSWidth(screenFrame), NSHeight(screenFrame)];
}

/*!
 * @brief Called immediately before the window closes.
 * 
 * We take the opportunity to save the current window position and size here.
 * When subclassing be sure to call super in this method, or window frames will not save.
 */
- (void)windowWillClose:(id)sender
{
	NSString	*key = [self adiumFrameAutosaveName];

 	if (key) {
		//Unique key for each number and size of screens
		[adium.preferenceController setPreference:[self stringWithSavedFrame]
											 forKey:[self multiscreenKeyWithAutosaveName:key]
											  group:PREF_GROUP_WINDOW_POSITIONS];		
	}
}

/*!
 * Prevent the system from cascading our windows, since it interferes with window position memory
 */
- (BOOL)shouldCascadeWindows
{
    return NO;
}

/*!
 * @brief Auto-saving window frame key
 *
 * This is the string used for saving this window's frame.  It should be unique to this window. 
 * Subclasses should override this method.
 *
 */
- (NSString *)adiumFrameAutosaveName
{
	return nil;
}
	
@end
