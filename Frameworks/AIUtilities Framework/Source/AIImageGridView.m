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

#import "AIImageGridView.h"
#import "AIScaledImageCell.h"

#define MIN_PADDING			1			//The minimum padding between images

@interface AIImageGridView ()
- (void)_initImageGridView;
- (void)_updateGrid;
- (void)_updateGridForNewFrame:(NSRect)newFrame;
- (void)_setHoveredIndex:(NSInteger)idx;
@end

@implementation AIImageGridView

//Init
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self _initImageGridView];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self _initImageGridView];
	}
	return self;
}

- (void)_initImageGridView
{
	cell = [[AIScaledImageCell alloc] init];
	imageSize = NSMakeSize(64,64);
	selectedIndex = -1;
	hoveredIndex = -1;
	[self _updateGrid];
}

- (void)dealloc
{
	[cell release];
	[super dealloc];
}

//Configuration --------------------------------------------------------------------------------------------------------
#pragma mark Configuration

//Set our delegate
- (void)setDelegate:(id<AIImageGridViewDelegate>)inDelegate
{
	delegate = inDelegate;
	
	//Make sure this delegate responds to the required methods
	NSParameterAssert([delegate respondsToSelector:@selector(numberOfImagesInImageGridView:)]);
	NSParameterAssert([delegate respondsToSelector:@selector(imageGridView:imageAtIndex:)]);

	//Determine (and cache) the optional methods it responds to
	_respondsToShouldSelect = [delegate respondsToSelector:@selector(imageGridView:shouldSelectIndex:)];
	_respondsToSelectionDidChange = [delegate respondsToSelector:@selector(imageGridViewSelectionDidChange:)];
	_respondsToSelectionIsChanging = [delegate respondsToSelector:@selector(imageGridViewSelectionIsChanging:)];
	_respondsToDeleteSelection = [delegate respondsToSelector:@selector(imageGridViewDeleteSelectedImage:)];
	_respondsToImageHovered = [delegate respondsToSelector:@selector(imageGridView:cursorIsHoveringImageAtIndex:)];
	
	//If the delegate wants mouse moved messages, enable them
	if (_respondsToImageHovered) [[self window] setAcceptsMouseMovedEvents:YES];
	[self reloadData];
}
- (id<AIImageGridViewDelegate>)delegate
{
	return delegate;
}

//Called when delegate data changes
- (void)reloadData
{
	[self _updateGrid];
}

//Set the size of the images in our grid
- (void)setImageSize:(NSSize)inSize
{
	imageSize = inSize;
	[self _updateGrid];
}
- (NSSize)imageSize
{
	return imageSize;
}

//Set the frame of our view
- (void)setFrame:(NSRect)frameRect
{
	[self _updateGridForNewFrame:frameRect];
}

//Drawing and sizing ---------------------------------------------------------------------------------------------------
#pragma mark Drawing and sizing

//Redisplay an image in the grid
- (void)setNeedsDisplayOfImageAtIndex:(NSInteger)idx
{
	if (idx >= 0) {
		[self setNeedsDisplayInRect:[self rectForImageAtIndex:idx]];
	}
}

//Returns the rect for an image in our grid
- (NSRect)rectForImageAtIndex:(NSInteger)idx
{
	NSInteger row = idx / columns;
	NSInteger column = idx % columns;

	return NSMakeRect(column * (imageSize.width  + padding.width)  + padding.width,
	                  row    * (imageSize.height + padding.height) + padding.height,
	                  imageSize.width,
	                  imageSize.height);
}

//Returns the image index at the specified point in our grid
- (NSInteger)imageIndexAtPoint:(NSPoint)point
{
	NSUInteger 	numberOfImages = [delegate numberOfImagesInImageGridView:self];
	//Determine which image was clicked
	for (NSUInteger i = 0; i < numberOfImages; i++) {
		if (NSPointInRect(point, [self rectForImageAtIndex:i])) {
			return i;
		}
	}

	return -1;
}

- (void)setDrawsBackground:(BOOL)flag
{
	if (flag != drawsBackground) {
		drawsBackground = flag;
		[self setNeedsDisplay:YES];
	}
}
- (BOOL)drawsBackground
{
	return drawsBackground;
}

