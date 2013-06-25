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

#import "AIContactController.h"

#import "AISCLViewPlugin.h"
#import <Adium/AIContactHidingController.h>

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AILoginControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>

#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AISortController.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIContactList.h>

#define KEY_FLAT_GROUPS					@"FlatGroups"			//Group storage
#define KEY_FLAT_CONTACTS				@"FlatContacts"			//Contact storage
#define KEY_FLAT_METACONTACTS			@"FlatMetaContacts"		//Metacontact objectID storage
#define KEY_BOOKMARKS					@"Bookmarks"

#define TOP_METACONTACT_ID				@"TopMetaContactID"
#define KEY_IS_METACONTACT				@"isMetaContact"
#define KEY_OBJECTID					@"objectID"
#define KEY_METACONTACT_OWNERSHIP		@"MetaContact Ownership"
#define CONTACT_DEFAULT_PREFS			@"ContactPrefs"

#define	SHOW_GROUPS_MENU_TITLE			AILocalizedString(@"Show Groups",nil)

#define SHOW_GROUPS_IDENTIFER			@"ShowGroups"

#define SERVICE_ID_KEY					@"ServiceID"
#define UID_KEY							@"UID"

//#define CONTACT_MOVEMENT_DEBUG

@interface AIListObject ()
@property (readwrite, nonatomic) CGFloat orderIndex;
@end

@interface AIMetaContact ()
- (BOOL)addObject:(AIListObject *)inObject;
- (BOOL)removeObject:(AIListObject *)inObject;
- (AIListContact *)preferredContactForContentType:(NSString *)inType;
@end

@interface AIListGroup ()
- (void)removeObject:(AIListObject *)inObject;
- (BOOL)addObject:(AIListObject *)inObject;
@end

@interface AIContactList ()
- (void)removeObject:(AIListObject *)inObject;
- (BOOL)addObject:(AIListObject *)inObject;
@end

@interface AIListBookmark ()
//Freshly minted bookmarks don't know where to restore to, since they have no serverside counterpart. This tells them.
- (void)setInitialGroup:(AIListGroup *)inGroup;
@end

@interface AIContactController ()
@property (readwrite, nonatomic) BOOL useOfflineGroup;
- (void)saveContactList;
- (void)_loadBookmarks;
- (void)_didChangeContainer:(id <AIContainingObject>)inContainingObject object:(AIListObject *)object;
- (void)prepareShowHideGroups;
- (void)_performChangeOfUseContactListGroups;
- (void)didSendContent:(NSNotification *)notification;
- (IBAction)toggleShowGroups:(id)sender;

//MetaContacts
- (BOOL)_restoreContactsToMetaContact:(AIMetaContact *)metaContact;
- (void)_restoreContactsToMetaContact:(AIMetaContact *)metaContact fromContainedContactsArray:(NSArray *)containedContactsArray;
- (void)addContact:(AIListContact *)inContact toMetaContact:(AIMetaContact *)metaContact;
- (BOOL)_performAddContact:(AIListContact *)inContact toMetaContact:(AIMetaContact *)metaContact;
- (void)removeContact:(AIListContact *)inContact fromMetaContact:(AIMetaContact *)metaContact;
- (void)_loadMetaContactsFromArray:(NSArray *)array;
- (void)_saveMetaContacts:(NSDictionary *)allMetaContactsDict;
- (void)_storeListObject:(AIListObject *)listObject inMetaContact:(AIMetaContact *)metaContact;
@end

@implementation AIContactController

- (id)init
{
	if ((self = [super init])) {
		//
		contactDict = [[NSMutableDictionary alloc] init];
		groupDict = [[NSMutableDictionary alloc] init];
		metaContactDict = [[NSMutableDictionary alloc] init];
		bookmarkDict = [[NSMutableDictionary alloc] init];
		contactToMetaContactLookupDict = [[NSMutableDictionary alloc] init];
		contactLists = [[NSMutableArray alloc] init];

		contactPropertiesObserverManager = [AIContactObserverManager sharedManager];
	}
	
	return self;
}

- (void)controllerDidLoad
{	
	//Default contact preferences
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:CONTACT_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_CONTACT_LIST];
	
	contactList = [[AIContactList alloc] initWithUID:ADIUM_ROOT_GROUP_NAME];
	[contactLists addObject:contactList];
	//Root is always "expanded"
	[contactList setExpanded:YES];
	
	//Show Groups menu item
	[self prepareShowHideGroups];
	
	//Observe content (for preferredContactForContentType:forListContact:)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                   selector:@selector(didSendContent:)
                                       name:CONTENT_MESSAGE_SENT
                                     object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(didSendContent:)
												 name:CONTENT_MESSAGE_SENT_GROUP
											   object:nil];
	
	[self loadContactList];
	[self sortContactList];
	
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
}

- (void)controllerWillClose
{
	[self saveContactList];
}

- (void)dealloc
{
	[adium.preferenceController unregisterPreferenceObserver:self];
		
	[contactDict release];
	[groupDict release];
	[metaContactDict release];
	[contactToMetaContactLookupDict release];
	[contactLists release];
	[bookmarkDict release];
	
	[contactPropertiesObserverManager release];

	[super dealloc];
}

- (void)clearAllMetaContactData
{
	if (metaContactDict.count) {
		[contactPropertiesObserverManager delayListObjectNotifications];
		
		//Remove all the metaContacts to get any existing objects out of them
		for (AIMetaContact *metaContact in [[[metaContactDict copy] autorelease] objectEnumerator]) {
			[self explodeMetaContact:metaContact];
		}
		
		[contactPropertiesObserverManager endListObjectNotificationsDelay];
	}
	
	[metaContactDict release]; metaContactDict = [[NSMutableDictionary alloc] init];
	[contactToMetaContactLookupDict release]; contactToMetaContactLookupDict = [[NSMutableDictionary alloc] init];
	
	//Clear the preferences for good measure
	[adium.preferenceController setPreference:nil
										 forKey:KEY_FLAT_METACONTACTS
										  group:PREF_GROUP_CONTACT_LIST];
	[adium.preferenceController setPreference:nil
										 forKey:KEY_METACONTACT_OWNERSHIP
										  group:PREF_GROUP_CONTACT_LIST];
	
	//Clear out old metacontact files
	[[NSFileManager defaultManager] removeFilesInDirectory:[[adium.loginController userDirectory] stringByAppendingPathComponent:OBJECT_PREFS_PATH]
												withPrefix:@"MetaContact"
											 movingToTrash:NO];
	[[NSFileManager defaultManager] removeFilesInDirectory:[adium cachesPath]
												withPrefix:@"MetaContact"
											 movingToTrash:NO];
}

#pragma mark Local Contact List Storage
//Load the contact list
- (void)loadContactList
{
	//We must load all the groups before loading contacts for the ordering system to work correctly.
	[self _loadMetaContactsFromArray:[adium.preferenceController preferenceForKey:KEY_FLAT_METACONTACTS
																			  group:PREF_GROUP_CONTACT_LIST]];
	[self _loadBookmarks];
}

