//
//  AICachedUserIconSource.m
//  Adium
//
//  Created by Evan Schoenberg on 1/4/08.
//

#import "AICachedUserIconSource.h"
#import <Adium/AIUserIcons.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>

static AICachedUserIconSource *sharedCachedUserIconSourceInstance = nil;

@implementation AICachedUserIconSource

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
		
		[AIUserIcons userIconSource:sharedCachedUserIconSourceInstance didChangeForObject:inObject];
		
		return success;
	}
}

- (id)init
{
	if (sharedCachedUserIconSourceInstance) {
		[self release];
		return [sharedCachedUserIconSourceInstance retain];
	} else {
		if ((self = [super init])) {
			sharedCachedUserIconSourceInstance = [self retain];
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
				   didDetermineUserIcon:[[[NSImage alloc] initWithData:iconData] autorelease]
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
			return [cachedImage autorelease];
		}
	}	
	
	return nil;
}

/*!
 * @brief The priority at which this source should be used. See the #defines in AIUserIcons.h for posible values.
 */
- (AIUserIconPriority)priority
{
	return AIUserIconLowestPriority;
}

@end
