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

#import "AIStatusController.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AISoundControllerProtocol.h>

#import <Adium/AIContactControllerProtocol.h>
#import "AdiumIdleManager.h"

#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIEventAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIStatusIcons.h>
#import "AIStatusGroup.h"
#import <Adium/AIStatus.h>

//State menu
#define STATUS_TITLE_OFFLINE		AILocalizedStringFromTable(@"Offline", @"Statuses", "Name of a status")

#define BUILT_IN_STATE_ARRAY		@"BuiltInStatusStates"

@interface AIStatusController ()
- (NSArray *)builtInStateArray;

- (void)_upgradeSavedAwaysToSavedStates;

- (NSArray *)_menuItemsForStatusesOfType:(AIStatusType)type forServiceCodeUniqueID:(NSString *)inServiceCodeUniqueID withTarget:(id)target;
- (void)_addMenuItemsForStatusOfType:(AIStatusType)type
						  withTarget:(id)target
							 fromSet:(NSSet *)sourceArray
							 toArray:(NSMutableArray *)menuItems
				  alreadyAddedTitles:(NSMutableSet *)alreadyAddedTitles;
- (void)buildBuiltInStatusTypes;
- (void)notifyOfChangedStatusArray;
@end

/*!
 * @class AIStatusController
 * @brief Core status & state methods
 *
 * This class provides a foundation for Adium's status and status state systems.
 */
@implementation AIStatusController

static 	NSMutableSet			*temporaryStateArray = nil;

/*!
 * Init the status controller
 */
- (id)init
{
	if ((self = [super init])) {
		stateMenuItemArraysDict = [[NSMutableDictionary alloc] init];
		stateMenuPluginsArray = [[NSMutableArray alloc] init];
		stateMenuItemsNeedingUpdating = [[NSMutableSet alloc] init];
		activeStatusUpdateDelays = 0;
		_sortedFullStateArray = nil;
		_activeStatusState = nil;
		_allActiveStatusStates = nil;
		temporaryStateArray = [[NSMutableSet alloc] init];
		
		accountsToConnect = [[NSMutableSet alloc] init];
		
		idleManager = [[AdiumIdleManager alloc] init];
	}
	
	return self;
}

/*!
 * @brief Finish initing the status controller
 *
 * Set our initial status state, and restore our array of accounts to connect when a global state is selected.
 */
- (void)controllerDidLoad
{
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];

	[self buildBuiltInStatusTypes];

	//Put each account into the status it was in last time we quit.
	BOOL		needToRebuildMenus = NO;
	AIStatus	*prevStatus = nil;

	for (AIAccount *account in adium.accountController.accounts) {
		NSData		*lastStatusData = [account preferenceForKey:@"LastStatus"
														  group:GROUP_ACCOUNT_STATUS];
		AIStatus	*lastStatus = nil;
		if (lastStatusData)
			lastStatus = [NSKeyedUnarchiver unarchiveObjectWithData:lastStatusData];

		if (lastStatus && [lastStatus isKindOfClass:[AIStatus class]]) {
			AIStatus	*existingStatus;
			
			/* We want to use a loaded status instance if one exists.  This will be the case if the account
			 * was last in a built-in or user defined and saved state.  If the last state was unsaved, existingStatus
			 * will be nil.
			 */
			existingStatus = [self statusStateWithUniqueStatusID:[lastStatus uniqueStatusID]];
			
			if (existingStatus) {
				lastStatus = existingStatus;
			} else {
				//Add to our temporary status array
				[temporaryStateArray addObject:lastStatus];
				
				/* We could clear out _flatStatusSet for the next iteration, but we _know_ what changed,
				 * so modify it directly for efficiency.
				 */
				[_flatStatusSet addObject:lastStatus];

				needToRebuildMenus = YES;
			}
			if (!prevStatus) {
				prevStatus = lastStatus;
			} //else if (prevStatus != lastStatus) {}

			[account setStatusStateAndRemainOffline:lastStatus];
		}
	}

	if (needToRebuildMenus) {
		[self notifyOfChangedStatusArray];
	}
}

/*!
 * @brief Begin closing the status controller
 *
 * Save the online accounts; they will be the accounts connected by a global status change
 *
 * Also save the current status state of each account so it can be restored on next launch.
 */
- (void)controllerWillClose
{
	for (AIAccount *account in adium.accountController.accounts) {
		/* Store the current status state for use on next launch.
		 *
		 * We use the valueForProperty:@"accountStatus" accessor rather than account.statusState
		 * because we don't want anything besides the account's actual status state.  That is, we don't
		 * want the default available state if the account doesn't have a state yet, and we want the
		 * real last-state-which-was-set (not the offline one) if the account is offline.
		 */
		AIStatus	*currentStatus = [account valueForProperty:@"accountStatus"];
		[account setPreference:((currentStatus && (currentStatus != offlineStatusState)) ?
								[NSKeyedArchiver archivedDataWithRootObject:currentStatus] :
								nil)
						forKey:@"LastStatus"
						 group:GROUP_ACCOUNT_STATUS];
	}
	
	[adium.preferenceController setPreference:[NSKeyedArchiver archivedDataWithRootObject:[[self rootStateGroup] containedStatusItems]]
										 forKey:KEY_SAVED_STATUS
										  group:PREF_GROUP_SAVED_STATUS];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[_rootStateGroup release]; _rootStateGroup = nil;
	[_sortedFullStateArray release]; _sortedFullStateArray = nil;
	[super dealloc];
}

