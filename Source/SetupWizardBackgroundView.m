//
//  SetupWizardBackgroundView.m
//  Adium
//
//  Created by Evan Schoenberg on 12/4/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "SetupWizardBackgroundView.h"
#import <AIUtilities/AIImageDrawingAdditions.h>

@implementation SetupWizardBackgroundView

- (id)initWithFrame:(NSRect)inFrame
{
	if ((self = [super initWithFrame:inFrame])) {
		transparentRect = NSZeroRect;
	}

	return self;
}

- (void)setBackgroundImage:(NSImage *)inImage
{
	if (backgroundImage != inImage) {
		[backgroundImage release];
		backgroundImage = [inImage retain];	
	}
	
	[self setNeedsDisplay:YES];
}

- (void) dealloc {
	[backgroundImage release]; backgroundImage = nil;
	[super dealloc];
}

- (void)setTransparentRect:(NSRect)inTransparentRect
{
	transparentRect = inTransparentRect;

	[self setNeedsDisplay:YES];
}

/*!
 * @brief Draw our background image
 *
 * The image is drawn faded behind our content view and solid elsewhere.
 *
 * Random Things I Remembered note: Unless you have a good reason, you always want to use -[NSBezierPath addClip], not -[NSBezierPath setClip],
 * so you take into account the existing clip rect.
 */
- (void)drawRect:(NSRect)rect {
	NSRect		 imageDrawingRect = NSInsetRect([self bounds], 3, 0);

	if (backgroundImage && NSIntersectsRect(imageDrawingRect, rect)) {
		NSSize		 imageSize = [backgroundImage size];
		NSBezierPath *path;

		//Clip to our content view and draw faded if we're supposed to draw in that area
		path = [NSBezierPath bezierPathWithRect:transparentRect];
		if (NSIntersectsRect(transparentRect, rect)) {
			[NSGraphicsContext saveGraphicsState];
			[path addClip];
			
			[backgroundImage drawInRect:imageDrawingRect
								 atSize:imageSize
							   position:IMAGE_POSITION_LEFT
							   fraction:.30f];
			[NSGraphicsContext restoreGraphicsState];
		}		

		//Now clip to everywhere that isn't our content view and draw non-faded
		[path appendBezierPathWithRect:NSInsetRect([self bounds], -1, -1)];
		[path setWindingRule:NSEvenOddWindingRule];

		[NSGraphicsContext saveGraphicsState];
		[path addClip];
	
		[backgroundImage drawInRect:imageDrawingRect
							 atSize:imageSize
						   position:IMAGE_POSITION_LEFT
						   fraction:1.0f];
		[NSGraphicsContext restoreGraphicsState];
	}
}

@end
