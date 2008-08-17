//
//  AIMessageTabSplitView.m
//  Adium
//
//  Created by Evan Schoenberg on 4/9/07.
//

#import "AIMessageTabSplitView.h"
#import <PSMTabBarControl/NSBezierPath_AMShading.h>

@implementation AIMessageTabSplitView

- (void)dealloc
{
	[leftColor release];
	[rightColor release];
	[super dealloc];
}

- (void)setLeftColor:(NSColor *)inLeftColor rightColor:(NSColor *)inRightColor
{
	if (leftColor != inLeftColor) {
		[leftColor release];
		leftColor = [inLeftColor retain];
	}

	if (rightColor != inRightColor) {
		[rightColor release];
		rightColor = [inRightColor retain];
	}
	
	[self setNeedsDisplay:YES];
}

-(void)drawDividerInRect:(NSRect)aRect
{	
	if (rightColor && leftColor) {
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:aRect];
		[path linearVerticalGradientFillWithStartColor:leftColor 
											  endColor:rightColor];
	} else {
		[super drawDividerInRect:aRect];
	}
}

@end