#pragma mark Status registration
/*!
 * @brief Register a status for a service
 *
 * Implementation note: Each AIStatusType has its own NSMutableDictionary, statusDictsByServiceCodeUniqueID.
 * statusDictsByServiceCodeUniqueID is keyed by serviceCodeUniqueID; each object is an NSMutableSet of NSDictionaries.
 * Each of these dictionaries has KEY_STATUS_NAME, KEY_STATUS_DESCRIPTION, and KEY_STATUS_TYPE.
 *
 * @param statusName A name which will be passed back to accounts of this service.  Internal use only.  Use the AIStatusController.h #defines where appropriate.
 * @param description A human-readable localized description which will be shown to the user.  Use the AIStatusController.h #defines where appropriate.
 * @param type An AIStatusType, the general type of this status.
 * @param service The AIService for which to register the status
 */
- (void)registerStatus:(NSString *)statusName withDescription:(NSString *)description ofType:(AIStatusType)type forService:(AIService *)service
{
	NSMutableSet	*statusDicts;
	NSString		*serviceCodeUniqueID = service.serviceCodeUniqueID;

	//Create the set if necessary
	if (!statusDictsByServiceCodeUniqueID[type]) statusDictsByServiceCodeUniqueID[type] = [[NSMutableDictionary alloc] init];
	if (!(statusDicts = [statusDictsByServiceCodeUniqueID[type] objectForKey:serviceCodeUniqueID])) {
		statusDicts = [NSMutableSet set];
		[statusDictsByServiceCodeUniqueID[type] setObject:statusDicts
												   forKey:serviceCodeUniqueID];
	}

	//Create a dictionary for this status entry
	NSDictionary *statusDict = [NSDictionary dictionaryWithObjectsAndKeys:
		statusName, KEY_STATUS_NAME,
		description, KEY_STATUS_DESCRIPTION,
		[NSNumber numberWithInteger:type], KEY_STATUS_TYPE,
		nil];

	[statusDicts addObject:statusDict];
}

#pragma mark Status menus
/*!
 * @brief Generate and return a menu of status types (Away, Be right back, etc.)
 *
 * @param service The service for which to return a specific list of types, or nil to return all available types
 * @param target The target for the menu items, which will have an action of @selector(selectStatus:)
 *
 * @result The menu of statuses, separated by available and away status types
 */
- (NSMenu *)menuOfStatusesForService:(AIService *)service withTarget:(id)target
{
	NSMenu			*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSMenuItem		*menuItem;
	NSString		*serviceCodeUniqueID = service.serviceCodeUniqueID;
	AIStatusType	type;

	for (type = AIAvailableStatusType ; type < STATUS_TYPES_COUNT ; type++) {
		NSArray		*menuItemArray;

		menuItemArray = [self _menuItemsForStatusesOfType:type
								   forServiceCodeUniqueID:serviceCodeUniqueID
											   withTarget:target];

		//Add a separator between each type after available
		if ((type > AIAvailableStatusType) && [menuItemArray count]) {
			[menu addItem:[NSMenuItem separatorItem]];
		}

		//Add the items for this type
		for (menuItem in menuItemArray) {
			[menu addItem:menuItem];
		}
	}

	return [menu autorelease];
}

/*!
 * @brief Return an array of menu items for an AIStatusType and service
 *
 * @pram type The AIStatusType for which to return statuses
 * @param inServiceCodeUniqueID The service for which to return active statuses.  If nil, return all statuses for online services.
 * @param target The target for the menu items
 *
 * @result An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects.
 */
- (NSArray *)_menuItemsForStatusesOfType:(AIStatusType)type forServiceCodeUniqueID:(NSString *)inServiceCodeUniqueID withTarget:(id)target
{
	NSMutableArray  *menuItems = [[NSMutableArray alloc] init];
	NSMutableSet	*alreadyAddedTitles = [NSMutableSet set];

	//First, add our built-in items (so they will be at the top of the array and service-specific 'copies' won't replace them)
	[self _addMenuItemsForStatusOfType:type
							withTarget:target
							   fromSet:builtInStatusTypes[type]
							   toArray:menuItems
					alreadyAddedTitles:alreadyAddedTitles];

	//Now, add items for this service, or from all available services, as appropriate
	if (inServiceCodeUniqueID) {
		NSSet	*statusDicts;

		//Obtain the status dicts for this type and service code unique ID
		if ((statusDicts = [statusDictsByServiceCodeUniqueID[type] objectForKey:inServiceCodeUniqueID])) {
			//And add them
			[self _addMenuItemsForStatusOfType:type
									withTarget:target
									   fromSet:statusDicts
									   toArray:menuItems
							alreadyAddedTitles:alreadyAddedTitles];
		}

	} else {
		for (AIService *service in [adium.accountController activeServicesIncludingCompatibleServices:NO]) {
			NSSet	*statusDicts;
			
			//Obtain the status dicts for this type and service code unique ID
			if ((statusDicts = [statusDictsByServiceCodeUniqueID[type] objectForKey:service.serviceCodeUniqueID])) {
				//And add them
				[self _addMenuItemsForStatusOfType:type
										withTarget:target
										   fromSet:statusDicts
										   toArray:menuItems
								alreadyAddedTitles:alreadyAddedTitles];
			}
			
		}
	}

	[menuItems sortUsingSelector:@selector(titleCompare:)];

	return [menuItems autorelease];
}

/*!
 * @brief Add menu items for a particular type of status
 *
 * @param type The AIStatusType, used for determining the icon of the menu items
 * @param target The target of the created menu items
 * @param statusDicts An NSSet of NSDictionary objects, which should each represent a status of the passed type
 * @param menuItems The NSMutableArray to which to add the menuItems
 * @param alreadyAddedTitles NSMutableSet of NSString titles which have already been added and should not be duplicated. Will be updated as items are added.
 */
