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

#import <Adium/AIMetaContact.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIService.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIAccount.h>
#import <Adium/AIAbstractListController.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <Adium/AIContactList.h>
#import <Adium/AIStatus.h>
#import <Adium/AIContactHidingController.h>

/* If META_TYPE_DEBUG is defined, metaContacts and uniqueMetaContacts are given an 
 * identifying suffix to their formattedUID in the contact list */
//#define META_TYPE_DEBUG TRUE

@interface AIListContact ()
@property (readwrite, nonatomic, assign) AIMetaContact *metaContact;
- (void)setContainingObject:(AIListGroup *)inGroup;
@end

@interface AIMetaContact ()
- (void)updateAllPropertiesForObject:(AIListObject *)inObject;

- (void)determineIfWeShouldAppearToContainOnlyOneContact;

- (NSArray *)uniqueContainedListContactsIncludingOfflineAccounts:(BOOL)includeOfflineAccounts visibleOnly:(BOOL)visibleOnly;

- (void)updateDisplayName;
- (void)restoreGrouping;
@property (weak, readonly, nonatomic) NSArray *visibleListContacts;

+ (NSArray *)_forwardedProperties;
@end

@implementation AIMetaContact

NSComparisonResult containedContactSort(AIListContact *objectA, AIListContact *objectB, void *context);

- (id)initWithObjectID:(NSNumber *)inObjectID
{
	if ((self = [super initWithUID:[inObjectID stringValue] service:nil])) {
		objectID = inObjectID;
		_preferredContact = nil;
		_listContacts = nil;
		_listContactsIncludingOfflineAccounts = nil;
		
		_containedObjects = [[NSMutableArray alloc] init];
		
		expanded = [[self preferenceForKey:KEY_EXPANDED group:PREF_GROUP_OBJECT_STATUS_CACHE] boolValue];

		containsOnlyOneUniqueContact = YES; /* Default to YES, because addObject: will change us to NO when needed */
		containedObjectsNeedsSort = NO;
		saveGroupingChanges = YES;
	}
	return self;
}

