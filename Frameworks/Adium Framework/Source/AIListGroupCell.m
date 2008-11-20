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

#import <Adium/AIListGroupCell.h>
#import <Adium/AIListOutlineView.h>
#import <Adium/ESObjectWithProperties.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIGradientAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>

#define FLIPPY_TEXT_PADDING		4
#define GROUP_COUNT_PADDING		4

@implementation AIListGroupCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListGroupCell *newCell = [super copyWithZone:zone];
	
	newCell->shadowColor = [shadowColor retain];
	newCell->backgroundColor = [backgroundColor retain];
	newCell->gradientColor = [gradientColor retain];
	newCell->_gradient = [_gradient retain];
	newCell->layoutManager = [layoutManager retain];
	newCell->drawsGradientEdges = drawsGradientEdges;
	
	return newCell;
}

//Init
- (id)init
{
	if ((self = [super init])) {
		shadowColor = nil;
		backgroundColor = nil;
		gradientColor = nil;
		_gradient = nil;
		drawsGradientEdges = NO;
		layoutManager = [[NSLayoutManager alloc] init];
	}
	
	return self;
}

//Dealloc
- (void)dealloc
{
	[shadowColor release];
	[backgroundColor release];
	[gradientColor release];
	[layoutManager release];

	[self flushGradientCache];
	[super dealloc];
}


//Display Options ------------------------------------------------------------------------------------------------------
#pragma mark Display Options
//Color of our display name shadow
- (void)setShadowColor:(NSColor *)inColor
{
	if (inColor != shadowColor) {
		[shadowColor release];
		shadowColor = [inColor retain];
	}
}
- (NSColor *)shadowColor{
	return shadowColor;
}

//
- (void)setDrawsBackground:(BOOL)inValue
{
	drawsBackground = inValue;
}

//Set the background color and alternate/gradient background color of this group
- (void)setBackgroundColor:(NSColor *)inBackgroundColor gradientColor:(NSColor *)inGradientColor
{
	if (inBackgroundColor != backgroundColor) {
		[backgroundColor release];
		backgroundColor = [inBackgroundColor retain];
	}
	if (inGradientColor != gradientColor) {
		[gradientColor release];
		gradientColor = [inGradientColor retain];
	}
	
	//Reset gradient cache
	[self flushGradientCache];
}

//
- (void)setDrawsGradientEdges:(BOOL)inValue
{
	drawsGradientEdges = inValue;
}

- (void)setShowCollapsedCount:(BOOL)inValue
{
	showCollapsedCount = inValue;
}



//Sizing & Padding -----------------------------------------------------------------------------------------------------
#pragma mark Sizing & Padding
//Padding.  Gives our cell a bit of extra padding for the group name and flippy triangle (disclosure triangle)
- (int)topPadding{
	return [super topPadding] + 1;
}
- (int)bottomPadding{
	return [super bottomPadding] + 1;
}
- (int)leftPadding{
	return [super leftPadding] + 2;
}
- (int)rightPadding{
	return [super rightPadding] + 4;
}

//Cell height and width
- (NSSize)cellSize
{
	NSSize	size = [super cellSize];
	return NSMakeSize(0, [layoutManager defaultLineHeightForFont:[self font]] + size.height);
}
- (int)cellWidth
{
	NSAttributedString	*displayName;
	unsigned			width = [super cellWidth] + [self flippyIndent] + GROUP_COUNT_PADDING;
	
	//Get the size of our display name
	displayName = [[NSAttributedString alloc] initWithString:[self labelString] attributes:[self labelAttributes]];
	width += ceil([displayName size].width) + 1;
	[displayName release];
	
	if (([listObject boolValueForProperty:@"Show Count"] || (showCollapsedCount && ![controlView isItemExpanded:listObject])) && 
		[listObject valueForProperty:@"Count Text"]) {
		NSAttributedString *countText = [[NSAttributedString alloc] initWithString:[listObject valueForProperty:@"Count Text"]
																		attributes:[self labelAttributes]];
		width += ceil([countText size].width) + 1;
		[countText release];
	}
	
	return width + 1;
}