- (void)_addMenuItemsForStatusOfType:(AIStatusType)type
						  withTarget:(id)target
							 fromSet:(NSSet *)statusDicts
							 toArray:(NSMutableArray *)menuItems
				  alreadyAddedTitles:(NSMutableSet *)alreadyAddedTitles
{
	NSDictionary	*statusDict;

	//Enumerate the status dicts
	for (statusDict in statusDicts) {
		NSString	*title = [statusDict objectForKey:KEY_STATUS_DESCRIPTION];

		/*
		 * Only add if it has not already been added by another service.... Services need to use unique titles if they have
		 * unique state names, but are welcome to share common name/description combinations, which is why the #defines
		 * exist.
		 */
		if (![alreadyAddedTitles containsObject:title]) {
			NSImage		*image;
			NSMenuItem	*menuItem;

			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																			target:target
																			action:@selector(selectStatus:)
																	 keyEquivalent:@""];

			image = [AIStatusIcons statusIconForStatusName:[statusDict objectForKey:KEY_STATUS_NAME]
												  statusType:type
													iconType:AIStatusIconMenu
												   direction:AIIconNormal];

			[menuItem setRepresentedObject:statusDict];
			[menuItem setImage:image];
			[menuItem setEnabled:YES];
			[menuItems addObject:menuItem];
			[menuItem release];

			[alreadyAddedTitles addObject:title];
		}
	}
}

#pragma mark Status State Descriptions
- (NSString *)localizedDescriptionForCoreStatusName:(NSString *)statusName
{
	static NSDictionary	*coreLocalizedStatusDescriptions = nil;
	if(!coreLocalizedStatusDescriptions){
		coreLocalizedStatusDescriptions = [[NSDictionary dictionaryWithObjectsAndKeys:
			AILocalizedStringFromTable(@"Available", @"Statuses", "Name of a status"), STATUS_NAME_AVAILABLE,
			AILocalizedStringFromTable(@"Free for chat", @"Statuses", "Name of a status"), STATUS_NAME_FREE_FOR_CHAT,
			AILocalizedStringFromTable(@"Available for friends only", @"Statuses", "Name of a status"), STATUS_NAME_AVAILABLE_FRIENDS_ONLY,
			AILocalizedStringFromTable(@"Away", @"Statuses", "Name of a status"), STATUS_NAME_AWAY,
			AILocalizedStringFromTable(@"Extended away", @"Statuses", "Name of a status"), STATUS_NAME_EXTENDED_AWAY,
			AILocalizedStringFromTable(@"Away for friends only", @"Statuses", "Name of a status"), STATUS_NAME_AWAY_FRIENDS_ONLY,
			AILocalizedStringFromTable(@"Do not disturb", @"Statuses", "Name of a status"), STATUS_NAME_DND,
			AILocalizedStringFromTable(@"Not available", @"Statuses", "Name of a status"), STATUS_NAME_NOT_AVAILABLE,
			AILocalizedStringFromTable(@"Occupied", @"Statuses", "Name of a status"), STATUS_NAME_OCCUPIED,
			AILocalizedStringFromTable(@"Be right back", @"Statuses", "Name of a status"), STATUS_NAME_BRB,
			AILocalizedStringFromTable(@"Busy", @"Statuses", "Name of a status"), STATUS_NAME_BUSY,
			AILocalizedStringFromTable(@"On the phone", @"Statuses", "Name of a status"), STATUS_NAME_PHONE,
			AILocalizedStringFromTable(@"Out to lunch", @"Statuses", "Name of a status"), STATUS_NAME_LUNCH,
			AILocalizedStringFromTable(@"Not at home", @"Statuses", "Name of a status"), STATUS_NAME_NOT_AT_HOME,
			AILocalizedStringFromTable(@"Not at my desk", @"Statuses", "Name of a status"), STATUS_NAME_NOT_AT_DESK,
			AILocalizedStringFromTable(@"Not in the office", @"Statuses", "Name of a status"), STATUS_NAME_NOT_IN_OFFICE,
			AILocalizedStringFromTable(@"On vacation", @"Statuses", "Name of a status"), STATUS_NAME_VACATION,
			AILocalizedStringFromTable(@"Stepped out", @"Statuses", "Name of a status"), STATUS_NAME_STEPPED_OUT,
			AILocalizedStringFromTable(@"Invisible", @"Statuses", "Name of a status"), STATUS_NAME_INVISIBLE,
			AILocalizedStringFromTable(@"Offline", @"Statuses", "Name of a status"), STATUS_NAME_OFFLINE,
			nil] retain];
	}
	
	return (statusName ? [coreLocalizedStatusDescriptions objectForKey:statusName] : nil);
}

- (NSString *)localizedDescriptionForStatusName:(NSString *)statusName statusType:(AIStatusType)statusType
{
	NSString *description = nil;

	if (statusName &&
		!(description = [self localizedDescriptionForCoreStatusName:statusName])) {		
		for (NSSet *set in statusDictsByServiceCodeUniqueID[statusType]) {
			NSEnumerator	*statusDictsEnumerator = [set objectEnumerator];
			NSDictionary	*statusDict;
			while (!description && (statusDict = [statusDictsEnumerator nextObject])) {
				if ([[statusDict objectForKey:KEY_STATUS_NAME] isEqualToString:statusName]){
					description = [statusDict objectForKey:KEY_STATUS_DESCRIPTION];
					break;
				}
			}
		}		
	}
	
	return description;
}

/*!
 * @brief Return the localized description for the sate of the passed status
 *
 * This could be stored with the statusState, but that would break if the locale changed.  This way, the nonlocalized
 * string is used to look up the appropriate localized one.
 *
 * @result A localized description such as @"Away" or @"Out to Lunch" of the state used by statusState
 */
- (NSString *)descriptionForStateOfStatus:(AIStatus *)statusState
{
	return [self localizedDescriptionForStatusName:statusState.statusName
										statusType:statusState.statusType];
}