- (void)dealloc
{
	//I've seen a crashlog with a delayed -updateDisplayName causing crashes due to a freed AIMetaContact, so let's cancel any pending updates
	[[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget:self];
}

@synthesize objectID;

- (NSString *)internalObjectID
{
	if (!internalObjectID) {
		internalObjectID = [AIMetaContact internalObjectIDFromObjectID:objectID];
	}
	return internalObjectID;
}

+ (NSString *)internalObjectIDFromObjectID:(NSNumber *)inObjectID
{
	return [NSString stringWithFormat:@"MetaContact-%i", [inObjectID intValue]];
}

//A metaContact's internalObjectID is completely unique to it, so return that for interalUniqueObjectID
- (NSString *)internalUniqueObjectID
{
	return self.internalObjectID;
}

//Return the account of this metaContact, which we may treat as the preferredContact's account
- (AIAccount *)account
{
	return self.preferredContact.account;
}

//Return the service of our preferred contact, so we will display the service icon of our preferred contact on the list
- (AIService *)service
{
	return self.preferredContact.service;
}

- (AIListContact *)parentContact
{
	return self;
}

- (AIMetaContact *)metaContact
{
	return nil;
}

- (NSSet *)remoteGroups
{
	return self.groups;
}

- (void) setMetaContact:(AIMetaContact *)meta{ NSAssert(NO, @"Should not be reached"); }

/*!
 * @brief Place this metacontact in all groups that its contained contacts are in
 */
- (void)restoreGrouping
{
	NSMutableSet *targetGroups = [NSMutableSet set];

	if (adium.contactController.useContactListGroups) {
		if (adium.contactController.useOfflineGroup && !self.online && !self.alwaysVisible)
			[targetGroups addObject:adium.contactController.offlineGroup];
		else {
			for (AIListContact *containedContact in self.uniqueContainedObjects) {
				[targetGroups unionSet:containedContact.remoteGroups];
			}
		}
	} else {
		[targetGroups addObject:adium.contactController.contactList];
	}

	if (self.groups.count || targetGroups.count)
		[adium.contactController _moveContactLocally:self fromGroups:self.groups toGroups:targetGroups];
}

- (void)removeFromGroup:(AIListObject <AIContainingObject> *)group
{	
	if (self.groups.count == 1) {
		if (self.uniqueContainedObjectsCount == 1) {
			//If the metaContact only has one listContact, we will remove that contact from all accounts
			AIListContact	*listContact = [self.uniqueContainedObjects objectAtIndex:0];
			
			NSSet *objectsToRemove = [adium.contactController allContactsWithService:listContact.service UID:listContact.UID];
			for (AIListContact *contact in objectsToRemove) {
				[contact removeFromGroup:group];
			}
		} else {	
			// Otherwise, we just need to explode the meta.
			[adium.contactController explodeMetaContact:self];
		}
	} else {
		// Otherwise, remove our contained contacts from this group.
		for (AIListContact *contact in self) {
			if ([contact.remoteGroups containsObject:group]) {
				[contact removeFromGroup:group];
			}
		}
	}
}

//A metaContact should never be a stranger
- (BOOL)isStranger
{
	return NO;
}

- (BOOL) existsServerside
{
	return NO;
}

/*!
 * @brief Are all the contacts in this meta blocked?
 *
 * @result Boolean flag indicating if all the listContacts are blocked
 */
- (BOOL)isBlocked
{
	BOOL			allContactsBlocked = self.uniqueContainedObjectsCount > 0 ? YES : NO;
	
	for (AIListContact *currentContact in self.uniqueContainedObjects) {
		//find any unblocked contacts
		if (![currentContact isBlocked]) {
			allContactsBlocked = NO;
			break;
		}
	}
	
	return allContactsBlocked;
}

/*!
 * @brief Block each contact contained in the meta
 */
- (void)setIsBlocked:(BOOL)yesOrNo updateList:(BOOL)addToPrivacyLists
{
	
	for (AIListContact *currentContact in self.uniqueContainedObjects) {
		[currentContact setIsBlocked:yesOrNo updateList:addToPrivacyLists];
	}
	
	//update property if we are completely blocked
	[self setValue:[NSNumber numberWithBool:self.isBlocked]
				   forProperty:KEY_IS_BLOCKED 
				   notify:NotifyNow];
}

//Object Storage -------------------------------------------------------------------------------------------------------
#pragma mark Object Storage
- (void)containedObjectsOrOrderDidChange
{
	_preferredContact = nil;
	_listContacts = nil;
	_listContactsIncludingOfflineAccounts = nil;
	
	//Our effective icon may have changed
	[AIUserIcons flushCacheForObject:self];
}

/*!
 * @brief Add an object to this meta contact
 *
 * Should only be called by AIContactController
 *
 * @result YES if the object was added (that is, was not already present)
 */
- (BOOL)addObject:(AIListObject *)inObject
{
	BOOL	success = NO;

	if (![self.containedObjects containsObjectIdenticalTo:inObject]) {
		NSParameterAssert([self canContainObject:inObject]);
		
		((AIListContact *)inObject).metaContact = self;
		[_containedObjects addObject:inObject];
		containedObjectsNeedsSort = YES;
		
		[self containedObjectsOrOrderDidChange];
		
		//If we were unique before, check if we will still be unique after adding this contact.
		//If we were not, no checking needed.
		if (containsOnlyOneUniqueContact) {
			[self determineIfWeShouldAppearToContainOnlyOneContact];
		}

		//Add the object from our status cache, notifying of the changes (silently) as appropriate
		if (inObject == [self preferredContact]) {
			[self updateAllPropertiesForObject:inObject];
		}
		
		[self restoreGrouping];

		//Force an immediate update of our visibileListContacts list, which will also update our visible count
		[self visibleListContacts];

		success = YES;
	} else {
		AILogWithSignature(@"%@ (meta=%p) already contained in %@", inObject, ((AIListContact *)inObject).metaContact, self);
	}
	
	return success;
}

/*!
 * @brief Remove an object from this meta contact
 *
 * Should only be called by AIContactController.
 */
- (BOOL)removeObject:(AIListObject *)inObject
{
	NSParameterAssert([inObject isKindOfClass:[AIListContact class]]);
	AIListContact *contact = (AIListContact *)inObject;
	if ([self.containedObjects containsObjectIdenticalTo:inObject]) {
		BOOL	needToResetToRemoteGroup = NO;

		BOOL	wasPreferredContact = (inObject == self.preferredContact);

		[_containedObjects removeObject:inObject];
		
		if (contact.metaContact == self) {
			/* If the contact is being reassigned to another metaContact, this may already have been done; we shouldn't
			 * mess with it if it's not still ours to order around. The other metaContact will manage it as needed.
			 */
			contact.metaContact = nil;
			
			if (contact.countOfRemoteGroupNames > 0) {
				//Reset it to its remote group
				needToResetToRemoteGroup = YES;
			} else {
				for (AIListGroup *group in self.groups)
					[contact addContainingGroup:group];
			}
		}

		[self containedObjectsOrOrderDidChange];

		//Only need to check if we are now unique if we weren't unique before, since we've either become
		//unique are stayed the same.
		if (!containsOnlyOneUniqueContact) {
			[self determineIfWeShouldAppearToContainOnlyOneContact];
		}

		//Remove all references to the object from our status cache; notifying of the changes as appropriate
		if (wasPreferredContact)
			[self updateAllPropertiesForObject:inObject];

		//If we remove our list object, don't continue to show up in the contact list
		[self restoreGrouping];

		/* Now that we're done reconfigured ourselves and the recently removed object,
		 * tell the contactController about the change in the removed object.
		 */
		if (needToResetToRemoteGroup) {
			[(AIListContact *)inObject restoreGrouping];
		}
		
		return YES;
	} else {
		AILogWithSignature(@"%@: Asked to remove %@, but it's not actually contained therein", self, inObject);
		return NO;
	}
}

- (void)removeObjectAfterAccountStopsTracking:(AIListObject *)inObject
{
	NSParameterAssert([inObject isKindOfClass:[AIListContact class]]);
	AIListContact *contact = (AIListContact *)inObject;
	
	[_containedObjects removeObject:inObject];
	contact.metaContact = nil;
	[self containedObjectsOrOrderDidChange];

	//If we remove our list object, don't continue to show up in the contact list
	if (self.countOfContainedObjects == 0)
		[adium.contactController _moveContactLocally:self fromGroups:self.groups toGroups:[NSSet set]];
	
}

- (AIListContact *)preferredContactForContentType:(NSString *)inType
{
	AIListObject *preferredContact = nil;
	
	/* If we've messaged this contact previously, prefer the last contact we sent to 
	 * if that contact's status is the most-available one the metacontact can offer
	 */
	NSString *objID = [self preferenceForKey:KEY_PREFERRED_DESTINATION_CONTACT group:PREF_GROUP_OBJECT_STATUS_CACHE];
	
	if (objID)
		preferredContact = [adium.contactController existingListObjectWithUniqueID:objID];
	
	//Use our standard preferred contact if:
	//a) we no longer contain the saved contact
	//b) we have a more available contact
	//c) we have a non-mobile contact and our saved contact is mobile
	if (
		(![self containsObject:preferredContact]) ||
		(preferredContact.statusSummary != self.statusSummary) ||
		(!self.isMobile && preferredContact.isMobile)	
	) {
		preferredContact = self.preferredContact;
	}
	
	return (AIListContact *)preferredContact;
}

/*!
 * @brief Return the preferred contact to use within this metaContact
 *
 * Respecting the objectArray's order, find the first available contact. Failing that,
 * find the first online contact.  Failing that,
 * find the first contact.
 *
 * Only contacts which are in the array returned by self.uniqueContainedObjects are eligible.
 * @see listContacts
 *
 * @result The <tt>AIListContact</tt> which is considered the best for interacting with this metaContact
 */
- (AIListContact *)preferredContact
{
	if (!_preferredContact) {
		AIListContact   *preferredContact = nil;
		
		//Search for an available contact who is not mobile
		for (AIListContact *thisContact in self.uniqueContainedObjects) {
			if (thisContact.statusSummary == AIAvailableStatus &&	!thisContact.isMobile) {
				preferredContact = thisContact;
				break;
			}
		}
		
		//If no available contacts, find the first online contact
		if (!preferredContact) {
			for (AIListContact *thisContact in self.uniqueContainedObjects) {
				if (thisContact.online) {
					preferredContact = thisContact;
					break;
				}
			}
		}

		//If no online contacts, find the first contact
		if (!preferredContact && self.uniqueContainedObjectsCount > 0) {
			preferredContact = [self.uniqueContainedObjects objectAtIndex:0];
		}

		//If no list contacts at all, try contacts on offline accounts
		if (!preferredContact) {
			if ([self.containedObjects count]) {
				preferredContact = [self.containedObjects objectAtIndex:0];
			}
		}

		_preferredContact = preferredContact;
	}
	
	return _preferredContact;
}

/*!
 * @brief The perferred contact on a given service
 *
 * Same as self.preferredContact but only looks at contacts on the specified service
 */
- (AIListContact *)preferredContactWithCompatibleService:(AIService *)inService
{	
	if (!inService)
		return self.preferredContact;
	
	NSString	*serviceClass = inService.serviceClass;
	
	//Search for an available contact who is not mobile
	for (AIListContact *thisContact in self.uniqueContainedObjects) {
		if ([thisContact.service.serviceClass isEqualToString:serviceClass] &&
			thisContact.statusSummary == AIAvailableStatus &&
			!thisContact.isMobile) {
			return thisContact;
		}
	}			
	
	//If no available contacts, find the first online contact
	for (AIListContact *thisContact in self.uniqueContainedObjects) {
		if (thisContact.online && [thisContact.service.serviceClass isEqualToString:serviceClass])
			return thisContact;
	}
	
	for (AIListContact *thisContact in self.uniqueContainedObjects) {
		if ([thisContact.service.serviceClass isEqualToString:serviceClass])
			return thisContact;
	}
	
	return nil;
}

/*!
 * @brief Return a flat array of contacts to be displayed to the user
 *
 * This only returns one of each 'unique' contact, whereas the containedObjects potentially contains multiple contacts
 * which appear the same to the user but are unique to Adium, since each account on the proper service will have its own
 * instance of AIListContact for a given contact.
 *
 * This also only returns contacts which are listed on online accounts.
 */
- (NSArray *)uniqueContainedObjects
{
	if (!_listContacts) {
		_listContacts = [self uniqueContainedListContactsIncludingOfflineAccounts:NO visibleOnly:NO];
	}
	
	return _listContacts;
}

/*!
 * @brief Return a flat array of contacts which would be visible in the contact list to be displayed to the user
 *
 * This only returns one of each 'unique' contact, whereas the containedObjects potentially contains multiple contacts
 * which appear the same to the user but are unique to Adium, since each account on the proper service will have its own
 * instance of AIListContact for a given contact.
 *
 * This also only returns contacts which are listed on online accounts.
 *
 * This also only returns contacts which would be visible in the contact list.
 */
- (NSArray *)visibleListContacts
{
		return [self uniqueContainedListContactsIncludingOfflineAccounts:NO visibleOnly:YES];
}

- (NSArray *)listContactsIncludingOfflineAccounts
{
	if (!_listContactsIncludingOfflineAccounts) {
		_listContactsIncludingOfflineAccounts = [self uniqueContainedListContactsIncludingOfflineAccounts:YES visibleOnly:NO];
	}

	return _listContactsIncludingOfflineAccounts;
}

/*!
 * @brief Dictionary of service classes and list contacts
 *
 * @result A dictionary whose keys are serviceClass strings and whose objects are arrays of contained contacts *on online accounts* on that serviceClass.
 */
- (NSDictionary *)dictionaryOfServiceClassesAndListContacts
{
	NSMutableDictionary *contactsDict = [NSMutableDictionary dictionary];

	for (AIListContact *listContact in self.uniqueContainedObjects) {
		NSString *serviceClass = listContact.service.serviceClass;
		
		// Is there already an entry for this service?
		NSMutableArray *contactArray = [contactsDict objectForKey:serviceClass];
		if (contactArray)
			[contactArray addObject:listContact];
		else {
			contactArray = [NSMutableArray arrayWithObject:listContact];
			[contactsDict setObject:contactArray forKey:serviceClass];
		}
	}
	
	return contactsDict;
}

- (NSArray *)servicesOfContainedObjects
{
	NSMutableArray	*services = [[NSMutableArray alloc] init];
	AIListObject	*listObject;

	for (listObject in self.containedObjects) {
		if (![services containsObject:listObject.service]) [services addObject:listObject.service];
	}

	return services;
}

- (NSUInteger)uniqueContainedObjectsCount
{
	return self.uniqueContainedObjects.count;
}

- (AIListObject *)uniqueObjectAtIndex:(int)idx
{
	return [self.uniqueContainedObjects objectAtIndex:idx];
}

/**
 * @brief Return an array of unique contained list contacts, optionally including those for offline accounts
 *
 * This is a reasonably expensive call; its return value is cached by -self.uniqueContainedObjects and -[self listContactsIncludingOfflineAccounts],
 * so those are the methods to use externally.
 *
 * Implementation note: uniqueObjectIDs is an array because its indexing matches the indexing of the nascent listContacts array;
 * this allows a fast comparison for existing contacts.
 */
- (NSArray *)uniqueContainedListContactsIncludingOfflineAccounts:(BOOL)includeOfflineAccounts visibleOnly:(BOOL)visibleOnly
{
	NSArray			*myContainedObjects = self.containedObjects;
	NSMutableArray	*listContacts = [[NSMutableArray alloc] init];
	
	//Search for an available contact
	for (AIListContact *listContact in myContainedObjects) {
		AIListContact *previousContact = [listContacts lastObject];
		
		//Take advantage of the fact that this is a sorted list. If there are duplicates, they will be right next to each other.
		if ([listContact.internalObjectID isEqualToString:previousContact.internalObjectID]) {
			/* If it is a duplicate, but the previous pick is offline and this contact is online, swap 'em out so our array 
			 * has the best possible listContacts (making display elsewhere more straightforward) 
			 */ 
			if (!previousContact.online && listContact.online)
				[listContacts replaceObjectAtIndex:[listContacts count] - 1 withObject:listContact];
			continue;
		}

		if ((listContact.countOfRemoteGroupNames > 0 || includeOfflineAccounts) && (!visibleOnly || [[AIContactHidingController sharedController] visibilityOfListObject:listContact inContainer:self])) {
			[listContacts addObject:listContact]; 
		}
	}
	
	return listContacts;
}

- (BOOL)containsOnlyOneService
{
	return self.servicesOfContainedObjects.count == 1;
}

//When the listContacts array has a single member, we only contain one unique contact.
- (void)determineIfWeShouldAppearToContainOnlyOneContact
{
	BOOL oldOnlyOne = containsOnlyOneUniqueContact;

	//Clear our preferred contact so the next call to it will update the preferred contact
	[self containedObjectsOrOrderDidChange];

	containsOnlyOneUniqueContact = self.uniqueContainedObjectsCount < 2;

	//If it changed, do stuff
	if (oldOnlyOne != containsOnlyOneUniqueContact)
		[self updateDisplayName];
}

- (void)updateRemoteGroupingOfContact:(AIListContact *)inListContact;
{
#ifdef META_GROUPING_DEBUG
	AILog(@"AIMetaContact: Remote grouping of %@ changed to %@",inListObject,inListObject.remoteGroupNames);
#endif
	
	//When a contact has its remote grouping changed, this may mean it is now listed on an online account.
	//We therefore update our containsOnlyOneContact boolean.
	[self determineIfWeShouldAppearToContainOnlyOneContact];
	
	[self restoreGrouping];

	//Force an immediate update of our visibleListContacts list, which will also update our visible count
	[self visibleListContacts];
}

//Property Handling -----------------------------------------------------------------------------------------------
#pragma mark Property Handling
/*
 * @brief Update our preferred ordering as objects that we contain change their status
 *
 * The purpose of this is to determine if we need to recalculate our preferredContact.
 * This will be done "lazily," though in reality it will most likely happen quite soon.
 */
- (void)object:(id)inObject didChangeValueForProperty:(NSString *)key notify:(NotifyTiming)notify
{
	/* If the online status of a contained object changed, we should also check if our one-contact-only
	 * in terms of online contacts has changed
	 */
	if ([key isEqualToString:@"isOnline"]) {
		_preferredContact = nil;
		[self determineIfWeShouldAppearToContainOnlyOneContact];

	} else  if ([key isEqualToString:@"listObjectStatusType"] ||
		[key isEqualToString:@"idleSince"] ||
		[key isEqualToString:@"isIdle"] ||
		[key isEqualToString:@"isMobile"] ||
		[key isEqualToString:@"listObjectStatusMessage"]) {
		_preferredContact = nil;
	}
	
	[super object:self didChangeValueForProperty:key notify:notify];
}

/*
 * @brief The properties that should be relayed to the _preferredContact.
 *
 * A bit of a hack. The old way of checking if the metacontact's property is non-nil
 * doesn't work with primitive types.
 */
+ (NSArray *)_forwardedProperties
{
	static NSArray *properties = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		properties = [[NSArray alloc] initWithObjects:@"isOnline", @"isBlocked",
					  @"isIdle", @"notAStranger", @"isMobile", @"signedOff", @"signedOn",
					  @"alwaysOnline", @"unviewedContent", @"unviewedMention", nil];
	});
	
	return properties;
}

