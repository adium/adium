/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIAlternatingRowTableView.h"
#import "AIGradient.h"
#import "AIImageAdditions.h"
#import "AIColorAdditions.h"
#import "AITigerCompatibility.h"

/*
 A subclass of table view that adds:

 - Alternating row colors
 - Delete key handling
 */

@interface AIAlternatingRowTableView (PRIVATE)
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected;
- (void)_initAlternatingRowTableView;
@end

@interface NSTableView (Undocumented)
- (id)_highlightColorForCell:(NSCell *)cell;
@end

@implementation AIAlternatingRowTableView

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self _initAlternatingRowTableView];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self _initAlternatingRowTableView];
	}
	return self;
}

- (void)_initAlternatingRowTableView
{
	acceptFirstMouse = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(alternatingRowTableViewSelectionDidChange:)
												 name:NSTableViewSelectionDidChangeNotification
											   object:self];	
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}


//Configuring ----------------------------------------------------------------------
- (void)setDrawsAlternatingRows:(BOOL)flag
{
	[self setUsesAlternatingRowBackgroundColors:flag];

    [self setNeedsDisplay:YES];
}

//Filter keydowns looking for the delete key (to delete the current selection)
- (void)keyDown:(NSEvent *)theEvent
{
    NSString	*charString = [theEvent charactersIgnoringModifiers];
    unichar		pressedChar = 0;

    //Get the pressed character
    if ([charString length] == 1) pressedChar = [charString characterAtIndex:0];

    //Check if 'delete' was pressed
    if (pressedChar == NSDeleteFunctionKey || pressedChar == NSBackspaceCharacter || pressedChar == NSDeleteCharacter) { //Delete
        if ([[self delegate] respondsToSelector:@selector(tableViewDeleteSelectedRows:)]) {
			[[self delegate] tableViewDeleteSelectedRows:self]; //Delete the selection
		}
    } else {
        [super keyDown:theEvent]; //Pass the key event on
    }
}

- (void)setDrawsGradientSelection:(BOOL)inDrawsGradientSelection
{
	drawsGradientSelection = inDrawsGradientSelection;
	[self setNeedsDisplay:YES];
}

- (BOOL)drawsGradientSelection
{
	return drawsGradientSelection;
}

// First mouse ----------------------------------------------------------------------
- (void)setAcceptsFirstMouse:(BOOL)inAcceptFirstMouse
{
	acceptFirstMouse = inAcceptFirstMouse;
}
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return acceptFirstMouse;
}

//Allow our delegate to specify context menus
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    if ([[self delegate] respondsToSelector:@selector(tableView:menuForEvent:)]) {
        return [[self delegate] tableView:self menuForEvent:theEvent];
    } else {
        return [super menuForEvent:theEvent];
    }
}

// Scrolling ----------------------------------------------------------------------
- (void)tile
{
    [super tile];

    [[self enclosingScrollView] setVerticalLineScroll: ([self rowHeight] + [self intercellSpacing].height) ];
}

#pragma mark Gradient selection and alternating rows
/*
 * @brief If we are drawing a gradient selection, returns the gradient to draw
 */
- (AIGradient *)selectedControlGradient
{
	return [AIGradient selectedControlGradientWithDirection:AIVertical];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
	if (drawsGradientSelection && [[self window] isKeyWindow] && ([[self window] firstResponder] == self)) {
		NSIndexSet *indices = [self selectedRowIndexes];
		unsigned int bufSize = [indices count];
		NSUInteger *buf = malloc(bufSize * sizeof(NSUInteger));
		unsigned int i = 0, j = 0;
		
		AIGradient *gradient = [self selectedControlGradient];
		
		NSRange range = NSMakeRange([indices firstIndex], ([indices lastIndex]-[indices firstIndex]) + 1);
		[indices getIndexes:buf maxCount:bufSize inIndexRange:&range];
		
		NSRect *selectionLineRects = (NSRect *)malloc(sizeof(NSRect) * bufSize);
		
		while (i < bufSize) {
			int startIndex = buf[i];
			int lastIndex = buf[i];
			while ((i + 1 < bufSize) &&
				   (buf[i + 1] == lastIndex + 1)){
				i++;
				lastIndex++;
			}
			
			NSRect thisRect = NSUnionRect([self rectOfRow:startIndex],
										  [self rectOfRow:lastIndex]);
			[gradient drawInRect:thisRect];
			
			//Draw a line at the light side, to make it look a lot cleaner
			thisRect.size.height = 1;
			selectionLineRects[j++] = thisRect;			
			
			i++;		
		}
		
		[[[gradient firstColor] darkenAndAdjustSaturationBy:0.1] set];
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

- (void)alternatingRowTableViewSelectionDidChange:(NSNotification *)notification
{
	if (drawsGradientSelection) {
		//We do fancy drawing, so we need a full redisplay when selection changes
		[self setNeedsDisplay:YES];
	}
}

@end
