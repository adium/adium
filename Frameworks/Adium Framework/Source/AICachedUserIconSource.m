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

#import "AICachedUserIconSource.h"
#import <Adium/AIUserIcons.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>

static AICachedUserIconSource *sharedCachedUserIconSourceInstance = nil;

@implementation AICachedUserIconSource

+ (AICachedUserIconSource  *)sharedCachedUserIconSourceInstance
{
	if (!sharedCachedUserIconSourceInstance)
		sharedCachedUserIconSourceInstance = [[self alloc] init];
	
	return sharedCachedUserIconSourceInstance;
}

/*!
 * @brief Retrieve the path at which to cache an AIListObject's image
 */
+ (NSString *)_cachedImagePathForObject:(AIListObject *)inObject
{
	return [[adium cachesPath] stringByAppendingPathComponent:inObject.internalObjectID];
}

/*!
 * @brief Cache user icon data for an object
 *
 * @param inData Image data to cache
 * @param inObject AIListObject to cache the data for
 *
 * @result YES if successful
 */
+ (BOOL)cacheUserIconData:(NSData *)inData forObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListContact class]] && 
		([[(AIListContact *)inObject account] managesOwnContactIconCache])) {
		//Don't cache if the account manages its own cache
		return NO;

	} else {
		BOOL		success;
		NSString	*cachedImagePath = [self _cachedImagePathForObject:inObject];
		
		if (inData && [inData length]) {
			success = ([inData writeToFile:cachedImagePath
								atomically:YES]);
		} else {
			success = [[NSFileManager defaultManager] removeItemAtPath:cachedImagePath
																 error:NULL];
		}
		
		[AIUserIcons userIconSource:[self sharedCachedUserIconSourceInstance] 
				 didChangeForObject:inObject];
		
		return success;
	}
}

- (id)init
{
	if (sharedCachedUserIconSourceInstance) {
		return sharedCachedUserIconSourceInstance;
	} else {
		if ((self = [super init])) {
			sharedCachedUserIconSourceInstance = self;
		}
	}
	
	return self;
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
	if ([inObject isKindOfClass:[AIListContact class]] && 
		([[(AIListContact *)inObject account] managesOwnContactIconCache])) {
		//Don't look for an icon if the account manages its own cache
		return AIUserIconSourceDidNotFindIcon;
		
	} else {
		NSData *iconData = [self cachedUserIconDataForObject:inObject];
		
		if (iconData) {
			[AIUserIcons userIconSource:self
				   didDetermineUserIcon:[[NSImage alloc] initWithData:iconData]
						 asynchronously:NO
							  forObject:inObject];
		}
		
		return (iconData ? AIUserIconSourceFoundIcon : AIUserIconSourceDidNotFindIcon);
	}
}

/*!
 * @brief Returns the cached user icon for an object
 *
 * @result The NSData for a cached user icon or nil
 */
- (NSData *)cachedUserIconDataForObject:(AIListObject *)inObject
{
	NSString	*cachedImagePath = [[self class] _cachedImagePathForObject:inObject];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:cachedImagePath]) {
		NSData				*cachedImage;
		
		if ((cachedImage = [[NSData alloc] initWithContentsOfFile:cachedImagePath])) {
			return cachedImage;
		}
	}	
	
	return nil;
}

/*!
 * @brief Returns if a cached user icon exists.
 *
 * @result YES if a cached user icon exists, NO otherwise.
 */
- (BOOL)cachedUserIconExistsForObject:(AIListObject *)inObject
{
	return ([[NSFileManager defaultManager] fileExistsAtPath:[[self class] _cachedImagePathForObject:inObject]]);
}

/*!
 * @brief The priority at which this source should be used. See the #defines in AIUserIcons.h for posible values.
 */
- (AIUserIconPriority)priority
{
	return AIUserIconLowestPriority;
}

@end