//Save the contact list
- (void)saveContactList
{
	for (AIListGroup *listGroup in [groupDict objectEnumerator]) {
		[listGroup setPreference:[NSNumber numberWithBool:[listGroup isExpanded]]
						  forKey:KEY_EXPANDED
						   group:PREF_GROUP_CONTACT_LIST];
	}
	
	NSMutableArray *bookmarks = [NSMutableArray array];
	for (AIListBookmark *bookmark in self.allBookmarks) {
		[bookmarks addObject:[NSKeyedArchiver archivedDataWithRootObject:bookmark]];
	}
	
	[adium.preferenceController setPreference:bookmarks
									   forKey:KEY_BOOKMARKS
										group:PREF_GROUP_CONTACT_LIST];
}

- (void)_loadBookmarks
{
	for (NSData *data in [adium.preferenceController preferenceForKey:KEY_BOOKMARKS group:PREF_GROUP_CONTACT_LIST]) {
		//As a bookmark is initialized, it will add itself to the contact list in the right place
		AIListBookmark	*bookmark = [NSKeyedUnarchiver unarchiveObjectWithData:data];

		if(bookmark) {
			if ([bookmarkDict objectForKey:bookmark.internalObjectID]) {
				// In case we end up with two bookmarks with the same internalObjectID; this should be almost impossible.
				[self removeBookmark:[bookmarkDict objectForKey:bookmark.internalObjectID]];
			}
			
			[bookmarkDict setObject:bookmark forKey:bookmark.internalObjectID];
			
			//It's a newly created object, so set its initial attributes
			[contactPropertiesObserverManager _updateAllAttributesOfObject:bookmark];
		}
	}
}

- (void)_loadMetaContactsFromArray:(NSArray *)array
{	
	for (NSString *identifier in array) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSNumber *objectID = [NSNumber numberWithInteger:[[[identifier componentsSeparatedByString:@"-"] objectAtIndex:1] integerValue]];
		[self metaContactWithObjectID:objectID];
		[pool release];
	}
}

#pragma mark Contact Grouping

- (void)_addContactLocally:(AIListContact *)listContact toGroup:(id<AIContainingObject>)localGroup
{
	BOOL			performedGrouping = NO;
	
	//Protect with a retain while we are removing and adding the contact to our arrays
	[listContact retain];
	
	if (listContact.canJoinMetaContacts) {
		AIListObject *existingObject = [localGroup objectWithService:listContact.service UID:listContact.UID];
		if (existingObject && (existingObject != listContact)) {
			/* If an object exists in this group with the same UID and serviceID, create a MetaContact for the two. */
			AIMetaContact *metaContact = [self groupContacts:[NSArray arrayWithObjects:listContact,existingObject,nil]];
						
			AILogWithSignature(@"%@ and %@ match; grouped into %@",
							   listContact, existingObject, metaContact);
			performedGrouping = YES;

		} else {
			AIMetaContact	*metaContact = [contactToMetaContactLookupDict objectForKey:listContact.internalObjectID];
			
			/* If no object exists in this group which matches, we should check if there is already
			 * a MetaContact holding a matching ListContact, since we should include this contact in it
			 * If we found a metaContact to which we should add, do it.
			 */
 			if (metaContact) {
				AILogWithSignature(@"%@: Add %@", metaContact, listContact);
 				[self addContact:listContact toMetaContact:metaContact];
 				performedGrouping = YES;
 			}
		}
	}
	
	if (!performedGrouping) {
		//If no similar objects exist, we add this contact directly to the list
		[localGroup addObject:listContact];
		
		//Add
		[self _didChangeContainer:localGroup object:listContact];
	}
	
	//Cleanup
	[listContact release];
}

/*!
 * @brief Handle a local move
 *
 * This will remove listContact from our local tracking within each of oldGroups, which must be AIListObject<AIContainingObject>
 * objects. It will then add them to groups, which must also be AIListObject<AIContainingObject> objects.
 *
 * This does not make any changes serverside; that should be handled separately.
 */
- (void)_moveContactLocally:(AIListContact *)listContact fromGroups:(NSSet *)oldGroups toGroups:(NSSet *)groups
{
	if (![oldGroups isEqualToSet:groups]) {
		//Protect with a retain while we are removing and adding the contact to our arrays
		[listContact retain];
		
		[contactPropertiesObserverManager delayListObjectNotifications];
		
#ifdef CONTACT_MOVEMENT_DEBUG
		AILogWithSignature(@"%@: %@ --> %@", 
						   listContact,
						   (oldGroups.count ? oldGroups : nil), 
						   (groups.count ? (groups.count == 1 ? [groups anyObject] ? groups) : nil));
#endif
		
		//Remove this object from any local groups we have it in currently
		for (id<AIContainingObject> group in oldGroups) {
			[group removeObject:listContact];
			[self _didChangeContainer:group object:listContact];
		}
		
		for (id<AIContainingObject> group in groups)
			[self _addContactLocally:listContact toGroup:group];
		
		[contactPropertiesObserverManager endListObjectNotificationsDelay];
		
		[listContact release];
	}
}

//Post a list grouping changed notification for the object and containing object
- (void)_didChangeContainer:(id<AIContainingObject>)inContainingObject object:(AIListObject *)object
{
	if ([contactPropertiesObserverManager shouldDelayUpdates]) {
		[contactPropertiesObserverManager noteContactChanged:object];

	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:Contact_ListChanged
												  object:inContainingObject
												userInfo:nil];
	}
}

- (BOOL)useContactListGroups
{
	return useContactListGroups;
}

- (void)setUseContactListGroups:(BOOL)inFlag
{
	if (inFlag != useContactListGroups) {
		useContactListGroups = inFlag;
		
		[self _performChangeOfUseContactListGroups];
	}
}

