//
//  AIProxyListObject.m
//  Adium
//
//  Created by Evan Schoenberg on 4/9/09.
//  Copyright 2009 Adium X / Saltatory Software. All rights reserved.
//

#import "AIProxyListObject.h"
#import <Adium/AIListObject.h>

@implementation AIProxyListObject

@synthesize listObject, key;

static NSMutableDictionary *proxyDict;

+ (void)initialize
{
	proxyDict = [[NSMutableDictionary alloc] init];
}

+ (AIProxyListObject *)proxyListObjectForListObject:(AIListObject *)inListObject inListObject:(id<AIContainingObject>)containingObject
{
	AIProxyListObject *proxy;
	NSString *key = (containingObject ? 
					 [NSString stringWithFormat:@"%@-%@", inListObject.internalObjectID, containingObject.internalObjectID] :
					 inListObject.internalObjectID);

	proxy = [proxyDict objectForKey:key];
	if (!proxy) {
		proxy = [[AIProxyListObject alloc] init];
		proxy.listObject = inListObject;
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

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	if (aSelector == @selector(init)) {
		return [super methodSignatureForSelector:aSelector];

	} else {
		return [listObject methodSignatureForSelector:aSelector];
	}
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];

    if ([listObject respondsToSelector:aSelector])
        [invocation invokeWithTarget:listObject];
    else
        [self doesNotRecognizeSelector:aSelector];
}

@end
