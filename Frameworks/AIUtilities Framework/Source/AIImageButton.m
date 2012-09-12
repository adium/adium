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

@synthesize cornerRadius, imageFloater;

- (id)copyWithZone:(NSZone *)zone
{
	AIImageButton *newButton = [super copyWithZone:zone];
	newButton.imageFloater = imageFloater;
	newButton.cornerRadius = self.cornerRadius;

	return newButton;
}

- (void)dealloc
{
	[imageFloater close:nil];
}

#pragma mark Drawing

- (void)drawRect:(NSRect)rect
{
	// Rounded corners
	if (cornerRadius > 0.0f) {
		[[NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:[self cornerRadius] yRadius:[self cornerRadius]] addClip];
	}
	
	[super drawRect:rect];
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
		}
		
		// Rounded corners
		if ([self cornerRadius] > 0.0f) {
			NSImage *roundedImage = [[NSImage alloc] initWithSize:[bigImage size]];
			NSRect imageFrame = NSMakeRect(0.0f, 0.0f, [bigImage size].width, [bigImage size].height);
			
			[roundedImage lockFocus];

			[[NSBezierPath bezierPathWithRoundedRect:imageFrame
											 xRadius:[self cornerRadius]
											 yRadius:[self cornerRadius]] addClip];

			[bigImage drawInRect:imageFrame fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0f];
			
			[roundedImage unlockFocus];
			
			[self setImage:roundedImage];
		}

		/* If the image would go off the right side of the screen from its origin, shift the origin left
		 * so it won't.
		 */
		maxXOrigin = NSMaxX([[window screen] frame]) - [bigImage size].width;
		if (point.x  > maxXOrigin) {
			point.x = maxXOrigin;
		}

		imageFloater = [AIFloater newFloaterWithImage:bigImage styleMask:NSBorderlessWindowMask];
		[imageFloater setMaxOpacity:1.0f];
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
		 imageFloater = nil;
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