- (void)_performChangeOfUseContactListGroups
{
	[contactPropertiesObserverManager delayListObjectNotifications];
	
	//Store the preference
	[adium.preferenceController setPreference:[NSNumber numberWithBool:!useContactListGroups]
										 forKey:KEY_HIDE_CONTACT_LIST_GROUPS
										  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	
	//Configure the sort controller to force ignoring of groups as appropriate
	[[AISortController activeSortController] forceIgnoringOfGroups:(useContactListGroups ? NO : YES)];
	
	//Restore the grouping of all root-level contacts
	for (AIListContact *contact in [self contactEnumerator]) {
		[contact restoreGrouping];
	}
	
	//Restore the grouping of all list bookmarks
	for (AIListBookmark *bookmark in [self bookmarkEnumerator]) {
		[bookmark restoreGrouping];
	}

	//Stop delaying object notifications; this will automatically resort the contact list, so we're done.
	[contactPropertiesObserverManager endListObjectNotificationsDelay];
}

- (void)prepareShowHideGroups
{
	//Load the preference
	useContactListGroups = ![[adium.preferenceController preferenceForKey:KEY_HIDE_CONTACT_LIST_GROUPS
																	  group:PREF_GROUP_CONTACT_LIST_DISPLAY] boolValue];
	
	//Show offline contacts menu item
    menuItem_showGroups = [[NSMenuItem alloc] initWithTitle:SHOW_GROUPS_MENU_TITLE
													 target:self
													 action:@selector(toggleShowGroups:)
											  keyEquivalent:@""];
	
	[menuItem_showGroups setState:useContactListGroups];
	
	[adium.menuController addMenuItem:menuItem_showGroups toLocation:LOC_View_Toggles];
}

- (IBAction)toggleShowGroups:(id)sender
{
	//Flip-flop.
	useContactListGroups = !useContactListGroups;
	[menuItem_showGroups setState:useContactListGroups];

	//Update the contact list.  Do it on the next run loop for better menu responsiveness, as it may be a lengthy procedure.
	[self performSelector:@selector(_performChangeOfUseContactListGroups)
			   withObject:nil
			   afterDelay:0];
}

@synthesize useOfflineGroup;

- (AIListGroup *)offlineGroup
{
	return [self groupWithUID:AILocalizedString(@"Offline", "Name of offline group")];
}

#pragma mark Meta Contacts

/*!
 * @brief Create or load a metaContact
 *
 * @param inObjectID The objectID of an existing but unloaded metaContact, or nil to create and save a new metaContact
 */
- (AIMetaContact *)metaContactWithObjectID:(NSNumber *)inObjectID
{
	BOOL			shouldRestoreContacts = YES;
	
	//If no object ID is provided, use the next available object ID
	//(MetaContacts should always have an individually unique object id)
	if (!inObjectID) {
		NSInteger topID = [[adium.preferenceController preferenceForKey:TOP_METACONTACT_ID
															  group:PREF_GROUP_CONTACT_LIST] integerValue];
		inObjectID = [NSNumber numberWithInteger:topID];
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:([inObjectID integerValue] + 1)]
											 forKey:TOP_METACONTACT_ID
											  group:PREF_GROUP_CONTACT_LIST];
		
		//No reason to waste time restoring contacts when none are in the meta contact yet.
		shouldRestoreContacts = NO;
	}
	
	//Look for a metacontact with this object ID.  If none is found, create one
	//and add its contained contacts to it.
	NSString		*metaContactDictKey = [AIMetaContact internalObjectIDFromObjectID:inObjectID];
	
	AIMetaContact   *metaContact = [metaContactDict objectForKey:metaContactDictKey];
	if (!metaContact) {
		metaContact = [(AIMetaContact *)[AIMetaContact alloc] initWithObjectID:inObjectID];
		
		//Keep track of it in our metaContactDict for retrieval by objectID
		[metaContactDict setObject:metaContact forKey:metaContactDictKey];
		
		//Add it to our more general contactDict, as well
		[contactDict setObject:metaContact forKey:[metaContact internalUniqueObjectID]];
		
		/* We restore contacts (actually, internalIDs for contacts, to be added as necessary later) if the metaContact
		 * existed before this call to metaContactWithObjectID:
		 */
		if (shouldRestoreContacts)
			[self _restoreContactsToMetaContact:metaContact];
		
		/* As with contactWithService:account:UID, update all attributes so observers are initially informed of
		 * this object's existence.
		 */
		[contactPropertiesObserverManager _updateAllAttributesOfObject:metaContact];
		
		[metaContact release];
	}
	
	return metaContact;
}

/*!
 * @brief Associate the appropriate internal IDs for contained contacts with a metaContact
 *
 * @result YES if one or more contacts was associated with the metaContact; NO if none were.
 */
- (BOOL)_restoreContactsToMetaContact:(AIMetaContact *)metaContact
{
	NSDictionary	*allMetaContactsDict = [adium.preferenceController preferenceForKey:KEY_METACONTACT_OWNERSHIP
																				 group:PREF_GROUP_CONTACT_LIST];
	NSArray			*containedContactsArray = [allMetaContactsDict objectForKey:metaContact.internalObjectID];
	
	if (containedContactsArray.count) {
		[self _restoreContactsToMetaContact:metaContact
				 fromContainedContactsArray:containedContactsArray];
		
		return YES;
		
	}
	
	return NO;
}

/*!
 * @brief Associate the internal IDs for an array of contacts with a specific metaContact
 *
 * This does not actually place any AIListContacts within the metaContact.  Instead, it updates the contactToMetaContactLookupDict
 * dictionary to have metaContact associated with the list contacts specified by containedContactsArray. This
 * allows us to add them lazily to the metaContact (in contactWithService:account:UID:) as necessary.
 *
 * @param metaContact The metaContact to which contact referneces are added
 * @param containedContactsArray An array of NSDictionary objects, each of which has SERVICE_ID_KEY and UID_KEY which together specify an internalObjectID of an AIListContact
 */
- (void)_restoreContactsToMetaContact:(AIMetaContact *)metaContact fromContainedContactsArray:(NSArray *)containedContactsArray
{	
	for (NSDictionary *containedContactDict in containedContactsArray) {
		/* Before Adium 0.80, metaContacts could be created within metaContacts. Simply ignore any attempt to restore
		 * such erroneous data, which will have a YES boolValue for KEY_IS_METACONTACT. */
		if (![[containedContactDict objectForKey:KEY_IS_METACONTACT] boolValue]) {
			/* Assign this metaContact to the appropriate internalObjectID for containedContact's represented listObject.
			 *
			 * As listObjects are loaded/created/requested which match this internalObjectID, 
			 * they will be inserted into the metaContact.
			 */
			NSString	*internalObjectID = [AIListObject internalObjectIDForServiceID:[containedContactDict objectForKey:SERVICE_ID_KEY]
																				UID:[containedContactDict objectForKey:UID_KEY]];
			[contactToMetaContactLookupDict setObject:metaContact
											   forKey:internalObjectID];
		}
	}
}

//Add a list object to a meta contact, setting preferences and such
//so the association is lasting across program launches.
- (void)addContact:(AIListContact *)inContact toMetaContact:(AIMetaContact *)metaContact
{
	if (!inContact) {
		//I can't think of why one would want to add an entire group to a metacontact. Let's say you can't.
		NSLog(@"Warning: addContact:toMetaContact: Attempted to add %@ to %@",inContact,metaContact);
		return;
	}
	
	if (inContact == metaContact) return;

	AILogWithSignature(@"%@ will add %@", metaContact, inContact);

	//If listObject contains other contacts, perform addContact:toMetaContact: recursively
	if ([inContact conformsToProtocol:@protocol(AIContainingObject)]) {
		AILogWithSignature(@"Adding recursively (%@)", ((id<AIContainingObject>)inContact).containedObjects);
		for (AIListContact *someObject in ((id<AIContainingObject>)inContact).containedObjects) {
			[self addContact:someObject toMetaContact:metaContact];
		}
		
	} else {
		//Obtain any metaContact this listObject is currently within, so we can remove it later
		AIMetaContact *oldMetaContact;
		
		/* First, look for a metaContact which is -properly- associated with inContact, already.
		 * That is, a metaContact that has current ownership but which should be disassociated, in faovr of the new
		 * metaContact.
		 */
		oldMetaContact = [contactToMetaContactLookupDict objectForKey:[inContact internalObjectID]];
		
		if (metaContact == oldMetaContact) {
			/* According to contactToMetaContactLookupDict, inContact is within metaContact already.
			 * However, a single UID/serviceID pair can have multiple AIListContacts (for multiple accounts).
			 * If Account A and Account B both have a contact like inContact, and we are looking at Account B's
			 * contact now, we'll have already made a reassignment.  This contact does still need to be removed from
			 * its parent, however.
			 */
			if ((inContact.parentContact != inContact) &&
				([inContact.parentContact isKindOfClass:[AIMetaContact class]])) {
				oldMetaContact = (AIMetaContact *)(inContact.parentContact);
			}
		}
		
		if ([self _performAddContact:inContact toMetaContact:metaContact]) {
			if (metaContact != oldMetaContact) {
				AILogWithSignature(@"oldMetaContact for %@ is %@", inContact.internalObjectID, oldMetaContact);

				//If this listObject was not in this metaContact in any form before, store the change
				//Remove the list object from any other metaContact it is in at present
				if (oldMetaContact)
					[self removeContact:inContact fromMetaContact:oldMetaContact];
				
				[self _storeListObject:inContact inMetaContact:metaContact];
				
				//Do the update thing
				[contactPropertiesObserverManager _updateAllAttributesOfObject:metaContact];
			} else {
				AILogWithSignature(@"The old metacontact was the same as the new metacontact");
			}
		} else {
			AILogWithSignature(@"Failed to add %@ to %@", inContact, metaContact);
		}
	}
}

