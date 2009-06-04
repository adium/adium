//
//  AIImageButton.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/16/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "AIImageButton.h"
#import "AIFloater.h"

@implementation AIImageButton

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		imageFloater = nil;
	}

	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	AIImageButton	*newButton = [super copyWithZone:zone];

	newButton->imageFloater = [imageFloater retain];

	return newButton;
}

- (void)dealloc
{
	[imageFloater close:nil];
	[imageFloater release];

	[super dealloc];
}

//Mouse Tracking -------------------------------------------------------------------------------------------------------
#pragma mark Mouse Tracking
//Custom mouse down tracking to display our image and highlight
- (void)mouseDown:(NSEvent *)theEvent
{
	if ([self isEnabled]) {
		NSWindow	*window = [self window];
		float		maxXOrigin;

		[self highlight:YES];

		//Find our display point, the bottom-left of our button, in screen coordinates
		NSPoint point = [window convertBaseToScreen:[self convertPoint:[self bounds].origin toView:nil]];
		point.y -= NSHeight([self frame]) + 2;
		point.x -= 1;

		//Move the display point down by the height of our image
		point.y -= [bigImage size].height;

		if (imageFloater) {
			[imageFloater close:nil];
			[imageFloater release];
		}

		/* If the image would go off the right side of the screen from its origin, shift the origin left
		 * so it won't.
		 */
		maxXOrigin = NSMaxX([[window screen] frame]) - [bigImage size].width;
		if (point.x  > maxXOrigin) {
			point.x = maxXOrigin;
		}

		imageFloater = [[AIFloater floaterWithImage:bigImage styleMask:NSBorderlessWindowMask] retain];
		[imageFloater setMaxOpacity:1.00];
		[imageFloater moveFloaterToPoint:point];
		[imageFloater setVisible:YES animate:NO];
		imageFloaterShouldBeOpen = TRUE;
	}
}

//Remove highlight and image on mouse up
- (void)mouseUp:(NSEvent *)theEvent
{
	[self highlight:NO];

	if (imageFloater) {
		[imageFloater setVisible:NO animate:YES];
		imageFloaterShouldBeOpen = FALSE;

		//Let it stay around briefly before closing so the animation fades it out
		[self performSelector:@selector(destroyImageFloater)
				   withObject:nil
				   afterDelay:0.5];
	}

	[super mouseUp:theEvent];
}

- (void)destroyImageFloater
{
	if (!imageFloaterShouldBeOpen) {
		[imageFloater close:nil];
		[imageFloater release]; imageFloater = nil;
	}
}

#pragma mark Accessibility

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	if([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		return @"AIImageButton";
	} else {
		return [super accessibilityAttributeValue:attribute];
	}
}

@end
