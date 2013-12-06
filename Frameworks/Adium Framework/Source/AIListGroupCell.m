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
#import <Adium/AIListObject.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>

#define FLIPPY_TEXT_PADDING		4
#define GROUP_COUNT_PADDING		4

@implementation AIListGroupCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListGroupCell *newCell = [super copyWithZone:zone];
	
	newCell->shadowColor = shadowColor;
	newCell->backgroundColor = backgroundColor;
	newCell->gradientColor = gradientColor;
	newCell->_gradient = _gradient;
	newCell->layoutManager = layoutManager;
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
	[self flushGradientCache];
}


//Display Options ------------------------------------------------------------------------------------------------------
#pragma mark Display Options
//Color of our display name shadow
- (void)setShadowColor:(NSColor *)inColor
{
	if (inColor != shadowColor) {
		shadowColor = inColor;
	}
	labelAttributes = nil;
}
- (NSColor *)shadowColor{
	return shadowColor;
}

- (void)setDrawsBackground:(BOOL)inValue
{
	drawsBackground = inValue;
}

//Set the background color and alternate/gradient background color of this group
- (void)setBackgroundColor:(NSColor *)inBackgroundColor gradientColor:(NSColor *)inGradientColor
{
	if (inBackgroundColor != backgroundColor) {
		backgroundColor = inBackgroundColor;
	}
	if (inGradientColor != gradientColor) {
		gradientColor = inGradientColor;
	}
	
	//Reset gradient cache
	[self flushGradientCache];
}

- (void)setDrawsGradientEdges:(BOOL)inValue
{
	drawsGradientEdges = inValue;
}

//Sizing & Padding -----------------------------------------------------------------------------------------------------
#pragma mark Sizing & Padding
//Padding.  Gives our cell a bit of extra padding for the group name and flippy triangle (disclosure triangle)
- (CGFloat)topPadding{
	return [super topPadding] + 1;
}
- (CGFloat)bottomPadding{
	return [super bottomPadding] + 1;
}
- (CGFloat)leftPadding{
	return [super leftPadding] + 2;
}
- (CGFloat)rightPadding{
	return [super rightPadding] + 4;
}

//Cell height and width
- (NSSize)cellSize
{
	NSSize	size = [super cellSize];
	return NSMakeSize(0, [layoutManager defaultLineHeightForFont:[self font]] + size.height);
}
- (CGFloat)cellWidth
{
	AIListObject    *listObject = [proxyObject listObject];
	CGFloat			width = [super cellWidth] + [self flippyIndent] + GROUP_COUNT_PADDING;
	
	//Get the size of our display name
	width += AIceil(self.displayNameSize.width) + 1;
	
	if ([listObject boolValueForProperty:@"showCount"] && 
		[listObject valueForProperty:@"countText"]) {
		NSAttributedString *countText = [[NSAttributedString alloc] initWithString:[listObject valueForProperty:@"countText"]
																		attributes:[self labelAttributes]];
		width += AIceil([countText size].width) + 1;
	}
	
	return width + 1;
}

/*!
 * @brief Get the distance from left margin to our display name.
 *
 * This is the space used by the flippy triangle (disclosure triangle)... more or less.
 */
- (CGFloat)flippyIndent
{
	NSSize size = [self cellSize];
	return size.height*0.4f + size.height*0.2f + FLIPPY_TEXT_PADDING;
}


//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
    AIListObject *listObject = [proxyObject listObject];
    
	//Draw flippy triangle (disclosure triangle)
	[[self flippyColor] set];
	
	NSBezierPath	*arrowPath = [NSBezierPath bezierPath];
	NSPoint			center = NSMakePoint(rect.origin.x + rect.size.height*0.4f, rect.origin.y + (rect.size.height/2.0f));

	if ([controlView isItemExpanded:proxyObject]) {
		[arrowPath moveToPoint:NSMakePoint(center.x - rect.size.height*0.3f, center.y - rect.size.height*0.15f)];
		[arrowPath relativeLineToPoint:NSMakePoint( rect.size.height*0.6f, 0)];
		[arrowPath relativeLineToPoint:NSMakePoint(-rect.size.height*0.3f, rect.size.height*0.4f)];		
	} else {
		[arrowPath moveToPoint:NSMakePoint(center.x - rect.size.height*0.2f, center.y - rect.size.height*0.3f)];
		[arrowPath relativeLineToPoint:NSMakePoint( 0, rect.size.height*0.6f)];
		[arrowPath relativeLineToPoint:NSMakePoint( rect.size.height*0.4f, -rect.size.height*0.3f)];		
	}
		
	[arrowPath closePath];
	[arrowPath fill];

	rect.origin.x += rect.size.height*0.4f + rect.size.height*0.2f + FLIPPY_TEXT_PADDING;
	rect.size.width -= rect.size.height*0.4f + rect.size.height*0.2f + FLIPPY_TEXT_PADDING;
	
	if ([listObject boolValueForProperty:@"showCount"]) {
		rect = [self drawGroupCountWithFrame:rect];
	}
	
	[self drawDisplayNameWithFrame:rect];
}

- (NSRect)drawGroupCountWithFrame:(NSRect)inRect
{
    AIListObject *listObject = [proxyObject listObject];

	if ([listObject valueForProperty:@"countText"]) {
		NSAttributedString	*groupCount = [[NSAttributedString alloc] initWithString:[listObject valueForProperty:@"countText"]
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
		
		CGFloat half = AIceil((rect.size.height - labelFontHeight) / 2.0f);
		[groupCount drawInRect:NSMakeRect(rect.origin.x,
										  rect.origin.y + half,
										  rect.size.width,
										  countSize.height)];
		
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
										   fraction:1.0f];
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
- (NSMutableDictionary *)labelAttributes
{
	if (!labelAttributes) {
		labelAttributes = super.labelAttributes;
		
		if (shadowColor) {
			NSShadow	*textShadow = [[NSShadow alloc] init];
			
			[textShadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
			[textShadow setShadowBlurRadius:2.0f];
			[textShadow setShadowColor:shadowColor];
			
			[labelAttributes setObject:textShadow forKey:NSShadowAttributeName];
		}
	}
	
	static NSMutableParagraphStyle *leftParagraphStyleWithTruncatingMiddle = nil;
	if (!leftParagraphStyleWithTruncatingMiddle) {
		leftParagraphStyleWithTruncatingMiddle = [NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																			  lineBreakMode:NSLineBreakByTruncatingMiddle];
	}

	[leftParagraphStyleWithTruncatingMiddle setMaximumLineHeight:(float)labelFontHeight];

	[labelAttributes setObject:leftParagraphStyleWithTruncatingMiddle
								  forKey:NSParagraphStyleAttributeName];
	
	return labelAttributes;
}


//Gradient -------------------------------------------------------------------------------------------------------------
#pragma mark Gradient
//Generates and caches an NSImage containing the group background gradient
- (NSImage *)cachedGradient:(NSSize)inSize
{
	if (!_gradient || !NSEqualSizes(inSize,_gradientSize)) {
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
	[[self backgroundGradient] drawInRect:inRect angle:90.0f];
	
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
	return [[NSGradient alloc] initWithStartingColor:backgroundColor endingColor:gradientColor];
}

//Reset gradient cache
- (void)flushGradientCache
{
	_gradient = nil;
}

@end
