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
#import <AIUtilities/AIGradient.h>

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
		outlineBubbleLineWidth = 1.0;
		drawWithGradient = NO;
	}	
	
	return self;
}

//Copy
- (AIListContactBubbleCell *)copyWithZone:(NSZone *)zone
{
	AIListContactBubbleCell *newCell = [super copyWithZone:zone];
	newCell->lastBackgroundBezierPath = [lastBackgroundBezierPath retain];
	
	return newCell;
}

- (void)dealloc
{
	[lastBackgroundBezierPath release]; lastBackgroundBezierPath = nil;
	
	[super dealloc];
}

//Give ourselves extra padding to compensate for the rounded bubble
- (int)leftPadding{
	return [super leftPadding] + EDGE_INDENT;
}
- (int)rightPadding{
	return [super rightPadding] + EDGE_INDENT;
}

- (int)cellWidth
{
	int		width = [super cellWidth];

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
		[lastBackgroundBezierPath release];
		lastBackgroundBezierPath = [[NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]] retain];
		
		//Draw using a (slow) AIGradient if requested, otherwise just fill
		if (drawWithGradient) {
			AIGradient	*gradient;
			
			gradient = [AIGradient gradientWithFirstColor:labelColor
											  secondColor:[labelColor darkenAndAdjustSaturationBy:0.4] 
												direction:AIVertical];
			[gradient drawInBezierPath:lastBackgroundBezierPath];
			
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
		AIGradient 	*gradient = highlightColor
			? [AIGradient gradientWithFirstColor:highlightColor
			                         secondColor:[highlightColor darkenAndAdjustSaturationBy:0.4] 
			                           direction:AIVertical]
			: [AIGradient selectedControlGradientWithDirection:AIVertical];

		[lastBackgroundBezierPath release];
		lastBackgroundBezierPath = [[NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:cellFrame]] retain];

		//Draw our bubble with the selected control gradient
		[gradient drawInBezierPath:lastBackgroundBezierPath];
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
	rect.origin.x += DROP_HIGHLIGHT_WIDTH_MARGIN / 2.0;
	
	rect.size.height -= DROP_HIGHLIGHT_HEIGHT_MARGIN;
	rect.origin.y += DROP_HIGHLIGHT_HEIGHT_MARGIN / 2.0;	
	
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]];
	
	[[[NSColor blueColor] colorWithAlphaComponent:0.2] set];
	[path fill];
	
	[[[NSColor blueColor] colorWithAlphaComponent:0.8] set];
	[path setLineWidth:2.0];
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
