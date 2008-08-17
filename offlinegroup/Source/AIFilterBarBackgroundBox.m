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
#import "CTGradient.h"

@implementation AIFilterBarBackgroundBox
- (void)drawRect:(NSRect)rect
{
	//Filter bar color's selflessly borrowed from Safari 3's inline search bar
	NSColor *topColor = [NSColor colorWithCalibratedRed:0.914 green:0.914 blue:0.914 alpha:1.0];
	NSColor *bottomColor = [NSColor colorWithCalibratedRed:0.816 green:0.816 blue:0.816 alpha:1.0];
	
	[[CTGradient gradientWithBeginningColor:bottomColor endingColor:topColor]fillRect:[self bounds] angle:90.0];
}
@end
