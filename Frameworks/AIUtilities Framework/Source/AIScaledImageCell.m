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

#import "AIScaledImageCell.h"

/*
 Used for displaying a potentially large image
 */
@interface AIScaledImageCell ()
- (BOOL)isHighlighted;
@end

@implementation AIScaledImageCell

- (id)init
{
	if ((self = [super init])) {
		maxSize = NSZeroSize;
	}
	
	return self;
}

- (void)setMaxSize:(NSSize)inMaxSize
{
	maxSize = inMaxSize;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSImage	*img = [self image];
	
	if (img) {
		//Size and location
		//Get image metrics
		NSSize	imgSize = [img size];
		NSRect	imgRect = NSMakeRect(0, 0, imgSize.width, imgSize.height);
		
		//Scaling
		NSRect	targetRect = cellFrame;
		
		//Determine the correct maximum size, taking into account maxSize and our cellFrame.
		NSSize	ourMaxSize = cellFrame.size;
		if ((maxSize.width != 0) && (ourMaxSize.width > maxSize.width)) {
			ourMaxSize.width = maxSize.width;
		}
		if ((maxSize.height != 0) && (ourMaxSize.height > maxSize.height)) {
			ourMaxSize.height = maxSize.height;
		}
		
		if ((imgSize.height > ourMaxSize.height) ||
			(imgSize.width  >  ourMaxSize.width)) {
			
			if (imgSize.width > imgSize.height) {
				//Give width priority: Make the height change by the same proportion as the width will change
				targetRect.size.width = ourMaxSize.width;
				targetRect.size.height = imgSize.height * (targetRect.size.width / imgSize.width);
			} else {
				//Give height priority: Make the width change by the same proportion as the height will change
				targetRect.size.height = ourMaxSize.height;
				targetRect.size.width = imgSize.width * (targetRect.size.height / imgSize.height);
			}
		} else {
			targetRect.size.width = imgSize.width;
			targetRect.size.height = imgSize.height;
		}
		
		//Centering
		targetRect = NSOffsetRect(targetRect, AIround((cellFrame.size.width - targetRect.size.width) / 2), AIround((cellFrame.size.height - targetRect.size.height) / 2));
		
		//Flip & reposition image
		[NSGraphicsContext saveGraphicsState];
		
		long cellPosition = AIfloor(cellFrame.origin.y / cellFrame.size.height) + 1;
		long yOffset = fmodl(cellFrame.origin.y, cellFrame.size.height);
		
		NSAffineTransform *xform = [NSAffineTransform transform];
		[xform translateXBy: 0.f yBy: cellPosition * cellFrame.size.height + yOffset];
		[xform scaleXBy: 1.f yBy: -1.f];
		[xform concat];
		
		//y offset already handled by translation
		targetRect.origin.y = 0.f;
		
		//Draw Image
		[img drawInRect:targetRect
			   fromRect:imgRect
			  operation:NSCompositeSourceOver 
			   fraction:([self isEnabled] ? 1.0f : 0.5f)];
		
		[NSGraphicsContext restoreGraphicsState];				
	}
}

//Super doesn't appear to handle the isHighlighted flag correctly, so we handle it to be safe.
- (void)setHighlighted:(BOOL)flag
{
	[self setState:(flag ? NSOnState : NSOffState)];
	isHighlighted = flag;
}
- (BOOL)isHighlighted
{
	return isHighlighted;
}

@end
