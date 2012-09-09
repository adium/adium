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
//Adapted from Colloquy  (www.colloquy.info)

#import "MVMenuButton.h"
#import "AIImageDrawingAdditions.h"

@interface MVMenuButton ()
- (NSBezierPath *)popUpArrowPath;
@end

@implementation MVMenuButton

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		//Default configure
		bigImage    = nil;
		toolbarItem = nil;
		arrowPath   = nil;
		drawsArrow  = YES;
		controlSize = NSRegularControlSize;
		[self setBordered:NO];
		[self setButtonType:NSMomentaryChangeButton];
	}

	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	MVMenuButton	*newButton = [[[self class] alloc] initWithFrame:[self frame]];

	//Copy our config
	[newButton setControlSize:controlSize];
	[newButton setImage:bigImage];
	[newButton setDrawsArrow:drawsArrow];

	//Copy super's config
	[newButton setMenu:[[self menu] copy]];
	
	return newButton;
}

//Configure ------------------------------------------------------------------------------------------------------------
#pragma mark Configure
//Control Size (Allows us to dynamically size for a small or big toolbar)
- (void)setControlSize:(NSControlSize)inControlSize
{
	NSSize		targetSize = NSMakeSize(0, 0);
	NSSize		bigImageSize;
	
	controlSize = inControlSize;

	//Update our containing toolbar item's size so it will scale with us
	switch (controlSize) {
		case NSRegularControlSize:
			targetSize = NSMakeSize(32, 32);
			break;
		case NSSmallControlSize:
			targetSize = NSMakeSize(24, 24);
			break;
		case NSMiniControlSize:
			targetSize = NSMakeSize(16, 16); /*XXX Numbers right?*/
			break;
	}	
	
	[toolbarItem setMinSize:targetSize];
	[toolbarItem setMaxSize:targetSize];

	bigImageSize = [bigImage size];
	if ((bigImageSize.width > targetSize.width) || (bigImageSize.height > targetSize.height)) {
		//If the image is bigger than our target, we should set a scaled image, not the bigImage itself
		[super setImage:[bigImage imageByScalingToSize:targetSize]];
		
	} else {
		[super setImage:bigImage];
	}
	
	//Reset the popup arrow path cache, we'll need to re-calculate it for the new size
	arrowPath = nil;
}
- (NSControlSize)controlSize
{
	return controlSize;
}

//Big Image (This is the one that should be called to configure this button)
- (void)setImage:(NSImage *)inImage
{
	if (bigImage != inImage) {
	   bigImage = inImage;
    }
	
	//Update our control size and the displayed image
	[self setControlSize:controlSize];
}
- (NSImage *)image
{
	return bigImage;
}

//Containing toolbar Item
- (void)setToolbarItem:(NSToolbarItem *)item
{
	toolbarItem = item;
}
- (NSToolbarItem *)toolbarItem
{
	return toolbarItem;
}

//Popup arrow Drawing
- (void)setDrawsArrow:(BOOL)inDraw
{
	drawsArrow = inDraw;
}
- (BOOL)drawsArrow
{
	return drawsArrow;
}


//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
- (void)drawRect:(NSRect)rect
{
	//Let super draw our image (Easier than drawing it on our own)
	[super drawRect:rect];

	//Draw the popup arrow
	if (drawsArrow) {
		[[[NSColor blackColor] colorWithAlphaComponent:0.75f] set];
		[[self popUpArrowPath] fill];
	}
}

//Path for the little popup arrow (Cached)
- (NSBezierPath *)popUpArrowPath
{
	if (!arrowPath) {
		NSRect	frame = [self frame];
		
		arrowPath = [NSBezierPath bezierPath];
		
		if (controlSize == NSRegularControlSize) {
			[arrowPath moveToPoint:NSMakePoint(NSWidth(frame)-9, NSHeight(frame)-5)];
			[arrowPath relativeLineToPoint:NSMakePoint( 8, 0)];
			[arrowPath relativeLineToPoint:NSMakePoint(-4, 5)];
		} else if (controlSize == NSSmallControlSize) {
			[arrowPath moveToPoint:NSMakePoint(NSWidth(frame)-7, NSHeight(frame)-5)];
			[arrowPath relativeLineToPoint:NSMakePoint( 6, 0)];
			[arrowPath relativeLineToPoint:NSMakePoint(-3, 4)];
		}
		[arrowPath closePath];
	}

	return arrowPath;
}


//Mouse Tracking -------------------------------------------------------------------------------------------------------
#pragma mark Mouse Tracking
//Custom mouse down tracking to display our menu and highlight
- (void)mouseDown:(NSEvent *)theEvent
{
	NSMenu	*menu = [self menu];
	
	if (!menu) {
		[super mouseDown:theEvent];
	} else {
		if ([self isEnabled]) {
			[self highlight:YES];

			NSPoint point = [self convertPoint:[self bounds].origin toView:nil];
			point.y -= NSHeight([self frame]) + 2;
			point.x -= 1;
			
			NSEvent *event = [NSEvent mouseEventWithType:[theEvent type]
												location:point
										   modifierFlags:[theEvent modifierFlags]
											   timestamp:[theEvent timestamp]
											windowNumber:[[theEvent window] windowNumber]
												 context:[theEvent context]
											 eventNumber:[theEvent eventNumber]
											  clickCount:[theEvent clickCount]
												pressure:[theEvent pressure]];
			[NSMenu popUpContextMenu:menu withEvent:event forView:self];
			
			[self mouseUp:[[NSApplication sharedApplication] currentEvent]];
		}
	}
}

//Remove highlight on mouse up
- (void)mouseUp:(NSEvent *)theEvent
{
	[self highlight:NO];
	[super mouseUp:theEvent];
}

//Ignore dragging
- (void)mouseDragged:(NSEvent *)theEvent
{
	//Empty
}

#pragma mark Accessibility 

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	if([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
		return [toolbarItem label];
	} else if([attribute isEqualToString:NSAccessibilityHelpAttribute]) { 
		return [toolbarItem toolTip]; 
	} else if([attribute isEqualToString:NSAccessibilityToolbarButtonAttribute]) { 
		return [self toolbarItem]; 
	} else { 
		return [super accessibilityAttributeValue:attribute]; 
	}
}

@end
