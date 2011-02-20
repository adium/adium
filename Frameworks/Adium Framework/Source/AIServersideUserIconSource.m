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
