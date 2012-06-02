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

#import "ESContactAlertsController.h"
#import "AIDoNothingContactAlertPlugin.h"
#import <Adium/AIListObject.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>

@interface ESContactAlertsController ()
- (NSArray *)arrayOfMenuItemsForEventsWithTarget:(id)target forGlobalMenu:(BOOL)global;

- (NSMutableArray *)appendEventsForObject:(AIListObject *)listObject eventID:(NSString *)eventID toArray:(NSMutableArray *)events;
- (void)addMenuItemsForEventHandlers:(NSDictionary *)inEventHandlers toArray:(NSMutableArray *)menuItemArray withTarget:(id)target forGlobalMenu:(BOOL)global;
- (void)removeAllAlertsFromListObject:(AIListObject *)listObject;
@end

@implementation ESContactAlertsController

static	NSMutableDictionary		*eventHandlersByGroup[EVENT_HANDLER_GROUP_COUNT];
static	NSMutableDictionary		*globalOnlyEventHandlersByGroup[EVENT_HANDLER_GROUP_COUNT];

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		globalOnlyEventHandlers = [[NSMutableDictionary alloc] init];
		eventHandlers = [[NSMutableDictionary alloc] init];
		actionHandlers = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)controllerDidLoad
{
}

- (void)controllerWillClose
{
	
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[globalOnlyEventHandlers release]; globalOnlyEventHandlers = nil;
	[eventHandlers release]; eventHandlers = nil;
	[actionHandlers release]; actionHandlers = nil;
	
	[super dealloc];
}


//Events ---------------------------------------------------------------------------------------------------------------
#pragma mark Events

/*!
 * @brief Register an event
 *
 * An event must have a unique eventID. handler is responsible for providing information
 * about the event, such as short and long descriptions. The group determines how the event will be displayed in the events
 * preferences; events in the same group are displayed together.
 *
 * @param eventID Unique event ID
 * @param handler The handler, which must conform to AIEventHandler
 * @param inGroup The group
 * @param global If YES, the event will only be displayed in the global Events preferences; if NO, the event is available for contacts and groups via Get Info, as well.
 */
- (void)registerEventID:(NSString *)eventID
			withHandler:(id <AIEventHandler>)handler
				inGroup:(AIEventHandlerGroupType)inGroup
			 globalOnly:(BOOL)global
{
	if (global) {
		[globalOnlyEventHandlers setObject:handler forKey:eventID];
		
		if (!globalOnlyEventHandlersByGroup[inGroup]) globalOnlyEventHandlersByGroup[inGroup] = [[NSMutableDictionary alloc] init];
		[globalOnlyEventHandlersByGroup[inGroup] setObject:handler forKey:eventID];
		
	} else {
		[eventHandlers setObject:handler forKey:eventID];
		
		if (!eventHandlersByGroup[inGroup]) eventHandlersByGroup[inGroup] = [[NSMutableDictionary alloc] init];
		[eventHandlersByGroup[inGroup] setObject:handler forKey:eventID];
	}
}

//Return all event IDs
- (NSArray *)allEventIDs
{
	return [[eventHandlers allKeys] arrayByAddingObjectsFromArray:[globalOnlyEventHandlers allKeys]];
}

//Return event IDs which aren't global
- (NSArray *)nonGlobalEventIDs
{
	return [eventHandlers allKeys];
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	id <AIEventHandler> handler;
	
	handler = [eventHandlers objectForKey:eventID];
	if (!handler) handler = [globalOnlyEventHandlers objectForKey:eventID];
	
	return [handler longDescriptionForEventID:eventID forListObject:listObject];
}

/*!
 * @brief Returns a menu of all events
 * 
 * A menu item's represented object is the dictionary describing the event it represents
 *
 * @param target The target on which @selector(selectEvent:) will be called on selection.
 * @param global If YES, the events listed will include global ones (such as Error Occurred) in addition to contact-specific ones.
 * @result An NSMenu of the events
 */
