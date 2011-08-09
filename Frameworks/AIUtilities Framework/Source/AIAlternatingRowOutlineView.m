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
 A subclass of outline view that adds:

 - Alternating rows
 - A vertical column grid
 - Gradient selection highlighting
 */

#import "AIAlternatingRowOutlineView.h"
#import "AIOutlineView.h"
#import "AIGradientAdditions.h"
#import "AIColorAdditions.h"

@interface AIAlternatingRowOutlineView ()
- (void)initAlternatingRowOutlineView;
- (void)_drawGridInClipRect:(NSRect)rect;
@end

@interface NSOutlineView (Undocumented)
- (id)_highlightColorForCell:(NSCell *)cell;
@end

@implementation AIAlternatingRowOutlineView

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self initAlternatingRowOutlineView];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self initAlternatingRowOutlineView];
	}
	return self;
}

- (void)initAlternatingRowOutlineView
{
	[self setUsesAlternatingRowBackgroundColors:NO];
	drawsBackground = YES;
	drawsGradientSelection = NO;
	alternatingRowColor = [[NSColor colorWithCalibratedRed:(237.0f/255.0f) green:(243.0f/255.0f) blue:(254.0f/255.0f) alpha:1.0f] retain];
}

- (void)dealloc
{
	[alternatingRowColor release];

	[super dealloc];
}


//Configuring ----------------------------------------------------------------------

- (void)setDrawsGradientSelection:(BOOL)inDrawsGradientSelection
{
	drawsGradientSelection = inDrawsGradientSelection;
	[self setNeedsDisplay:YES];
}

- (BOOL)drawsGradientSelection
{
	return drawsGradientSelection;
}

//Set the alternating row color
- (void)setAlternatingRowColor:(NSColor *)color
{
	if (color != alternatingRowColor) {
		[alternatingRowColor release];
		alternatingRowColor = [color retain];
		[self setNeedsDisplay:YES];
	}
}
- (NSColor *)alternatingRowColor{
	return alternatingRowColor;
}

//Toggle drawing of our background (Including the alternating grid)
//Set this to NO if cells are going to take responsibility for drawing the background or grid
- (void)setDrawsBackground:(BOOL)inDraw
{
	drawsBackground = inDraw;
	[self setNeedsDisplay:YES];
}
- (BOOL)drawsBackground{
	return drawsBackground;
}

//Returns the color which will be drawn behind the specified row
- (NSColor *)backgroundColorForRow:(NSInteger)row
{
	return ((row % 2) ? [self backgroundColor] : [self alternatingRowColor]);
}

#pragma mark Drawing

//Draw the alternating colors and grid below the "bottom" of the outlineview
- (void)drawAlternatingRowsInRect:(NSRect)rect
{
	if (!drawsBackground || ![self usesAlternatingRowBackgroundColors]) 
	    return;

	unsigned	rectNumber = 0;
	
	//Setup
	NSInteger numberOfRows = [self numberOfRows];
	CGFloat rowHeight = [self rowHeight];
    
	NSRectArray gridRects = (NSRectArray)alloca(sizeof(NSRect) * (numberOfRows + ((NSInteger)round(((rect.size.height / rowHeight) / 2) + 0.5f))));
	for (unsigned row = 0; row < numberOfRows; row += 2) {
		if (row < numberOfRows) {
			NSRect	thisRect = [self rectOfRow:row];
			if (NSIntersectsRect(thisRect, rect)) { 
				gridRects[rectNumber++] = thisRect;
			} else {
				NSLog(@"Not drawing because %@ is not in %@",NSStringFromRect(thisRect),NSStringFromRect(rect));
			}
		}
	}

	if (rectNumber > 0) {
		[[self alternatingRowColor] set];
		NSRectFillListUsingOperation(gridRects, rectNumber, NSCompositeSourceOver);
	}
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];

	if (drawsBackground && [self usesAlternatingRowBackgroundColors] && [self gridStyleMask] != NSTableViewGridNone) {
		[self _drawGridInClipRect:rect];
	}
}

#pragma mark Gradient selection and alternating rows

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
	NSIndexSet *indices = [self selectedRowIndexes];
	NSUInteger bufSize = [indices count];
	
	if (drawsGradientSelection && bufSize > 0 && [[self window] isKeyWindow] && ([[self window] firstResponder] == self)) {
		NSUInteger *buf = malloc(bufSize * sizeof(NSUInteger));
		NSUInteger i = 0, j = 0;

		NSGradient *gradient = [NSGradient selectedControlGradient];
		
		NSRange range = NSMakeRange([indices firstIndex], ([indices lastIndex]-[indices firstIndex]) + 1);
		[indices getIndexes:buf maxCount:bufSize inIndexRange:&range];
		
		NSRect *selectionLineRects = (NSRect *)malloc(sizeof(NSRect) * bufSize);
		
		while (i < bufSize) {
			NSUInteger startIndex = buf[i];
			NSUInteger lastIndex = buf[i];

			while ((i + 1 < bufSize) &&
				   (buf[i + 1] == lastIndex + 1)){
				i++;
				lastIndex++;
			}

			NSRect startRow = [self rectOfRow:startIndex];
			NSRect endRow = [self rectOfRow:lastIndex];
			if (!NSIsEmptyRect(startRow)) {
				NSRect thisRect;
				if (!NSIsEmptyRect(endRow)) {
					thisRect = NSUnionRect(startRow, endRow);
				} else {
					thisRect = startRow;
				}

				[gradient drawInRect:thisRect angle:90.0f];
				
				//Draw a line at the light side, to make it look a lot cleaner
				thisRect.size.height = 1;
				selectionLineRects[j++] = thisRect;			
			}

			i++;		
		}

		[[NSColor alternateSelectedControlColor] set];
		NSRectFillListUsingOperation(selectionLineRects, j, NSCompositeSourceOver);
		
		free(buf);
		free(selectionLineRects);
	
	} else {
		[super highlightSelectionInClipRect:clipRect];
	}
}

//Override to prevent drawing glitches; otherwise, the cell will try to draw a highlight, too
- (id)_highlightColorForCell:(NSCell *)cell
{
	if (drawsGradientSelection && [[self window] isKeyWindow] && ([[self window] firstResponder] == self)) {
		return nil;
	} else {
		return [super _highlightColorForCell:cell];
	}
}

#pragma mark Grid

- (void)drawGridInClipRect:(NSRect)rect
{
    if (drawsBackground && [self usesAlternatingRowBackgroundColors]) {
		//We do our grid drawing later
	} else {
		[super drawGridInClipRect:rect];
	}
}

- (void)_drawGridInClipRect:(NSRect)rect
{
    NSEnumerator	*enumerator;
    NSTableColumn	*column;
    CGFloat		xPos = 0.5f;
    CGFloat			intercellWidth = [self intercellSpacing].width;
    
    [[self gridColor] set];
    [NSBezierPath setDefaultLineWidth:1.0f];

    enumerator = [[self tableColumns] objectEnumerator];
    while ((column = [enumerator nextObject])) {
        xPos += [column width] + intercellWidth;

        [NSBezierPath strokeLineFromPoint:NSMakePoint(xPos, rect.origin.y)
                                  toPoint:NSMakePoint(xPos, rect.origin.y + rect.size.height)];
    }
}

@end
