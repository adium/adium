//
//  AIFilterBarView.m
//  Adium
//
//  Created by Zachary West on 2009-04-02.
//

#import "AIFilterBarView.h"

#import <AIUtilities/AIBezierPathAdditions.h>

@implementation AIFilterBarView

@synthesize backgroundColor, backgroundIsRounded, drawsBackground;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{	
	if (drawsBackground && backgroundColor) {
		NSBezierPath *bezierPath;
		
		if (backgroundIsRounded) {
			bezierPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds];
		} else {
			bezierPath = [NSBezierPath bezierPathWithRect:self.bounds];
		}
		
		[backgroundColor set];
		[bezierPath fill];
	}
	
	[super drawRect:rect];
}

@end
