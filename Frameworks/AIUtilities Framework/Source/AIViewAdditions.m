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
    Useful additions to NSView
*/

#import "AIViewAdditions.h"

NSComparisonResult bringToFront(id itemA, id itemB, void *target);

@implementation NSView (AIViewAdditions)

//Remove all the subviews from a view
- (void)removeAllSubviews
{
    NSArray 	*subviews;
    int		loop;

    subviews = [[self subviews] copy];
    for (loop = 0;loop < [subviews count]; loop++) {
        [[subviews objectAtIndex:loop] removeFromSuperview];
    }
    [subviews release];
}

- (void)bringSubviewToFront:(NSView *)subview
{
    [self sortSubviewsUsingFunction:bringToFront context:subview];
}

NSComparisonResult bringToFront(id itemA, id itemB, void *target)
{
    if (itemA == target) {
        return NSOrderedDescending;
    } else if (itemB == target) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}


@end






