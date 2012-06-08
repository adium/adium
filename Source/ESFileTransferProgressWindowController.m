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

#import "ESFileTransferProgressRow.h"
#import "ESFileTransferProgressView.h"
#import "ESFileTransferProgressWindowController.h"
#import "ESFileTransfer.h"
#import <AIUtilities/AIVariableHeightOutlineView.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIGenericViewCell.h>

#define FILE_TRANSFER_PROGRESS_NIB			@"FileTransferProgressWindow"
#define KEY_TRANSFER_PROGRESS_WINDOW_FRAME	@"Transfer Progress Window Frame"

@interface ESFileTransferProgressWindowController ()
- (void)addFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)updateStatusBar;
- (void)reloadAllData;
- (void)_removeFileTransfer:(ESFileTransfer *)inFileTransfer;
- (ESFileTransferProgressRow *)existingRowForFileTransfer:(ESFileTransfer *)inFileTransfer;
- (void)newFileTransfer:(NSNotification *)notification;
@end

@interface ESFileTransferController ()
- (void)_removeFileTransfer:(ESFileTransfer *)fileTransfer;
@end

#ifndef NSAppKitVersionNumber10_3
#	define NSTableViewUniformColumnAutoresizingStyle 1
#endif

@implementation ESFileTransferProgressWindowController

static ESFileTransferProgressWindowController *sharedTransferProgressInstance = nil;

//Return the shared contact info window
#pragma mark Class Methods
+ (id)sharedTransferProgressWindowController
{
	//Create the window
    if (!sharedTransferProgressInstance) {
        sharedTransferProgressInstance = [[self alloc] initWithWindowNibName:FILE_TRANSFER_PROGRESS_NIB];
	}

	return sharedTransferProgressInstance;
}

+ (id)showFileTransferProgressWindow
{
	//Configure and show window
	[[self sharedTransferProgressWindowController] showWindow:nil];

	return (sharedTransferProgressInstance);
}

+ (id)showFileTransferProgressWindowIfNotOpen
{
	[[[self sharedTransferProgressWindowController] window] orderFront:nil];
	
	return (sharedTransferProgressInstance);
}

//Close the info window
+ (void)closeTransferProgressWindow
{
    if (sharedTransferProgressInstance) {
        [sharedTransferProgressInstance closeWindow:nil];
    }
}

