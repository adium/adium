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

/* 
	Cocoa wrapper around lower level gradient drawing functions.  Draws simple gradients.
 */

#import "AIGradient.h"
#import "AIColorAdditions.h"
#import "AITigerCompatibility.h"

@interface AIGradient (PRIVATE)
- (id)initWithFirstColor:(NSColor*)inColor1 secondColor:(NSColor*)inColor2 direction:(enum AIDirection)inDirection;
@end

//RGB Color
struct FloatRGB {
	CGFloat red;
	CGFloat green;
	CGFloat blue;
	CGFloat alpha;
};

//Start and end colors of a gradient
struct TwoColors {
	struct FloatRGB start;
	struct FloatRGB end;
};

//Number of bits for each component of a colour value.
//for a 24-bit RGB value, this is 8.
//for a 32-bit RGBA value (which is what this code uses), this is still 8.
enum {
	componentsPerPixel = 4, //RGBA
	bitsPerComponent = 8,
	bitsPerPixel = bitsPerComponent * componentsPerPixel
};

void returnColorValue(void *refcon, const CGFloat *blendPoint, CGFloat *output);
int BlendColors(struct FloatRGB *result, struct FloatRGB *a, struct FloatRGB *b, float scale);
CGPathRef CreateCGPathWithNSBezierPath(const CGAffineTransform *transform, NSBezierPath *bezierPath);

@implementation AIGradient

#pragma mark Class Initialization
+ (AIGradient*)gradientWithFirstColor:(NSColor*)inColor1
						  secondColor:(NSColor*)inColor2
							direction:(enum AIDirection)inDirection
{
	return ([[[self alloc] initWithFirstColor:inColor1 secondColor:inColor2 direction:inDirection] autorelease]);
}

+ (AIGradient*)selectedControlGradientWithDirection:(enum AIDirection)inDirection
{
	NSColor *selectedColor = [NSColor alternateSelectedControlColor];
	
	return ([self gradientWithFirstColor:[selectedColor darkenAndAdjustSaturationBy:-0.1] secondColor:[selectedColor darkenAndAdjustSaturationBy:0.1] direction:inDirection]);
}

- (id)initWithFirstColor:(NSColor*)inColor1
			 secondColor:(NSColor*)inColor2
			   direction:(enum AIDirection)inDirection
{
	if ((self = [self init])) {
		[self setFirstColor:inColor1];
		[self setSecondColor:inColor2];
		[self setDirection:inDirection];
	}
	return self;
}

- (void)dealloc
{
	[color1 release];
	[color2 release];
	[super dealloc];
}



//Configure ------------------------------------------------------------------------------------------------------------
#pragma mark Configure
//Gradient start color
- (void)setFirstColor:(NSColor*)inColor{
	if (color1 != inColor) {
		[color1 release];
		color1 = [inColor retain];
	}
}
- (NSColor*)firstColor{
	return color1;
}

//Gradient end color
- (void)setSecondColor:(NSColor*)inColor
{
	if (color2 != inColor) {
		[color2 release];
		color2 = [inColor retain];
	}
}
- (NSColor*)secondColor{
	return color2;
}

//Gradient Direction
- (void)setDirection:(enum AIDirection)inDirection{
	direction = inDirection;
}
- (enum AIDirection)direction{
	return direction;
}


//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
//Draw in a rect
- (void)drawInRect:(NSRect)inRect
{
	//Non-integer widths will crash this code!
	inRect = NSMakeRect((int)inRect.origin.x, (int)inRect.origin.y, (int)inRect.size.width, (int)inRect.size.height);
	
	[self drawInBezierPath:[NSBezierPath bezierPathWithRect:inRect]];
}

//Draw within a bezier path
- (void)drawInBezierPath:(NSBezierPath *)inPath
{   
	NSRect inRect = [inPath bounds];
	float   width  = inRect.size.width;
	float	height = inRect.size.height;

	struct TwoColors blendPoints;
	NSColor *startColor = [color1 retain], *endColor = [color2 retain], *temp;

	if (![[startColor colorSpaceName] isEqualToString:NSDeviceRGBColorSpace]) {
		temp = startColor;
		startColor = [[startColor colorUsingColorSpaceName:NSDeviceRGBColorSpace] retain];
		[temp release];
	}

	if (![[endColor colorSpaceName] isEqualToString:NSDeviceRGBColorSpace]) {
		temp = endColor;
		endColor = [[endColor colorUsingColorSpaceName:NSDeviceRGBColorSpace] retain];
		[temp release];
	}

	[startColor getRed:&(blendPoints.start.red)
	             green:&(blendPoints.start.green)
	              blue:&(blendPoints.start.blue)
	             alpha:&(blendPoints.start.alpha)];

	[endColor getRed:&(blendPoints.end.red)
	           green:&(blendPoints.end.green)
	            blue:&(blendPoints.end.blue)
	           alpha:&(blendPoints.end.alpha)];

	[startColor release];
	[endColor release];

	CGFunctionCallbacks callbacks = { 0, returnColorValue, NULL };
	
	CGFunctionRef function = CGFunctionCreate(
		&blendPoints,	// void *info,
		1,				// size_t domainDimension,
		NULL,			// float const *domain,
		4,				// size_t rangeDimension,
		NULL,			// float const *range,
		&callbacks		// CGFunctionCallbacks const *callbacks
	);
	if (function != NULL) {
		CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
		if (cspace != NULL) {
			CGPoint srcPt, dstPt;

			if (direction == AIVertical) {
				//draw the gradient from the bottom middle to the top middle.
				srcPt.x = dstPt.x = inRect.origin.x + width * 0.5f;
				srcPt.y = inRect.origin.y;
				dstPt.y = inRect.origin.y + height;
			} else {
				//draw the gradient from the middle left to the middle right.
				srcPt.y = dstPt.y = inRect.origin.y + height * 0.5f;
				srcPt.x = inRect.origin.x;
				dstPt.x = inRect.origin.x + width;
			}

			CGShadingRef shading = CGShadingCreateAxial(
				cspace,		// CGColorSpaceRef colorspace,
				srcPt,		// CGPoint start,
				dstPt,		// CGPoint end,
				function,	// CGFunctionRef function,
				false,		// bool extendStart,
				false		// bool extendEnd
			);

			if (shading != NULL) {
				CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
				CGContextSaveGState(context);

				NSAssert2(context, @"%s: The Quartz graphics context that we obtained from the current NSGraphicsContext (%@) is NULL.", __PRETTY_FUNCTION__, context);
				CGContextBeginPath(context);

				//Drawing stuff
				CGPathRef pathToAdd = CreateCGPathWithNSBezierPath(/*transform*/ NULL, inPath); //thanks boredzo :)
				if (pathToAdd != NULL) {
					CGContextAddPath(context, pathToAdd);
					CGContextClip(context);

					CGContextDrawShading(context, shading);

					CGPathRelease(pathToAdd);
				} /* if (pathToAdd != NULL) */

				CGContextRestoreGState(context);

				CGShadingRelease(shading);
			} /* if (shading) */
			CGColorSpaceRelease(cspace);
		} /* if (cspace) */
		CGFunctionRelease(function);
	} /* if (function) */
}

