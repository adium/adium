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

#import "AIManuallySetUserIconSource.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListObject.h>

@implementation AIManuallySetUserIconSource
- (void)setManuallySetUserIconData:(NSData *)inData forObject:(AIListObject *)inObject
{
	[inObject setPreference:inData
					 forKey:KEY_USER_ICON
					  group:PREF_GROUP_USERICONS];
	[AIUserIcons userIconSource:self didChangeForObject:inObject];
}

- (NSData *)manuallySetUserIconDataForObject:(AIListObject *)inObject
{
	return [inObject preferenceForKey:KEY_USER_ICON group:PREF_GROUP_USERICONS];
}

/*!
 * @brief AIUserIcons wants this source to update its user icon for an object
 *
 * Call +[AIUserIcons userIconSource:didDetermineUserIcon:asynchronously:forObject:] with the new icon, if appropriate
 *
 * @result An AIUserIconSourceQueryResult indicating the result
 */
- (AIUserIconSourceQueryResult)updateUserIconForObject:(AIListObject *)inObject
{
	NSData *userIconData = [self manuallySetUserIconDataForObject:inObject];

	if (userIconData) {
		[AIUserIcons userIconSource:self
			   didDetermineUserIcon:[[NSImage alloc] initWithData:userIconData]
					 asynchronously:NO
						  forObject:inObject];

		return AIUserIconSourceFoundIcon;

	} else {
		return AIUserIconSourceDidNotFindIcon;		
	}
}

/*!
 * @brief The priority at which this source should be used. See the #defines in AIUserIcons.h for posible values.
 */
- (AIUserIconPriority)priority
{
	return AIUserIconHighestPriority;
}

@end