- (void)_storeListObject:(AIListObject *)listObject inMetaContact:(AIMetaContact *)metaContact
{
	//we only allow group->meta->contact, not group->meta->meta->contact
	NSParameterAssert(![listObject conformsToProtocol:@protocol(AIContainingObject)]);
	
	NSDictionary		*containedContactDict;
	NSMutableDictionary	*allMetaContactsDict;
	NSMutableArray		*containedContactsArray;
	
	NSString			*metaContactInternalObjectID = [metaContact internalObjectID];
	
	//Get the dictionary of all metaContacts
	allMetaContactsDict = [[adium.preferenceController preferenceForKey:KEY_METACONTACT_OWNERSHIP
																	group:PREF_GROUP_CONTACT_LIST] mutableCopy];
	if (!allMetaContactsDict) {
		allMetaContactsDict = [[NSMutableDictionary alloc] init];
	}
	
	//Load the array for the new metaContact
	containedContactsArray = [[allMetaContactsDict objectForKey:metaContactInternalObjectID] mutableCopy];
	if (!containedContactsArray) containedContactsArray = [[NSMutableArray alloc] init];
	containedContactDict = nil;
	
	//Create the dictionary describing this list object
	containedContactDict = [NSDictionary dictionaryWithObjectsAndKeys:
							listObject.service.serviceID, SERVICE_ID_KEY,
							listObject.UID, UID_KEY, nil];
	
	//Only add if this dict isn't already in the array
	if (containedContactDict && ([containedContactsArray indexOfObject:containedContactDict] == NSNotFound)) {
		[containedContactsArray addObject:containedContactDict];
		[allMetaContactsDict setObject:containedContactsArray forKey:metaContactInternalObjectID];
		
		//Save
		[self _saveMetaContacts:allMetaContactsDict];
		
		[adium.contactAlertsController mergeAndMoveContactAlertsFromListObject:listObject
																  intoListObject:metaContact];
		
		AILogWithSignature(@"Updated %@'s containedContactsArray: %@", metaContact, containedContactsArray);
	}
	
	[allMetaContactsDict release];
	[containedContactsArray release];
}

/*!
 * @brief Makes the associations between an AIListContact and an AIMetaContact within memory
 *
 * No preferences are changed; this is an internal step during the process of moving a contact into a metacontact.
 *
 * Attempts to add the list object, causing group reassignment and updates our contactToMetaContactLookupDict
 * for quick lookup of the MetaContact given a AIListContact uniqueObjectID if successful.
 *
 * @result YES if a change was made; NO if inContact is already contained by metaContact
 */
- (BOOL)_performAddContact:(AIListContact *)inContact toMetaContact:(AIMetaContact *)metaContact
{
	if (inContact.metaContact == metaContact) {
		AILogWithSignature(@"%@'s metaContact is already %@", inContact, metaContact);
		return NO;
	}

	//we only allow group->meta->contact, not group->meta->meta->contact
	NSParameterAssert([metaContact canContainObject:inContact]);
	
	BOOL success;
	
	//Remove the object from its previous containing groups
	if (inContact.groups.count)
		[self _moveContactLocally:inContact fromGroups:inContact.groups toGroups:[NSSet set]];
	
	//AIMetaContact will handle reassigning the list object's grouping to being itself
	if ((success = [metaContact addObject:inContact])) {
		[contactToMetaContactLookupDict setObject:metaContact forKey:[inContact internalObjectID]];
		
		[self _didChangeContainer:metaContact object:inContact];

		//Ensure the metacontact ends up in the appropriate groups
		[metaContact restoreGrouping];
	}
	
	return success;
}

- (void)removeContact:(AIListContact *)inContact fromMetaContact:(AIMetaContact *)metaContact
{
	AILogWithSignature(@"%@: Remove %@", metaContact, inContact);

	//we only allow group->meta->contact, not group->meta->meta->contact
	NSParameterAssert(![inContact conformsToProtocol:@protocol(AIContainingObject)]);
	
	NSString			*metaContactInternalObjectID = [metaContact internalObjectID];
	
	//Get the dictionary of all metaContacts
	NSMutableDictionary *allMetaContactsDict = [adium.preferenceController preferenceForKey:KEY_METACONTACT_OWNERSHIP
																   group:PREF_GROUP_CONTACT_LIST];
	
	//Load the array for the metaContact
	NSArray *containedContactsArray = [allMetaContactsDict objectForKey:metaContactInternalObjectID];
	
	//Enumerate it, looking only for the appropriate type of containedContactDict
	
	NSString	*listObjectUID = inContact.UID;
	NSString	*listObjectServiceID = inContact.service.serviceID;
	
	NSDictionary *containedContactDict = nil;
	for (containedContactDict in containedContactsArray) {
		if ([[containedContactDict objectForKey:UID_KEY] isEqualToString:listObjectUID] &&
			[[containedContactDict objectForKey:SERVICE_ID_KEY] isEqualToString:listObjectServiceID]) {
			break;
		}
	}
	
	//If we found a matching dict (referring to our contact in the old metaContact), remove it and store the result
	if (containedContactDict) {
		NSMutableArray		*newContainedContactsArray;
		NSMutableDictionary	*newAllMetaContactsDict;
		
		newContainedContactsArray = [containedContactsArray mutableCopy];
		[newContainedContactsArray removeObjectIdenticalTo:containedContactDict];
		
		newAllMetaContactsDict = [allMetaContactsDict mutableCopy];
		[newAllMetaContactsDict setObject:newContainedContactsArray
								   forKey:metaContactInternalObjectID];
		
		[self _saveMetaContacts:newAllMetaContactsDict];
		
		[newContainedContactsArray release];
		[newAllMetaContactsDict release];
	}

	/* Remove all contacts matching this service/UID from the metacontact */
	[contactPropertiesObserverManager delayListObjectNotifications];

	for (AIListContact *matchingContact in [self allContactsWithService:inContact.service UID:inContact.UID]) {
		if ([metaContact removeObject:matchingContact]) {
			[contactPropertiesObserverManager _updateAllAttributesOfObject:inContact];
			[self _didChangeContainer:metaContact object:inContact];
		}		
	}

	[contactPropertiesObserverManager _updateAllAttributesOfObject:metaContact];
	[contactPropertiesObserverManager endListObjectNotificationsDelay];
}

/*!
 * @brief Determine the existing metacontact into which a grouping of UIDs and services would be placed
 *
 * @param UIDsArray NSArray of UIDs
 * @param servicesArray NSArray of serviceIDs corresponding to entries in UIDsArray
 * 
 * @result Either the existing AIMetaContact -[self groupUIDs:forServices:usingMetaContactHint:] would return if passed a nil metaContactHint,
 *         or nil (if no existing metacontact would be used).
 */
