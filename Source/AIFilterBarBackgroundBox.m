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

#import "AIFilterBarBackgroundBox.h"

@implementation AIFilterBarBackgroundBox
- (void)drawRect:(NSRect)rect
{
	static NSGradient *gradient;
	if (!gradient) {
		//Filter bar color's selflessly borrowed from Safari 3's inline search bar
		NSColor *topColor = [NSColor colorWithCalibratedRed:0.914f green:0.914f blue:0.914f alpha:1.0f];
		NSColor *bottomColor = [NSColor colorWithCalibratedRed:0.816f green:0.816f blue:0.816f alpha:1.0f];
		gradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor]; //intentional one time leak
	}
	
	[gradient drawInRect:[self bounds] angle:270.0f];
}
@end
