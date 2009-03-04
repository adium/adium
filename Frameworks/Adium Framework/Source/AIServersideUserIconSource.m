//
//  AIServersideUserIconSource.m
//  Adium
//
//  Created by Evan Schoenberg on 1/4/08.
//

#import "AIServersideUserIconSource.h"
#import <Adium/AIUserIcons.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AICachedUserIconSource.h>

@implementation AIServersideUserIconSource

- (id)init
{
	if ((self = [super init])) {
		serversideIconDataCache = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)setServersideUserIconData:(NSData *)inData forObject:(AIListObject *)inObject
{
	//If we're already in the middle of retrieving data, ignore this duplicative set message
	if (!gettingServersideData) {
		/* Just keep the data itself around for the updating process;
		 * we don't want to keep it separately in memory long-term.
		 */
		if (inData)
			[serversideIconDataCache setObject:inData forKey:inObject.internalObjectID];
		
		//Tell AIUserIcons that we're ready
		[AIUserIcons userIconSource:self didChangeForObject:inObject];
		//Cache the icon if desired
		[AICachedUserIconSource cacheUserIconData:inData forObject:inObject];
		
		[serversideIconDataCache removeObjectForKey:inObject.internalObjectID];
	}
}

- (NSData *)serversideUserIconDataForObject:(AIListObject *)inObject
{
	NSData *iconData = [serversideIconDataCache objectForKey:inObject.internalObjectID];
	if (!iconData && [inObject isMemberOfClass:[AIListContact class]]) {
		//If this is specifically an AIListContact, ask the account if it has serverside data.
		gettingServersideData = YES;
		iconData = [[(AIListContact *)inObject account] serversideIconDataForContact:(AIListContact *)inObject];
		gettingServersideData = NO;
	}

	return iconData;
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
	NSData *iconData = [self serversideUserIconDataForObject:inObject];

	if (iconData) {
		[AIUserIcons userIconSource:self
			   didDetermineUserIcon:[[[NSImage alloc] initWithData:iconData] autorelease]
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
	return AIUserIconMediumPriority;
}

@end