- (NSMenu *)menuOfEventsWithTarget:(id)target forGlobalMenu:(BOOL)global
{
	NSMenu				*menu;

	//Prepare our menu
	menu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	[menu setAutoenablesItems:NO];
	
	for (NSMenuItem *item in [self arrayOfMenuItemsForEventsWithTarget:target forGlobalMenu:global]) {
		[menu addItem:item];
	}
	
	return [menu autorelease];
}

- (NSArray *)arrayOfMenuItemsForEventsWithTarget:(id)target forGlobalMenu:(BOOL)global
{
	NSMutableArray		*menuItemArray = [NSMutableArray array];
	BOOL				addedItems = NO;
	NSInteger					i;
	
	for (i = 0; i < EVENT_HANDLER_GROUP_COUNT; i++) {
		NSMutableArray		*groupMenuItemArray;

		//Create an array of menu items for this group
		groupMenuItemArray = [NSMutableArray array];
		
		[self addMenuItemsForEventHandlers:eventHandlersByGroup[i]
								   toArray:groupMenuItemArray
								withTarget:target
							 forGlobalMenu:global];
		if (global) {
			[self addMenuItemsForEventHandlers:globalOnlyEventHandlersByGroup[i]
									   toArray:groupMenuItemArray
									withTarget:target
								 forGlobalMenu:global];
		}
		
		if ([groupMenuItemArray count]) {
			//Add a separator if we are adding a group and we have added before
			if (addedItems) {
				[menuItemArray addObject:[NSMenuItem separatorItem]];
			} else {
				addedItems = YES;
			}
			
			//Sort the array of menuItems alphabetically by title within this group
			[groupMenuItemArray sortUsingSelector:@selector(titleCompare:)];

			[menuItemArray addObjectsFromArray:groupMenuItemArray];
		}
	}
	
	return menuItemArray;
}	

- (void)addMenuItemsForEventHandlers:(NSDictionary *)inEventHandlers toArray:(NSMutableArray *)menuItemArray withTarget:(id)target forGlobalMenu:(BOOL)global
{	
	NSMenuItem			*menuItem;
	
	for (NSString *eventID in inEventHandlers) {
		id <AIEventHandler>	eventHandler = [inEventHandlers objectForKey:eventID];		
		
        menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:(global ?
																				[eventHandler globalShortDescriptionForEventID:eventID] :
																				[eventHandler shortDescriptionForEventID:eventID])
																		target:target 
																		action:@selector(selectEvent:) 
																 keyEquivalent:@""];
        [menuItem setRepresentedObject:eventID];
		[menuItemArray addObject:menuItem];
		[menuItem release];
    }
}

/*!
 * @brief Sort an array of event IDs
 *
 * @brief inArray The array of eventIDs to sort
 * @return The array sorted by eventIDSort()
 */
- (NSArray *)sortedArrayOfEventIDsFromArray:(NSArray *)inArray
{
	return [inArray sortedArrayUsingComparator:^(id objectA, id objectB){
		NSInteger					groupA, groupB;
		id <AIEventHandler> eventHandlerA;
		id <AIEventHandler> eventHandlerB;
		
		//Determine the group of the first event ID
		for (groupA = 0; groupA < EVENT_HANDLER_GROUP_COUNT; groupA++) {
			eventHandlerA = [eventHandlersByGroup[groupA] objectForKey:objectA];
			if (!eventHandlerA) {
				eventHandlerA = [globalOnlyEventHandlersByGroup[groupA] objectForKey:objectA];
			}
			
			if (eventHandlerA) break;
		}
		
		//Determine the group of the second ID
		for (groupB = 0; groupB < EVENT_HANDLER_GROUP_COUNT; groupB++) {
			eventHandlerB = [eventHandlersByGroup[groupB] objectForKey:objectB];
			if (!eventHandlerB) {
				eventHandlerB = [globalOnlyEventHandlersByGroup[groupB] objectForKey:objectB];
			}
			
			if (eventHandlerB) break;
		}
		
		if (groupA < groupB) {
			return (NSComparisonResult)NSOrderedAscending;
			
		} else if (groupB < groupA) {
			return (NSComparisonResult)NSOrderedDescending;
			
		} else {
			NSString	*descriptionA = [eventHandlerA globalShortDescriptionForEventID:objectA];
			NSString	*descriptionB = [eventHandlerA globalShortDescriptionForEventID:objectB];
			
			return ([descriptionA localizedCaseInsensitiveCompare:descriptionB]);
		}
	}];
}

