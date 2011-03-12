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