/*!
 * @brief The status name to use by default for a passed type
 *
 * This is the name which will be used for new AIStatus objects of this type.
 */
- (NSString *)defaultStatusNameForType:(AIStatusType)statusType
{
	//Set the default status name
	switch (statusType) {
		case AIAvailableStatusType:
			return STATUS_NAME_AVAILABLE;
			break;
		case AIAwayStatusType:
			return STATUS_NAME_AWAY;
			break;
		case AIInvisibleStatusType:
			return STATUS_NAME_INVISIBLE;
			break;
		case AIOfflineStatusType:
			return STATUS_NAME_OFFLINE;
			break;
	}

	return nil;
}

#pragma mark Setting Status States
/*!
 * @brief Set the active status state
 *
 * Sets the currently active status state.  This applies throughout Adium and to all accounts.  The state will become
 * effective immediately.
 */
- (void)setActiveStatusState:(AIStatus *)statusState
{
	//Apply the state to our accounts and notify (delay to the next run loop to improve perceived speed)
	[self performSelector:@selector(applyState:toAccounts:)
			   withObject:statusState
			   withObject:adium.accountController.accounts
			   afterDelay:0];
}
/*!
 * @brief Set the active status state for some account
 *
 * Sets the currently active status state for the specified account.
 * This applies throughout Adium and to all accounts.  The state will become
 * effective immediately.
 */
- (void)setActiveStatusState:(AIStatus *)state forAccount:(AIAccount *)account
{
	[self removeIfNecessaryTemporaryStatusState:account.statusState];
	[self applyState:state toAccounts:[NSArray arrayWithObject:account]];
}

/*!
 * @brief Return the <tt>AIStatus</tt> to be used by accounts as they are created
 */
- (AIStatus *)defaultInitialStatusState
{
	return [self availableStatus];
}

/*!
 * @brief Reset the active status state
 *
 * All active status states cache will also reset.  Posts an active status changed notification.  The active state
 * will be regenerated the next time it is requested.
 */
- (void)_resetActiveStatusState
{
	//Clear the active status state.  It will be rebuilt next time it is requested
	[_activeStatusState release]; _activeStatusState = nil;
	[_allActiveStatusStates release]; _allActiveStatusStates = nil;

	//Let observers know the active state has changed
	if (!activeStatusUpdateDelays) {
		[[NSNotificationCenter defaultCenter] postNotificationName:AIStatusActiveStateChangedNotification object:nil];
	}
}

/*!
 * @brief Account status changed.
 *
 * Rebuild all our state menus
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		if ([inModifiedKeys containsObject:@"isOnline"] ||
			[inModifiedKeys containsObject:@"idleSince"] ||
			[inModifiedKeys containsObject:@"accountStatus"] ||
			[inModifiedKeys containsObject:KEY_ENABLED]) {
			
			[self _resetActiveStatusState];
		}
	}
	
    return nil;
}


/*!
 * @brief Delay activee status menu updates
 *
 * This should be called to prevent duplicative updates when multiple accounts are changing status simultaneously.
 */
- (void)setDelayActiveStatusUpdates:(BOOL)shouldDelay
{
	if (shouldDelay)
		activeStatusUpdateDelays++;
	else
		activeStatusUpdateDelays--;
	
	if (!activeStatusUpdateDelays) {
		[[NSNotificationCenter defaultCenter] postNotificationName:AIStatusActiveStateChangedNotification object:nil];
	}
}

/*!
 * @brief Delay activee status menu updates
 *
 * This should be called to prevent duplicative rebuilds when the status menu will change multple times.
 */
- (void)setDelayStatusMenuRebuilding:(BOOL)shouldDelay
{
	if (shouldDelay)
		statusMenuRebuildDelays++;
	else
		statusMenuRebuildDelays--;
	
	if (!statusMenuRebuildDelays) {
		[[NSNotificationCenter defaultCenter] postNotificationName:AIStatusStateArrayChangedNotification object:nil];	
	}
}

/*!
 * @brief Apply a state to multiple accounts
 */
- (void)applyState:(AIStatus *)statusState toAccounts:(NSArray *)accountArray
{
	AIStatus		*aStatusState;
	BOOL			shouldRebuild = NO;
	BOOL			isOfflineStatus = (statusState.statusType == AIOfflineStatusType);
	[self setDelayActiveStatusUpdates:YES];
	
	/* If we're going offline, determine what accounts are currently online or connecting/reconnecting, first,
	 * so that we can restore that when an online state is chosen later.
	 */
	if  (isOfflineStatus && [adium.accountController oneOrMoreConnectedOrConnectingAccounts]) {
		[accountsToConnect removeAllObjects];

		for (AIAccount *account in accountArray) {
			// Save the account if we're online or trying to be online.
			if (account.online || [account boolValueForProperty:@"isConnecting"] || [account valueForProperty:@"waitingToReconnect"])
				[accountsToConnect addObject:account];
		}
	}

	// Don't consider "connecting" accounts when connecting previously offline.
	if (![adium.accountController oneOrMoreConnectedAccounts]) {
		/* No connected accounts: Connect all enabled accounts which were set offline previously.
		 * If we have no such list of accounts, connect 'em all.
		 */
		BOOL noAccountsToConnectCount = ([accountsToConnect count] == 0);
		for (AIAccount *account in accountArray) {
			if (account.enabled &&
				([accountsToConnect containsObject:account] || noAccountsToConnectCount)) {
				[account setStatusState:statusState];

			} else {
				[account setStatusStateAndRemainOffline:statusState];	
			}
		}

	} else {
		//At least one account is online.  Just change its status without taking any other accounts online.
		for (AIAccount *account in accountArray) {
			if (account.online || isOfflineStatus) {
				[account setStatusState:statusState];
				
			} else {
				[account setStatusStateAndRemainOffline:statusState];			
			}
		}
		shouldRebuild = YES;
	}

	//If this is not an offline status, we've now made use of accountsToConnect and should clear it so it isn't used again.
	if (!isOfflineStatus) {
		[accountsToConnect removeAllObjects];
	}

	//Any objects in the temporary state array which aren't the state we just set should now be removed.
	for (aStatusState in [[temporaryStateArray copy] autorelease]) {
		if (aStatusState != statusState) {
			[temporaryStateArray removeObject:aStatusState];
			shouldRebuild = YES;
		}
	}

	//Add to our temporary status array if it's not in our state array
	if (![[self flatStatusSet] containsObject:statusState] &&
		![temporaryStateArray containsObject:statusState]) {
		[temporaryStateArray addObject:statusState];
		shouldRebuild = YES;
	}

	if (shouldRebuild) {
		[self notifyOfChangedStatusArray];
	}

	[self setDelayActiveStatusUpdates:NO];
}