/*!
 * @brief Return the image associated with an event
 */
- (NSImage *)imageForEventID:(NSString *)eventID
{
	id <AIEventHandler>	eventHandler;
	
	eventHandler = [eventHandlers objectForKey:eventID];		
	if (!eventHandler) eventHandler = [globalOnlyEventHandlers objectForKey:eventID];

	return [eventHandler imageForEventID:eventID];
}

/*!
 * @brief Generate an event, returning a set of the actionIDs which were performed.
 *
 * @param eventID The event which occurred
 * @param listObject The object for which the event occurred
 * @param userInfo Event-specific user info
 * @param previouslyPerformedActionIDs If non-nil, a set of actionIDs which should be treated as if they had already been performed in this invocation.
 *
 * @result The set of actions which were performed, suitable for being passed back in for another event generation via previouslyPerformedActionIDs
 */
- (NSSet *)generateEvent:(NSString *)eventID forListObject:(AIListObject *)listObject userInfo:(id)userInfo previouslyPerformedActionIDs:(NSSet *)previouslyPerformedActionIDs
{
	NSArray			*alerts = [self appendEventsForObject:listObject eventID:eventID toArray:nil];
	NSMutableSet	*performedActionIDs = nil;
	
	if (alerts && [alerts count]) {
		performedActionIDs = (previouslyPerformedActionIDs ?
							  [[previouslyPerformedActionIDs mutableCopy] autorelease]:
							  [NSMutableSet set]);
		
		//We go from contact->group->root; a given action will only fire once for this event

		//Process each alert (There may be more than one for an event)
		for (NSDictionary *alert in alerts) {
			NSString *actionID = [alert objectForKey:KEY_ACTION_ID];
			id <AIActionHandler> actionHandler = [actionHandlers objectForKey:actionID];
			
			if ((![performedActionIDs containsObject:actionID]) || ([actionHandler allowMultipleActionsWithID:actionID])) {
				if ([actionHandler performActionID:actionID
											 forListObject:listObject
											   withDetails:[alert objectForKey:KEY_ACTION_DETAILS] 
										 triggeringEventID:eventID
										  userInfo:userInfo]) {
					
					//If this alert was a single-fire alert, we can delete it now
					if ([[alert objectForKey:KEY_ONE_TIME_ALERT] integerValue]) {
						AILogWithSignature(@"One time alert, so removing %@ from %@", alert, listObject);
						[self removeAlert:alert fromListObject:listObject];
					}
					
					//We don't want to perform this action again for this event
					[performedActionIDs addObject:actionID];
				}
			}
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:eventID
											  object:listObject 
											userInfo:userInfo];
	
	/* If we generated a new perfromedActionIDs, return it.  If we didn't, return the original
	 * previouslyPerformedActionIDs, which may also be nil or may be actionIDs performed on some previous invocation.
	 */
	return (performedActionIDs ? performedActionIDs : previouslyPerformedActionIDs);
}

/*!
 * @brief Append events for the passed object to the specified array.
 *
 * @param events The array of events so far. Create the array if passed nil.
 * @param The object for which we're retrieving events. If nil, we retrieve the global preferences.
 *
 * This method is intended to be called recursively; it should generate an array which has alerts from:
 * contact->metaContact->group->global preferences (skipping any which don't exist).
 *
 * @result An array which contains the object's own events followed by its containingObject's events.
 */
- (NSMutableArray *)appendEventsForObject:(AIListObject *)listObject eventID:(NSString *)eventID toArray:(NSMutableArray *)events
{
	NSArray			*newEvents;

	//Add events for this object (replacing any inherited from the containing object so that this object takes precendence)
	newEvents = [[adium.preferenceController preferenceForKey:KEY_CONTACT_ALERTS
														  group:PREF_GROUP_CONTACT_ALERTS
									  objectIgnoringInheritance:listObject] objectForKey:eventID];
	
	if (newEvents && [newEvents count]) {
		if (!events) events = [NSMutableArray array];
		[events addObjectsFromArray:newEvents];
		
		//Don't add any more events if there's a Do Nothing action
		for (NSDictionary *event in newEvents){
			NSString *actionID = [event objectForKey:KEY_ACTION_ID];
			if ([actionID isEqualToString:DO_NOTHING_ALERT_IDENTIFIER])
				return events;
		}
	}

	//Get all events from the contanining object if we have an object
	if (listObject) {
		if (listObject.containingObjects.count > 0) {
			for (AIListObject<AIContainingObject> *container in listObject.containingObjects) {
				events = [self appendEventsForObject:container eventID:eventID toArray:events];
			}
		} else
			events = [self appendEventsForObject:nil eventID:eventID toArray:events];
	}

	return events;
}

/*!
 * @brief Return the default event ID for a new alert
 */
- (NSString *)defaultEventID
{
	NSString *defaultEventID = [adium.preferenceController preferenceForKey:KEY_DEFAULT_EVENT_ID
																		group:PREF_GROUP_CONTACT_ALERTS];
	if (![eventHandlers objectForKey:defaultEventID]) {
		defaultEventID = [[eventHandlers allKeys] objectAtIndex:0];
	}
	
	return defaultEventID;
}

/*!
 * @brief Find the eventID associated with an English name
 *
 * This exists for compatibility with old AdiumXtras...
 */
- (NSString *)eventIDForEnglishDisplayName:(NSString *)displayName
{	
	for (NSString *eventID in eventHandlers) {
		id <AIEventHandler>	eventHandler = [eventHandlers objectForKey:eventID];		
		if ([[eventHandler englishGlobalShortDescriptionForEventID:eventID] isEqualToString:displayName]) {
			return eventID;
		}
	}

	for (NSString *eventID in globalOnlyEventHandlers) {
		id <AIEventHandler>	eventHandler = [globalOnlyEventHandlers objectForKey:eventID];		
		if ([[eventHandler englishGlobalShortDescriptionForEventID:eventID] isEqualToString:displayName]) {
			return eventID;
		}
	}
	
	return nil;
}

/*!
 * @brief Return a short description to describe eventID when considered globally
 */
- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	id <AIEventHandler>	eventHandler;
	
	eventHandler = [eventHandlers objectForKey:eventID];
	if (!eventHandler) eventHandler = [globalOnlyEventHandlers objectForKey:eventID];
	
	if (eventHandler) {
		return [eventHandler globalShortDescriptionForEventID:eventID];
	}
	
	return @"";
}