- (AIMetaContact *)knownMetaContactForGroupingUIDs:(NSArray *)UIDsArray forServices:(NSArray *)servicesArray
{
	AIMetaContact	*metaContact = nil;
	NSInteger count = [UIDsArray count];
	
	for (NSInteger i = 0; i < count; i++) {
		if ((metaContact = [contactToMetaContactLookupDict objectForKey:[AIListObject internalObjectIDForServiceID:[servicesArray objectAtIndex:i]
																											   UID:[UIDsArray objectAtIndex:i]]])) {
			break;
		}
	}
	
	return metaContact;
}

/*!
 * @brief Groups UIDs for services into a single metacontact
 *
 * UIDsArray and servicesArray should be a paired set of arrays, with each index corresponding to
 * a UID and a service, respectively, which together define a contact which should be included in the grouping.
 *
 * Assumption: This is only called after the contact list is finished loading, which occurs via
 * -(void)controllerDidLoad above.
 *
 * @param UIDsArray NSArray of UIDs
 * @param servicesArray NSArray of serviceIDs corresponding to entries in UIDsArray
 * @param metaContactHint If passed, an AIMetaContact to use for the grouping if an existing one isn't found. If nil, a new metacontact will be craeted in that case.
 */
- (AIMetaContact *)groupUIDs:(NSArray *)UIDsArray forServices:(NSArray *)servicesArray usingMetaContactHint:(AIMetaContact *)metaContactHint
{
	NSMutableSet *internalObjectIDs = [[NSMutableSet alloc] init];
	AIMetaContact *metaContact = nil;
	NSString *internalObjectID;
	NSInteger count = [UIDsArray count];
	
	/* Build an array of all contacts matching this description (multiple accounts on the same service listing
	 * the same UID mean that we can have multiple AIListContact objects with a UID/service combination)
	 */
	for (NSUInteger i = 0; i < count; i++) {
		NSString	*serviceID = [servicesArray objectAtIndex:i];
		NSString	*UID = [UIDsArray objectAtIndex:i];
		
		internalObjectID = [AIListObject internalObjectIDForServiceID:serviceID
																  UID:UID];
		if(!metaContact) {
			metaContact = [contactToMetaContactLookupDict objectForKey:internalObjectID];
		}
		
		[internalObjectIDs addObject:internalObjectID];
	}
	
	if ([internalObjectIDs count] > 1) {
		//Create a new metaContact is we didn't find one and weren't supplied a hint
		if (!metaContact && !(metaContact = metaContactHint)) {
			AILogWithSignature(@"New metacontact to group %@ on %@", UIDsArray, servicesArray);
			metaContact = [self metaContactWithObjectID:nil];
		}
		
		for (internalObjectID in internalObjectIDs) {
			AIListObject	*existingObject;
			if ((existingObject = [self existingListObjectWithUniqueID:internalObjectID])) {
				/* If there is currently an object (or multiple objects) matching this internalObjectID
				 * we should add immediately.
				 */
				NSAssert([metaContact canContainObject:existingObject], @"Attempting to add something metacontacts can't hold to a metacontact");
				[self addContact:(id)existingObject
					  toMetaContact:metaContact];	
			} else {
				/* If no objects matching this internalObjectID exist, we can simply add to the 
				 * contactToMetaContactLookupDict for use if such an object is created later.
				 */
				[contactToMetaContactLookupDict setObject:metaContact
												   forKey:internalObjectID];			
			}
		}
	}

	[internalObjectIDs release];
	
	return metaContact;
}

/* @brief Group an NSArray of AIListContacts, returning the meta contact into which they are added.
 *
 * This will reuse an existing metacontact (for one of the contacts in the array) if possible.
 * @param contactsToGroupArray Contacts to group together
 */
- (AIMetaContact *)groupContacts:(NSArray *)contactsToGroupArray
{
	AIMetaContact   *metaContact = nil;

	//Look for a metacontact we were passed directly
	for (AIListContact *listContact in contactsToGroupArray) {
		if ([listContact isKindOfClass:[AIMetaContact class]]) {
			metaContact = (AIMetaContact *)listContact;
			break;
		}
	}

	//If we weren't passed a metacontact, look for an existing metacontact associated with a passed contact
	if (!metaContact) {
		for (AIListContact *listContact in contactsToGroupArray) {
			if (![listContact isKindOfClass:[AIMetaContact class]] &&
				(metaContact = [contactToMetaContactLookupDict objectForKey:[listContact internalObjectID]])) {
					break;
			}
		}
	}

	//Create a new metaContact is we didn't find one.
	if (!metaContact) {
		metaContact = [self metaContactWithObjectID:nil];
		AILogWithSignature(@"Created new metacontact %@ for grouping %@", metaContact, contactsToGroupArray);
	} else {
		AILogWithSignature(@"Existing metacontact %@ will now gain %@", metaContact, contactsToGroupArray);
	}
	
	/* Add all these contacts to our MetaContact.
	 * Some may already be present, but that's fine, as nothing will happen.
	 */
	for (AIListContact *listContact in contactsToGroupArray) {
		[self addContact:listContact toMetaContact:metaContact];
		
		if ([listContact isKindOfClass:[AIMetaContact class]] && listContact != metaContact) {
			/* If adding a metacontact to another metacontact, its contents will be recursively added.
			 * The original metacontact must then be destroyed lest it give rise to a zombie metacontact apocalypse.
			 */
			[self explodeMetaContact:(AIMetaContact *)listContact];
		}
	}
	
	AILogWithSignature(@"Completed groupContacts; metaContact is %@", metaContact);

	return metaContact;
}

- (void)explodeMetaContact:(AIMetaContact *)metaContact
{
	AILogWithSignature(@"Exploding %@", metaContact);

	//Remove the objects within it from being inside it
	[contactPropertiesObserverManager delayListObjectNotifications];
	NSArray	*containedObjects = metaContact.containedObjects;
	
	NSMutableDictionary *allMetaContactsDict = [[adium.preferenceController preferenceForKey:KEY_METACONTACT_OWNERSHIP
																						 group:PREF_GROUP_CONTACT_LIST] mutableCopy];
	
	for (AIListContact *object in containedObjects) {
		//Remove from the contactToMetaContactLookupDict first so we don't try to reinsert into this metaContact
		[contactToMetaContactLookupDict removeObjectForKey:[object internalObjectID]];
		
		[self removeContact:object fromMetaContact:metaContact];
	}
	
	//Then, procede to remove the metaContact
	
	//Protect!
	[metaContact retain];
	
	//Remove it from its containing groups (no contained contacts == present in no groups)
	[metaContact restoreGrouping];
	
	NSString	*metaContactInternalObjectID = [metaContact internalObjectID];
	
	//Remove our reference to it internally
	[metaContactDict removeObjectForKey:metaContactInternalObjectID];
	
	//Remove it from the preferences dictionary
	[allMetaContactsDict removeObjectForKey:metaContactInternalObjectID];
	
	//Save the updated allMetaContactsDict which no longer lists the metaContact
	[self _saveMetaContacts:allMetaContactsDict];
	
	[contactPropertiesObserverManager endListObjectNotificationsDelay];
	
	//Protection is overrated.
	[metaContact release];
	[allMetaContactsDict release];
}