+ (void)removeFileTransfer:(ESFileTransfer *)inFileTransfer
{
    if (sharedTransferProgressInstance) {
        [sharedTransferProgressInstance _removeFileTransfer:inFileTransfer];
    }
}
//init
#pragma mark Basic window controller functionality
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    if ((self = [super initWithWindowNibName:windowNibName])) {
		progressRows = [[NSMutableArray alloc] init];
		
		[self.window setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
		[self.window setContentBorderThickness:24.0f forEdge: NSMinYEdge];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[progressRows release]; progressRows = nil;

    [super dealloc];
}

- (NSString *)adiumFrameAutosaveName
{
	return KEY_TRANSFER_PROGRESS_WINDOW_FRAME;
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	//Set the localized title
	[[self window] setTitle:AILocalizedString(@"File Transfers",nil)];

	//There's already a menu item in the Window menu; no reason to duplicate it
	[[self window] setExcludedFromWindowsMenu:YES];

	//Configure the scroll view
	[scrollView setHasVerticalScroller:YES];
	[scrollView setHasHorizontalScroller:NO];
	[[scrollView contentView] setCopiesOnScroll:NO];
	if ([scrollView respondsToSelector:@selector(setAutohidesScrollers:)]) {
		[scrollView setAutohidesScrollers:YES];
	}

	//Configure the outline view
	[[[outlineView tableColumns] objectAtIndex:0] setDataCell:[[[AIGenericViewCell alloc] init] autorelease]];

	[outlineView sizeLastColumnToFit];
	[outlineView setAutoresizesSubviews:YES];
	[outlineView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
	[outlineView setUsesAlternatingRowBackgroundColors:YES];
	[outlineView setDataSource:self];
	[outlineView setDelegate:self];

	//Set up and size our Clear button
	{
		NSRect	newFrame, oldFrame;
		
		//Clear
		[button_clear setAutoresizingMask:(NSViewMaxXMargin | NSViewMaxYMargin)];

		oldFrame = [button_clear frame];
		[button_clear setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
		[button_clear setTitle:AILocalizedString(@"Clear",nil)];
		[button_clear sizeToFit];
		newFrame = [button_clear frame];
		
		//Don't let the button get smaller than it was initially
		if (newFrame.size.width < oldFrame.size.width) newFrame.size.width = oldFrame.size.width;
		
		//Keep the origin and height the same - we just want to size for width
		newFrame.origin = oldFrame.origin;
		newFrame.size.height = oldFrame.size.height;
		[button_clear setFrame:newFrame];
		[button_clear setNeedsDisplay:YES];

		//Resize the status bar text
		NSInteger widthChange = oldFrame.size.width - newFrame.size.width;
		if (widthChange) {
			NSRect	statusFrame;
			
			statusFrame = [textField_statusBar frame];
			statusFrame.origin.x += widthChange;
			statusFrame.size.width -= widthChange;
			[textField_statusBar setFrame:statusFrame];
			[textField_statusBar setNeedsDisplay:YES];
		}
	}
	
	[outlineView accessibilitySetOverrideValue:AILocalizedString(@"File Transfers", nil)
								  forAttribute:NSAccessibilityDescriptionAttribute];

	//Call super's implementation
	[super windowDidLoad];

	//Observe for new file transfers
	[[NSNotificationCenter defaultCenter] addObserver:self
                                   selector:@selector(newFileTransfer:)
                                       name:FileTransfer_NewFileTransfer
									 object:nil];
	
	//Create progress rows for all existing file transfers
	shouldScrollToNewFileTransfer = NO;
	for (ESFileTransfer *fileTransfer in [adium.fileTransferController fileTransferArray]) {
		[self addFileTransfer:fileTransfer];
	}
	
	//Go time
	[self reloadAllData];
	
	shouldScrollToNewFileTransfer = YES;
	[outlineView scrollRectToVisible:[outlineView rectOfRow:([progressRows count]-1)]];
}

//called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	//release the window controller (ourself)
    sharedTransferProgressInstance = nil;
    [self autorelease];
}

- (void)configureControlDimming
{	
	ESFileTransferProgressRow	*row;
	BOOL						enableClear = NO;
	
	for (row in progressRows) {
		if ([[row fileTransfer] isStopped]) {
			enableClear = YES;
			break;
		}
	}
	
	[button_clear setEnabled:enableClear];
}

//Called when a progress row has loaded its view and is ready to be added to our window
#pragma mark Progress row addition to the window
- (void)progressRowDidAwakeFromNib:(ESFileTransferProgressRow *)progressRow
{
	if (![progressRows containsObjectIdenticalTo:progressRow]) {
		[progressRows addObject:progressRow];
	}

	if (shouldScrollToNewFileTransfer) {
		[self reloadAllData];
		
		[outlineView scrollRectToVisible:[outlineView rectOfRow:[progressRows indexOfObject:progressRow]]];
	}
}

#pragma mark Progress row details twiddle
//Called when the file transfer view's twiddle is clicked.
- (void)fileTransferProgressRow:(ESFileTransferProgressRow *)progressRow
			  heightChangedFrom:(CGFloat)oldHeight
							 to:(CGFloat)newHeight
{
	if (shouldScrollToNewFileTransfer) {
		[self reloadAllData];
		
		[outlineView scrollRectToVisible:[outlineView rectOfRow:[progressRows indexOfObject:progressRow]]];
	}
}

#pragma mark Adding file transfers
//Notification of a new file transfer; add it to the window
- (void)newFileTransfer:(NSNotification *)notification
{
	ESFileTransfer	*fileTransfer;

	if ((fileTransfer = [notification object])) {
		[self addFileTransfer:fileTransfer];
	}
}

//Add a file transfer's progress row if we don't already have one for the fileTransfer.
//This will call back on progressRowDidAwakeFromNib: if it adds a new row.
- (void)addFileTransfer:(ESFileTransfer *)inFileTransfer
{
	if (![self existingRowForFileTransfer:inFileTransfer]) {
		[ESFileTransferProgressRow rowForFileTransfer:inFileTransfer withOwner:self];
	}
}

- (void)_removeFileTransfer:(ESFileTransfer *)inFileTransfer
{
	ESFileTransferProgressRow	*row;

	if ((row = [self existingRowForFileTransfer:inFileTransfer])) [self _removeFileTransferRow:row];
}

- (ESFileTransferProgressRow *)existingRowForFileTransfer:(ESFileTransfer *)inFileTransfer
{
	ESFileTransferProgressRow	*row;

	for (row in progressRows) {
		if ([row fileTransfer] == inFileTransfer) break;
	}

	return row;
}

//Remove a file transfer row from the window. This is coupled to the file transfer controller; care must be taken
//that we don't remove a row which is in progress, as this will remove the file transfer controller's tracking of it.
//This must be done so we don't see the file transfer again if the progress window is closed and then reopened.
- (void)_removeFileTransferRow:(ESFileTransferProgressRow *)progressRow
{
	ESFileTransfer	*fileTransfer = [progressRow fileTransfer];

	if ([fileTransfer isStopped]) {
		NSClipView		*clipView = [scrollView contentView];
		NSUInteger		row;

		//Protect
		[progressRow retain];

		//Remove the row from our array, and its file transfer from the fileTransferController
		row = [progressRows indexOfObject:progressRow];
		[progressRows removeObject:progressRow];
		[adium.fileTransferController _removeFileTransfer:fileTransfer];
		
		if (shouldScrollToNewFileTransfer) {
			//Refresh the outline view
			[self reloadAllData];
			
			//Determine the row to reselect.  If the current row is valid, keep it.  If it isn't, use the last row.
			if (row >= [progressRows count]) {
				row = [progressRows count] - 1;
			}
			[clipView scrollToPoint:[clipView constrainScrollPoint:([outlineView rectOfRow:row].origin)]];
			
			[self updateStatusBar];
		}
		
		//Clean up
		[progressRow release];
	}
}

#pragma mark Status bar
//Called when a progress row changes its type, typically from Unknown to either Incoming or Outgoing
- (void)progressRowDidChangeType:(ESFileTransferProgressRow *)progressRow
{
	/* We get here as a progress row intializes itself, before it claims to be ready for display and therefore before
	 * we have it in the progressRows array.  Add it now if necessary */
	if (![progressRows containsObjectIdenticalTo:progressRow]) {
		[progressRows addObject:progressRow];
	}
	
	[self updateStatusBar];
}

- (void)progressRowDidChangeStatus:(ESFileTransferProgressRow *)progressRow
{
	[self configureControlDimming];
}

//Update the status bar at the bottom of the window
- (void)updateStatusBar
{
	ESFileTransferProgressRow	*aRow;
	NSString					*statusBarString, *downloadsString = nil, *uploadsString = nil;
	NSUInteger					downloads = 0, uploads = 0;
	
	for (aRow in progressRows) {
		AIFileTransferType type = [aRow type];
		if (type == Incoming_FileTransfer) {
			downloads++;
		} else if (type == Outgoing_FileTransfer) {
			uploads++;
		}
	}

	if (downloads > 0) {
		if (downloads == 1)
			downloadsString = AILocalizedString(@"1 download",nil);
		else
			downloadsString = [NSString stringWithFormat:AILocalizedString(@"%lu downloads","(number) downloads"), downloads];
	}

	if (uploads > 0) {
		if (uploads == 1)
			uploadsString = AILocalizedString(@"1 upload",nil);
		else
			uploadsString = [NSString stringWithFormat:AILocalizedString(@"%lu uploads","(number) uploads"), uploads];
	}

	if (downloadsString && uploadsString) {
		statusBarString = [NSString stringWithFormat:@"%@; %@",downloadsString,uploadsString];
	} else if (downloadsString) {
		statusBarString = downloadsString;
	} else if (uploadsString) {
		statusBarString = uploadsString;
	} else {
		statusBarString = @"";
	}

	[textField_statusBar setStringValue:statusBarString];
}

- (IBAction)clearAllCompleteTransfers:(id)sender
{
	shouldScrollToNewFileTransfer = NO;
	for (ESFileTransferProgressRow *row in [[progressRows copy] autorelease]) {
		if ([[row fileTransfer] isStopped]) [self _removeFileTransferRow:row];
	}	
	shouldScrollToNewFileTransfer = YES;
	
	[self reloadAllData];

	[outlineView scrollRectToVisible:[outlineView rectOfRow:0]];	
}

#pragma mark OutlineView dataSource
- (id)outlineView:(NSOutlineView *)inOutlineView child:(NSInteger)idx ofItem:(id)item
{
	if (idx < [progressRows count]) {
		return [progressRows objectAtIndex:idx];
	} else {
		return nil;
	}
}

- (NSInteger)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(id)item
{
	return [progressRows count];
}

//No items are expandable for the outline view
- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(id)item
{
	return NO;
}

//We don't use object values
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return @"";
}

//Each row should be the height of its item's view
- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	NSView *view = [(ESFileTransferProgressRow *)item view];
	
	return (view ? [view frame].size.height : 0);
}

