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


#import "AIImageCollectionView.h"


@interface AIImageCollectionView ()

- (void)AI_initImageCollectionView;

- (NSUInteger)indexAtPoint:(NSPoint)aPoint;

- (void)highlightItemAtIndex:(NSUInteger)anIndex;
- (void)selectItemAtIndex:(NSUInteger)anIndex;

- (void)resetHighlight;

@end


@implementation AIImageCollectionView

@dynamic delegate;
@synthesize itemsController;
@synthesize highlightStyle, highlightSize, highlightCornerRadius;
@synthesize highlightedIndex;


- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		// Initialize
		[self AI_initImageCollectionView];
	}	

	return self;
}

- (void)awakeFromNib
{
	// Initialize
	[self AI_initImageCollectionView];
}

/*!
 * @brief Initialize object using default values
 */
- (void)AI_initImageCollectionView
{
	highlightStyle = AIImageCollectionViewHighlightBorderStyle;
	highlightSize = 2.0f;
	highlightCornerRadius = 0.0f;
	
	highlightedIndex = NSNotFound;
	
	// Mouse Tracking
	[self addTrackingArea:[[[NSTrackingArea alloc] initWithRect:[self bounds]
														options:(NSTrackingMouseEnteredAndExited |
																 NSTrackingActiveInKeyWindow |
																 NSTrackingInVisibleRect)
														  owner:self
													   userInfo:nil] autorelease]];
	
	// Temporary solution, 1st tracking area will only report MouseMoved Events
	[self addTrackingArea:[[[NSTrackingArea alloc] initWithRect:[self bounds]
														options:(NSTrackingMouseMoved |
																 NSTrackingActiveInKeyWindow |
																 NSTrackingInVisibleRect)
														  owner:self
													   userInfo:nil] autorelease]];

	// Track for item's selection changes
	[self addObserver:self forKeyPath:@"selectionIndexes"
			  options:(NSKeyValueObservingOptionNew)
			  context:NULL];
	
	// Track for item's content changes
	[self addObserver:self forKeyPath:@"content"
			  options:(NSKeyValueObservingOptionNew)
			  context:NULL];
}

- (void)dealloc
{	
	[self removeObserver:self forKeyPath:@"selectionIndexes"];
	[self removeObserver:self forKeyPath:@"content"];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
	// Draw selection
	if ([[self selectionIndexes] count] > 0) {
		[[NSColor selectedMenuItemColor] set];
		
		[[self selectionIndexes] enumerateIndexesUsingBlock:^(NSUInteger anIndex, BOOL *stop) {
			NSRect highlightRect = [self frameForItemAtIndex:anIndex];
			
			// Adjust Pattern
			[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0.0f, NSMaxY([self convertRect:highlightRect toView:nil]))];
			
			// Adjust highlight rect
			highlightRect.origin.x += (highlightSize / 2);
			highlightRect.origin.y += (highlightSize / 2);
			highlightRect.size.width -= highlightSize;
			highlightRect.size.height -= highlightSize;
			
			NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:highlightRect	xRadius:[self highlightCornerRadius]
																						yRadius:[self highlightCornerRadius]];
			[path setLineWidth:[self highlightSize]];
			
			// Style
			switch ([self highlightStyle]) {
				// Border
				case AIImageCollectionViewHighlightBorderStyle:
					[path stroke];
					break;
					
				// Background
				case AIImageCollectionViewHighlightBackgroundStyle:
				default:
					[path fill];
					break;
			}
		}];
	}
	
	// Draw highlight
	if ([self highlightedIndex] != NSNotFound) {
		NSRect highlightRect = [[[self subviews] objectAtIndex:[self highlightedIndex]] frame];
		
		[[NSColor selectedMenuItemColor] set];
		
		// Adjust Pattern
		[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0.0f, NSMaxY([self convertRect:highlightRect toView:nil]))];
		
		// Adjust highlight rect
		highlightRect.origin.x += (highlightSize / 2);
		highlightRect.origin.y += (highlightSize / 2);
		highlightRect.size.width -= highlightSize;
		highlightRect.size.height -= highlightSize;
		
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:highlightRect 	xRadius:[self highlightCornerRadius]
															 						yRadius:[self highlightCornerRadius]];
		[path setLineWidth:[self highlightSize]];
		
		// Style
		switch ([self highlightStyle]) {
			// Border
			case AIImageCollectionViewHighlightBorderStyle:
				[path stroke];
				break;
			
			// Background
			case AIImageCollectionViewHighlightBackgroundStyle:
			default:
				[path fill];
				break;
		}
	}
}

#pragma mark -

/*!
 * Handle KVO
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// Selection has changed
	if ([keyPath isEqual:@"selectionIndexes"]) {
		[[change objectForKey:NSKeyValueChangeNewKey] enumerateIndexesUsingBlock:^(NSUInteger anIndex, BOOL *stop) {
			[self selectItemAtIndex:anIndex];
		}];

		// No selection
		if ([[self selectionIndexes] isEqualToIndexSet:[NSIndexSet indexSet]]) {
			[self selectItemAtIndex:NSNotFound];
		}
		
		[self setNeedsDisplay:YES];
	
	// Content has changed
    } else if ([keyPath isEqual:@"content"]) {
		// We don't want to highlight a removed item
		if ([self highlightedIndex] == [[self content] count]) {
			// Reset highlight
			[self resetHighlight];
		}
	}
}

#pragma mark -  AIImageCollectionView ()

/*!
 * @brief Called when an item is highlighted
 *
 * @param <tt>NSUInteger</tt>
 */
