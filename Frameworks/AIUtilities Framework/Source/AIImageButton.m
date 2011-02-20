/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIImageButton.h"
#import "AIFloater.h"

@interface AIImageButton (PRIVATE)
- (void)destroyImageFloater;
@end

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
		CGFloat		maxXOrigin;

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
		[imageFloater setMaxOpacity:1.00f];
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