@end

//C Functions ----------------------------------------------------------------------------------------------------------
#pragma mark C Functions

//returnColorValue
//
//callback function for Quartz shaders.
//simply returns a colour along a plane, where blendPoint = 0.0f represents the
//  start of the plane and blendPoint = 1.0f represents the end of it.
//1 input:   the blend-point.
//4 outputs: the four components (RGBA) of the colour resulting from the blend.
//reference constant: a pointer to a TwoColors value giving the start and end
//  points of the aforementioned plane.
void returnColorValue(void *refcon, const CGFloat *blendPoint, CGFloat *output) {
	struct TwoColors *gradient = refcon;

	//this version exploits the RGBA nature of the FloatRGB structure to gain
	//  speed.
	BlendColors((struct FloatRGB *)output, &(gradient->start), &(gradient->end), *blendPoint);

	//this version is slower, but will be correct no matter what format is used.
	//use this version instead if FloatRGB ever changes.
	/*
	struct FloatRGB newColor;
	
	BlendColors(&newColor, &(gradient->start), &(gradient->end), *blendPoint);

	output[0] = newColor.red;
	output[1] = newColor.green;
	output[2] = newColor.blue;
	output[3] = newColor.alpha;
	*/
}

//BlendColors
//
//blend two colours, a and b, biased by scale (0.0f-1.0f).
//components, as is typical of Quartz, are 0.0f-1.0f also.
//return value is 0 if successful or < 0 if not.

int BlendColors(register struct FloatRGB *result, register struct FloatRGB *a, register struct FloatRGB *b, register float scale) {
	//assure that the scale value is within the range of 0.0f-1.0f.
	if      (scale > 1.0f) scale = 1.0f;
	else if (scale < 0.0f) scale = 0.0f;

	register float scaleComplement = 1.0f - scale;
	result->alpha = scale * b->alpha + scaleComplement * a->alpha;
	scale		  = scale * a->alpha + scaleComplement * (1.0f - b->alpha);
	scaleComplement = 1.0f - scale;
	result->red   = scale * b->red   + scaleComplement * a->red;
 	result->green = scale * b->green + scaleComplement * a->green;
	result->blue  = scale * b->blue  + scaleComplement * a->blue;

	return 0;
}

//transform can be NULL. --boredzo
CGPathRef CreateCGPathWithNSBezierPath(const CGAffineTransform *transform, NSBezierPath *bezierPath) {
	CGMutablePathRef cgpath = CGPathCreateMutable();

	if (cgpath != NULL) {
		int numElements = [bezierPath elementCount];
		int curElement;
		NSBezierPathElement elementType;
		NSPoint points[3];

		for (curElement = 0; curElement < numElements; curElement++) {
			//the points are copied into our points array. --boredzo
			elementType = [bezierPath elementAtIndex:curElement associatedPoints:points];

			switch (elementType) {
				case NSMoveToBezierPathElement:
					CGPathMoveToPoint(cgpath, transform,
						points[0].x, points[0].y);
					break;
				case NSLineToBezierPathElement:
					CGPathAddLineToPoint(cgpath, transform,
						points[0].x, points[0].y);
					break;
				case NSCurveToBezierPathElement:
					CGPathAddCurveToPoint(cgpath, transform,
						points[0].x, points[0].y,
						points[1].x, points[1].y,
						points[2].x, points[2].y);
					break;
				case NSClosePathBezierPathElement:
					CGPathCloseSubpath(cgpath);
					break;
				default:
					/*do something here? --boredzo
					 *I don't know if there are any others... --colin
					 *there aren't, but if elementAtIndex:associatedPoints:
					 *  returns an invalid (error) value, we might want to
					 *  report that to the user or something --boredzo
					 */;
			} //switch (elementType)
		} //for (curElement = 0; curElement < numElements; curElement++)
	} //if (cgpath != NULL)

	return cgpath;
}
