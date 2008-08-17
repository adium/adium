//
//  AIContactObserverManager.h
//  Adium
//
//  Created by Evan Schoenberg on 4/16/08.
//

@class AIListObject, AIListContact;

//Observer which receives notifications of changes in list object status
@protocol AIListObjectObserver
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
@end

@interface AIContactObserverManager : NSObject {
	//Status and Attribute updates
	NSMutableSet			*contactObservers;
	NSMutableSet			*removedContactObservers;
	NSTimer					*delayedUpdateTimer;
	NSInteger				delayedStatusChanges;
	NSMutableSet			*delayedModifiedStatusKeys;
	NSInteger				delayedAttributeChanges;
	NSMutableSet			*delayedModifiedAttributeKeys;

	BOOL						updatesAreDelayed;
	NSMutableSet			*changedObjects;
	
	BOOL						informingObservers;
	NSInteger				delayedContactChanges;
	NSInteger				delayedUpdateRequests;
}

+ (AIContactObserverManager *)sharedManager;
- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver;
- (void)unregisterListObjectObserver:(id)inObserver;
- (void)updateAllListObjectsForObserver:(id <AIListObjectObserver>)inObserver;
- (void)updateContacts:(NSSet *)contacts forObserver:(id <AIListObjectObserver>)inObserver;
- (void)delayListObjectNotifications;
- (void)endListObjectNotificationsDelay;
- (BOOL)updatesAreDelayed;
- (void)delayListObjectNotificationsUntilInactivity;
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
- (void)listObjectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSSet *)inModifiedKeys;
- (void)updateListContactStatus:(AIListContact *)inContact;

- (void)_updateAllAttributesOfObject:(AIListObject *)inObject;

- (void)noteContactChanged:(AIListObject *)inObject;

@end
