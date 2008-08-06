//
//  AdiumContactPropertiesObserverManager.m
//  Adium
//
//  Created by Evan Schoenberg on 4/16/08.
//

#import "AdiumContactPropertiesObserverManager.h"
#import "AIContactController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AISortController.h>

/*
 #ifdef DEBUG_BUILD
 #define CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG	TRUE
 #endif
 */

#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
	#import <Foundation/NSDebug.h>
#endif

@interface AdiumContactPropertiesObserverManager (PRIVATE)
- (NSSet *)_informObserversOfObjectStatusChange:(AIListObject *)inObject withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent;
- (void)_performDelayedUpdates:(NSTimer *)timer;
@end

#define UPDATE_CLUMP_INTERVAL			1.0

@implementation AdiumContactPropertiesObserverManager

- (id)init
{
	if ((self = [super init])) {
		contactObservers = [[NSMutableSet alloc] init];
		delayedStatusChanges = 0;
		delayedModifiedStatusKeys = [[NSMutableSet alloc] init];
		delayedAttributeChanges = 0;
		delayedModifiedAttributeKeys = [[NSMutableSet alloc] init];
		delayedContactChanges = 0;
		delayedUpdateRequests = 0;
		updatesAreDelayed = NO;		
	}
	
	return self;
}
- (void)dealloc
{
	[contactObservers release]; contactObservers = nil;
	[delayedModifiedStatusKeys release];
	[delayedModifiedAttributeKeys release];

	[super dealloc];
}

//Status and Display updates -------------------------------------------------------------------------------------------
#pragma mark Status and Display updates
//These delay Contact_ListChanged, ListObject_AttributesChanged, Contact_OrderChanged notificationsDelays,
//sorting and redrawing to prevent redundancy when making a large number of changes
//Explicit delay.  Call endListObjectNotificationsDelay to end
- (void)delayListObjectNotifications
{
	delayedUpdateRequests++;
	updatesAreDelayed = YES;
}

//End an explicit delay
- (void)endListObjectNotificationsDelay
{
	delayedUpdateRequests--;
	if (delayedUpdateRequests == 0 && !delayedUpdateTimer) {
		[self _performDelayedUpdates:nil];
	}
}

- (BOOL)updatesAreDelayed
{
	return updatesAreDelayed;
}

//Delay all list object notifications until a period of inactivity occurs.  This is useful for accounts that do not
//know when they have finished connecting but still want to mute events.
- (void)delayListObjectNotificationsUntilInactivity
{
    if (!delayedUpdateTimer) {
		updatesAreDelayed = YES;
		delayedUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:UPDATE_CLUMP_INTERVAL
															   target:self
															 selector:@selector(_performDelayedUpdates:)
															 userInfo:nil
															  repeats:YES] retain];
    } else {
		//Reset the timer
		[delayedUpdateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:UPDATE_CLUMP_INTERVAL]];
	}
}

//Update the status of a list object.  This will update any information that is otherwise too expensive to update
//automatically, such as their profile.
- (void)updateListContactStatus:(AIListContact *)inContact
{
	//If we're handed something that can contain other contacts, update the status of the contacts contained within it
	if ([inContact conformsToProtocol:@protocol(AIContainingObject)]) {
		NSEnumerator	*enumerator = [[(AIListObject<AIContainingObject> *)inContact listContacts] objectEnumerator];
		AIListContact	*contact;
		
		while ((contact = [enumerator nextObject])) {
			[self updateListContactStatus:contact];
		}
		
	} else {
		AIAccount *account = [inContact account];
		if (![account online]) {
			account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																			 toContact:inContact];
		}
		
		[account updateContactStatus:inContact];
	}
}

//Called after modifying a contact's status
// Silent: Silences all events, notifications, sounds, overlays, etc. that would have been associated with this status change
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    NSSet			*modifiedAttributeKeys;
	
    //Let all observers know the contact's status has changed before performing any sorting or further notifications
	modifiedAttributeKeys = [self _informObserversOfObjectStatusChange:inObject withKeys:inModifiedKeys silent:silent];
	
    //Resort the contact list
	if (updatesAreDelayed) {
		delayedStatusChanges++;
		[delayedModifiedStatusKeys unionSet:inModifiedKeys];
	} else {
		//We can safely skip sorting if we know the modified attributes will invoke a resort later
		if (![[[adium contactController] activeSortController] shouldSortForModifiedAttributeKeys:modifiedAttributeKeys] &&
			[[[adium contactController] activeSortController] shouldSortForModifiedStatusKeys:inModifiedKeys]) {
			[[adium contactController] sortListObject:inObject];
		}
	}
	
    //Post an attributes changed message (if necessary)
    if ([modifiedAttributeKeys count]) {
		[self listObjectAttributesChanged:inObject modifiedKeys:modifiedAttributeKeys];
    }
}

