//
//  AIManuallySetUserIconSource.m
//  Adium
//
//  Created by Evan Schoenberg on 1/4/08.
//

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
			   didDetermineUserIcon:[[[NSImage alloc] initWithData:userIconData] autorelease]
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
