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