- (void)_saveMetaContacts:(NSDictionary *)allMetaContactsDict
{
	AILog(@"MetaContacts: Saving!");
	[adium.preferenceController setPreference:allMetaContactsDict
										 forKey:KEY_METACONTACT_OWNERSHIP
										  group:PREF_GROUP_CONTACT_LIST];
	[adium.preferenceController setPreference:[allMetaContactsDict allKeys]
										 forKey:KEY_FLAT_METACONTACTS
										  group:PREF_GROUP_CONTACT_LIST];
}

#pragma mark Preference observing
/*!
 * @brief Preferences changed
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (key &&
		![key isEqualToString:KEY_HIDE_CONTACTS] &&
		![key isEqualToString:KEY_SHOW_OFFLINE_CONTACTS] &&
		![key isEqualToString:KEY_USE_OFFLINE_GROUP] &&
		![key isEqualToString:KEY_HIDE_CONTACT_LIST_GROUPS]) {
		return;
	}

	BOOL shouldUseOfflineGroup = ((![[prefDict objectForKey:KEY_HIDE_CONTACTS] boolValue] ||
								   [[prefDict objectForKey:KEY_SHOW_OFFLINE_CONTACTS] boolValue]) &&
								  [[prefDict objectForKey:KEY_USE_OFFLINE_GROUP] boolValue]);
	
	if (shouldUseOfflineGroup != self.useOfflineGroup || !key) {
		self.useOfflineGroup = shouldUseOfflineGroup;
		
		if (self.useOfflineGroup)
			[contactPropertiesObserverManager registerListObjectObserver:self];
		
		[contactPropertiesObserverManager updateAllListObjectsForObserver:self];	
		
		if (!self.useOfflineGroup)
			[contactPropertiesObserverManager unregisterListObjectObserver:self];    
	}
}

/*!
 * @brief Move contacts to and from the offline group as necessary as their online state changes.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ((!inModifiedKeys || [inModifiedKeys containsObject:@"isOnline"]) && [inObject isKindOfClass:[AIListContact class]]) {
		[((AIListContact *)inObject).parentContact restoreGrouping];
	}
	
	return nil;
}

#pragma mark Contact Sorting

//Sort the entire contact list
- (void)sortContactList
{
	[self sortContactLists:contactLists];
}

- (void)sortContactLists:(NSArray *)lists
{
	for(AIContactList *list in lists) {
		[list sort];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:Contact_OrderChanged object:nil];
}

//Sort an individual object
- (void)sortListObject:(AIListObject *)inObject
{
	if ([contactPropertiesObserverManager shouldDelayUpdates]) {
		[contactPropertiesObserverManager noteContactChanged:inObject];

	} else {
		for (AIListGroup *group in inObject.groups) {
			//Sort the groups containing this object
			[group sortListObject:inObject];
			[[NSNotificationCenter defaultCenter] postNotificationName:Contact_OrderChanged object:group];
		}
	}
}

#pragma mark Contact List Access

@synthesize contactList;

/*!
 * @brief Return an array of all contact list groups
 */
- (NSArray *)allGroups
{
	return [groupDict allValues];
}

/*!
 * @brief Returns a flat array of all contacts
 *
 * This does not include metacontacts
 */
- (NSArray *)allContacts
{
	NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];

	for (AIListContact *contact in self.contactEnumerator) {
		/* We want only contacts, not metacontacts. For a given contact, -[contact parentContact] could be used to access the meta. */
		if (![contact conformsToProtocol:@protocol(AIContainingObject)])
			[result addObject:contact];
	}
	
	return result;
}

/*!
 * @brief Returns a flat array of all bookmarks.
 */
- (NSArray *)allBookmarks
{
	return [[[bookmarkDict allValues] copy] autorelease];
}

/*!
 * @brief Returns a flat array of all metacontacts
 */
- (NSArray *)allMetaContacts
{
	return [metaContactDict allValues];
}

//Return a flat array of all the objects in a group on an account (and all subgroups, if desired)
- (NSArray *)allContactsInObject:(id<AIContainingObject>)inGroup onAccount:(AIAccount *)inAccount
{
	NSParameterAssert(inGroup != nil);
	
	NSMutableArray	*contactArray = [NSMutableArray array];    
	
	for (AIListObject *object in inGroup) {
		if ([object conformsToProtocol:@protocol(AIContainingObject)]) {
			[contactArray addObjectsFromArray:[self allContactsInObject:(id<AIContainingObject>)object
															  onAccount:inAccount]];
		} else if ([object isMemberOfClass:[AIListContact class]] && (!inAccount || ([(AIListContact *)object account] == inAccount)))
			[contactArray addObject:object];
	}
	
	return contactArray;
}

#pragma mark Contact List Menus

//Returns a menu containing all the groups within a group
//- Selector called on group selection is selectGroup:
//- The menu items represented object is the group it represents
- (NSMenu *)groupMenuWithTarget:(id)target
{
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
	[menu setAutoenablesItems:NO];
	    
    // Separate groups by the contact list they're on.
    NSMutableDictionary *groupsByList = [NSMutableDictionary dictionaryWithCapacity:contactLists.count];
	for (AIListGroup *group in self.allGroups) {
		if (group != self.offlineGroup) {
            NSMutableArray *groups = [groupsByList objectForKey:group.contactList.UID];
            if (!groups) {
                groups = [NSMutableArray array];
                [groupsByList setObject:groups forKey:group.contactList.UID];
            }
            [groups addObject:group];
		}
	}
    
    // Now traverse the contactLists array in order and build a menu showing the groups in each list with separators in between.
    NSInteger i = 0;
    for (AIContactList *list in contactLists) {
        NSMutableArray *groups = [groupsByList objectForKey:list.UID];
        [groups sortUsingActiveSortControllerInContainer:list];
        for (AIListGroup *group in groups) {
            NSMenuItem	*menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:group.displayName
                                                                                        target:target
                                                                                        action:@selector(selectGroup:)
                                                                                 keyEquivalent:@""];
            [menuItem setRepresentedObject:group];
            [menu addItem:menuItem];
            [menuItem release];
        }
                
        i++;

        // Add the separator unless this is the last list.
        if (i < contactLists.count) {
            [menu addItem:[NSMenuItem separatorItem]];
        }

    }
    
	
	return [menu autorelease];
}

#pragma mark Retrieving Specific Contacts

/*!
 * @brief Change the UID for a contact
 *
 * @param UID The new UID to set
 * @param contact The contact whose UID is going to be changed
 *
 * Preserves our reference to the contact as the UID changes, allowing us to continue 
 * returning it when asked about the new UID in the future.
 */
- (void)setUID:(NSString *)UID forContact:(AIListContact *)contact
{
	[contact retain];
	
	// Remove the old value, its internal ID is going to change.
	[contactDict removeObjectForKey:contact.internalUniqueObjectID];
	
	// Set the UID.
	[contact setUID:UID];
	
	// Add it back int othe dict.
	[contactDict setObject:contact forKey:contact.internalUniqueObjectID];
	
	[contact release];
}

