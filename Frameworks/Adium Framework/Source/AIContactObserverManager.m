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

#import <Adium/AIContactControllerProtocol.h>
#import "AIContactObserverManager.h"
#import "AIContactController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AISortController.h>

/*
 #ifdef DEBUG_BUILD
 #define CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG	TRUE
 #endif
 */

#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
	#import <Foundation/NSDebug.h>
#endif

@interface AIContactObserverManager ()
- (NSSet *)_informObserversOfObjectStatusChange:(AIListObject *)inObject withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent;
- (void)_performDelayedUpdates:(NSTimer *)timer;
@property (nonatomic, retain) NSTimer *delayedUpdateTimer;
@end

#define UPDATE_CLUMP_INTERVAL			1.0

static AIContactObserverManager *sharedObserverManager = nil;

@implementation AIContactObserverManager

+ (AIContactObserverManager *)sharedManager
{
	if(!sharedObserverManager)
		sharedObserverManager = [[self alloc] init];
	return sharedObserverManager;
}

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
		updatesAreDelayedUntilInactivity = NO;
	}
	
	return self;
}
- (void)dealloc
{
	[contactObservers release]; contactObservers = nil;
	[delayedModifiedStatusKeys release];
	[delayedModifiedAttributeKeys release];
	self.delayedUpdateTimer = nil;

	[super dealloc];
}

//Status and Display updates -------------------------------------------------------------------------------------------
#pragma mark Status and Display updates

@synthesize delayedUpdateTimer;

/*!
 * @brief Should potentially expensive updates be deferred?
 *
 * Returns YES if, for any reason, now is just not the time to speak up.
 *
 * This could be YES because delayListObjectNotifications has been called without endListObjectNotificationsDelay being
 * called yet, or because delayListObjectNotificationsUntilInactivity was called at least once and we haven't had a
 * period of inactivity yet.
 */
- (BOOL)shouldDelayUpdates
{
	return ((delayedUpdateRequests > 0) || updatesAreDelayedUntilInactivity);
}

/*!
 * @brief Delay notifications for listObject changes until a matching endListObjectNotificationsDelay is called.
 *
 * This delays Contact_ListChanged, ListObject_AttributesChanged, Contact_OrderChanged notificationsDelays,
 * sorting and redrawing to prevent redundancy when making a large number of changes.
 *
 * Each call must be paired with endListObjectNotificationsDelay. Nested calls are supported; notifications are sent
 * when all delays have been ended.
 */
- (void)delayListObjectNotifications
{
	delayedUpdateRequests++;
}

/*!
 * @brief End a delay of notifications for listObject changes.
 *
 * This is paired with delayListObjectNotifications. Nested calls are supported; notifications are sent
 * when all delays have been ended.
 */
- (void)endListObjectNotificationsDelay
{
	if (delayedUpdateRequests > 0) {
		delayedUpdateRequests--;
		if (![self shouldDelayUpdates])
			[self _performDelayedUpdates:nil];
	}
}

/*!
 * @brief Immediately end all notifications for listObject changes.
 *
 * This ignores nested delayListObjectNotifications / endListObjectNotificationsDelay pairs and cancels
 * all delays immediately.  Subsequent calls to endListObjectNotificationsDelay (until delayListObjectNotifications is
 * called) will be ignored.
 *
 * This is useful if changes are made that require an immediate update, regardless of what other code might want for
 * efficiency. Notably, after deallocating AIListProxyObjects, the contact list *must* have reloadData called upon it
 * (which occurs via its response to Contact_ListChanged sent via -[AIContactObserverManager _performDelayedUpdates:])
 * or it may crash as it accesses deallocated objects as it does not retain the objects it displays.
 */
- (void)endListObjectNotificationsDelaysImmediately
{
	AILogWithSignature(@"");

	if ([self shouldDelayUpdates]) {
		delayedUpdateRequests = 0;

		BOOL restoreDelayUntilInactivity = (self.delayedUpdateTimer != nil);
		
		[self.delayedUpdateTimer invalidate]; self.delayedUpdateTimer = nil;

		[self _performDelayedUpdates:nil];
		
		/* After immediately performing updates as requested, go back to delaying until inactivity if that was the
		 * status quo.
		 */
		if (restoreDelayUntilInactivity)
			[self delayListObjectNotificationsUntilInactivity];
	}
}

#define QUIET_DELAYED_UPDATE_PERIODS 3

