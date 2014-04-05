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

#import <Adium/AIListContactBubbleCell.h>
#import <Adium/AIListOutlineView.h>
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIGradientAdditions.h>

#define EDGE_INDENT 			4

@interface AIListContactBubbleCell ()

@end

@implementation AIListContactBubbleCell

- (id)init
{
	if ((self = [super init]))
	{
		lastBackgroundBezierPath = nil;
		outlineBubble = NO;
		outlineBubbleLineWidth = 1.0f;
		drawWithGradient = NO;
	}	
	
	return self;
}

//Copy
- (AIListContactBubbleCell *)copyWithZone:(NSZone *)zone
{
	AIListContactBubbleCell *newCell = [super copyWithZone:zone];
	newCell->lastBackgroundBezierPath = lastBackgroundBezierPath;
	
	return newCell;
}

//Give ourselves extra padding to compensate for the rounded bubble
- (CGFloat)leftPadding{
	return [super leftPadding] + EDGE_INDENT;
}
- (CGFloat)rightPadding{
	return [super rightPadding] + EDGE_INDENT;
}

- (CGFloat)cellWidth
{
	CGFloat		width = [super cellWidth];

	return width + EDGE_INDENT;
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if (![self cellIsSelected]) {
		NSColor	*labelColor;
		
		//Label color.  If there is no label color we draw the background color (taking care of gridding if needed)
		//We cannot use the regular table background drawing for bubble cells because of our rounded corners
		labelColor = [self labelColor];
		if (!labelColor) labelColor = [self backgroundColor];
		
		//Draw our background with rounded corners, retaining the bezier path for use in drawUserIconInRect:position:
		lastBackgroundBezierPath = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]];
		
		//Draw using a (slow) AIGradient if requested, otherwise just fill
		if (drawWithGradient) {
			
			NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:labelColor endingColor:[labelColor darkenAndAdjustSaturationBy:0.4f]];
			[gradient drawInBezierPath:lastBackgroundBezierPath angle:90.0f];
			
		} else {
			[labelColor set];
			[lastBackgroundBezierPath fill];
		}
		
		//Draw an outline around the bubble in the textColor if requested
		if (outlineBubble) {
			[lastBackgroundBezierPath setLineWidth:outlineBubbleLineWidth];
			[[self textColor] set];
			[lastBackgroundBezierPath stroke];
		}
	}
}

//Draw a custom selection
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	if ([self cellIsSelected]) {
		NSColor *highlightColor = [controlView highlightColor];
		NSGradient 	*gradient = highlightColor
			? [[NSGradient alloc] initWithStartingColor:highlightColor endingColor:[highlightColor darkenAndAdjustSaturationBy:0.4f]]
			: [NSGradient selectedControlGradient];

		lastBackgroundBezierPath = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:cellFrame]];

		//Draw our bubble with the selected control gradient
		[gradient drawInBezierPath:lastBackgroundBezierPath angle:90.0f];
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

//User Icon, clipping to the last bezier path (which should have been part of this same drawing operation)
- (NSRect)drawUserIconInRect:(NSRect)inRect position:(IMAGE_POSITION)position
{
	NSRect	returnRect;
	
	[NSGraphicsContext saveGraphicsState];

	[lastBackgroundBezierPath addClip];
	
	returnRect = [super drawUserIconInRect:inRect position:position];

	[NSGraphicsContext restoreGraphicsState];
	
	return returnRect;
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

- (void)setDrawWithGradient:(BOOL)flag
{
	drawWithGradient = flag;
}

@end
