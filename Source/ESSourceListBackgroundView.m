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

#import "ESSourceListBackgroundView.h"
#import <Adium/KNShelfSplitView.h>
#import <AIUtilities/AIImageAdditions.h>

@implementation ESSourceListBackgroundView

- (void)_initSourceListBackgroundView
{
	background = [[NSImage imageNamed:@"sourceListBackground" forClass:[KNShelfSplitView class]] retain];
	backgroundSize = [background size];
	
	[self setNeedsDisplay:YES];
}

- (id)initWithCoder:(NSCoder *)inCoder
{
	if ((self = [super initWithCoder:inCoder])) {
		[self _initSourceListBackgroundView];
	}
	
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self _initSourceListBackgroundView];
	}
	
	return self;
}

- (void)dealloc
{
	[background release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	NSRect	frame = [self frame];
	
	//Draw the background, tiling across
    NSRect sourceRect = NSMakeRect(0, 0, backgroundSize.width, backgroundSize.height);
    NSRect destRect = NSMakeRect(0, 0, sourceRect.size.width, frame.size.height);
	
    while ((destRect.origin.x < NSWidth(frame)) && destRect.size.width > 0) {
        //Crop
        if (NSMaxX(destRect) > NSWidth(frame)) {
            sourceRect.size.width = NSWidth(destRect);
        }
		
        [background drawInRect:destRect
					  fromRect:sourceRect
					 operation:NSCompositeSourceOver
					  fraction:1.0f];
        destRect.origin.x += NSWidth(destRect);
    }
	
	//Draw a border line at the top
	NSRect lineRect = NSMakeRect(0, frame.size.height-1, NSWidth(frame), 1);
	[[NSColor windowFrameColor] set];
	NSRectFill(lineRect);
}

@end
