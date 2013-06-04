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

@synthesize key, cachedDisplayName, cachedDisplayNameString, cachedLabelAttributes, cachedDisplayNameSize;
@synthesize listObject, containingObject, nick;


static inline NSMutableDictionary *_getProxyDict() {
    static NSMutableDictionary *proxyDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxyDict = [[NSMutableDictionary alloc] init];
    });
    return proxyDict;
}

#define proxyDict _getProxyDict()

+ (AIProxyListObject *)existingProxyListObjectForListObject:(AIListObject *)inListObject
											   inListObject:(ESObjectWithProperties <AIContainingObject>*)inContainingObject
{
	NSString *key = (inContainingObject ? 
					 [NSString stringWithFormat:@"%@-%@", inListObject.internalObjectID, inContainingObject.internalObjectID] :
					 inListObject.internalObjectID);
	
	return [proxyDict objectForKey:key];
}

+ (AIProxyListObject *)proxyListObjectForListObject:(AIListObject *)inListObject
									   inListObject:(ESObjectWithProperties <AIContainingObject>*)inContainingObject
{
	return [self proxyListObjectForListObject:inListObject inListObject:inContainingObject withNick:nil];
}

+ (AIProxyListObject *)proxyListObjectForListObject:(AIListObject *)inListObject
									   inListObject:(ESObjectWithProperties <AIContainingObject>*)inContainingObject
										   withNick:(NSString *)inNick
{
	AIProxyListObject *proxy;
	NSString *key = (inContainingObject ? 
					 [NSString stringWithFormat:@"%@-%@", inListObject.internalObjectID, inContainingObject.internalObjectID] :
					 inListObject.internalObjectID);
	
	if (inNick) {
		key = [key stringByAppendingFormat:@"-%@", inNick];
	}

	proxy = [proxyDict objectForKey:key];

	if (proxy && proxy.listObject != inListObject) {
        /* This is generally a memory management failure; AIContactController stopped tracking a list object, but it never deallocated and
		 * so never called [AIProxyListObject releaseProxyObject:]. -evands 8/28/11
		 */
		AILogWithSignature(@"%@ was leaked! Meh. We'll recreate the proxy for %@.", proxy.listObject, proxy.key);
		[self releaseProxyObject:proxy];
		proxy = nil;
	}

	if (!proxy) {
		proxy = [[AIProxyListObject alloc] init];
		proxy.listObject = inListObject;
		proxy.containingObject = inContainingObject;
		proxy.key = key;
		proxy.nick = inNick;
		[inListObject noteProxyObject:proxy];
		[proxyDict setObject:proxy
					  forKey:key];
		[proxy release];
	}

	return proxy;
}

- (void)flushCache
{
	self.cachedDisplayName = nil;
	self.cachedDisplayNameString = nil;
	self.cachedLabelAttributes = nil;
}

/*!
 * @brief Called when an AIListObject is done with an AIProxyListObject to remove it from the global dictionary
 *
 * This should be called only by AIListObject when it deallocates, for each of its proxy objects
 */
+ (void)releaseProxyObject:(AIProxyListObject *)proxyObject
{
	[[proxyObject retain] autorelease];
	proxyObject.listObject = nil;
	[proxyObject flushCache];
	[proxyDict removeObjectForKey:proxyObject.key];
}

- (void)dealloc
{
	AILogWithSignature(@"%@", self);
	self.key = nil;

    [self flushCache];
	
	[super dealloc];
}

/* Pretend to be our listObject. I suspect being an NSProxy subclass could do this more cleanly, but my initial attempt
 * failed and this works fine.
 */
- (Class)class
{
	return [[self listObject] class];
}

- (BOOL)isKindOfClass:(Class)class
{
	return [[self listObject] isKindOfClass:class];
}

- (BOOL)isMemberOfClass:(Class)class
{
	return [[self listObject] isMemberOfClass:class];
}

- (BOOL)isEqual:(id)inObject
{
	return [[self listObject] isEqual:inObject];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	return [self listObject];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<AIProxyListObject %p -> %@>", self, [self listObject]];
}

@end
