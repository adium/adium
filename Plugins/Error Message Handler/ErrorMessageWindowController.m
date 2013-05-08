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

#import "ErrorMessageWindowController.h"

#define MAX_ERRORS				80				// The max # of errors to display
#define MAX_ERROR_FRAME_HEIGHT	300
#define	ERROR_WINDOW_NIB		@"ErrorWindow"	// Filename of the error window nib

@interface ErrorMessageWindowController ()

- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)dealloc;
- (void)refreshErrorDialog;
- (void)windowDidLoad;

@end

@implementation ErrorMessageWindowController

/* SharedInstance
 * Returns the shared instance of AIErrorController
 */
static ErrorMessageWindowController *sharedErrorMessageInstance = nil;

+ (id)errorMessageWindowController
{
    if (!sharedErrorMessageInstance) {
        sharedErrorMessageInstance = [[self alloc] initWithWindowNibName:ERROR_WINDOW_NIB];
    }

    return sharedErrorMessageInstance;
}

+ (void)closeSharedInstance
{
    if (sharedErrorMessageInstance) {
        [sharedErrorMessageInstance closeWindow:nil];
    }
}

- (void)displayError:(NSString *)inTitle withDescription:(NSString *)inDesc withTitle:(NSString *)inWindowTitle;
{
	if (inTitle && inDesc && inWindowTitle) {
		// Force the window to load
		[sharedErrorMessageInstance window];
		
		// Add the error
		if ([errorTitleArray count] < MAX_ERRORS) { // Stop logging errors after too many
			[errorTitleArray addObject:inTitle];
			[errorDescArray addObject:inDesc];
			[errorWindowTitleArray addObject:inWindowTitle];
		}
		
		[self refreshErrorDialog];
	}
}

- (IBAction)okay:(id)sender
{
    if ([errorTitleArray count] == 1) { // Close the error dialog
        [self closeWindow:nil];

    } else { // Remove the first error and display the next one
        [errorTitleArray removeObjectAtIndex:0];
        [errorDescArray removeObjectAtIndex:0];
        [errorWindowTitleArray removeObjectAtIndex:0];

        [self refreshErrorDialog];
    }
}

- (IBAction)okayToAll:(id)sender
{
    // Close the error dialog
    [self closeWindow:nil];
}

#pragma mark Private

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    if ((self = [super initWithWindowNibName:windowNibName])) {
    	errorTitleArray = [[NSMutableArray alloc] init];
    	errorDescArray =  [[NSMutableArray alloc] init];
    	errorWindowTitleArray = [[NSMutableArray alloc] init];
	}

    return self;
}

- (void)dealloc
{
    [errorTitleArray release]; errorTitleArray = nil;
    [errorDescArray release]; errorDescArray = nil;
    [errorWindowTitleArray release]; errorWindowTitleArray = nil;

    [super dealloc];
}

- (void)refreshErrorDialog
{
    NSRect	frame = [[self window] frame];

    // Display the current error title
	NSString	*title = [errorTitleArray objectAtIndex:0];
    [textView_errorTitle setString:title];

	// Resize the window frame to fit the error title
	[textView_errorTitle sizeToFit];
	CGFloat	titleHeightChange = [textView_errorTitle frame].size.height - [scrollView_errorTitle documentVisibleRect].size.height;
	
	NSRect errorTitleFrame = [scrollView_errorTitle frame];
	errorTitleFrame.size.height += titleHeightChange;
	errorTitleFrame.origin.y -= titleHeightChange;
	[scrollView_errorTitle setFrame:errorTitleFrame];

	frame.size.height += titleHeightChange;
	frame.origin.y -= titleHeightChange;
	
	// Display the message
	[textView_errorInfo setString:[errorDescArray objectAtIndex:0]];

	// Resize the window frame to fit the error message
	[textView_errorInfo sizeToFit];
	CGFloat errorInfoChange = [textView_errorInfo frame].size.height - [scrollView_errorInfo documentVisibleRect].size.height;
	NSRect errorInfoFrame = [scrollView_errorInfo frame];
	
	if (errorInfoChange + NSHeight(errorInfoFrame) > MAX_ERROR_FRAME_HEIGHT) {
		errorInfoChange = MAX_ERROR_FRAME_HEIGHT - NSHeight(errorInfoFrame);
	}
	
	errorInfoFrame.size.height += errorInfoChange;
	errorInfoFrame.origin.y -= errorInfoChange;
	// Also move it down to keep it from overlapping the title
	errorInfoFrame.origin.y -= titleHeightChange;
	[scrollView_errorInfo setFrame:errorInfoFrame];

	frame.size.height += errorInfoChange;
    frame.origin.y -= errorInfoChange;
	
	// Perform the window resizing as needed
	[[self window] setFrame:frame display:YES animate:YES];

    // Display the current error count
    if ([errorTitleArray count] == 1) {
		[button_dismissAll setHidden:YES];
        [[self window] setTitle:[errorWindowTitleArray objectAtIndex:0]];
        [button_okay setTitle:@"OK"];
		[[self window] makeFirstResponder:button_okay];
    } else {
		[button_dismissAll setHidden:NO];
        [[self window] setTitle:[NSString stringWithFormat:@"%@ (x%li)",[errorWindowTitleArray objectAtIndex:0],[errorTitleArray count]]];
        [button_okay setTitle:AILocalizedString(@"Next",nil)];
		[button_dismissAll setTitle:AILocalizedString(@"Dismiss All", @"Used in the error window; closes all open errors.")];
		[[self window] makeFirstResponder:button_dismissAll];
    }

    [[self window] makeKeyAndOrderFront:nil];
}

// Called after the about window loads, so we can set up the window before it's displayed
- (void)windowDidLoad
{
    // Setup the textviews
    [textView_errorTitle setHorizontallyResizable:NO];
    [textView_errorTitle setVerticallyResizable:YES];
    [textView_errorTitle setDrawsBackground:NO];
    [scrollView_errorTitle setDrawsBackground:NO];
	
    [textView_errorInfo setHorizontallyResizable:NO];
    [textView_errorInfo setVerticallyResizable:YES];
    [textView_errorInfo setDrawsBackground:NO];
    [scrollView_errorInfo setDrawsBackground:NO];
	
	// Center
	[[self window] center];
}

// Called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
    // Release the window controller (ourself)
    sharedErrorMessageInstance = nil;
    [self autorelease];
}

@end