#pragma mark Retrieving Status States
/*!
 * @brief Access to Adium's user-defined states
 *
 * Returns the root AIStatusGroup of user-defined states
 */
- (AIStatusGroup *)rootStateGroup
{
	if (!_rootStateGroup) {
		NSData	*savedStateData = [adium.preferenceController preferenceForKey:KEY_SAVED_STATUS
																		   group:PREF_GROUP_SAVED_STATUS];
		if (savedStateData) {
			id archivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:savedStateData];

			if ([archivedObject isKindOfClass:[AIStatusGroup class]]) {
				//Adium 1.0 archives an AIStatusGroup
				_rootStateGroup = [archivedObject retain];
			
			} else if  ([archivedObject isKindOfClass:[NSArray class]]) {
				//Adium 0.8x archived an NSArray
				_rootStateGroup = [[AIStatusGroup statusGroupWithContainedStatusItems:archivedObject] retain];
			}
		}

		if (!_rootStateGroup) _rootStateGroup = [[AIStatusGroup statusGroup] retain];

		//Upgrade Adium 0.7x away messages
		[self _upgradeSavedAwaysToSavedStates];
	}

	return _rootStateGroup;
}

/*!
 * @brief Return the array of built-in states
 *
 * These are basic Available and Away states which should always be visible and are (by convention) immutable.
 * The first state in BUILT_IN_STATE_ARRAY will be used as the default for accounts as they are created.
 */
- (NSArray *)builtInStateArray
{
	if (!builtInStateArray) {
		NSArray			*savedBuiltInStateArray = [NSArray arrayNamed:BUILT_IN_STATE_ARRAY forClass:[self class]];
		NSDictionary	*dict;

		builtInStateArray = [[NSMutableArray alloc] initWithCapacity:[savedBuiltInStateArray count]];

		for (dict in savedBuiltInStateArray) {
			AIStatus	*status = [AIStatus statusWithDictionary:dict];
			[builtInStateArray addObject:status];

			//Store a reference to our offline state if we just loaded it
			if (status.statusType == AIOfflineStatusType) {
				[offlineStatusState release];
				offlineStatusState = [status retain];
			}
		}
	}

	return builtInStateArray;
}

/*!
* @brief Create and add the built-in status types; even if no service explicitly registers these, they are available.
 *
 * The built-in status types are basic, generic "Available" and "Away" states.
 */
- (void)buildBuiltInStatusTypes
{
	NSDictionary	*statusDict;
	
	builtInStatusTypes[AIAvailableStatusType] = [[NSMutableSet alloc] init];
	statusDict = [NSDictionary dictionaryWithObjectsAndKeys:
		STATUS_NAME_AVAILABLE, KEY_STATUS_NAME,
		[self localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE], KEY_STATUS_DESCRIPTION,
		[NSNumber numberWithInt:AIAvailableStatusType], KEY_STATUS_TYPE,
		nil];
	[builtInStatusTypes[AIAvailableStatusType] addObject:statusDict];
	
	builtInStatusTypes[AIAwayStatusType] = [[NSMutableSet alloc] init];
	statusDict = [NSDictionary dictionaryWithObjectsAndKeys:
		STATUS_NAME_AWAY, KEY_STATUS_NAME,
		[self localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY], KEY_STATUS_DESCRIPTION,
		[NSNumber numberWithInt:AIAwayStatusType], KEY_STATUS_TYPE,
		nil];
	[builtInStatusTypes[AIAwayStatusType] addObject:statusDict];
}

/**
 * @brief Returns the built in available status
 */
- (AIStatus *)availableStatus
{
	return [[[self builtInStateArray] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"statusType == %i",AIAvailableStatusType]] objectAtIndex:0];
}
/**
 * @brief Returns the built in away status
 */
- (AIStatus *)awayStatus
{
	return [[[self builtInStateArray] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"statusType == %i",AIAwayStatusType]] objectAtIndex:0];
}
/**
 * @brief Returns the built in invisible status
 */
- (AIStatus *)invisibleStatus
{
	return [[[self builtInStateArray] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"statusType == %i",AIInvisibleStatusType]] objectAtIndex:0];
}
/**
 * @brief Returns the built in offline status
 *
 * This method duplicates the functionality found in - [AIStatusController offlineStatusState].
 * However, this has the same method signature format as the other statuses.
 */
- (AIStatus *)offlineStatus
{
	return [[[self builtInStateArray] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"statusType == %i",AIOfflineStatusType]] objectAtIndex:0];
}

- (AIStatus *)offlineStatusState
{
	//Ensure the built in states have been loaded
	[self builtInStateArray];

	NSAssert(offlineStatusState != nil, @"Nil offline status state");
	return offlineStatusState;
}