- (AIListContact *)contactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID
{
	if (!(inUID && [inUID length] && inService)) return nil; //Ignore invalid requests
	
	AIListContact	*contact = nil;
	NSString		*key = [AIListContact internalUniqueObjectIDForService:inService
															account:inAccount
																UID:inUID];
	contact = [contactDict objectForKey:key];
	if (!contact) {
		//Create
		contact = [[AIListContact alloc] initWithUID:inUID account:inAccount service:inService];
		
		//Check to see if we should add to a metaContact
		AIMetaContact *metaContact = [contactToMetaContactLookupDict objectForKey:[contact internalObjectID]];
		if (metaContact) {
			/* We already know to add this object to the metaContact, since we did it before with another object,
			 but this particular listContact is new and needs to be added directly to the metaContact
			 (on future launches, the metaContact will obtain it automatically since all contacts matching this UID
			 and serviceID should be included). */
			[self _performAddContact:contact toMetaContact:metaContact];
		}
		
		//Set the contact as mobile if it is a phone number
		if ([inUID hasPrefix:@"+"]) {
			[contact setIsMobile:YES notify:NotifyNever];
		}
		
		//Add
		[contactDict setObject:contact forKey:key];

		//Do the update thing
		[contactPropertiesObserverManager _updateAllAttributesOfObject:contact];

		[contact release];
	}
	
	return contact;
}

- (void)accountDidStopTrackingContact:(AIListContact *)inContact
{
	[[inContact retain] autorelease];

	for (id<AIContainingObject> container in inContact.containingObjects) {
		[container removeObjectAfterAccountStopsTracking:inContact];
	}

	[contactDict removeObjectForKey:inContact.internalUniqueObjectID];
}

/*!
 * @brief Find an existing bookmark
 *
 * Finds an existing bookmark for a given AIChat
 */
- (AIListBookmark *)existingBookmarkForChat:(AIChat *)inChat
{
	return [self existingBookmarkForChatName:inChat.name
								   onAccount:inChat.account
							chatCreationInfo:inChat.chatCreationDictionary];
}

/*!
 * @brief Find an existing bookmark
 *
 * Finds an existing bookmark for given information.
 */
- (AIListBookmark *)existingBookmarkForChatName:(NSString *)inName
									  onAccount:(AIAccount *)inAccount
							   chatCreationInfo:(NSDictionary *)inCreationInfo
{
	AIListBookmark *existingBookmark = nil;
	
	for(AIListBookmark *listBookmark in self.allBookmarks) {
		if([listBookmark.name isEqualToString:[inAccount.service normalizeChatName:inName]] &&
			listBookmark.account == inAccount &&
			((!listBookmark.chatCreationDictionary && !inCreationInfo) ||
			 ([listBookmark.chatCreationDictionary isEqualToDictionary:inCreationInfo]))) {
			existingBookmark = listBookmark;
			break;
		}
	}
	
	return existingBookmark;
}


/*!
 * @brief Find or create a bookmark for a chat
 */
- (AIListBookmark *)bookmarkForChat:(AIChat *)inChat inGroup:(AIListGroup *)group
{
	AIListBookmark *bookmark = [self existingBookmarkForChat:inChat];
	
	if (!bookmark) {
		bookmark = [[[AIListBookmark alloc] initWithChat:inChat] autorelease];
		
		if ([bookmarkDict objectForKey:bookmark.internalObjectID]) {
			// In case we end up with two bookmarks with the same internalObjectID; this should be almost impossible.
			[self removeBookmark:[bookmarkDict objectForKey:bookmark.internalObjectID]];
		}
		
		[bookmarkDict setObject:bookmark forKey:bookmark.internalObjectID];
		
		[bookmark setInitialGroup:group];
		
		[self saveContactList];
	}
	
	[bookmark restoreGrouping];
	
	//Do the update thing
	[contactPropertiesObserverManager _updateAllAttributesOfObject:bookmark];
	
	return bookmark;
}

/*!
 * @brief Remove a bookmark
 */
- (void)removeBookmark:(AIListBookmark *)listBookmark
{
	[self moveContact:listBookmark fromGroups:listBookmark.groups intoGroups:[NSSet set]];
	[bookmarkDict removeObjectForKey:listBookmark.internalObjectID];
	
	[self saveContactList];
}

- (AIListContact *)existingContactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID
{
	if (inService && [inUID length]) {
		return [contactDict objectForKey:[AIListContact internalUniqueObjectIDForService:inService
											account:inAccount
											    UID:inUID]];
	}
	return nil;
}

/*!
 * @brief Return a set of all contacts with a specified UID and service
 *
 * @param service The AIService in question
 * @param inUID The UID, which should be normalized (lower case, no spaces, etc.) as appropriate for the service
 */
- (NSSet *)allContactsWithService:(AIService *)service UID:(NSString *)inUID
{
	NSMutableSet	*returnContactSet = [NSMutableSet set];

	for (AIAccount *account in [adium.accountController accountsCompatibleWithService:service]) {
		AIListContact *listContact = [self existingContactWithService:service
														account:account
															UID:inUID];
		
		if (listContact) {
			[returnContactSet addObject:listContact];
		}
	}
	
	return returnContactSet;
}

- (AIListObject *)existingListObjectWithUniqueID:(NSString *)uniqueID
{	
	//Contact
	for (AIListObject *listObject in contactDict.objectEnumerator) {
		if ([listObject.internalObjectID isEqualToString:uniqueID]) return listObject;
	}
	
	//Group
	for (AIListGroup *listObject in groupDict.objectEnumerator) {
		if ([listObject.internalObjectID isEqualToString:uniqueID]) return listObject;
	}
	
	//Metacontact
	for (AIMetaContact *listObject in metaContactDict.objectEnumerator) {
		if ([listObject.internalObjectID isEqualToString:uniqueID]) return listObject;
	}
	
	return nil;
}

/*!
 * @brief Get the best AIListContact to send a given content type to a contat
 *
 * The resulting AIListContact will be the most available individual contact (not metacontact) on the best account to
 * receive the specified content type.
 *
 * @result The contact, or nil if it is impossible to send inType to inContact
 */
- (AIListContact *)preferredContactForContentType:(NSString *)inType forListContact:(AIListContact *)inContact
{
	if ([inContact isKindOfClass:[AIMetaContact class]])
		inContact = [(AIMetaContact *)inContact preferredContactForContentType:inType];

	/* Find the best account for talking to this contact, and return an AIListContact on that account.
	 * We'll get nil if no account can send inType to inContact.
	 */
	AIAccount *account = [adium.accountController preferredAccountForSendingContentType:inType toContact:inContact];

	if (account)
		return [self contactWithService:inContact.service account:account UID:inContact.UID];

	return nil;
}

//XXX - This is ridiculous.
- (AIListContact *)preferredContactWithUID:(NSString *)inUID andServiceID:(NSString *)inService forSendingContentType:(NSString *)inType
{
	AIService		*theService = [adium.accountController firstServiceWithServiceID:inService];
	AIListContact	*tempListContact = [[AIListContact alloc] initWithUID:inUID
																service:theService];
	AIAccount		*account = [adium.accountController preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																				 toContact:tempListContact];
	[tempListContact release];

	return [self contactWithService:theService account:account UID:inUID];
}


/*!
 * @brief Watch outgoing content, remembering the user's choice of destination contact for contacts within metaContacts
 *
 * If the destination contact's parent contact differs from the destination contact itself, the chat is with a metaContact.
 * If that metaContact's preferred destination for messaging isn't the same as the contact which was just messaged,
 * update the preference so that a new chat with this metaContact would default to the proper contact.
 */