/*!
 * @brief Return a natural language, localized description for an event
 *
 * This will be suitable for display to the user such as in a message window or a Growl notification
 *
 * @param eventID The event
 * @param listObject The object for which the event occurred
 * @param userInfo Event-specific userInfo
 * @param includeSubject If YES, the return value is a complete sentence. If NO, the return value is suitable for display after a name or other identifier.
 * @result The natural language description
 */
- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	id <AIEventHandler>	eventHandler;

	eventHandler = [eventHandlers objectForKey:eventID];
	if (!eventHandler) eventHandler = [globalOnlyEventHandlers objectForKey:eventID];

	if (eventHandler) {
		return [eventHandler naturalLanguageDescriptionForEventID:eventID
													   listObject:listObject
														 userInfo:userInfo
												   includeSubject:includeSubject];
	}

	return @"";
}

- (NSString *)descriptionForCombinedEventID:(NSString *)eventID
							  forListObject:(AIListObject *)listObject
									forChat:(AIChat *)chat
								  withCount:(NSUInteger)count
{
	id <AIEventHandler>	eventHandler;
	
	eventHandler = [eventHandlers objectForKey:eventID];
	if (!eventHandler) eventHandler = [globalOnlyEventHandlers objectForKey:eventID];
	
	if (eventHandler) {
		return [eventHandler descriptionForCombinedEventID:eventID
											 forListObject:listObject
												   forChat:chat
												 withCount:count];
	}
	
	return @"";	
}

