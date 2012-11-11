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

#import "AIPreferenceCollectionView.h"
#import "AIPreferencePane.h"


@implementation AIPreferenceCollectionView
@synthesize highlightedIndex, matchedSearchIndexes, delegate;

- (void)setHighlightedIndex:(NSUInteger)anIndex
{
	if (highlightedIndex == anIndex)
		return;
	
	highlightedIndex = anIndex;
	[self setNeedsDisplay:YES];
}

- (void)awakeFromNib
{
	[self addObserver:self forKeyPath:@"matchedSearchIndexes"
			  options:(NSKeyValueObservingOptionNew)
			  context:NULL];
	
	highlightedIndex = NSNotFound;
}

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"matchedSearchIndexes"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	//Selection has changed
	if ([keyPath isEqualToString:@"matchedSearchIndexes"]) {
		[self setNeedsDisplay:YES];
	}
}

- (NSUInteger)indexAtPoint:(NSPoint)aPoint
{
	NSUInteger numberOfCols = [self maxNumberOfColumns];
	
	NSUInteger indexX = ceilf(aPoint.x / self.maxItemSize.width);
	NSUInteger indexY = ceilf(aPoint.y / self.maxItemSize.height);
	
	NSUInteger anIndex = (((indexY * numberOfCols) - (numberOfCols - indexX)) - 1);
	
	return (NSPointInRect(aPoint, [self frameForItemAtIndex:anIndex]) ? anIndex : NSNotFound);
}

- (void)mouseDown:(NSEvent *)theEvent
{
	//Highlight the item that the mouse is over
	NSUInteger itemID = [self indexAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
	if (itemID != NSNotFound && itemID < [[self content] count]) {
		[[self itemAtIndex:itemID] setSelected:YES];
		self.highlightedIndex = itemID;
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	self.highlightedIndex = NSNotFound;
	
	//Update the delegate
	NSUInteger itemID = [self indexAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
	if (itemID != NSNotFound && itemID < [[self content] count]) {
		if ([[self selectionIndexes] containsIndex:itemID])
			if ([[self delegate] respondsToSelector:@selector(preferenceCollectionView:didSelectItem:)])
				[[self delegate] preferenceCollectionView:self didSelectItem:[self itemAtIndex:itemID]];
	}
	
	//Unhighlight the selected item
	[[self selectionIndexes] enumerateIndexesUsingBlock:^(NSUInteger anIndex, BOOL *stop) {
		[[self itemAtIndex:anIndex] setSelected:NO];
	}];
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	id highlightItems = ^(NSUInteger anIndex, BOOL *stop) {
		if ([[self itemAtIndex:anIndex] isSelected])
			return;
		if (anIndex == self.highlightedIndex)
			[[NSColor whiteColor] set];
		else
			[[NSColor lightGrayColor] set];
		
		NSRect highlightRect = [self frameForItemAtIndex:anIndex];
		
		CGFloat radius = MIN(highlightRect.size.width, highlightRect.size.height);
		
		radius = radius * 0.9f;
		highlightRect.origin.x += (highlightRect.size.width - radius) / 2;
		
		highlightRect.size.width = radius;
		highlightRect.size.height = radius;
		
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:highlightRect
															 xRadius:radius
															 yRadius:radius];
		[path fill];
	};
	
	if ([self.selectionIndexes count] > 0)
		[self.selectionIndexes enumerateIndexesUsingBlock:highlightItems];
	else if ([self.matchedSearchIndexes count] > 0)
		[self.matchedSearchIndexes enumerateIndexesUsingBlock:highlightItems];
}

@end