- (id)valueForProperty:(NSString *)key
{
	id ret;
	
	if ([[[self class] _forwardedProperties] containsObject:key]) {
		ret = [self.preferredContact valueForProperty:key];
	} else {
		ret = [super valueForProperty:key] ?: [self.preferredContact valueForProperty:key];
	}
	
	return ret;
}

- (NSInteger)integerValueForProperty:(NSString *)key
{
	NSInteger ret;
	
	if ([[[self class] _forwardedProperties] containsObject:key]) {
		ret = [self.preferredContact integerValueForProperty:key];
	} else {
		ret = [super integerValueForProperty:key] ?: [self.preferredContact integerValueForProperty:key];
	}
	
	return ret;
}

- (int)intValueForProperty:(NSString *)key
{
	int ret;
	
	if ([[[self class] _forwardedProperties] containsObject:key]) {
		ret = [self.preferredContact intValueForProperty:key];
	} else {
		ret = [super intValueForProperty:key] ?: [self.preferredContact intValueForProperty:key];
	}
	
	return ret;
}

- (BOOL)boolValueForProperty:(NSString *)key
{
	BOOL ret;
	
	if ([[[self class] _forwardedProperties] containsObject:key]) {
		ret = [self.preferredContact boolValueForProperty:key];
	} else {
		ret = [super boolValueForProperty:key] ?: [self.preferredContact boolValueForProperty:key];
	}
	
	return ret;
}