//Actions --------------------------------------------------------------------------------------------------------------
#pragma mark Actions
/*!
 * @brief Register an actionID and its handler
 *
 * When an event occurs -- that is, when the event is generated via
 * -[ESContactAlertsController generateEvent:forListObject:userInfo:] -- the handler for each action
 * associated with that event within the appropriate list object's heirarchy (object -> containing group -> global)
 * will be called as per the AIActionHandler protocol.
 *
 * @param actionID The actionID
 * @param handler The handler, which must conform to the AIActionHandler protocol
 */
- (void)registerActionID:(NSString *)actionID withHandler:(id <AIActionHandler>)handler
{
	[actionHandlers setObject:handler forKey:actionID];
}

/*!
 * @brief Return a dictionary whose keys are action IDs and whose objects are objects conforming to AIActionHandler
 */
- (NSDictionary *)actionHandlers
{
	return actionHandlers;
}

/*!
 * @brief Returns a menu of all actions
 *
 * A menu item's represented object is the dictionary describing the action it represents
 *
 * @param target The target on which @selector(selectAction:) will be called on selection
 * @result The NSMenu, which does not send validateMenuItem: messages
 */
- (NSMenu *)menuOfActionsWithTarget:(id)target
{
	NSMenu			*menu;
	NSMutableArray	*menuItemArray;
	
	//Prepare our menu
	menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];
	
	menuItemArray = [[NSMutableArray alloc] init];
	
    //Insert a menu item for each available action
	for (NSString *actionID in actionHandlers) {
		id <AIActionHandler> actionHandler = [actionHandlers objectForKey:actionID];		
		NSMenuItem			 *menuItem;

        menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[actionHandler shortDescriptionForActionID:actionID]
																		target:target 
																		action:@selector(selectAction:) 
																 keyEquivalent:@""];
        [menuItem setRepresentedObject:actionID];
		[menuItem setImage:[[actionHandler imageForActionID:actionID] imageByScalingForMenuItem]];
		
        [menuItemArray addObject:menuItem];
		[menuItem release];
    }

	//Sort the array of menuItems alphabetically by title	
	[menuItemArray sortUsingSelector:@selector(titleCompare:)];
	
	for (NSMenuItem	*menuItem in menuItemArray) {
		[menu addItem:menuItem];
	}
	
	[menuItemArray release];

	return [menu autorelease];
}	

/*!
 * @brief Return the default action ID for a new alert
 */
- (NSString *)defaultActionID
{
	NSString *defaultActionID = [adium.preferenceController preferenceForKey:KEY_DEFAULT_ACTION_ID
																		 group:PREF_GROUP_CONTACT_ALERTS];
	if (![actionHandlers objectForKey:defaultActionID]) {
		defaultActionID = [[actionHandlers allKeys] objectAtIndex:0];
	}
	
	return defaultActionID;
}

//Alerts ---------------------------------------------------------------------------------------------------------------
#pragma mark Alerts
/*!
 * @brief Returns an array of all the alerts of a given list object
 *
 * @param listObject The object
 */
- (NSArray *)alertsForListObject:(AIListObject *)listObject
{
	return [self alertsForListObject:listObject withEventID:nil actionID:nil];
}

