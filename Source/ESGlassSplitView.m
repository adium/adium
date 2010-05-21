//
//  ESGlassSplitView.m
//  Adium
//
//  Created by Evan Schoenberg on 6/30/06.
//

#import "ESGlassSplitView.h"
#import <Adium/KNShelfSplitView.h>
#import <AIUtilities/AIImageAdditions.h>

@implementation ESGlassSplitView
- (void)_initGlassSplitView
{
	background = [[NSImage imageNamed:@"sourceListBackground" forClass:[KNShelfSplitView class]] retain];
	backgroundSize = [background size];
	
	[self setNeedsDisplay:YES];
}

- (id)initWithCoder:(NSCoder *)inCoder
{
	if ((self = [super initWithCoder:inCoder])) {
		[self _initGlassSplitView];
	}
	
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self _initGlassSplitView];
	}
	
	return self;
}

- (void)dealloc
{
	[background release];
	
	[super dealloc];
}

-(void)drawDividerInRect:(NSRect)aRect
{	
	//Draw the background, tiling across
    NSRect sourceRect = NSMakeRect(0, 0, backgroundSize.width, backgroundSize.height);
    NSRect destRect = NSMakeRect(aRect.origin.x, aRect.origin.y, sourceRect.size.width, aRect.size.width);
	
    while ((NSMinX(destRect) < NSMaxX(aRect)) && NSWidth(destRect) > 0) {
        //Crop
        if (NSMaxX(destRect) > NSMaxX(aRect)) {
            sourceRect.size.width = NSWidth(destRect);
        }
		
        [background drawInRect:destRect
					  fromRect:sourceRect
					 operation:NSCompositeSourceOver
					  fraction:1.0f];
        destRect.origin.x += NSWidth(destRect);
    }
	
	//Draw the borders
	[[NSColor windowFrameColor] set];
	NSRectFill(NSMakeRect(aRect.origin.x, aRect.origin.y, aRect.size.width, 1.0f));
	NSRectFill(NSMakeRect(aRect.origin.x, aRect.origin.y + aRect.size.height - 1, aRect.size.width, 1.0f));
	
	//Draw the thumb
	//[[NSColor blackColor] set];
	NSBezierPath *ovalPath = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(aRect.origin.x + (aRect.size.width / 2.0f) - 2,
																			   aRect.origin.y + (aRect.size.height / 2.0f) - 2,
																			   4,
																			   4
																			   )];
	[[[NSColor lightGrayColor] colorWithAlphaComponent:0.5f] set];
	[ovalPath fill];

	[ovalPath setLineWidth:0];
	[[NSColor windowFrameColor] set];
	[ovalPath stroke];
}

@end
