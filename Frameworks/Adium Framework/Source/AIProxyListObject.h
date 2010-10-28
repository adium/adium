//
//  AIProxyListObject.h
//  Adium
//
//  Created by Evan Schoenberg on 4/9/09.
//  Copyright 2009 Adium X / Saltatory Software. All rights reserved.
//

@class ESObjectWithProperties;
@protocol AIContainingObject;

@interface AIProxyListObject : NSObject {
	id listObject;
	id <AIContainingObject> containingObject;
	NSString *key;
	NSString *cachedDisplayNameString;
	NSAttributedString *cachedDisplayName;
	NSDictionary *cachedLabelAttributes;
	NSSize cachedDisplayNameSize;
}
@property (nonatomic, copy) NSDictionary *cachedLabelAttributes;
@property (nonatomic, retain) NSString *cachedDisplayNameString;
@property (nonatomic, retain) NSAttributedString *cachedDisplayName;
@property (nonatomic) NSSize cachedDisplayNameSize;

/*! 
 * @brief Return the listObject represented by this AIProxyListObject
 *
 * This is a retain loop, as listObject also retains its AIProxyListObjects.
 * It is therefore imperative that, when an AIListObject is no longer tracked by an account,
 * +[AIProxyListObject releaseProxyObject:] is called. This must not wait until -[AIListContact dealloc] or it would
 * never be called.
 */
@property (nonatomic, retain) id listObject; 
@property (nonatomic, assign) id <AIContainingObject> containingObject;
@property (nonatomic, retain) NSString *key;

+ (AIProxyListObject *)proxyListObjectForListObject:(ESObjectWithProperties *)inListObject
									   inListObject:(ESObjectWithProperties<AIContainingObject> *)containingObject;

+ (AIProxyListObject *)existingProxyListObjectForListObject:(ESObjectWithProperties *)inListObject
											   inListObject:(ESObjectWithProperties <AIContainingObject>*)inContainingObject;

/*!
 * @biref Called by ESObjectWithProperties to release its proxy object.
 *
 * This method resolves the retain count noted in documentation for -[AIPorxyListObject listObject]; it must be called.
 */
+ (void)releaseProxyObject:(AIProxyListObject *)proxyObject;

@end
