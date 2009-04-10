//
//  AIProxyListObject.h
//  Adium
//
//  Created by Evan Schoenberg on 4/9/09.
//  Copyright 2009 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIListObject;
@protocol AIContainingObject;

@interface AIProxyListObject : NSObject {
	AIListObject *listObject;
	NSString *key;
}

@property (nonatomic, assign) AIListObject *listObject;
@property (nonatomic, retain) NSString *key;

+ (AIProxyListObject *)proxyListObjectForListObject:(AIListObject *)inListObject
									   inListObject:(id<AIContainingObject>)containingObject;
+ (void)releaseProxyObject:(AIProxyListObject *)proxyObject;

@end