/*!
 * @brief Get the distance from left margin to our display name.
 *
 * This is the space used by the flippy triangle (disclosure triangle)... more or less.
 */
- (int)flippyIndent
{
//	if ([self textAlignment] != NSCenterTextAlignment) {
		NSSize size = [self cellSize];
		return size.height*.4 + size.height*.2 + FLIPPY_TEXT_PADDING;
/*	} else {
		return 0;
	}
*/
}


//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	//Draw flippy triangle (disclosure triangle)
	[[self flippyColor] set];
	
	NSBezierPath	*arrowPath = [NSBezierPath bezierPath];
	NSPoint			center = NSMakePoint(rect.origin.x + rect.size.height*.4, rect.origin.y + (rect.size.height/2.0));

	if ([controlView isItemExpanded:listObject]) {
		[arrowPath moveToPoint:NSMakePoint(center.x - rect.size.height*.3, center.y - rect.size.height*.15)];
		[arrowPath relativeLineToPoint:NSMakePoint( rect.size.height*.6, 0)];
		[arrowPath relativeLineToPoint:NSMakePoint(-rect.size.height*.3, rect.size.height*.4)];		
	} else {
		[arrowPath moveToPoint:NSMakePoint(center.x - rect.size.height*.2, center.y - rect.size.height*.3)];
		[arrowPath relativeLineToPoint:NSMakePoint( 0, rect.size.height*.6)];
		[arrowPath relativeLineToPoint:NSMakePoint( rect.size.height*.4, -rect.size.height*.3)];		
	}
		
	[arrowPath closePath];
	[arrowPath fill];

//	if ([self textAlignment] != NSCenterTextAlignment) {
		rect.origin.x += rect.size.height*.4 + rect.size.height*.2 + FLIPPY_TEXT_PADDING;
		rect.size.width -= rect.size.height*.4 + rect.size.height*.2 + FLIPPY_TEXT_PADDING;
//	}
	
	if ([listObject boolValueForProperty:@"Show Count"] ||
		(showCollapsedCount && ![controlView isItemExpanded:listObject])) {
		rect = [self drawGroupCountWithFrame:rect];
	}
	rect = [self drawDisplayNameWithFrame:rect];
}

- (NSRect)drawGroupCountWithFrame:(NSRect)inRect
{
	if ([listObject valueForProperty:@"Count Text"]) {
		NSAttributedString	*groupCount = [[NSAttributedString alloc] initWithString:[listObject valueForProperty:@"Count Text"]
																		  attributes:[self labelAttributes]];
		
		NSSize				countSize = [groupCount size];
		NSRect				rect = inRect;
		
		if (countSize.width + GROUP_COUNT_PADDING > rect.size.width) countSize.width = rect.size.width;
		if (countSize.height > rect.size.height) countSize.height = rect.size.height;
		
		if ([self textAlignment] == NSRightTextAlignment) {
			// If the alignment is on the left, we need to move the original rect's x origin to the right.
			inRect.origin.x += countSize.width + GROUP_COUNT_PADDING;
		} else {
			// If alignment is on the left or center, we need to move our drawing x origin to the right.
			rect.origin.x += (rect.size.width - countSize.width);
		}
		
		int half = ceil((rect.size.height - labelFontHeight) / 2.0);
		[groupCount drawInRect:NSMakeRect(rect.origin.x,
										  rect.origin.y + half,
										  rect.size.width,
										  countSize.height)];
			
		[groupCount release];
		
		inRect.size.width -= countSize.width + GROUP_COUNT_PADDING;
	}
	
	return inRect;
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if (![self cellIsSelected] && drawsBackground) {
		[[self cachedGradient:rect.size] drawInRect:rect
										   fromRect:NSMakeRect(0,0,rect.size.width,rect.size.height)
										  operation:NSCompositeCopy
										   fraction:1.0];
	}
}