/*!
 * @brief Return a sorted state array for use in menu item creation
 *
 * The array is created by adding the built in states to the user states, then sorting using _statusArraySort
 * The resulting array may contain AIStatus and AIStatusGroup objects.
 *
 * @result A cached NSArray which is sorted by status type (available, away), built-in vs. user-made, and then original ordering.
 */
- (NSArray *)sortedFullStateArray
{
	if (!_sortedFullStateArray) {
		NSArray			*originalStateArray;
		NSMutableArray	*tempArray;

		//Start with everything contained 1) in our built-in array and then 2) in our root group
		originalStateArray = [[self builtInStateArray] arrayByAddingObjectsFromArray:[[self rootStateGroup] containedStatusItems]];
		
		tempArray = [originalStateArray mutableCopy];

		//Now add the temporary statues
		[tempArray addObjectsFromArray:[temporaryStateArray allObjects]];

		//Pass the original array so its indexes can be used for comparison of saved state ordering
		[AIStatusGroup sortArrayOfStatusItems:tempArray context:originalStateArray];

		_sortedFullStateArray = tempArray;
	}

	return _sortedFullStateArray;
}

/*!
 * @brief Generate and return an array of AIStatus objects which are all known saved, temporary, and built-in statuses
 */
- (NSSet *)flatStatusSet
{
	if (!_flatStatusSet) {
		NSMutableSet	*tempArray = [[[self rootStateGroup] flatStatusSet] mutableCopy];

		//Add built in states
		[tempArray addObjectsFromArray:[self builtInStateArray]];

		//Add temporary ones
		[tempArray addObjectsFromArray:[temporaryStateArray allObjects]];

		_flatStatusSet = tempArray;
	}
	
	return _flatStatusSet;
}

/*!
 * @brief Retrieve active status state
 *
 * @result The currently active status state.
 *
 * This is defined as the status state which the most accounts are currently using.  The behavior in case of a tie
 * is currently undefined but will yield one of the tying states.
 */
- (AIStatus *)activeStatusState
{
	if (!_activeStatusState) {
		NSCountedSet		*statusCounts = [NSCountedSet set];
		NSUInteger			 highestCount = 0;

		if (adium.accountController.oneOrMoreConnectedAccounts) {
			AIStatus	*bestStatusState = nil;

			for (AIAccount *account in adium.accountController.accounts) {
				if (account.online) {
					AIStatus *accountStatusState = account.statusState;
					[statusCounts addObject:(accountStatusState ?
											 accountStatusState :
											 self.defaultInitialStatusState)];
				}
			}

			for (AIStatus *statusState in statusCounts) {
				NSUInteger thisCount = [statusCounts countForObject:statusState];
				if (thisCount > highestCount) {
					bestStatusState = statusState;
					highestCount = thisCount;
				}
			}

			_activeStatusState = (bestStatusState ? [bestStatusState retain]: [offlineStatusState retain]);

		} else {
			_activeStatusState = [offlineStatusState retain];
		}
	}

	return _activeStatusState;
}

/*!
 * @brief Find the 'active' AIStatusType
 *
 * The active type is the one used by the largest number of accounts.  In case of a tie, the order of the AIStatusType
 * enum is respected
 *
 * @param invisibleIsAway If YES, AIInvisibleStatusType is trated as AIAwayStatusType
 * @result The active AIStatusType for online accounts, or AIOfflineStatusType if all accounts are  offline
 */
- (AIStatusType)activeStatusTypeTreatingInvisibleAsAway:(BOOL)invisibleIsAway
{
	AIStatusType		statusTypeCount[STATUS_TYPES_COUNT];
	AIStatusType		activeStatusType = AIOfflineStatusType;
	NSUInteger			highestCount = 0;

	int i;
	for (i = 0 ; i < STATUS_TYPES_COUNT ; i++) {
		statusTypeCount[i] = 0;
	}

	for (AIAccount *account in adium.accountController.accounts) {
		if (account.online || [account boolValueForProperty:@"isConnecting"]) {
			AIStatusType statusType = account.statusState.statusType;

			//If invisibleIsAway, pretend that invisible is away
			if (invisibleIsAway && (statusType == AIInvisibleStatusType)) statusType = AIAwayStatusType;

			statusTypeCount[statusType]++;
		}
	}

	for (i = 0 ; i < STATUS_TYPES_COUNT ; i++) {
		if (statusTypeCount[i] > highestCount) {
			activeStatusType = i;
			highestCount = statusTypeCount[i];
		}
	}

	return activeStatusType;
}

/*!
 * @brief All active status states
 *
 * A status state is active if any enabled account is currently in that state.
 *
 * The return value of this method is cached.
 *
 * @result An <tt>NSSet</tt> of <tt>AIStatus</tt> objects
 */
- (NSSet *)allActiveStatusStates
{
	if (!_allActiveStatusStates) {
		_allActiveStatusStates = [[NSMutableSet alloc] init];

		for (AIAccount *account in adium.accountController.accounts) {
			if (account.enabled) {
				[_allActiveStatusStates addObject:account.statusState];
			}
		}
	}

	return _allActiveStatusStates;
}

/*!
 * @brief Return the set of all unavailable statuses in use by online or connection accounts
 *
 * @param activeUnvailableStatusType Pointer to an AIStatusType; returns by reference the most popular unavailable type
 * @param activeUnvailableStatusName Pointer to an NSString*; returns by reference a status name if all states are in the same name, or nil if they differ
 * @param allOnlineAccountsAreUnvailable Pointer to a BOOL; returns by reference YES is all online accounts are unavailable, NO if one or more is available
 */
