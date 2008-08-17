//
//  CTGradient.h
//
//  Created by Chad Weider on 12/3/05.
//  Copyright (c) 2006 Cotingent.
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//
//  Version: 1.5

#import <Cocoa/Cocoa.h>

typedef struct _CTGradientElement 
	{
	CGFloat red, green, blue, alpha;
	CGFloat position;
	
	struct _CTGradientElement *nextElement;
	} CTGradientElement;

typedef enum  _CTBlendingMode
	{
	CTLinearBlendingMode,
	CTChromaticBlendingMode,
	CTInverseChromaticBlendingMode
	} CTGradientBlendingMode;


@interface CTGradient : NSObject <NSCopying, NSCoding>
	{
	CTGradientElement* elementList;
	CTGradientBlendingMode blendingMode;
	
	CGFunctionRef gradientFunction;
	}

+ (id)gradientWithBeginningColor:(NSColor *)begin endingColor:(NSColor *)end;

+ (id)aquaSelectedGradient;
+ (id)aquaNormalGradient;
+ (id)aquaPressedGradient;

+ (id)unifiedSelectedGradient;
+ (id)unifiedNormalGradient;
+ (id)unifiedPressedGradient;
+ (id)unifiedDarkGradient;

+ (id)rainbowGradient;
+ (id)hydrogenSpectrumGradient;

+ (id)sourceListSelectedGradient;
+ (id)sourceListUnselectedGradient;

- (CTGradient *)gradientWithAlphaComponent:(CGFloat)alpha;

- (CTGradient *)addColorStop:(NSColor *)color atPosition:(CGFloat)position;	//positions given relative to [0,1]
- (CTGradient *)removeColorStopAtIndex:(NSUInteger)index;
- (CTGradient *)removeColorStopAtPosition:(CGFloat)position;

- (CTGradientBlendingMode)blendingMode;
- (NSColor *)colorStopAtIndex:(NSUInteger)index;
- (NSColor *)colorAtPosition:(CGFloat)position;


- (void)drawSwatchInRect:(NSRect)rect;
- (void)fillRect:(NSRect)rect angle:(CGFloat)angle;					//fills rect with axial gradient
																	//	angle in degrees
- (void)radialFillRect:(NSRect)rect;								//fills rect with radial gradient
																	//  gradient from center outwards
@end