- (void)didSendContent:(NSNotification *)notification
{
	AIChat			*chat = [[notification userInfo] objectForKey:@"AIChat"];
	AIListContact	*destContact = chat.listObject;
	AIListContact	*metaContact = destContact.metaContact;
	
	if (!metaContact) 
		return;
	
	NSString	*destinationInternalObjectID = destContact.internalObjectID;
	NSString	*currentPreferredDestination = [metaContact preferenceForKey:KEY_PREFERRED_DESTINATION_CONTACT 
                                                                    group:PREF_GROUP_OBJECT_STATUS_CACHE];
	
	if (![destinationInternalObjectID isEqualToString:currentPreferredDestination]) {
		[metaContact setPreference:destinationInternalObjectID
							forKey:KEY_PREFERRED_DESTINATION_CONTACT
							 group:PREF_GROUP_OBJECT_STATUS_CACHE];
	}
}

#pragma mark Retrieving Groups

//Retrieve a group from the contact list (Creating if necessary)
- (AIListGroup *)groupWithUID:(NSString *)groupUID
{
	NSParameterAssert(groupUID != nil);
	
	//Return our root group if it is requested. 
	if ([groupUID isEqualToString:ADIUM_ROOT_GROUP_NAME])
		return [self contactList];
	
	AIListGroup		*group = nil;
	if (!(group = [groupDict objectForKey:[groupUID lowercaseString]])) {
		//Create
		group = [[AIListGroup alloc] initWithUID:groupUID];
		
		//Add
		//Update afterwards, in case it's being called inside updateListObject already.
		[contactPropertiesObserverManager performSelector:@selector(_updateAllAttributesOfObject:) withObject:group afterDelay:0.0];
		[groupDict setObject:group forKey:[groupUID lowercaseString]];
		
		//Add to the contact list
		[contactList addObject:group];
		[self _didChangeContainer:contactList object:group];
		[group release];
	}
	
	return group;
}

#pragma mark Contact list editing
- (void)removeListGroup:(AIListGroup *)group
{
	NSMutableSet *accountsToIgnore = nil;

	for (AIAccount *account in adium.accountController.accounts) {
		if (account.online) {
			if ([account willDeleteGroup:group] == AIAccountGroupDeletionShouldIgnoreContacts) {
				if (!accountsToIgnore)
					accountsToIgnore = [NSMutableSet set];

				[accountsToIgnore addObject:account];
			}
		}
	}

	AIContactList	*containingObject = group.contactList;

	//Remove all the contacts from this group
	for (AIListContact *contact in group.containedObjects) {
		if ([contact isKindOfClass:[AIMetaContact class]]) {
			/* Look at each contact within the metaContact */
			for (AIListContact *containedContact in (AIMetaContact *)contact) {
				/* Remove it from the group if that contact's account isn't within accountstoIgnore */
				if (![accountsToIgnore containsObject:containedContact.account])
					[containedContact removeFromGroup:group];
			}
			
		} else {
			/* Remove it from the group if the contact's account isn't within accountstoIgnore */
			if (![accountsToIgnore containsObject:contact.account])
				[contact removeFromGroup:group];
		}
	}
	
	//Delete the group from all active accounts
	for (AIAccount *account in adium.accountController.accounts) {
		if (account.online) {
			[account deleteGroup:group];
		}
	}
	
	//Then, procede to delete the group
	[group retain];
	[containingObject removeObject:group];
	[groupDict removeObjectForKey:[group.UID lowercaseString]];
	[self _didChangeContainer:containingObject object:group];
	[group release];
}

- (void)requestAddContactWithUID:(NSString *)contactUID service:(AIService *)inService account:(AIAccount *)inAccount
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:contactUID
																	   forKey:UID_KEY];
	if (inService) [userInfo setObject:inService forKey:@"AIService"];
	if (inAccount) [userInfo setObject:inAccount forKey:@"AIAccount"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:Contact_AddNewContact
											  object:nil
											userInfo:userInfo];
}

- (void)moveContact:(AIListContact *)contact fromGroups:(NSSet *)oldGroups intoGroups:(NSSet *)groups
{
	AILogWithSignature(@"moveContact %@ [meta=%p; contained by %@; %@] from %@ into %@", 
					   contact, 
					   contact.metaContact, contact.containingObjects, (contact.existsServerside ? @"exists serverside" : @"does NOT exist serverside"),
					   oldGroups,groups);

	[contactPropertiesObserverManager delayListObjectNotifications];
	if (contact.metaContact) {
		AIMetaContact *meta = contact.metaContact;
		//Remove from the contactToMetaContactLookupDict first so we don't try to reinsert into this metaContact
		[contactToMetaContactLookupDict removeObjectForKey:contact.internalObjectID];
		
		[self removeContact:contact fromMetaContact:meta];
	}
	
	if (contact.existsServerside) {
		/* This is an AIListContact for an online account; just perform the serverside move */
		if (contact.account.online)
			[contact.account moveListObjects:[NSArray arrayWithObject:contact] fromGroups:oldGroups toGroups:groups];
	} else {
		[self _moveContactLocally:contact fromGroups:oldGroups toGroups:groups];
		
		if ([contact conformsToProtocol:@protocol(AIContainingObject)]) {
			//This is a meta contact, move the objects within it.
			for (AIListContact *child in (id<AIContainingObject>)contact) {
				//Only move the contact if it is actually listed on the account in question
				if (child.account.online && !child.isStranger)
					[child.account moveListObjects:[NSArray arrayWithObject:child] fromGroups:oldGroups toGroups:groups];
			}
		}		
	}
	[contactPropertiesObserverManager endListObjectNotificationsDelay];
}

#pragma mark Detached Contact Lists
- (void)moveGroup:(AIListGroup *)group fromContactList:(AIContactList *)oldContactList toContactList:(AIContactList *)newContactList
{
	if (![oldContactList containsObject:group] || [newContactList containsObject:group]) {
		return;
	}
	
	[oldContactList removeObject:group];
	[newContactList addObject:group];

	[[NSNotificationCenter defaultCenter] postNotificationName:Contact_ListChanged
														object:newContactList
													  userInfo:nil];
	
	if (!oldContactList.containedObjects.count) {
		[[NSNotificationCenter defaultCenter] postNotificationName:DetachedContactListIsEmpty
															object:oldContactList
														  userInfo:nil];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:Contact_ListChanged
															object:oldContactList
														  userInfo:nil];
	}
}

/*!
 * @returns Empty contact list
 */
- (AIContactList *)createDetachedContactList
{
	static NSInteger count = 0;
	AIContactList *list = [[AIContactList alloc] initWithUID:[NSString stringWithFormat:@"Detached%ld",count++]];
	[contactLists addObject:list];
	[list release];
	return list;
}

/*!
 * @brief Removes detached contact list
 */
- (void)removeDetachedContactList:(AIContactList *)detachedList
{
	[contactLists removeObject:detachedList];
}

@end

@implementation AIContactController (ContactControllerHelperAccess)
- (NSEnumerator *)contactEnumerator
{
	return [contactDict objectEnumerator];
}
- (NSEnumerator *)groupEnumerator
{
	return [groupDict objectEnumerator];
}
- (NSEnumerator *)bookmarkEnumerator
{
	return [bookmarkDict objectEnumerator];
}
@end