//Delay all list object notifications until a period of inactivity occurs.  This is useful for accounts that do not
//know when they have finished connecting but still want to mute events.
- (void)delayListObjectNotificationsUntilInactivity
{
    if (!delayedUpdateTimer) {
		updatesAreDelayedUntilInactivity = YES;
		self.delayedUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_CLUMP_INTERVAL
																   target:self
																 selector:@selector(_performDelayedUpdates:)
																 userInfo:nil
																  repeats:YES];
		quietDelayedUpdatePeriodsRemaining = QUIET_DELAYED_UPDATE_PERIODS; 

    } else {
		//Reset the timer
		[delayedUpdateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:UPDATE_CLUMP_INTERVAL]];
		quietDelayedUpdatePeriodsRemaining = QUIET_DELAYED_UPDATE_PERIODS;
	}
}

//Update the status of a list object.  This will update any information that is otherwise too expensive to update
//automatically, such as their profile.
- (void)updateListContactStatus:(AIListContact *)inContact
{
	//If we're handed something that can contain other contacts, update the status of the contacts contained within it
	if ([inContact conformsToProtocol:@protocol(AIContainingObject)]) {
		
		for (AIListContact *contact in (id <AIContainingObject>)inContact) {
			[self updateListContactStatus:contact];
		}
		
	} else {
		AIAccount *account = inContact.account;
		if (!account.online) {
			account = [adium.accountController preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
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
	if ([self shouldDelayUpdates]) {
		delayedStatusChanges++;
		[delayedModifiedStatusKeys unionSet:inModifiedKeys];
	} else {
		//We can safely skip sorting if we know the modified attributes will invoke a resort later
		if (![[AISortController activeSortController] shouldSortForModifiedAttributeKeys:modifiedAttributeKeys] &&
			[[AISortController activeSortController] shouldSortForModifiedStatusKeys:inModifiedKeys]) {
			[adium.contactController sortListObject:inObject];
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
	BOOL shouldDelay = [self shouldDelayUpdates];
	if (shouldDelay) {
		delayedAttributeChanges++;
		[delayedModifiedAttributeKeys unionSet:inModifiedKeys];
	} else {
        //Resort the contact list if necessary
        if ([[AISortController activeSortController] shouldSortForModifiedAttributeKeys:inModifiedKeys]) {
			[adium.contactController sortListObject:inObject];
        }
	}

	//Post an attributes changed message
	[[NSNotificationCenter defaultCenter] postNotificationName:ListObject_AttributesChanged
														object:inObject
													  userInfo:(inModifiedKeys ?
																[NSDictionary dictionaryWithObject:inModifiedKeys
																							forKey:@"Keys"] :
																nil)];
	 
	if (!shouldDelay) {
		/* Note that we completed 1 or more delayed attribute changes */
		[[NSNotificationCenter defaultCenter] postNotificationName:ListObject_AttributeChangesComplete
															object:inObject
														  userInfo:[NSDictionary dictionaryWithObject:inModifiedKeys
																							   forKey:@"Keys"]];
	}
}

//Performs any delayed list object/handle updates
- (void)_performDelayedUpdates:(NSTimer *)timer
{
	BOOL	updatesOccured = (delayedStatusChanges || delayedAttributeChanges || delayedContactChanges);
	
	//Send out global attribute & status changed notifications (to cover any delayed updates)
	if (updatesOccured) {
		BOOL shouldSort = NO;
		BOOL postAttributesChangesComplete = NO;
		//Inform observers of any changes
		if (delayedContactChanges) {
			delayedContactChanges = 0;
			shouldSort = YES;
		}
		if (delayedStatusChanges) {
			if (!shouldSort &&
				[[AISortController activeSortController] shouldSortForModifiedStatusKeys:delayedModifiedStatusKeys]) {
				shouldSort = YES;
			}
			[delayedModifiedStatusKeys removeAllObjects];
			delayedStatusChanges = 0;
		}
		if (delayedAttributeChanges) {
			if (!shouldSort &&
				[[AISortController activeSortController] shouldSortForModifiedAttributeKeys:delayedModifiedAttributeKeys]) {
				shouldSort = YES;
			}
			
			postAttributesChangesComplete = YES;
			 
			[delayedModifiedAttributeKeys removeAllObjects];
			delayedAttributeChanges = 0;
		}
		
		//Sort only if necessary
		if (shouldSort) {
			[adium.contactController sortContactList];
		}
		
		if (postAttributesChangesComplete) {
			/* Note that we completed 1 or more delayed attribute changes; the precise object isn't known
			 *
			 * This MUST be done AFTER we sort the contact list, if that was necessary, or we may trigger a redisplay
			 * before the contact list does reloadData, leading to bad things as released objects are messaged via
			 * the contact list delegate.
			 */
			[[NSNotificationCenter defaultCenter] postNotificationName:ListObject_AttributeChangesComplete
																object:nil
															  userInfo:[NSDictionary dictionaryWithObject:delayedModifiedAttributeKeys
																								   forKey:@"Keys"]];
		}		
	}
	
    //If no more updates are left to process, disable the update timer
	//If there are no delayed update requests, remove the hold
	if (!delayedUpdateTimer || !updatesOccured) {
		if (delayedUpdateTimer && (quietDelayedUpdatePeriodsRemaining-- <= 0)) {
			[delayedUpdateTimer invalidate];
			self.delayedUpdateTimer = nil;
			updatesAreDelayedUntilInactivity = NO;			
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
	[self delayListObjectNotifications];
	
	id <NSFastEnumeration> en = contacts ?: (id)[(AIContactController *)adium.contactController contactEnumerator];
	
	for (AIListObject *listObject in en) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSSet	*attributes = [inObserver updateListObject:listObject keys:nil silent:YES];
		if (attributes) [self listObjectAttributesChanged:listObject modifiedKeys:attributes];
		
		if ([listObject isKindOfClass:[AIListContact class]]) {
			AIListContact *contact = (AIListContact *)listObject;
			
			//If this contact is within a meta contact, update the meta contact too
			if (contact.metaContact) {
				attributes = [inObserver updateListObject:contact.metaContact
															keys:nil
														  silent:YES];
				if (attributes) [self listObjectAttributesChanged:contact.metaContact
													 modifiedKeys:attributes];
			}
		}
		
		[pool release];
	}
	
	[self endListObjectNotificationsDelay];
}

//Instructs a controller to update all available list objects
- (void)updateAllListObjectsForObserver:(id <AIListObjectObserver>)inObserver
{
	[self delayListObjectNotifications];
	
	//All contacts
	[self updateContacts:nil forObserver:inObserver];
	
	//All bookmarks
	for (AIListBookmark *listBookmark in [(AIContactController *)adium.contactController bookmarkEnumerator]) {
		NSSet	*attributes = [inObserver updateListObject:listBookmark keys:nil silent:YES];
		if (attributes) [self listObjectAttributesChanged:listBookmark modifiedKeys:attributes];
	}
	
    //Reset all groups
	for (AIListGroup *listGroup in [(AIContactController *)adium.contactController groupEnumerator]) {
		NSSet	*attributes = [inObserver updateListObject:listGroup keys:nil silent:YES];
		if (attributes) [self listObjectAttributesChanged:listGroup modifiedKeys:attributes];
	}
	
	//Reset all accounts
	for (AIAccount *account in adium.accountController.accounts) {
		NSSet	*attributes = [inObserver updateListObject:account keys:nil silent:YES];
		if (attributes) [self listObjectAttributesChanged:account modifiedKeys:attributes];
	}
	
	[self endListObjectNotificationsDelay];
}


//Notify observers of a status change.  Returns the modified attribute keys
- (NSSet *)_informObserversOfObjectStatusChange:(AIListObject *)inObject withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent
{
	NSMutableSet	*attrChange = nil;

	for (NSValue *observerValue in [[contactObservers copy] autorelease]) {
		
		/* Skip any observer which has been removed while we were iterating over observers,
		 * as we don't retain observers and therefore risk messaging a released object.
		 */
		if (removedContactObservers && [removedContactObservers containsObject:observerValue])
			continue;
		
		id <AIListObjectObserver> observer = [observerValue nonretainedObjectValue];
#ifdef CONTACT_OBSERVER_MEMORY_MANAGEMENT_DEBUG
		/* This will log a warning in 10.4 about +[Object allocWithZone:] being a compatibility method.
		 * It is only used in debug builds, so that's fine.
		 */
		if (NSIsFreedObject(observer)) {
			AILogWithSignature(@"%p is a released observer! This is a crash.", observer);
			NSAssert1(FALSE, @"%p is a released observer. Please check the Adium Debug Log. If it wasn't logging to file, do that next time.", observer);
		}
#endif		
		
		NSSet *newKeys = [observer updateListObject:inObject keys:modifiedKeys silent:silent];
		if (newKeys) {
			if (!attrChange) attrChange = [[NSMutableSet alloc] init];
			[attrChange unionSet:newKeys];
		}
	}
	//Send out the notification for other observers
	[[NSNotificationCenter defaultCenter] postNotificationName:ListObject_StatusChanged
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
	for (NSValue *observerValue in [[contactObservers copy] autorelease]) {
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

/*!
 * @brief Keep track of a contact who needs to be resorted whenever we're no longer delaying updates.
 */
- (void)noteContactChanged:(AIListObject *)inObject;
{
	if (!changedObjects)
		changedObjects = [[NSMutableSet alloc] init];
	[changedObjects addObject:inObject];

	delayedContactChanges++;
}

@end