- (void)highlightItemAtIndex:(NSUInteger)anIndex
{
	// Set highlight
	if (anIndex != NSNotFound && anIndex < [[self content] count] && anIndex != [self highlightedIndex]) {
		// Message delegate: Should Highlight
		if ([[self delegate] respondsToSelector:@selector(imageCollectionView:shouldHighlightItemAtIndex:)]) {
			if ([[self delegate] imageCollectionView:self shouldHighlightItemAtIndex:anIndex]) {
				[self setHighlightedIndex:anIndex];
				[self setNeedsDisplay:YES];
				
				// Message delegate : Did Highlight
				if ([[self delegate] respondsToSelector:@selector(imageCollectionView:didHighlightItemAtIndex:)]) {
					[[self delegate] imageCollectionView:self didHighlightItemAtIndex:anIndex];
				}
			} else if ([self highlightedIndex] != NSNotFound) {
				// Reset highlight
				[self resetHighlight];
			}
		}
	} else if ([self highlightedIndex] != NSNotFound && (anIndex == NSNotFound || anIndex >= [[self content] count])) {
		// Reset highlight
		[self resetHighlight];
	}
}

/*!
 * @brief Called when an item is selected
 *
 * @param <tt>NSUInteger</tt>
 */
- (void)selectItemAtIndex:(NSUInteger)anIndex
{
	// Message delegate: Should Select
	if ([[self delegate] respondsToSelector:@selector(imageCollectionView:shouldSelectItemAtIndex:)]) {
		if ([[self delegate] imageCollectionView:self shouldSelectItemAtIndex:anIndex]) {
			// Message delegate : Did Select
			if ([[self delegate] respondsToSelector:@selector(imageCollectionView:didSelectItemAtIndex:)]) {
				[[self delegate] imageCollectionView:self didSelectItemAtIndex:anIndex];
			}
		} /*else {
			// @todo Reset selection
		}*/
	}
}

/*!
 * @brief Reset highlight
 *
 */
- (void)resetHighlight
{
	[self setHighlightedIndex:NSNotFound];
	[self setNeedsDisplay:YES];
	
	// Message delegate: Should Highlight
	if ([[self delegate] respondsToSelector:@selector(imageCollectionView:shouldHighlightItemAtIndex:)]) {
		[[self delegate] imageCollectionView:self shouldHighlightItemAtIndex:NSNotFound];
	}
}

/*!
 * @brief Return the item index at a point
 *
 * @param <tt>NSPoint</tt> aPoint - the point in local coords
 * @return <tt>NSUInteger</tt>
 */
- (NSUInteger)indexAtPoint:(NSPoint)aPoint
{
	NSUInteger numberOfCols = [self maxNumberOfColumns];

	NSUInteger indexX = AIceil(aPoint.x / self.maxItemSize.width);
	NSUInteger indexY = AIceil(aPoint.y / self.maxItemSize.height);
	
	NSUInteger anIndex = (((indexY * numberOfCols) - (numberOfCols - indexX)) - 1);
	
	return (NSPointInRect(aPoint, [self frameForItemAtIndex:anIndex]) ? anIndex : NSNotFound);
}

#pragma mark -

- (void)setImage:(NSImage *)anImage forItemAtIndex:(NSUInteger)anIndex
{
	if (anIndex != NSNotFound && anIndex < [[self content] count]) {
		[(NSImageView *)[[self itemAtIndex:anIndex] view] setImage:anImage];
	}
}

#pragma mark - Mouse Events 

- (void)mouseMoved:(NSEvent *)anEvent
{
	// Highlight item
	[self highlightItemAtIndex:[self indexAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]]];
	
	[super mouseMoved:anEvent];
}

- (void)mouseExited:(NSEvent *)anEvent
{
	// Reset highlight
	[self resetHighlight];
	
	[super mouseExited:anEvent];
}

- (void)scrollWheel:(NSEvent *)anEvent
{
	// Scrolling first
	[super scrollWheel:anEvent];
		
	// Highlight item
	[self highlightItemAtIndex:[self indexAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]]];
}

#pragma mark - Key Events

- (void)keyDown:(NSEvent *)anEvent
{
	// Delete
	if ([[self delegate] respondsToSelector:@selector(imageCollectionView:shouldDeleteItemsAtIndexes:)] && [[anEvent charactersIgnoringModifiers] length]) {
		unichar	pressedKey = [[anEvent charactersIgnoringModifiers] characterAtIndex:0];
		
		if (pressedKey == NSDeleteFunctionKey || pressedKey == NSBackspaceCharacter || pressedKey == NSDeleteCharacter) {
			// Delete selected items
			// Message delegate: Should Delete
			if ([[self delegate] imageCollectionView:self shouldDeleteItemsAtIndexes:[self selectionIndexes]] &&
				[[self delegate] respondsToSelector:@selector(imageCollectionView:didDeleteItemsAtIndexes:)]) {
				// Message delegate: Did Delete
				[[self delegate] imageCollectionView:self didDeleteItemsAtIndexes:[self selectionIndexes]];
			}
		}
	}
	
	[super keyDown:anEvent];
}

@end