//Draw
- (void)drawRect:(NSRect)drawRect
{
	NSUInteger numberOfImages = [delegate numberOfImagesInImageGridView:self];
	
	if (drawsBackground) {
		[[NSColor controlBackgroundColor] set];
		[NSBezierPath fillRect:drawRect];	
	}
	
	//Draw all images that lie in the dirty rect
	for (NSUInteger i = 0; i < numberOfImages; i++) {
		NSRect	imageRect = [self rectForImageAtIndex:i];

		if (NSIntersectsRect(drawRect, imageRect)) {
			[cell setImage:[delegate imageGridView:self imageAtIndex:i]];
			[cell setHighlighted:(selectedIndex == i)];
			[cell drawWithFrame:imageRect inView:self];
		}
	}
}

//This view is flipped since we intend for it to be within a scrollview
- (BOOL)isFlipped
{
	return YES;
}

//Update our frame height, number of columns, and padding
- (void)_updateGrid
{
	[self _updateGridForNewFrame:[self frame]];
}
- (void)_updateGridForNewFrame:(NSRect)newFrame
{
	NSScrollView	*scrollView = [self enclosingScrollView];
	NSUInteger 			numberOfImages = [delegate numberOfImagesInImageGridView:self];
	NSUInteger 			rows;

	//Recalculate the number of columns
	columns = newFrame.size.width / (imageSize.width + MIN_PADDING);
	
	//Increase padding to stretch the columns to the full width of our view
	padding.width = AIround((newFrame.size.width - (columns * imageSize.width)) / (columns + 1));
	padding.height = padding.width;
	
	//Resize our view so it's tall enuogh to display enough rows for all our images and that it always
	//covers the entire visible area in our scroll view.
	rows = AIceil(numberOfImages / columns);
	newFrame.size.height = rows * (imageSize.height + padding.height) + padding.height;
	if (scrollView && [scrollView contentSize].height > newFrame.size.height) {
		newFrame.size.height = [scrollView contentSize].height;
	}
	[super setFrame:newFrame];
	[self setNeedsDisplay:YES];
}

//Behavior  ------------------------------------------------------------------------------------------------------------
//Methods to handle click selection, keyboard selection, and deletion behavior
#pragma mark Behavior

//Sets our selected index to the passed value, restricting it to within the allowable bounds if necessary.
//The delegate will be informed of the new selection and the view will be updated to reflect it.
- (void)selectIndex:(NSInteger)idx
{
	NSUInteger		numberOfImages = [delegate numberOfImagesInImageGridView:self];
	BOOL	shouldSelect = YES;
	
	//Restrict the index to our bounds
	while (idx < 0) idx += numberOfImages;
	while (idx > numberOfImages-1) idx -= numberOfImages;
	
	//If the delegate supports it, confirm that this selection should be allowed
	if (_respondsToShouldSelect) {
		shouldSelect = [delegate imageGridView:self shouldSelectIndex:idx];
	}
	
	//Make the selection change, update our view and notify
	if (shouldSelect && idx != selectedIndex) {
		//Notification: Selection is changing 
		[[NSNotificationCenter defaultCenter] postNotificationName:AIImageGridViewSelectionIsChangingNotification object:self];
		if (_respondsToSelectionIsChanging) {
			[delegate imageGridViewSelectionIsChanging:[NSNotification notificationWithName:AIImageGridViewSelectionIsChangingNotification object:self]];
		}
		
		//Mark the old and new selections for redraw
		[self setNeedsDisplayOfImageAtIndex:selectedIndex];
		[self setNeedsDisplayOfImageAtIndex:idx];
		
		selectedIndex = idx;
		[self scrollRectToVisible:NSInsetRect([self rectForImageAtIndex:selectedIndex], -padding.width, -padding.height)];
		
		//Notification: Selection did change 
		[[NSNotificationCenter defaultCenter] postNotificationName:AIImageGridViewSelectionDidChangeNotification object:self];
		if (_respondsToSelectionDidChange) {
			[delegate imageGridViewSelectionDidChange:[NSNotification notificationWithName:AIImageGridViewSelectionDidChangeNotification object:self]];
		}
	}
}
- (NSInteger)selectedIndex
{
	return selectedIndex;
}