//Before a cell is display, set its embedded view
- (void)outlineView:(NSOutlineView *)inOutlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[cell setEmbeddedView:[(ESFileTransferProgressRow *)item view]];
}

#pragma mark Outline view delegate
- (void)outlineViewDeleteSelectedRows:(NSOutlineView *)inOutlineView
{
	NSInteger		row = [inOutlineView selectedRow];
	BOOL	didDelete = NO;
	if (row != -1) {
		ESFileTransferProgressRow	*progressRow = [inOutlineView itemAtRow:row];
		if ([[progressRow fileTransfer] isStopped]) {
			[self _removeFileTransferRow:progressRow];
			didDelete = YES;
		}
	}

	//If they tried to delete a row that isn't finished, or we got here with no valid selection, sound the system beep
	if (!didDelete) {
		NSBeep();
	} else {
		[inOutlineView deselectAll:nil];
	}
}

- (NSMenu *)outlineView:(NSOutlineView *)inOutlineView menuForEvent:(NSEvent *)inEvent
{
	NSMenu	*menu = nil;
    NSPoint	location;
    NSInteger		row;

    //Get the clicked item
    location = [inOutlineView convertPoint:[inEvent locationInWindow]
								  fromView:nil];
    row = [inOutlineView rowAtPoint:location];

	if (row != -1) {
		ESFileTransferProgressRow	*progressRow = [inOutlineView itemAtRow:row];
		menu = [progressRow menuForEvent:inEvent];
	}

	return menu;
}

