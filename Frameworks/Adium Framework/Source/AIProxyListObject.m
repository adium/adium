//
//  AIProxyListObject.m
//  Adium
//
//  Created by Evan Schoenberg on 4/9/09.
//  Copyright 2009 Adium X / Saltatory Software. All rights reserved.
//

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
		NSLog(@"Attempting to correct for old proxy listobject, keyed %@", key);
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
	[proxyDict removeObjectForKey:proxyObject.key];
}

- (void)dealloc
{
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

@end