//Call after modifying an object's display attributes
//(When modifying display attributes in response to a status change, this is not necessary)
- (void)listObjectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSSet *)inModifiedKeys
{
	if (updatesAreDelayed) {
		delayedAttributeChanges++;
		[delayedModifiedAttributeKeys unionSet:inModifiedKeys];
	} else {
        //Resort the contact list if necessary
        if ([[[adium contactController] activeSortController] shouldSortForModifiedAttributeKeys:inModifiedKeys]) {
			[[adium contactController] sortListObject:inObject];
        }
	}

	//Post an attributes changed message
	[[adium notificationCenter] postNotificationName:ListObject_AttributesChanged
											  object:inObject
											userInfo:(inModifiedKeys ?
													  [NSDictionary dictionaryWithObject:inModifiedKeys
																				  forKey:@"Keys"] :
													  nil)];	
}

//Performs any delayed list object/handle updates
- (void)_performDelayedUpdates:(NSTimer *)timer
{
	BOOL	updatesOccured = (delayedStatusChanges || delayedAttributeChanges || delayedContactChanges);
	
	//Send out global attribute & status changed notifications (to cover any delayed updates)
	if (updatesOccured) {
		BOOL shouldSort = NO;
		
		//Inform observers of any changes
		if (delayedContactChanges) {
			delayedContactChanges = 0;
			shouldSort = YES;
		}
		if (delayedStatusChanges) {
			if (!shouldSort &&
				[[[adium contactController] activeSortController] shouldSortForModifiedStatusKeys:delayedModifiedStatusKeys]) {
				shouldSort = YES;
			}
			[delayedModifiedStatusKeys removeAllObjects];
			delayedStatusChanges = 0;
		}
		if (delayedAttributeChanges) {
			if (!shouldSort &&
				[[[adium contactController] activeSortController] shouldSortForModifiedAttributeKeys:delayedModifiedAttributeKeys]) {
				shouldSort = YES;
			}
			[delayedModifiedAttributeKeys removeAllObjects];
			delayedAttributeChanges = 0;
		}
		
		//Sort only if necessary
		if (shouldSort) {
			[[adium contactController] sortContactList];
		}
	}
	
    //If no more updates are left to process, disable the update timer
	//If there are no delayed update requests, remove the hold
	if (!delayedUpdateTimer || !updatesOccured) {
		if (delayedUpdateTimer) {
			[delayedUpdateTimer invalidate];
			[delayedUpdateTimer release];
			delayedUpdateTimer = nil;
		}
		if (delayedUpdateRequests == 0) {
			updatesAreDelayed = NO;
		}
    }

	[changedObjects autorelease]; changedObjects = nil;
}

//List object observers ------------------------------------------------------------------------------------------------
#pragma mark List object observers
//Registers code to observe handle status changes
- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver
{
	//Add the observer
#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
	AILogWithSignature(@"%@", inObserver);
#endif
    [contactObservers addObject:[NSValue valueWithNonretainedObject:inObserver]];
	
    //Let the new observer process all existing objects
	[self updateAllListObjectsForObserver:inObserver];
}

- (void)unregisterListObjectObserver:(id)inObserver
{
#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
	AILogWithSignature(@"%@", inObserver);
#endif
    [contactObservers removeObject:[NSValue valueWithNonretainedObject:inObserver]];
	
	/* If we're in the middle of informing observers, we need to note this now-removed observer
	 * so that we don't attempt to message it during this iteration.
	 */
	if (informingObservers) {
		if (!removedContactObservers) removedContactObservers = [[NSMutableSet alloc] init];
		[removedContactObservers addObject:[NSValue valueWithNonretainedObject:inObserver]];
	}
}


/*!
 * @brief Update all contacts for an observer, notifying the observer of each one in turn
 *
 * @param contacts The contacts to update, or nil to update all contacts
 * @param inObserver The observer
 */
- (void)updateContacts:(NSSet *)contacts forObserver:(id <AIListObjectObserver>)inObserver
{
	NSEnumerator	*enumerator;
	AIListObject	*listObject;
	
	[self delayListObjectNotifications];
	
	enumerator = (contacts ? [contacts objectEnumerator] : [(AIContactController *)[adium contactController] contactEnumerator]);
	while ((listObject = [enumerator nextObject])) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSSet	*attributes = [inObserver updateListObject:listObject keys:nil silent:YES];
		if (attributes) [self listObjectAttributesChanged:listObject modifiedKeys:attributes];
		
		//If this contact is within a meta contact, update the meta contact too
		AIListObject<AIContainingObject>	*containingObject = [listObject containingObject];
		if (containingObject && [containingObject isKindOfClass:[AIMetaContact class]]) {
			NSSet	*attributes = [inObserver updateListObject:containingObject
														keys:nil
													  silent:YES];
			if (attributes) [self listObjectAttributesChanged:containingObject
												 modifiedKeys:attributes];
		}
		[pool release];
	}
	
	[self endListObjectNotificationsDelay];
}