/*!
 * @brief Reload all data
 *
 * After removing the subviews of the outline view, reload the data.
 * Next, ensure the height of the outline view is still correct.
 * Finally, update our display and associated controls.
 */
- (void)reloadAllData
{
	[[[[outlineView subviews] copy] autorelease] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[outlineView reloadData];

	NSRect	outlineFrame = [outlineView frame];
	NSInteger		totalHeight = [outlineView totalHeight];

	if (outlineFrame.size.height != totalHeight) {
		outlineFrame.size.height = totalHeight;
		[outlineView setFrame:outlineFrame];
		[outlineView setNeedsDisplay:YES];
	}

	//Update our status bar
	[self updateStatusBar];

	//Enable/disable our controls
	[self configureControlDimming];
}

#pragma mark Window zoom
//Size for window zoom
- (NSRect)windowWillUseStandardFrame:(NSWindow *)inWindow defaultFrame:(NSRect)defaultFrame
{
	NSRect	oldWindowFrame = [inWindow frame];
	NSRect	windowFrame = oldWindowFrame;
	NSSize	minWinSize = [inWindow minSize];
	NSSize	maxWinSize = [inWindow maxSize];

	//Take the desired height and add the parts of the window which aren't in the scrollView.
	NSInteger desiredHeight = ([outlineView totalHeight] + (windowFrame.size.height - [scrollView frame].size.height));

	windowFrame.size.height = desiredHeight;
	windowFrame.size.width = 300;

	//Respect the min and max sizes
	if (windowFrame.size.width < minWinSize.width) windowFrame.size.width = minWinSize.width;
	if (windowFrame.size.height < minWinSize.height) windowFrame.size.height = minWinSize.height;
	if (windowFrame.size.width > maxWinSize.width) windowFrame.size.width = maxWinSize.width;
	if (windowFrame.size.height > maxWinSize.height) windowFrame.size.height = maxWinSize.height;

	//Keep the top-left corner the same
	windowFrame.origin.y = oldWindowFrame.origin.y + oldWindowFrame.size.height - windowFrame.size.height;

    return windowFrame;
}

@end
