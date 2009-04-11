//
//  AIProxyListObject.h
//  Adium
//
//  Created by Evan Schoenberg on 4/9/09.
//  Copyright 2009 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ESObjectWithProperties;
@protocol AIContainingObject;

@interface AIProxyListObject : NSObject {
	id listObject;
	id <AIContainingObject> containingObject;
	NSString *key;
}

@property (nonatomic, assign) id listObject;
@property (nonatomic, assign) id <AIContainingObject> containingObject;
@property (nonatomic, retain) NSString *key;

+ (AIProxyListObject *)proxyListObjectForListObject:(ESObjectWithProperties *)inListObject
									   inListObject:(ESObjectWithProperties<AIContainingObject> *)containingObject;
+ (void)releaseProxyObject:(AIProxyListObject *)proxyObject;

@end