/*!
 * @brief Return an array of all alerts for a list object
 *
 * @param listObject The object, or nil for global
 * @param eventID If specified, only return events matching eventID. If nil, don't filter based on events.
 * @param actionID If specified, only return actions matching actionID. If nil, don't filter based on actionID.
 */
- (NSArray *)alertsForListObject:(AIListObject *)listObject withEventID:(NSString *)eventID actionID:(NSString *)actionID
{
	NSDictionary	*contactAlerts = [adium.preferenceController preferenceForKey:KEY_CONTACT_ALERTS
																			  group:PREF_GROUP_CONTACT_ALERTS
														  objectIgnoringInheritance:listObject];
	NSMutableArray	*alertArray = [NSMutableArray array];

	if (eventID) {
		/* If we have an eventID, just look at the alerts for this eventID */		
		for (NSDictionary *alert in [[contactAlerts objectForKey:eventID] objectEnumerator]) {
			//If we don't have a specific actionID, or this one is right, add it
			if (!actionID || [actionID isEqualToString:[alert objectForKey:KEY_ACTION_ID]]) {
				[alertArray addObject:alert];
			}
		}
		
	} else {
		/* If we don't have an eventID, look at all alerts */
		
		//Flatten the alert dict into an array
		for (NSString *anEventID in contactAlerts) {
			for (NSDictionary *alert in [[contactAlerts objectForKey:anEventID] objectEnumerator]) {
				//If we don't have a specific actionID, or this one is right, add it
				if (!actionID || [actionID isEqualToString:[alert objectForKey:KEY_ACTION_ID]]) {
					[alertArray addObject:alert];
				}
			}
		}	
	}
	
	return alertArray;	
}

/*!
 * @brief Add an alert (passed as a dictionary) to a list object
 *
 * @param newAlert The alert to add
 * @param listObject The object to which to add, or nil for global
 * @param setAsNewDefaults YES to make the type and details of newAlert be the new default for new alerts
 */
- (void)addAlert:(NSDictionary *)newAlert toListObject:(AIListObject *)listObject setAsNewDefaults:(BOOL)setAsNewDefaults
{
	NSString			*newAlertEventID = [newAlert objectForKey:KEY_EVENT_ID];
	NSMutableDictionary	*contactAlerts;
	NSMutableArray		*eventArray;
	
	[adium.preferenceController delayPreferenceChangedNotifications:YES];
	
	//Get the alerts for this list object
	contactAlerts = [[adium.preferenceController preferenceForKey:KEY_CONTACT_ALERTS
															  group:PREF_GROUP_CONTACT_ALERTS
										  objectIgnoringInheritance:listObject] mutableCopy];
	if (!contactAlerts) contactAlerts = [[NSMutableDictionary alloc] init];
	
	//Get the event array for the new alert, making a copy so we can modify it
	eventArray = [[contactAlerts objectForKey:newAlertEventID] mutableCopy];
	if (!eventArray) eventArray = [[NSMutableArray alloc] init];
	
	//Avoid putting the exact same alert into the array twice
	if ([eventArray indexOfObject:newAlert] == NSNotFound) {
		//Add the new alert
		[eventArray addObject:newAlert];
		
		//Put the modified event array back into the contact alert dict, and save our changes
		[contactAlerts setObject:eventArray forKey:newAlertEventID];
		[adium.preferenceController setPreference:contactAlerts
											 forKey:KEY_CONTACT_ALERTS
											  group:PREF_GROUP_CONTACT_ALERTS
											 object:listObject];	
	}

	//Update the default events if requested
	if (setAsNewDefaults) {
		[adium.preferenceController setPreference:newAlertEventID
											 forKey:KEY_DEFAULT_EVENT_ID
											  group:PREF_GROUP_CONTACT_ALERTS];
		[adium.preferenceController setPreference:[newAlert objectForKey:KEY_ACTION_ID]
											 forKey:KEY_DEFAULT_ACTION_ID
											  group:PREF_GROUP_CONTACT_ALERTS];	
	}
	
	//Cleanup
	[contactAlerts release];
	[eventArray release];
	
	[adium.preferenceController delayPreferenceChangedNotifications:NO];
}

