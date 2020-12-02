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

@class ESObjectWithProperties, MAZeroingWeakRef;
@protocol AIContainingObject;

@interface AIProxyListObject : NSObject {
	AIListObject *listObject;
    ESObjectWithProperties <AIContainingObject> *containingObject;
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

@property (nonatomic, retain) NSString *key;

@property (nonatomic, assign) AIListObject *listObject;
@property (nonatomic, assign) ESObjectWithProperties <AIContainingObject> * containingObject;

+ (AIProxyListObject *)proxyListObjectForListObject:(ESObjectWithProperties *)inListObject
									   inListObject:(ESObjectWithProperties<AIContainingObject> *)containingObject;

+ (AIProxyListObject *)existingProxyListObjectForListObject:(ESObjectWithProperties *)inListObject
											   inListObject:(ESObjectWithProperties <AIContainingObject>*)inContainingObject;

/*!
 * @brief Called when an AIListObject is done with an AIProxyListObject to remove it from the global dictionary
 */
+ (void)releaseProxyObject:(AIProxyListObject *)proxyObject;

/*!
 * @brief Clear out cached display information; should be called when the AIProxyListObject may be used later
 */
- (void)flushCache;

@end