//Instructs a controller to update all available list objects
- (void)updateAllListObjectsForObserver:(id <AIListObjectObserver>)inObserver
{
	NSEnumerator	*enumerator;
	AIListObject	*listObject;
	
	[self delayListObjectNotifications];
	
	//All contacts
	[self updateContacts:nil forObserver:inObserver];
	
    //Reset all groups
	enumerator = [(AIContactController *)[adium contactController] groupEnumerator];
	while ((listObject = [enumerator nextObject])) {
		NSSet	*attributes = [inObserver updateListObject:listObject keys:nil silent:YES];
		if (attributes) [self listObjectAttributesChanged:listObject modifiedKeys:attributes];
	}
	
	//Reset all accounts
	enumerator = [[[adium accountController] accounts] objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		NSSet	*attributes = [inObserver updateListObject:listObject keys:nil silent:YES];
		if (attributes) [self listObjectAttributesChanged:listObject modifiedKeys:attributes];
	}
	
	[self endListObjectNotificationsDelay];
}


//Notify observers of a status change.  Returns the modified attribute keys
- (NSSet *)_informObserversOfObjectStatusChange:(AIListObject *)inObject withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent
{
	NSMutableSet	*attrChange = nil;
	
	NSEnumerator	*enumerator;
	NSValue			*observerValue;
	
	informingObservers = YES;

	//Let our observers know
	enumerator = [[[contactObservers copy] autorelease] objectEnumerator];
	while ((observerValue = [enumerator nextObject])) {
		id <AIListObjectObserver>	observer;
		NSSet						*newKeys;
		
		/* Skip any observer which has been removed while we were iterating over observers,
		 * as we don't retain observers and therefore risk messaging a released object.
		 */
		if (removedContactObservers && [removedContactObservers containsObject:observerValue])
			continue;
		
		observer = [observerValue nonretainedObjectValue];
#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
		/* This will log a warning in 10.4 about +[Object allocWithZone:] being a compatibility method.
		 * It is only used in debug builds, so that's fine.
		 */
		if (NSIsFreedObject(observer)) {
			AILogWithSignature(@"%p is a released observer! This is a crash.", observer);
			NSAssert1(FALSE, @"%p is a released observer. Please check the Adium Debug Log. If it wasn't logging to file, do that next time.", observer);
		}
#endif		
		if ((newKeys = [observer updateListObject:inObject keys:modifiedKeys silent:silent])) {
			if (!attrChange) attrChange = [[NSMutableSet alloc] init];
			[attrChange unionSet:newKeys];
		}
	}
	//Send out the notification for other observers
	[[adium notificationCenter] postNotificationName:ListObject_StatusChanged
											  object:inObject
											userInfo:(modifiedKeys ? [NSDictionary dictionaryWithObject:modifiedKeys
																								 forKey:@"Keys"] : nil)];
	
	informingObservers = NO;

	//If we removed any observers while informing them, we don't need that information any more
	if (removedContactObservers) {
		[removedContactObservers release]; removedContactObservers = nil;
	}

	return [attrChange autorelease];
}

//Command all observers to apply their attributes to an object
- (void)_updateAllAttributesOfObject:(AIListObject *)inObject
{
	NSEnumerator	*enumerator = [[[contactObservers copy] autorelease] objectEnumerator];
	NSValue			*observerValue;

	informingObservers = YES;

	while ((observerValue = [enumerator nextObject])) {
		/* Skip any observer which has been removed while we were iterating over observers,
		 * as we don't retain observers and therefore risk messaging a released object.
		 */
		if (removedContactObservers && [removedContactObservers containsObject:observerValue])
			continue;

		id <AIListObjectObserver> observer = [observerValue nonretainedObjectValue];
		
		[observer updateListObject:inObject keys:nil silent:YES];
	}
	
	//If we removed any observers while informing them, we don't need that information any more
	if (removedContactObservers) {
		[removedContactObservers release]; removedContactObservers = nil;
	}
	
	informingObservers = NO;
}

- (void)noteContactChanged:(AIListObject *)inObject;
{
	if (!changedObjects)
		changedObjects = [[NSMutableSet alloc] init];
	[changedObjects addObject:inObject];

	delayedContactChanges++;
}

@end