/*!
 * @brief Add an alert at the global level
 */
- (void)addGlobalAlert:(NSDictionary *)newAlert
{
	[self addAlert:newAlert toListObject:nil setAsNewDefaults:NO];
}

/*!
 * @brief Remove an alert from a listObject
 *
 * @param victimAlert The alert to remove; it will be tested against existing alerts using isEqual: so must be identical
 * @param listObject The object (or nil, for global) from which to remove victimAlert
 */
- (void)removeAlert:(NSDictionary *)victimAlert fromListObject:(AIListObject *)listObject
{
	AILogWithSignature(@"Removing %@ from %@", victimAlert, listObject);
	NSMutableDictionary	*contactAlerts = [[adium.preferenceController preferenceForKey:KEY_CONTACT_ALERTS
																				   group:PREF_GROUP_CONTACT_ALERTS
															   objectIgnoringInheritance:listObject] mutableCopy];
	NSString			*victimEventID = [victimAlert objectForKey:KEY_EVENT_ID];
	NSMutableArray		*eventArray;
	
	//Get the event array containing the victim alert, making a copy so we can modify it
	eventArray = [[contactAlerts objectForKey:victimEventID] mutableCopy];
	
	//Remove the victim
	[eventArray removeObject:victimAlert];
	
	//Put the modified event array back into the contact alert dict, and save our changes
	if ([eventArray count]) {
		[contactAlerts setObject:eventArray forKey:victimEventID];
	} else {
		[contactAlerts removeObjectForKey:victimEventID];	
	}
	
	[adium.preferenceController setPreference:contactAlerts
										 forKey:KEY_CONTACT_ALERTS
										  group:PREF_GROUP_CONTACT_ALERTS
										 object:listObject];
	[eventArray release];
	[contactAlerts release];
}

/*!
 * @brief Remove all alerts which are specifically applied to listObject
 *
 * This does not affect alerts set at higher (containing object, root) levels 
 */
- (void)removeAllAlertsFromListObject:(AIListObject *)listObject
{
	[listObject setPreference:nil
					   forKey:KEY_CONTACT_ALERTS
						group:PREF_GROUP_CONTACT_ALERTS];
}

/*!
 * @brief Remove all global (root-level) alerts with a given action ID
 */
- (void)removeAllGlobalAlertsWithActionID:(NSString *)actionID
{
	NSDictionary		*contactAlerts = [adium.preferenceController preferenceForKey:KEY_CONTACT_ALERTS 
																				  group:PREF_GROUP_CONTACT_ALERTS];
	NSMutableDictionary *newContactAlerts = [contactAlerts mutableCopy];
	
	//The contact alerts preference is a dictionary keyed by event.  Each event key yields an array of dictionaries;
	//each of these dictionaries represents an alert.  We want to remove all dictionaries which represent alerts with
	//the passed actionID
	for (NSString *victimEventID in contactAlerts) {
		NSMutableArray  *newEventArray = nil;
		NSArray			*eventArray;

		eventArray = [contactAlerts objectForKey:victimEventID];

		//Enumerate each alert for this event
		for (NSDictionary *alertDict in eventArray) {
			//We found an alertDict which needs to be removed
			if ([[alertDict objectForKey:KEY_ACTION_ID] isEqualToString:actionID]) {
				//If this is the first modification to the current eventArray, make a mutableCopy with which to work
				if (!newEventArray) newEventArray = [eventArray mutableCopy];
				[newEventArray removeObject:alertDict];
			}
		}
		
		//newEventArray will only be non-nil if we made changes; now that we have enumerated this eventArray, save them
		if (newEventArray) {
			if ([newEventArray count]) {
				[newContactAlerts setObject:newEventArray forKey:victimEventID];
			} else {
				[newContactAlerts removeObjectForKey:victimEventID];	
			}
			
			//Clean up
			[newEventArray release];
		}
	}
	
	[adium.preferenceController setPreference:newContactAlerts
										 forKey:KEY_CONTACT_ALERTS
										  group:PREF_GROUP_CONTACT_ALERTS];
	[newContactAlerts release];
}

