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

#import <Adium/AIListGroupBubbleCell.h>
#import <Adium/AIListOutlineView.h>
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIGradientAdditions.h>
#import <AIUtilities/AIColorAdditions.h>

#define EDGE_INDENT 			4

@implementation AIListGroupBubbleCell

- (id)init
{
	if ((self = [super init]))
	{
		outlineBubble = NO;
		outlineBubbleLineWidth = 1.0f;
		drawBubble = YES;
	}
	
	return self;
}

//Give ourselves extra padding to compensate for the rounded bubble
- (CGFloat)leftPadding{
	return [super leftPadding] + EDGE_INDENT;
}
- (CGFloat)rightPadding{
	return [super rightPadding] + EDGE_INDENT;
}

//Draw a regular bubble background for our cell if gradient background drawing is disabled
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if (drawBubble) {
		if (drawsBackground) {
			[super drawBackgroundWithFrame:[self bubbleRectForFrame:rect]];
		} else {
			if (![self cellIsSelected]) {
				NSBezierPath	*bezierPath;
				
				[[self backgroundColor] set];
				bezierPath = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]];
				
				[bezierPath fill];
				
				if (outlineBubble) {
					[bezierPath setLineWidth:outlineBubbleLineWidth];
					[[self textColor] set];
					[bezierPath stroke];
				}
			}
		}
	}
}

//Draw a custom selection
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	if ([self cellIsSelected]) {
		NSColor *highlightColor = [self.outlineControlView highlightColor];
		NSGradient 	*gradient = (highlightColor ?
								 [[[NSGradient alloc] initWithStartingColor:highlightColor endingColor:[highlightColor darkenAndAdjustSaturationBy:0.4f]] autorelease] :
								 [NSGradient selectedControlGradient]);
		[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:cellFrame]] angle:270.0f];
	}
}

//Draw our background gradient bubble
- (void)drawBackgroundGradientInRect:(NSRect)inRect
{
	if (drawBubble) {
		NSBezierPath	*bezierPath;
		
		bezierPath = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:inRect]];
		[[self backgroundGradient] drawInBezierPath:bezierPath angle:90.0f];
		
		if (outlineBubble) {
			[bezierPath setLineWidth:outlineBubbleLineWidth];
			[[self textColor] set];
			[bezierPath stroke];
		}
	}
}

- (void)drawDropHighlightWithFrame:(NSRect)rect
{	
	[NSGraphicsContext saveGraphicsState];

	//Ensure we don't draw outside our rect
	[[NSBezierPath bezierPathWithRect:rect] addClip];

	//Cell spacing
	rect.origin.y += [self topSpacing];
	rect.size.height -= [self bottomSpacing] + [self topSpacing];
	rect.origin.x += [self leftSpacing];
	rect.size.width -= [self rightSpacing] + [self leftSpacing];
	
	//Margin for the drop highlight
	rect.size.width -= DROP_HIGHLIGHT_WIDTH_MARGIN;
	rect.origin.x += DROP_HIGHLIGHT_WIDTH_MARGIN / 2.0f;
	
	rect.size.height -= DROP_HIGHLIGHT_HEIGHT_MARGIN;
	rect.origin.y += DROP_HIGHLIGHT_HEIGHT_MARGIN / 2.0f;	
	
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]];

	[[[NSColor blueColor] colorWithAlphaComponent:0.2f] set];
	[path fill];
	
	[[[NSColor blueColor] colorWithAlphaComponent:0.8f] set];
	[path setLineWidth:2.0f];
	[path stroke];
	
	[NSGraphicsContext restoreGraphicsState];	
}

//Pass drawing rects through this method before drawing a bubble.  This allows us to make adjustments to bubble
//positioning and size.
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	return rect;
}

//Because of the rounded corners, we cannot rely on the outline view to draw our grid.  Return NO here to let
//the outline view know we'll be drawing the grid ourself
- (BOOL)drawGridBehindCell
{
	return NO;
}

- (void)setOutlineBubble:(BOOL)flag
{
	outlineBubble = flag;
}
- (void)setOutlineBubbleLineWidth:(float)inWidth
{
	outlineBubbleLineWidth = inWidth;
}

- (void)setHideBubble:(BOOL)flag
{
	drawBubble = !(flag);
}

@end