- (NSSet *)activeUnavailableStatusesAndType:(AIStatusType *)activeUnvailableStatusType withName:(NSString **)activeUnvailableStatusName allOnlineAccountsAreUnvailable:(BOOL *)allOnlineAccountsAreUnvailable
{
	NSMutableSet		*activeUnvailableStatuses = [NSMutableSet set];
	BOOL				foundStatusName = NO;
	NSInteger			statusTypeCount[STATUS_TYPES_COUNT];

	statusTypeCount[AIAwayStatusType] = 0;
	statusTypeCount[AIInvisibleStatusType] = 0;
	
	//Assume all accounts are unavailable until proven otherwise
	if (allOnlineAccountsAreUnvailable != NULL) {
		*allOnlineAccountsAreUnvailable = YES;
	}
	
	for (AIAccount *account in adium.accountController.accounts) {
		if (account.online || [account boolValueForProperty:@"isConnecting"]) {
			AIStatus	*statusState = account.statusState;
			AIStatusType statusType = statusState.statusType;
			
			if ((statusType == AIAwayStatusType) || (statusType == AIInvisibleStatusType)) {
				NSString	*statusName = statusState.statusName;
				
				[activeUnvailableStatuses addObject:statusState];
				
				statusTypeCount[statusType]++;
				
				if (foundStatusName) {
					//Once we find a status name, we only want to return it if all our status names are the same.
					if ((activeUnvailableStatusName != NULL) &&
					   (*activeUnvailableStatusName != nil) && 
					   ![*activeUnvailableStatusName isEqualToString:statusName]) {
						*activeUnvailableStatusName = nil;
					}
				} else {
					//We haven't found a status name yet, so store this one as the active status name
					if (activeUnvailableStatusName != NULL) {
						*activeUnvailableStatusName = statusState.statusName;
					}
					foundStatusName = YES;
				}
			} else {
				//An online account isn't unavailable
				if (allOnlineAccountsAreUnvailable != NULL) {
					*allOnlineAccountsAreUnvailable = NO;
				}
			}
		}
	}
	
	if (activeUnvailableStatusType != NULL) {
		if (statusTypeCount[AIAwayStatusType] > statusTypeCount[AIInvisibleStatusType]) {
			*activeUnvailableStatusType = AIAwayStatusType;
		} else {
			*activeUnvailableStatusType = AIInvisibleStatusType;		
		}
	}
	
	return activeUnvailableStatuses;
}

/*!
 * @brief Find the status state with the requested uniqueStatusID
 */
- (AIStatus *)statusStateWithUniqueStatusID:(NSNumber *)uniqueStatusID
{
	AIStatus		*statusState = nil;

	if (uniqueStatusID) {
		for (statusState in self.flatStatusSet) {
			if ([statusState.uniqueStatusID compare:uniqueStatusID] == NSOrderedSame)
				break;
		}
	}

	return statusState;
}

//State Editing --------------------------------------------------------------------------------------------------------
#pragma mark State Editing
/*!
 * @brief Add a state
 *
 * Add a new state to Adium's state array.
 * @param state AIState to add
 */
- (void)addStatusState:(AIStatus *)statusState
{
	AIStatusMutabilityType mutabilityType = [statusState mutabilityType];
	
	if ((mutabilityType == AILockedStatusState) ||
		(mutabilityType == AISecondaryLockedStatusState)) {
		//If we are adding a locked status, add it to the built-in statuses
		[(NSMutableArray *)[self builtInStateArray] addObject:statusState];

		[self notifyOfChangedStatusArray];

	} else {
		//Otherwise, add it to the user-created statuses
		[[self rootStateGroup] addStatusItem:statusState atIndex:-1];
	}
}

/*!
 * @brief Remove a state
 *
 * Remove a new state from Adium's state array.
 * @param state AIStatus to remove
 */
- (void)removeStatusState:(AIStatus *)statusState
{
	NSLog(@"shouldn't be calling this.");
//	[stateArray removeObject:statusState];
	[self savedStatusesChanged];
}

- (void)notifyOfChangedStatusArray
{
	//Clear the sorted menu items array since our state array changed.
	[_sortedFullStateArray release]; _sortedFullStateArray = nil;
	[_flatStatusSet release]; _flatStatusSet = nil;

	if (!statusMenuRebuildDelays) {
		[[NSNotificationCenter defaultCenter] postNotificationName:AIStatusStateArrayChangedNotification object:nil];	
	}
}

/*!
 * @brief Save changes to the state array and notify observers
 *
 * Saves any outstanding changes to the state array.  There should be no need to call this manually, since all the
 * state array modifying methods in this class call it automatically after making changes.
 *
 * After the state array is saved, observers are notified that is has changed.  Call after making any changes to the
 * state array from within the controller.
 */
- (void)savedStatusesChanged
{
	[adium.preferenceController setPreference:[NSKeyedArchiver archivedDataWithRootObject:[[self rootStateGroup] containedStatusItems]]
										 forKey:KEY_SAVED_STATUS
										  group:PREF_GROUP_SAVED_STATUS];
	[self notifyOfChangedStatusArray];
}

- (void)statusStateDidSetUniqueStatusID
{
	[adium.preferenceController setPreference:[NSKeyedArchiver archivedDataWithRootObject:[[self rootStateGroup] containedStatusItems]]
										 forKey:KEY_SAVED_STATUS
										  group:PREF_GROUP_SAVED_STATUS];
}

/*!
* @brief Called when a state could potentially need to removed from the temporary (non-saved) list
 *
 * If originalState is in the temporary status array, and it is being used on one or zero accounts, it 
 * is removed from the temporary status array. This method should be used when one or more accounts have stopped
 * using a single status state to determine if that status state is both non-saved and unused.
 *
 * Note that while it would seem logical to post AIStatusStateArrayChangedNotification when this method would
 * return YES, we don't want to force observers of the notification to update immediately since there may be further
 * processing. We therefore let the calling method take action if it chooses to.
 *
 * @result YES if the state was removed
 */