#pragma mark Attribute arrays
/**
 * @brief Request that Adium update our display name based on our current information
 */
- (void)updateDisplayName
{
	[[NSNotificationCenter defaultCenter] postNotificationName:Contact_ApplyDisplayName
											  object:self
											userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																				 forKey:@"Notify"]];
}

- (void)listObject:(AIListObject *)listObject mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(AIListObject *)inOwner priorityLevel:(float)priority
{
	if ((listObject != self) &&
		(inArray == [listObject displayArrayForKey:@"Display Name" create:NO]) &&
		(!anObject || ([anObject isEqualToString:[inArray objectValue]]))) {
		/* One of our contained objects changed its display name in such a  way that its Display Name array's objectValue changed. 
		 * Our own display name may need to change in turn.
		 * We used isEqualToString above because the Display Name array contains NSString objects.
		 * 
		 * Wait until the next run loop so that all observers of the changed contained object have done their thing; as a metaContact, our return values
		 * may be based on this contact's values.
		 */
		[self performSelector:@selector(updateDisplayName)
				   withObject:nil
				   afterDelay:0];
	}
}

/*!
 * @brief Notify that all properties of an object just changed for us
 *
 * We pretend that the AIMetaContact's values changed (or may have changed) for every
 * property that the object has. This lets code elsewhere update appropriately.
 *
 * This should be called when an object is added to or removed from the meta contact.
 *
 * @param inObject The object for which we will notify
 */