//Selection changing via mouse
- (void)mouseDown:(NSEvent *)theEvent
{
	[self selectIndex:[self imageIndexAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]]];
}

//We need to accept first responder to get keyboard input
- (BOOL)acceptsFirstResponder
{
	return YES;
}

//selects an index relative to the current selectedIndex.
- (void)selectRelativeIndex:(NSInteger)delta
{
	if (delta) {
		[self selectIndex:selectedIndex + delta];
	}
}

//Selection changing via keyboard
- (void)moveRight:(id)sender
{
	[self selectRelativeIndex:+1];
}
- (void)moveLeft:(id)sender
{
	[self selectRelativeIndex:-1];
}
- (void)moveUp:(id)sender
{
	[self selectRelativeIndex:-columns];
}
- (void)moveDown:(id)sender
{
	[self selectRelativeIndex: columns];
}

- (void)keyDown:(NSEvent *)theEvent
{
	if (_respondsToDeleteSelection && [[theEvent charactersIgnoringModifiers] length]) {
		unichar	pressedKey = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
		if (pressedKey == NSDeleteFunctionKey || pressedKey == NSBackspaceCharacter || pressedKey == NSDeleteCharacter) { //Delete
			//Delete selected image
			[delegate imageGridViewDeleteSelectedImage:self];
			return;
		}
	}

	[super keyDown:theEvent];
}

//Cursor Tracking  -----------------------------------------------------------------------------------------------------
//If a delegate chooses it can be notified when the user hovers an image in the grid.  This code handles the cursor
//tracking and messaging required to make that happen.
//Also, while we're tracking (but not otherwise), we accept arrow-key commands.
#pragma mark Cursor Tracking

//Reset our cursor tracking
- (void)resetCursorRects
{
	if (_respondsToImageHovered) {
		NSView	*scrollView = [self enclosingScrollView];
		NSRect	scrollFrame = [scrollView frame];
		
		//Stop any existing tracking
		if (trackingTag != -1) {
			[scrollView removeTrackingRect:trackingTag];
			trackingTag = -1;
		}
		
		//Add a tracking rect if our scrollview and window are ready
		if (scrollView && [scrollView window]) {
			NSRect	trackRect = NSMakeRect(0,0,scrollFrame.size.width, scrollFrame.size.height);
			NSPoint	localPoint = [scrollView convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]]
												 fromView:nil];
			BOOL	mouseInside = NSPointInRect(localPoint, trackRect);

			trackingTag = [scrollView addTrackingRect:trackRect owner:self userData:nil assumeInside:mouseInside];
			if (mouseInside) [self mouseEntered:nil];
		}
	}
}

//Cursor entered our view, begin tracking its movement
- (void)mouseEntered:(NSEvent *)theEvent
{
	isTracking = YES;
	NSWindow *window = [self window];
	
	[window setAcceptsMouseMovedEvents:YES];
	[window makeFirstResponder:self];
}

//Cursor left our view, stop tracking its movement
- (void)mouseExited:(NSEvent *)theEvent
{
	isTracking = NO;
	[self _setHoveredIndex:-1];
}

//Cursor moved, inform our delegate if a new cell is being hovered
- (void)mouseMoved:(NSEvent *)theEvent
{
	[self _setHoveredIndex:[self imageIndexAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]]];
}

//Set the hovered image index
- (void)_setHoveredIndex:(NSInteger)idx
{
	if (idx != hoveredIndex) {
		//Mark the old and new hovered image for redraw
		[self setNeedsDisplayOfImageAtIndex:hoveredIndex];
		[self setNeedsDisplayOfImageAtIndex:idx];
		
		//Make the change and notify our delegate
		hoveredIndex = idx;
		if (_respondsToImageHovered) [delegate imageGridView:self cursorIsHoveringImageAtIndex:hoveredIndex];
	}
}

@end
