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

- (void)selectItemAtIndex:(NSUInteger)index;

@end


@implementation AIImageCollectionView


@synthesize delegate;
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
																 NSTrackingActiveInKeyWindow)
														  owner:self
													   userInfo:nil] autorelease]];
	
	// Temporary solution, 1st tracking area will only report MouseMoved Events
	[self addTrackingArea:[[[NSTrackingArea alloc] initWithRect:[self bounds]
														options:(NSTrackingMouseMoved |
																 NSTrackingActiveInKeyWindow)
														  owner:self
													   userInfo:nil] autorelease]];
	
	// Track for item's selection
	[self addObserver:self forKeyPath:@"selectionIndexes"
			  options:(NSKeyValueObservingOptionNew)
			  context:NULL];
}

- (void)dealloc
{	
	[self removeObserver:self forKeyPath:@"selectionIndexes"];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
	// Draw highlight
	if ([self highlightedIndex] != NSNotFound) {
		NSRect highlightRect = [[[self subviews] objectAtIndex:[self highlightedIndex]] frame];
		
		[[NSColor selectedMenuItemColor] set];

		switch ([self highlightStyle]) {
			// Border Style
			case AIImageCollectionViewHighlightBorderStyle:
				// Adjust highlight rect
				highlightRect.origin.x += (highlightSize / 2);
				highlightRect.origin.y += (highlightSize / 2);
				highlightRect.size.width -= highlightSize;
				highlightRect.size.height -= highlightSize;
				
				NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:highlightRect xRadius:[self highlightCornerRadius] yRadius:[self highlightCornerRadius]];
				[path setLineWidth:[self highlightSize]];
				[path stroke];
				break;
			
			// Background Style
			case AIImageCollectionViewHighlightBackgroundStyle:
			default:
				NSRectFill(highlightRect);
				break;
		}
	}
}

#pragma mark -

/*!
 * We are registered to receive KVO notifiactions for "selectionIndexes"
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"selectionIndexes"]) {
		[self selectItemAtIndex:[[change objectForKey:NSKeyValueChangeNewKey] firstIndex]];
    }
}

/*!
 * @brief Called when an item is selected
 *
 * @return <tt>NSUInteger</tt>
 */
- (void)selectItemAtIndex:(NSUInteger)index
{
	// Message delegate: Should Select
	if ([delegate respondsToSelector:@selector(imageCollectionView:shouldSelectItemAtIndex:)]) {
		if ([delegate imageCollectionView:self shouldSelectItemAtIndex:index]) {
			// Message delegate : Did Select
			if ([delegate respondsToSelector:@selector(imageCollectionView:didSelectItemAtIndex:)]) {
				[delegate imageCollectionView:self didSelectItemAtIndex:index];
			}
		}
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
	CGFloat itemWidth = self.maxItemSize.width;
	CGFloat itemHeight = self.maxItemSize.height;
	NSUInteger numberOfCols = [self maxNumberOfColumns];
	
	NSUInteger indexX = ceil(aPoint.x / itemWidth);
	NSUInteger indexY = ceil(aPoint.y / itemHeight);

	return (((indexY * numberOfCols) - (numberOfCols - indexX)) - 1);
}

#pragma mark -
#pragma mark Mouse Events 

- (void)mouseMoved:(NSEvent *)anEvent
{
	NSUInteger newHighlightedIndex = [self indexAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]];
	
	// Set highlight
	if (newHighlightedIndex < [[self content] count] && [self highlightedIndex] != newHighlightedIndex) {
		// Message delegate: Should Highlight
		if ([delegate respondsToSelector:@selector(imageCollectionView:shouldHighlightItemAtIndex:)]) {
			if ([delegate imageCollectionView:self shouldHighlightItemAtIndex:newHighlightedIndex]) {
				[self setHighlightedIndex:newHighlightedIndex];
				[self setNeedsDisplay:YES];
				
				// Message delegate : Did Highlight
				if ([delegate respondsToSelector:@selector(imageCollectionView:didHighlightItemAtIndex:)]) {
					[delegate imageCollectionView:self didHighlightItemAtIndex:newHighlightedIndex];
				}
			} else {
				// Reset highlight index
				[self setHighlightedIndex:NSNotFound];
				[self setNeedsDisplay:YES];
			}
		}
	}
}

- (void)mouseExited:(NSEvent *)anEvent
{
	// Reset highlight index
	[self setHighlightedIndex:NSNotFound];
	[self setNeedsDisplay:YES];
}

@end