- (void)updateAllPropertiesForObject:(AIListObject *)inObject
{
	for (NSString *key in inObject.properties) {
		[super object:self didChangeValueForProperty:key notify:NotifyLater];
	}

	[self notifyOfChangedPropertiesSilently:YES];
}

//Preferences -------------------------------------------------------------------------------------------------
#pragma mark Preferences

//Retrieve a preference value (with the option of ignoring inherited values)
//If we don't find a preference, query our preferredContact to take its preference as our own.
//We could potentially query all the objects.. but that's possibly overkill.
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName
{
	id returnValue = [super preferenceForKey:inKey group:groupName];
	
	//Look to our first contained object
	if (!returnValue && [self.containedObjects count]) {
		returnValue = [self.preferredContact preferenceForKey:inKey group:groupName];

		//Move the preference to us so we will have it next time and the contact won't (lazy migration)
		if (returnValue) {
			[self setPreference:returnValue forKey:inKey group:groupName];
			[self.preferredContact setPreference:nil forKey:inKey group:groupName];
		}
	}
	
	return returnValue;
}

#pragma mark User Icon
/** 
 * @brief Return the user icon for this metaContact
 *
 * We always want to provide a userIcon if at all possible.
 * First, call displayUserIcon. See below for details.
 * If that returns nil, look at our preferredContact's userIcon.
 * If that returns nil, find any userIcon of a containedContact.
 *
 * Note that this is one of the few places that a metacontact will display information from a contact other
 * than its preferred contact.
 *
 * @result The <tt>NSImage</tt> to associate with this metaContact
 */