//Color of our flippy triangle (disclosure triangle).  By default we use the cell's text color.
- (NSColor *)flippyColor
{
	return [self textColor];
}

/*!
 * @brief Additional label attributes
 *
 * We override the paragraph style to be truncating middle.
 * The user's layout preferences may have indicated to add a shadow to the text.
 */
- (NSDictionary *)additionalLabelAttributes
{
	NSMutableDictionary *additionalLabelAttributes = [NSMutableDictionary dictionary];
	
	if (shadowColor) {
		NSShadow	*shadow = [[[NSShadow alloc] init] autorelease];
		
		[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
		[shadow setShadowBlurRadius:2.0];
		[shadow setShadowColor:shadowColor];
		
		[additionalLabelAttributes setObject:shadow forKey:NSShadowAttributeName];
	}
	
	static NSMutableParagraphStyle *leftParagraphStyleWithTruncatingMiddle = nil;
	if (!leftParagraphStyleWithTruncatingMiddle) {
		leftParagraphStyleWithTruncatingMiddle = [[NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																			  lineBreakMode:NSLineBreakByTruncatingMiddle] retain];
	}

	[leftParagraphStyleWithTruncatingMiddle setMaximumLineHeight:(float)labelFontHeight];

	[additionalLabelAttributes setObject:leftParagraphStyleWithTruncatingMiddle
								  forKey:NSParagraphStyleAttributeName];
	
	return additionalLabelAttributes;
}


//Gradient -------------------------------------------------------------------------------------------------------------
#pragma mark Gradient
//Generates and caches an NSImage containing the group background gradient
- (NSImage *)cachedGradient:(NSSize)inSize
{
	if (!_gradient || !NSEqualSizes(inSize,_gradientSize)) {
		[_gradient release];
		_gradient = [[NSImage alloc] initWithSize:inSize];
		_gradientSize = inSize;
		
		[_gradient lockFocus];
		[self drawBackgroundGradientInRect:NSMakeRect(0,0,inSize.width,inSize.height)];
		[_gradient unlockFocus];
	}
	
	return _gradient;
}

//Draw our background gradient
- (void)drawBackgroundGradientInRect:(NSRect)inRect
{
	CGFloat backgroundL;
	CGFloat gradientL;
	
	//Gradient
	[[self backgroundGradient] drawInRect:inRect angle:90.0];
	
	//Add a sealing line at the light side of the gradient to make it look more polished.  Apple does this with
	//most gradients in OS X.
	[backgroundColor getHue:NULL saturation:NULL brightness:&backgroundL alpha:NULL];
	[gradientColor   getHue:NULL saturation:NULL brightness:&gradientL   alpha:NULL];
	
	if (gradientL < backgroundL) { //Seal the top
		[gradientColor set];
		[NSBezierPath fillRect:NSMakeRect(inRect.origin.x, inRect.origin.y, inRect.size.width, 1)];
	} else { //Seal the bottom
		[backgroundColor set];
		[NSBezierPath fillRect:NSMakeRect(inRect.origin.x, inRect.origin.y + inRect.size.height - 1, inRect.size.width, 1)];
	}
	
	//Seal the edges
	if (drawsGradientEdges) {
		[NSBezierPath fillRect:NSMakeRect(inRect.origin.x, inRect.origin.y, 1, inRect.size.height)];
		[NSBezierPath fillRect:NSMakeRect(inRect.origin.x+inRect.size.width-1, inRect.origin.y, 1, inRect.size.height)];
	}
}

//Group background gradient
- (NSGradient *)backgroundGradient
{
	return [[[NSGradient alloc] initWithStartingColor:backgroundColor endingColor:gradientColor] autorelease];
}

//Reset gradient cache
- (void)flushGradientCache
{
	[_gradient release]; _gradient = nil;
}

@end
