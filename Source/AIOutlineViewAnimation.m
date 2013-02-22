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

#import "AIOutlineViewAnimation.h"
#import "AIAnimatingListOutlineView.h"

@interface AIAnimatingListOutlineView (AIOutlineViewAnimationDelegate)
- (void)animation:(AIOutlineViewAnimation *)animation didSetCurrentValue:(float)currentValue forDict:(NSDictionary *)animatingRowsDict;
@end

@interface AIOutlineViewAnimation ()
- (id)initWithDictionary:(NSDictionary *)inDict delegate:(AIAnimatingListOutlineView *)inOutlineView;
@end

/*!
 * @class AIOutlineViewAnimation
 * @brief NSAnimation subclass for AIOutlineView's animations
 *
 * This NSAnimation subclass is a simple subclass to let the outline view handle changes in progress
 * along a non-blocking ease-in/ease-out animation.
 * AIOutlineView should release the AIOutlineViewAnimation when the animation is complete.
 */
@implementation AIOutlineViewAnimation
+ (AIOutlineViewAnimation *)listObjectAnimationWithDictionary:(NSDictionary *)inDict delegate:(AIAnimatingListOutlineView *)inOutlineView
{
	return [[self alloc] initWithDictionary:inDict delegate:inOutlineView];
}

- (id)initWithDictionary:(NSDictionary *)inDict delegate:(AIAnimatingListOutlineView <NSAnimationDelegate> *)inOutlineView
{
	if ((self = [super initWithDuration:LIST_OBJECT_ANIMATION_DURATION animationCurve:NSAnimationEaseInOut])) {
		dict = inDict;

		[self setDelegate:inOutlineView];
		[self setAnimationBlockingMode:NSAnimationNonblocking];
	}
	
	return self;
}

/*!
 * @brief We want to run our animation no matter what's going on
 */
- (NSArray *)runLoopModesForAnimating
{
    return [NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil];
}

/*!
 * @brief When progress updates, inform the delegate
 */
- (void)setCurrentProgress:(NSAnimationProgress)progress
{
	[super setCurrentProgress:progress];

	[(AIAnimatingListOutlineView *)self.delegate animation:self didSetCurrentValue:[self currentValue] forDict:dict];
}

@end