- (NSImage *)userIcon
{
	NSImage		 *internalUserIcon = [self internalUserIcon];
	NSImage		 *userIcon = internalUserIcon;
	AIListObject *sourceListObject = self;

	BOOL	useOwnIconAsLastResort = NO;

	id <AIUserIconSource> myUserIconSource = [AIUserIcons userIconSourceForObject:self];
	if (myUserIconSource) {
		if ([myUserIconSource priority] > AIUserIconMediumPriority) {
			/* If our own user iocn if it is at less than medium priority, don't use it unless
			 * we find nothing else; this allows a contact's serverside icon to still be used if desired.
			 */
			useOwnIconAsLastResort = YES;
			userIcon = nil;
			sourceListObject = nil;
		}
	}
	
	if (!userIcon) {
		sourceListObject = self.preferredContact;
		userIcon = [sourceListObject userIcon];
	}
	if (!userIcon) {
		NSArray		*theContainedObjects = self.uniqueContainedObjects;

		NSUInteger count = [theContainedObjects count];
		for (NSUInteger i = 0; i < count && !userIcon; i++) {
			sourceListObject = [theContainedObjects objectAtIndex:i];
			userIcon = [sourceListObject userIcon];
		}
	}

	if (!userIcon && useOwnIconAsLastResort) {
		sourceListObject = self;
		userIcon = internalUserIcon;
	}

	if (userIcon && (sourceListObject != self)) {
		[AIUserIcons setActualUserIcon:userIcon
							 andSource:[AIUserIcons userIconSourceForObject:sourceListObject]
							 forObject:self];
	}

	return userIcon;
}

