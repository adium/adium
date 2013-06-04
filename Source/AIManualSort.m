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

#import "AIManualSort.h"
#import <Adium/AIListObject.h>

/*!
 * @class AIManualSort
 * @brief AISortController to sort only by manual ordering
 */
@implementation AIManualSort

/*!
 * @brief Non-localized identifier
 */
- (NSString *)identifier{
    return @"ManualSort";
}

/*!
 * @brief Localized display name
 */
- (NSString *)displayName{
    return AILocalizedString(@"Sort Contacts Manually",nil);
}

/*!
 * @brief Always sort groups to the top?
 *
 * For manual sorting, groups get sorted like any other object
 */
- (BOOL)alwaysSortGroupsToTopByDefault{
	return NO;
}

/*!
 * @brief Can the user manually reorder when this sort controller is active?
 *
 * By definition, the manual sort controller allows manual sorting
 */
- (BOOL)canSortManually {
	return YES;
}

/*!
 * @brief Manual sort
 */
NSInteger manualSort(id objectA, id objectB, BOOL groups, id<AIContainingObject>container)
{
	//Contacts and Groups in manual order
	CGFloat orderIndexA = [container orderIndexForObject:objectA];
	CGFloat orderIndexB = [container orderIndexForObject:objectB];
	
	if (orderIndexA > orderIndexB) {
		return NSOrderedDescending;
	} else if (orderIndexA < orderIndexB) {
		return NSOrderedAscending;
	} else {
		return [[objectA internalObjectID] caseInsensitiveCompare:[objectB internalObjectID]];
	}
	
}

/*!
 * @brief Sort function
 */
- (sortfunc)sortFunction{
	return &manualSort;
}

@end