/*!
 * @brief Remove all current global alerts and replace them with the alerts in allGlobalAlerts
 *
 * Used for setting a preset of events
 */
- (void)setAllGlobalAlerts:(NSArray *)allGlobalAlerts
{
	NSMutableDictionary	*contactAlerts = [[NSMutableDictionary alloc] init];;
	NSDictionary		*eventDict;
	
	[adium.preferenceController delayPreferenceChangedNotifications:YES];
	
	for (eventDict in allGlobalAlerts) {
		NSMutableArray		*eventArray;
		NSString			*eventID = [eventDict objectForKey:KEY_EVENT_ID];

		/* Get the event array for this alert. Since we are creating the entire dictionary, we can be sure we are working
		 * with an NSMutableArray.
		 */
		eventArray = [contactAlerts objectForKey:eventID];
		if (!eventArray) eventArray = [NSMutableArray array];		

		//Add the new alert
		[eventArray addObject:eventDict];
		
		//Put the modified event array back into the contact alert dict
		[contactAlerts setObject:eventArray forKey:eventID];		
	}
	
	[adium.preferenceController setPreference:contactAlerts
										 forKey:KEY_CONTACT_ALERTS
										  group:PREF_GROUP_CONTACT_ALERTS
										 object:nil];
	[contactAlerts release];

	[adium.preferenceController delayPreferenceChangedNotifications:NO];
	
}

/*!
 * @brief Move all contact alerts from oldObject to newObject
 *
 * This is useful when adding oldObject to the metaContact newObject so that any existing contact alerts for oldObject
 * are applied at the contact-general level, displayed and handled properly for the new, combined contact.
 *
 * @param oldObject The object from which to move contact alerts
 * @param newObject The object to which to we want to add the moved contact alerts
 */
- (void)mergeAndMoveContactAlertsFromListObject:(AIListObject *)oldObject intoListObject:(AIListObject *)newObject
{
	NSArray				*oldAlerts = [self alertsForListObject:oldObject];
	NSDictionary		*alertDict;
	
	[adium.preferenceController delayPreferenceChangedNotifications:YES];
	
	//Add each alert to the target (addAlert:toListObject:setAsNewDefaults: will ensure identical alerts aren't added more than once)
	for (alertDict in oldAlerts) {
		[self addAlert:alertDict toListObject:newObject setAsNewDefaults:NO];
	}
	
	//Remove the alerts from the originating list object
	[self removeAllAlertsFromListObject:oldObject];
	
	[adium.preferenceController delayPreferenceChangedNotifications:NO];
}

#pragma mark -
/*!
 * @brief Is the passed event a message event?
 *
 * Examples of messages events are "message sent" and "message received."
 *
 * @result YES if it is a message event
 */
- (BOOL)isMessageEvent:(NSString *)eventID
{
	return ([eventHandlersByGroup[AIMessageEventHandlerGroup] objectForKey:eventID] != nil ||
		   ([globalOnlyEventHandlersByGroup[AIMessageEventHandlerGroup] objectForKey:eventID] != nil));
}

/*!
 * @brief Is the passed event a contact status event?
 *
 * Examples of messages events are "contact signed on" and "contact went away."
 *
 * @result YES if it is a contact status event
 */
- (BOOL)isContactStatusEvent:(NSString *)eventID
{
	return ([eventHandlersByGroup[AIContactsEventHandlerGroup] objectForKey:eventID] != nil ||
			([globalOnlyEventHandlersByGroup[AIContactsEventHandlerGroup] objectForKey:eventID] != nil));
}

@end