- (NSString *)displayName
{
	return [self displayArrayObjectForKey:@"Display Name"] ?: self.preferredContact.ownDisplayName;
}

- (NSString *)phoneticName
{	
	return [self displayArrayObjectForKey:@"Phonetic Name"] ?: self.preferredContact.ownPhoneticName;
}

//FormattedUID will return nil if we have multiple different UIDs contained within us
- (NSString *)formattedUID
{
#ifdef META_TYPE_DEBUG
	return (containsOnlyOneUniqueContact ? 
			[self.preferredContact.formattedUID stringByAppendingString:@" (uniqueMeta)"] : 
			@"meta");	
#else
	return containsOnlyOneUniqueContact ? self.preferredContact.formattedUID : nil;
#endif
}

- (NSString *)longDisplayName
{
	return [self displayArrayObjectForKey:@"Long Display Name"] ?: self.preferredContact.longDisplayName;
}

#pragma mark Status
- (NSString *)statusName
{
	return self.preferredContact.statusName;
}

- (AIStatusType)statusType
{
	return self.preferredContact.statusType;
}

/*!
 * @brief Determine the status message to be displayed in the contact list
 *
 * @result <tt>NSAttributedString</tt> which will be the message for this contact in the contact list, after modifications
 */
- (NSAttributedString *)contactListStatusMessage
{
	NSAttributedString	*contactListStatusMessage = nil;
	
	//Try to use an actual status message first
	contactListStatusMessage = self.preferredContact.statusMessage;

	if (!contactListStatusMessage)
		contactListStatusMessage = [self.preferredContact contactListStatusMessage];

	if (!contactListStatusMessage) { 
		contactListStatusMessage = self.statusMessage;
		if (contactListStatusMessage)
			AILogWithSignature(@"%@: Odd. Why do I have a statusmessage (%@) but my preferred contact doesn't?", 
							   self, contactListStatusMessage);
	}

	return contactListStatusMessage;
}

/**
 * @brief Are sounds for this contact muted?
 */
- (BOOL)soundsAreMuted
{
	return self.preferredContact.account.statusState.mutesSound;
}

//Object Storage ---------------------------------------------------------------------------------------------
#pragma mark Object Storage
//Return our contained objects

- (NSArray *)visibleContainedObjects
{
	return self.visibleListContacts;
}

