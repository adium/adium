//
//  AIGenericViewCell.m
//  Adium
//
//  Created by Mac-arena the Bored Zo on Sun May 09 2004.
//

#import "AIGenericViewCell.h"

//Based on sample code from SubViewTableView by Joar Wingfors, http://www.joar.com/code/

@interface NSView (AIGenericViewCellEmbeddedView)
- (void)setIsHighlighted:(BOOL)flag;
@end

@implementation AIGenericViewCell

- (void)dealloc
{
	[embeddedView release];
	[super dealloc];
}

- (void)setEmbeddedView:(NSView *)inView
{
	if (embeddedView != inView) {
		[embeddedView release];
		embeddedView = [inView retain];
	}
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIGenericViewCell *newCell = [super copyWithZone:zone];
	newCell->embeddedView = [embeddedView retain];

	return newCell;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ([embeddedView respondsToSelector:@selector(setIsHighlighted:)]) {
		[embeddedView setIsHighlighted:[self isHighlighted]];
	}

	if ([embeddedView superview] != controlView) {
		[controlView addSubview:embeddedView];
	}
	
	[embeddedView setFrame:cellFrame];	
}

- (void)drawEmbeddedViewWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSImage	*image;

	if ([embeddedView respondsToSelector:@selector(setIsHighlighted:)]) {
		[embeddedView setIsHighlighted:[self isHighlighted]];
	}

	if ([embeddedView superview] != controlView) {
		[controlView addSubview:embeddedView];
	}

	NSRect	frame = [embeddedView frame];
	NSRect	usableFrame = NSMakeRect(0,0,frame.size.width,frame.size.height);

	image = [[[NSImage alloc] initWithSize:frame.size] autorelease];
	[image lockFocus];
	[embeddedView setNeedsDisplay:YES];
	[embeddedView drawRect:usableFrame];
	
	//Now draw each subview in its proper place
	NSEnumerator	*enumerator = [[embeddedView subviews] objectEnumerator];
	NSView			*subView;

	while ((subView = [enumerator nextObject])) {
		NSRect	subFrame = [subView frame];
		NSRect	subUsableFrame = NSMakeRect(0, 0, subFrame.size.width, subFrame.size.height);

		//Cache to an image
		NSImage	*subImage = [[[NSImage alloc] initWithSize:subFrame.size] autorelease];
		[subImage lockFocus];
		[subView drawRect:subUsableFrame];
		[subImage unlockFocus];

		//Draw that image in the proper place
		[subImage drawInRect:subFrame
					fromRect:subUsableFrame
				   operation:NSCompositeSourceOver
					fraction:1.0];
	}
	[image unlockFocus];

	//Draw the composited image in our current context
	[image drawInRect:cellFrame
			 fromRect:usableFrame
			operation:NSCompositeSourceOver
			 fraction:1.0];	
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{	
	return NSCellHitContentArea;
}

- (BOOL)drawGridBehindCell
{
	return YES;
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	if (embeddedView)
		return [embeddedView accessibilityAttributeValue:attribute];
	else
		return [super accessibilityAttributeValue:attribute];
}

@end
