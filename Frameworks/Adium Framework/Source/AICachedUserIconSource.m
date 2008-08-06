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
	return [[adium cachesPath] stringByAppendingPathComponent:[inObject internalObjectID]];
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
			success = [[NSFileManager defaultManager] removeFileAtPath:cachedImagePath
															   handler:NULL];
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
		NSString	*cachedImagePath = [[self class] _cachedImagePathForObject:inObject];
		BOOL		gotCachedImage = NO;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:cachedImagePath]) {
			NSImage				*cachedImage;
			
			if ((cachedImage = [[NSImage alloc] initWithContentsOfFile:cachedImagePath])) {
				[AIUserIcons userIconSource:self
					   didDetermineUserIcon:cachedImage
							 asynchronously:NO
								  forObject:inObject];
				[cachedImage release];
				
				gotCachedImage = YES;
			}
		}	

		return (gotCachedImage ? AIUserIconSourceFoundIcon : AIUserIconSourceDidNotFindIcon);
	}
}

/*!
 * @brief The priority at which this source should be used. See the #defines in AIUserIcons.h for posible values.
 */
- (AIUserIconPriority)priority
{
	return AIUserIconLowestPriority;
}

@end