- (NSArray *)containedObjects
{
	//Sort the containedObjects if the flag tells us it's needed
	if (containedObjectsNeedsSort) {
		containedObjectsNeedsSort = NO;
		[_containedObjects sortUsingFunction:containedContactSort context:(__bridge void *)(self)];
	}
	
	return [_containedObjects copy];
}
- (NSUInteger)countOfContainedObjects
{
    return [_containedObjects count];
}

//Test for the presence of an object in our group
- (BOOL)containsObject:(AIListObject *)inObject
{
	return [_containedObjects containsObject:inObject];
}

//Retrieve an object by index
- (id)objectAtIndex:(NSUInteger)idx
{
    return [self.uniqueContainedObjects objectAtIndex:idx];
}

- (AIListObject *)objectWithService:(AIService *)inService UID:(NSString *)inUID
{
	for (AIListContact *object in self) {
		if ([inUID isEqualToString:object.UID] && object.service == inService)
			return object;
	}
	
	return nil;
}

- (NSString *)contentsBasedIdentifier
{
	return self.internalObjectID;
}

//Expanded State -------------------------------------------------------------------------------------------------------
#pragma mark Expanded State
//Set the expanded/collapsed state of this group (PRIVATE: For the contact list view to let us know our state)
- (void)setExpanded:(BOOL)inExpanded
{
	if (expanded != inExpanded) {
		expanded = inExpanded;
		
		[self setPreference:[NSNumber numberWithBool:expanded]
					 forKey:KEY_EXPANDED
					  group:PREF_GROUP_OBJECT_STATUS_CACHE];
	
	}
}
//Returns the current expanded/collapsed state of this group
- (BOOL)isExpanded
{
    return expanded;
}

- (BOOL)isExpandable
{
	return !containsOnlyOneUniqueContact;
}

- (void)listObject:(AIListObject *)listObject didSetOrderIndex:(float)inOrderIndex
{
	[super listObject:listObject didSetOrderIndex:inOrderIndex];

	//We'll need to resort next time we're accessed
	containedObjectsNeedsSort = YES;

	[self containedObjectsOrOrderDidChange];	
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])stackbuf count:(NSUInteger)len
{
	return [self.containedObjects countByEnumeratingWithState:state objects:stackbuf count:len];
}

#pragma mark Contained Contact sorting

/*!
 * @brief Sort contained contacts, first by order index and then by internalUniqueObjectID
 */
NSComparisonResult containedContactSort(AIListContact *objectA, AIListContact *objectB, void *context)
{
	float orderIndexA = [(__bridge AIMetaContact *)context orderIndexForObject:objectA];
	float orderIndexB = [(__bridge AIMetaContact *)context orderIndexForObject:objectB];
	if (orderIndexA > orderIndexB) {
		return NSOrderedDescending;
		
	} else if (orderIndexA < orderIndexB) {
		return NSOrderedAscending;
		
	} else {
		return [[objectA internalUniqueObjectID] caseInsensitiveCompare:[objectB internalUniqueObjectID]];
	}
}

//Visibility -----------------------------------------------------------------------------------------------------------
#pragma mark Visibility
/*!
 * @brief Returns the number of visible objects in this metaContact, which is the same as the count of listContacts
 */
- (NSUInteger)visibleCount
{
	return [self.visibleListContacts count];
}

/*!
 * @brief Get the visbile object at a given index
 */
- (AIListObject *)visibleObjectAtIndex:(NSUInteger)idx
{
	return [self.visibleListContacts objectAtIndex:idx];
}

- (NSUInteger)visibleIndexOfObject:(AIListObject *)obj
{
	return [self.visibleListContacts indexOfObject:obj];
}

#pragma mark Debugging
- (NSString *)description
{
	NSMutableArray *subobjectDescs = [[NSMutableArray alloc] initWithCapacity:[self.containedObjects count]];

	for(AIListContact *subobject in self.containedObjects)
		[subobjectDescs addObject:[subobject description]];

	NSString *subobjectDescsDesc = [subobjectDescs description];

	return [NSString stringWithFormat:@"<%@:%p %@: %@>",NSStringFromClass([self class]), self, self.internalObjectID, subobjectDescsDesc];
}

- (BOOL) canContainObject:(id)obj
{
	return [obj isKindOfClass:[AIListContact class]] && ![obj isKindOfClass:[AIMetaContact class]];
}

//inherit these
@dynamic largestOrder;
@dynamic smallestOrder;

@end
