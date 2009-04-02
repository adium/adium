//
//  AIFilterBarView.m
//  Adium
//
//  Created by Zachary West on 2009-04-02.
//

#import "AIFilterBarView.h"

#import <AIUtilities/AIBezierPathAdditions.h>

@implementation AIFilterBarView

@synthesize backgroundColor, backgroundIsRounded, drawBackground;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{	
	if (drawBackground && backgroundColor) {
		NSBezierPath *bezierPath;
		
		if (backgroundIsRounded) {
			bezierPath = [NSBezierPath bezierPathWithRoundedRect:rect];
		} else {
			bezierPath = [NSBezierPath bezierPathWithRect:rect];
		}
		
		[backgroundColor set];
		[bezierPath fill];
	}
	
	[super drawRect:rect];
}

@end
