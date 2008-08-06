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

/* 
 This NSImageCell poseAsClass implementation exists to fix a simple bug: an animating NSImageCell, as of
 10.3, does not mark its controlView as needing display, so the animation occurs but is not reflected in the view
 until something else causes a display update.
 */

#import <Adium/AIImageCellAnimationFix.h>
#import <AIUtilities/AIImageAdditions.h>

@implementation AIImageCellAnimationFix

+ (void)load
{
	[self poseAsClass:[NSImageCell class]];
}

- (void)_animationTimerCallback:(NSTimer *)inTimer
{
	[super _animationTimerCallback:inTimer];
	
	[[self controlView] setNeedsDisplay:YES];
}

@end
