//
//  AISearchFieldCell.m
//  Adium
//
//  Created by Evan Schoenberg on 5/1/08.
//

#import "AISearchFieldCell.h"
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>

@implementation AISearchFieldCell

- (void)dealloc
{
	[backgroundColor release];
	[super dealloc];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (backgroundColor) {
		[backgroundColor setFill];
		[[NSBezierPath bezierPathWithRoundedRect:cellFrame] fill];
	}

	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)setTextColor:(NSColor *)inTextColor backgroundColor:(NSColor *)inBackgroundColor
{
	NSSearchField	*searchField = (NSSearchField *)[self controlView];

	[searchField setTextColor:(inTextColor ? inTextColor : [NSColor blackColor])];

	if (backgroundColor != inBackgroundColor) {
		[backgroundColor release];
		backgroundColor = [inBackgroundColor retain];
	}
}

@end
