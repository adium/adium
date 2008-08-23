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

#import <Adium/ESObjectWithProperties.h>
#import <Adium/AIStatus.h>

@class AIListObject, AIService, AIMutableOwnerArray, AIListGroup;

#define	KEY_ORDER_INDEX		@"Order Index"
#define KEY_IS_BLOCKED		@"isBlocked"

typedef enum {
	AIAvailableStatus = 'avaL',
	AIAwayStatus = 'awaY',
	AIIdleStatus = 'idlE',
	AIAwayAndIdleStatus = 'aYiE',
	AIOfflineStatus = 'offL',
	AIUnknownStatus = 'unkN'
} AIStatusSummary;

@protocol AIContainingObject <NSObject, NSFastEnumeration>

@property (readonly, nonatomic) NSArray *containedObjects;
@property (readonly, nonatomic) NSUInteger containedObjectsCount;

@property (readonly, nonatomic)  NSString *contentsBasedIdentifier;

- (BOOL)containsObject:(AIListObject *)inObject;
- (id)objectAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfObject:(AIListObject *)inObject;
- (AIListObject *)objectWithService:(AIService *)inService UID:(NSString *)inUID;
@property (readonly, nonatomic) BOOL containsMultipleContacts;

/*!
 * @brief Get the visbile object at a given index
 */
- (AIListObject *)visibleObjectAtIndex:(NSUInteger)index;

@property (readonly, nonatomic) CGFloat smallestOrder;
@property (readonly, nonatomic) CGFloat largestOrder;
- (void)listObject:(AIListObject *)listObject didSetOrderIndex:(float)inOrderIndex;
- (float)orderIndexForObject:(AIListObject *)listObject;

//Should list each list contact only once (for groups, this is the same as the objectEnumerator)
@property (readonly, nonatomic) NSArray *listContacts;
@property (readonly, nonatomic) NSArray *visibleListContacts;

- (BOOL)addObject:(AIListObject *)inObject;
- (void)removeObject:(AIListObject *)inObject;
- (void)removeAllObjects;

@property (readwrite, nonatomic, getter=isExpanded) BOOL expanded;
@property (readonly, nonatomic, getter=isExpandable) BOOL expandable;
@property (readonly, nonatomic) NSUInteger visibleCount;
- (BOOL)canContainObject:(id)obj;

- (void)visibilityOfContainedObject:(AIListObject *)inObject changedTo:(BOOL)inVisible;

@end

@interface AIListObject : ESObjectWithProperties {
	AIService			*service;
	
	NSString				*UID;
	NSString				*internalObjectID;
	BOOL							visible;				//Visibility of this object
	BOOL							alwaysVisible;

	//Grouping, Manual ordering
	AIListObject <AIContainingObject>	*containingObject;		//The group/metacontact this object is in
	CGFloat					orderIndex;				//Placement of this contact within a group
	
	//For AIContainingObject-compliant subclasses
	CGFloat					largestOrder;
	CGFloat					smallestOrder;
}

- (id)initWithUID:(NSString *)inUID service:(AIService *)inService;

- (void)object:(id)inObject didChangeValueForProperty:(NSString *)key notify:(NotifyTiming)notify;
- (void)notifyOfChangedPropertiesSilently:(BOOL)silent;

//Identifying information
@property (readonly, nonatomic) NSString *UID;
@property (readonly, nonatomic) AIService *service;
@property (readonly, nonatomic) NSString *serviceID;
@property (readonly, nonatomic) NSString *serviceClass;
@property (readonly, nonatomic) NSString *internalObjectID;
+ (NSString *)internalObjectIDForServiceID:(NSString *)inServiceID UID:(NSString *)inUID;

//Visibility
@property (readwrite, nonatomic) BOOL visible;
@property (readwrite, nonatomic) BOOL alwaysVisible;

//Grouping
@property (readonly, nonatomic) AIListObject <AIContainingObject> *containingObject;

//Display
@property (readonly, nonatomic) NSString *formattedUID;
- (void)setFormattedUID:(NSString *)inFormattedUID notify:(NotifyTiming)notify;
@property (readonly, nonatomic) NSString *longDisplayName;

//Prefs
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName;
- (void)setPreferences:(NSDictionary *)prefs inGroup:(NSString *)group;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName ignoreInheritedValues:(BOOL)ignore;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName;
@property (readonly, nonatomic) NSString *pathToPreferences;

//Alter the placement of this object in a group (PRIVATE: Setting this is for AIListGroup ONLY)
@property (readwrite, nonatomic) CGFloat orderIndex;

//Grouping (PRIVATE: These are for AIListGroup and AIMetaContact ONLY)
- (void)setContainingObject:(AIListObject <AIContainingObject> *)inGroup;

//Key-Value pairing
@property (readonly, nonatomic) BOOL online;

@property (readonly, nonatomic) NSString *statusName;
@property (readonly, nonatomic) AIStatusType statusType;
- (void)setStatusWithName:(NSString *)statusName statusType:(AIStatusType)statusType notify:(NotifyTiming)notify;
@property (readonly, nonatomic) NSAttributedString *statusMessage;
@property (readonly, nonatomic) NSString *statusMessageString;
- (void)setStatusMessage:(NSAttributedString *)statusMessage notify:(NotifyTiming)notify;
- (void)setBaseAvailableStatusAndNotify:(NotifyTiming)notify;
@property (readonly, nonatomic) AIStatusSummary statusSummary;

@property (readonly, nonatomic) BOOL soundsAreMuted;

@property (readonly, nonatomic) BOOL isStranger;
@property (readonly, nonatomic) BOOL isMobile;
@property (readonly, nonatomic) BOOL isBlocked;

@property (readwrite, nonatomic, retain) NSString *displayName;

@property (readonly, nonatomic) NSString *phoneticName;

@property (readwrite, nonatomic, retain) NSString *notes;

@property (readonly, nonatomic) NSNumber *idleTime;

@property (readonly, nonatomic) NSImage *userIcon;
@property (readonly, nonatomic) NSImage *menuIcon;
@property (readonly, nonatomic) NSImage *statusIcon;
@property (readonly, nonatomic) NSData *userIconData;
- (void)setUserIconData:(NSData *)inData;

//For use only by subclasses
@property (readonly, nonatomic) NSImage *internalUserIcon;

//mutableOwnerArray delegate and methods
- (void)listObject:(AIListObject *)listObject mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(AIListObject *)inOwner priorityLevel:(float)priority;

//Comparison
- (NSComparisonResult)compare:(AIListObject *)other;

/*!
 * These methods are part of the AIContainingObject protocol
 * but are implemented by AIListObject (which does not conform to the protocol) for the convenience
 * of subclasses.
 */
@property (readonly, nonatomic) CGFloat smallestOrder;
@property (readonly, nonatomic) CGFloat largestOrder;
- (void)listObject:(AIListObject *)listObject didSetOrderIndex:(float)inOrderIndex;
- (float)orderIndexForObject:(AIListObject *)listObject;
@end