- (BOOL)removeIfNecessaryTemporaryStatusState:(AIStatus *)originalState
{
	BOOL didRemove = NO;

	/* If the original (old) status state is in our temporary array and is not being used in more than 1 account, 
	* then we should remove it.
	*/
	if ([temporaryStateArray containsObject:originalState]) {
		NSInteger count = 0;
		
		for (AIAccount *account in adium.accountController.accounts) {
			if (account.actualStatusState == originalState) {
				if (++count > 1) break;
			}
		}

		if (count <= 1) {
			[temporaryStateArray removeObject:originalState];
			didRemove = YES;
		}
	}

	return didRemove;
}

- (void)saveStatusAsLastUsed:(AIStatus *)statusState
{
	NSMutableDictionary *lastStatusStates;
	
	lastStatusStates = [[[adium.preferenceController preferenceForKey:@"LastStatusStates"
																  group:PREF_GROUP_STATUS_PREFERENCES] mutableCopy] autorelease];
	if (!lastStatusStates) lastStatusStates = [NSMutableDictionary dictionary];
	
	[lastStatusStates setObject:[NSKeyedArchiver archivedDataWithRootObject:statusState]
						 forKey:[[NSNumber numberWithInteger:statusState.statusType] stringValue]];

	[adium.preferenceController setPreference:lastStatusStates
										 forKey:@"LastStatusStates"
										  group:PREF_GROUP_STATUS_PREFERENCES];	
}
//Status state menu support ---------------------------------------------------------------------------------------------------
#pragma mark Status state menu support
/*!
 * @brief Apply a custom state
 *
 * Invoked when the custom state window is closed by the user clicking OK.  In response this method sets the custom
 * state as the active state.
 */
- (void)customStatusState:(AIStatus *)originalState changedTo:(AIStatus *)newState forAccount:(AIAccount *)account
{
	BOOL shouldRebuild = NO;
	
	if ([newState mutabilityType] != AITemporaryEditableStatusState) {
		[adium.statusController addStatusState:newState];
	}

	if (account) {
		shouldRebuild = [self removeIfNecessaryTemporaryStatusState:originalState];

		//Now set the newState for the account
		[account setStatusState:newState];
		
		//Enable the account if it isn't currently enabled
		if (!account.enabled) {
			[account setEnabled:YES];
		}		

		//Add to our temporary status array if it's not in our state array
		if (shouldRebuild || (![[self flatStatusSet] containsObject:newState])) {
			[temporaryStateArray addObject:newState];
			
			[self notifyOfChangedStatusArray];
		}
		
	} else {
		//Set the state for all accounts.  This will clear out the temporaryStatusArray as necessary and update its contents.
		[self setActiveStatusState:newState];
	}

	[self saveStatusAsLastUsed:newState];
}


#pragma mark Upgrade code
/*!
 * @brief Temporary upgrade code for 0.7x -> 0.8
 *
 * Versions 0.7x and prior stored their away messages in a different format.  This code allows a seamless
 * transition from 0.7x to 0.8.  We can easily recognize the old format because the away messages are of
 * type "Away" instead of type "State", which is used for all 0.8 and later saved states.
 * Since we are changing the array as we scan it, an enumerator will not work here.
 */
#define OLD_KEY_SAVED_AWAYS			@"Saved Away Messages"
#define OLD_GROUP_AWAY_MESSAGES		@"Away Messages"
#define OLD_STATE_SAVED_AWAY		@"Away"
#define OLD_STATE_AWAY				@"Message"
#define OLD_STATE_AUTO_REPLY		@"Autoresponse"
#define OLD_STATE_TITLE				@"Title"
- (void)_upgradeSavedAwaysToSavedStates
{
	NSArray	*savedAways = [adium.preferenceController preferenceForKey:OLD_KEY_SAVED_AWAYS
																   group:OLD_GROUP_AWAY_MESSAGES];

	if (savedAways) {
		NSDictionary	*state;

		AILog(@"*** Upgrading Adium 0.7x saved aways: %@", savedAways);

		[self setDelayStatusMenuRebuilding:YES];

		//Update all the away messages to states.
		for (state in savedAways) {
			if ([[state objectForKey:@"Type"] isEqualToString:OLD_STATE_SAVED_AWAY]) {
				AIStatus	*statusState;

				//Extract the away message information from this old record
				NSData		*statusMessageData = [state objectForKey:OLD_STATE_AWAY];
				NSData		*autoReplyMessageData = [state objectForKey:OLD_STATE_AUTO_REPLY];
				NSString	*title = [state objectForKey:OLD_STATE_TITLE];

				//Create an AIStatus from this information
				statusState = [AIStatus status];

				//General category: It's an away type
				[statusState setStatusType:AIAwayStatusType];

				//Specific state: It's the generic away. Funny how that works out.
				[statusState setStatusName:STATUS_NAME_AWAY];

				//Set the status message (which is just the away message).
				[statusState setStatusMessage:[NSAttributedString stringWithData:statusMessageData]];

				//It has an auto reply.
				[statusState setHasAutoReply:YES];

				if (autoReplyMessageData) {
					//Use the custom auto reply if it was set.
					[statusState setAutoReply:[NSAttributedString stringWithData:autoReplyMessageData]];
				} else {
					//If no autoReplyMesssage, use the status message.
					[statusState setAutoReplyIsStatusMessage:YES];
				}

				if (title) [statusState setTitle:title];

				//Add the updated state to our state array.
				[self addStatusState:statusState];
			}
		}

		AILog(@"*** Finished upgrading old saved statuses");

		//Save these changes and delete the old aways so we don't need to do this again.
		[self setDelayStatusMenuRebuilding:NO];

		[adium.preferenceController setPreference:nil
											 forKey:OLD_KEY_SAVED_AWAYS
											  group:OLD_GROUP_AWAY_MESSAGES];
	}
}

@end
