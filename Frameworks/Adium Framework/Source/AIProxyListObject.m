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

#import "AIProxyListObject.h"
#import <Adium/ESObjectWithProperties.h>
#import <Adium/AIListObject.h>

@interface NSObject (PublicAPIMissingFromHeadersAndDocsButInTheReleaseNotesGoshDarnit)
- (id)forwardingTargetForSelector:(SEL)aSelector;
@end

@implementation AIProxyListObject

@synthesize listObject, containingObject, key, cachedDisplayName, cachedDisplayNameString, cachedLabelAttributes, cachedDisplayNameSize;

static NSMutableDictionary *proxyDict;

+ (void)initialize
{
	if (self == [AIProxyListObject class])
		proxyDict = [[NSMutableDictionary alloc] init];
}

+ (AIProxyListObject *)existingProxyListObjectForListObject:(ESObjectWithProperties *)inListObject
											   inListObject:(ESObjectWithProperties <AIContainingObject>*)inContainingObject
{
	NSString *key = (inContainingObject ? 
					 [NSString stringWithFormat:@"%@-%@", inListObject.internalObjectID, inContainingObject.internalObjectID] :
					 inListObject.internalObjectID);
	
	return [proxyDict objectForKey:key];
}

+ (AIProxyListObject *)proxyListObjectForListObject:(ESObjectWithProperties *)inListObject
									   inListObject:(ESObjectWithProperties <AIContainingObject>*)inContainingObject
{
	AIProxyListObject *proxy;
	NSString *key = (inContainingObject ? 
					 [NSString stringWithFormat:@"%@-%@", inListObject.internalObjectID, inContainingObject.internalObjectID] :
					 inListObject.internalObjectID);

	proxy = [proxyDict objectForKey:key];
	
	if (proxy && proxy.listObject != inListObject) {
		// If the old list object is for some reason invalid (released in contact controller, but not fully released)
		// we end up with an old list object as our proxied object. Correct this by getting rid of the old one.
#ifdef DEBUG_BUILD
		NSLog(@"Re-used AIProxyListObject (this should not happen.). Key %@ for inListObject %@ -> %p.listObject=%@", key,inListObject,proxy,proxy.listObject);
#endif
		[proxy.listObject removeProxyObject:proxy];
		[self releaseProxyObject:proxy];
		proxy = nil;
	}
	
	if (!proxy) {
		proxy = [[AIProxyListObject alloc] init];
		proxy.listObject = inListObject;
		proxy.containingObject = inContainingObject;
		proxy.key = key;
		[inListObject noteProxyObject:proxy];

		[proxyDict setObject:proxy
					  forKey:key];
		[proxy release];
	}

	return proxy;
}

/*!
 * @brief Release a proxy object
 *
 * This should be called only by AIListObject when it deallocates, for each of its proxy objects
 */
+ (void)releaseProxyObject:(AIProxyListObject *)proxyObject
{
	[[proxyObject retain] autorelease];
	proxyObject.listObject = nil;
	[proxyDict removeObjectForKey:proxyObject.key];
}

- (void)dealloc
{
	AILogWithSignature(@"%@", self);
	self.listObject = nil;
	self.key = nil;
	self.cachedDisplayName = nil;
	self.cachedDisplayNameString = nil;
	self.cachedLabelAttributes = nil;
	
	[super dealloc];
}

/* Pretend to be our listObject. I suspect being an NSProxy subclass could do this more cleanly, but my initial attempt
 * failed and this works fine.
 */
- (Class)class
{
	return [listObject class];
}

- (BOOL)isKindOfClass:(Class)class
{
	return [listObject isKindOfClass:class];
}

- (BOOL)isMemberOfClass:(Class)class
{
	return [listObject isMemberOfClass:class];
}

- (BOOL)isEqual:(id)inObject
{
	return [listObject isEqual:inObject];
}

- (id)forwardingTargetForSelector:(SEL)aSelector;
{
	return listObject;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<AIProxyListObject %p -> %@>", self, listObject];
}

@end
