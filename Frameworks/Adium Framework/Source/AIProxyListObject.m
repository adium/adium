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

@synthesize listObject, containingObject, key;

static NSMutableDictionary *proxyDict;

+ (void)initialize
{
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
	[proxyDict removeObjectForKey:proxyObject.key];
}

- (void)dealloc
{
	self.key = nil;

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
	NSLog(@"XXX forwarding %@; break on -[AIProxyListObject forwardingTargetForSelector:]", NSStringFromSelector(aSelector));
	return listObject;
}

@end
