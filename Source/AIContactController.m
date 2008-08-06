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

// $Id$

#import "AIContactController.h"

#import "AISCLViewPlugin.h"
#import "AIContactHidingController.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AILoginControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>

#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIApplicationAdditions.h>
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

#import "AdiumAuthorization.h"

#import "AdiumContactPropertiesObserverManager.h"

#define KEY_FLAT_GROUPS					@"FlatGroups"			//Group storage
#define KEY_FLAT_CONTACTS				@"FlatContacts"			//Contact storage
#define KEY_FLAT_METACONTACTS			@"FlatMetaContacts"		//Metacontact objectID storage
#define KEY_BOOKMARKS					@"Bookmarks"

#define	OBJECT_STATUS_CACHE				@"Object Status Cache"


#define TOP_METACONTACT_ID				@"TopMetaContactID"
#define KEY_IS_METACONTACT				@"isMetaContact"
#define KEY_OBJECTID					@"objectID"
#define KEY_METACONTACT_OWNERSHIP		@"MetaContact Ownership"
#define CONTACT_DEFAULT_PREFS			@"ContactPrefs"

#define	SHOW_GROUPS_MENU_TITLE			AILocalizedString(@"Show Groups",nil)
#define	HIDE_GROUPS_MENU_TITLE			AILocalizedString(@"Hide Groups",nil)

#define SHOW_GROUPS_IDENTIFER			@"ShowGroups"

#define SERVICE_ID_KEY					@"ServiceID"
#define UID_KEY							@"UID"

@interface AIContactController (PRIVATE)
- (AIListGroup *)processGetGroupNamed:(NSString *)serverGroup;

- (void)saveContactList;
- (void)prepareContactInfo;

- (NSMenu *)menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)inGroup withTarget:(id)target firstLevel:(BOOL)firstLevel;
- (void)_menuOfAllGroups:(NSMenu *)menu forGroup:(AIListGroup *)group withTarget:(id)target level:(int)level;

- (NSArray *)_arrayRepresentationOfListObjects:(NSArray *)listObjects;
- (void)_loadGroupsFromArray:(NSArray *)array;

- (void)_loadBookmarks;
- (NSArray *)allBookmarks;

- (void)_listChangedGroup:(AIListObject *)group object:(AIListObject *)object;
- (void)prepareShowHideGroups;
- (void)_performChangeOfUseContactListGroups;

- (void)_positionObject:(AIListObject *)listObject atIndex:(int)index inObject:(AIListObject<AIContainingObject> *)group;
- (void)_moveObjectServerside:(AIListObject *)listObject toGroup:(AIListGroup *)group;
- (void)_renameGroup:(AIListGroup *)listGroup to:(NSString *)newName;

//MetaContacts
- (BOOL)_restoreContactsToMetaContact:(AIMetaContact *)metaContact;
- (void)_restoreContactsToMetaContact:(AIMetaContact *)metaContact fromContainedContactsArray:(NSArray *)containedContactsArray;
- (void)addListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact;
- (BOOL)_performAddListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact;
- (void)removeListObject:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact;
- (void)_loadMetaContactsFromArray:(NSArray *)array;
- (void)_saveMetaContacts:(NSDictionary *)allMetaContactsDict;
- (void)breakdownAndRemoveMetaContact:(AIMetaContact *)metaContact;
- (void)_storeListObject:(AIListObject *)listObject inMetaContact:(AIMetaContact *)metaContact;

- (void)_addMenuItemsFromArray:(NSArray *)contactArray toMenu:(NSMenu *)contactMenu target:(id)target offlineContacts:(BOOL)offlineContacts;

@end

@implementation AIContactController

//init
- (id)init
{
	if ((self = [super init])) {
		//
		sortControllerArray = [[NSMutableArray alloc] init];
		activeSortController = nil;
				
		//
		contactDict = [[NSMutableDictionary alloc] init];
		groupDict = [[NSMutableDictionary alloc] init];
		metaContactDict = [[NSMutableDictionary alloc] init];
		contactToMetaContactLookupDict = [[NSMutableDictionary alloc] init];
		detachedContactLists = [[NSMutableArray alloc] init];

		contactPropertiesObserverManager = [[AdiumContactPropertiesObserverManager alloc] init];
	}
	
	return self;
}

//finish initing
- (void)controllerDidLoad
{	
	//Default contact preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_CONTACT_LIST];
	
	contactList = [[AIListGroup alloc] initWithUID:ADIUM_ROOT_GROUP_NAME];
	//Root is always "expanded"
	[contactList setExpanded:YES];
	
	//Show Groups menu item
	[self prepareShowHideGroups];
	
	//Observe content (for preferredContactForContentType:forListContact:)
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(didSendContent:)
                                       name:CONTENT_MESSAGE_SENT
                                     object:nil];
	
	[self loadContactList];
	[self sortContactList];
	
	adiumAuthorization = [[AdiumAuthorization alloc] init];
	
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
	
	contactHidingController = [[AIContactHidingController alloc]init];
}

//close
- (void)controllerWillClose
{
	[self saveContactList];
}

//dealloc
- (void)dealloc
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
    [contactList release];
	
	[sortControllerArray release];
	
	[contactDict release];
	[groupDict release];
	[metaContactDict release];
	[contactToMetaContactLookupDict release];
	[detachedContactLists release];
	
	[adiumAuthorization release];
	
	[contactHidingController release];
	[contactPropertiesObserverManager release];

    [super dealloc];
}

- (void)clearAllMetaContactData
{
	NSString		*path;
	NSDictionary	*metaContactDictCopy = [metaContactDict copy];
	NSEnumerator	*enumerator;
	AIMetaContact	*metaContact;
	
	if ([metaContactDictCopy count]) {
		[self delayListObjectNotifications];
		
		//Remove all the metaContacts to get any existing objects out of them
		enumerator = [metaContactDictCopy objectEnumerator];
		while ((metaContact = [enumerator nextObject])) {
			[self breakdownAndRemoveMetaContact:metaContact];
		}
		
		[self endListObjectNotificationsDelay];
	}
	
	[metaContactDict release]; metaContactDict = [[NSMutableDictionary alloc] init];
	[contactToMetaContactLookupDict release]; contactToMetaContactLookupDict = [[NSMutableDictionary alloc] init];
	
	//Clear the preferences for good measure
	[[adium preferenceController] setPreference:nil
										 forKey:KEY_FLAT_METACONTACTS
										  group:PREF_GROUP_CONTACT_LIST];
	[[adium preferenceController] setPreference:nil
										 forKey:KEY_METACONTACT_OWNERSHIP
										  group:PREF_GROUP_CONTACT_LIST];
	
	//Clear out old metacontact files
	path = [[[adium loginController] userDirectory] stringByAppendingPathComponent:OBJECT_PREFS_PATH];
	[[NSFileManager defaultManager] removeFilesInDirectory:path
												withPrefix:@"MetaContact"
											 movingToTrash:NO];
	[[NSFileManager defaultManager] removeFilesInDirectory:[adium cachesPath]
												withPrefix:@"MetaContact"
											 movingToTrash:NO];
	
	[metaContactDictCopy release];
}

//Local Contact List Storage -------------------------------------------------------------------------------------------
#pragma mark Local Contact List Storage
//Load the contact list
- (void)loadContactList
{
	//We must load all the groups before loading contacts for the ordering system to work correctly.
	[self _loadMetaContactsFromArray:[[adium preferenceController] preferenceForKey:KEY_FLAT_METACONTACTS
																			  group:PREF_GROUP_CONTACT_LIST]];
	[self _loadBookmarks];
}

//Save the contact list
- (void)saveContactList
{
	NSEnumerator *enumerator = [groupDict objectEnumerator];
	AIListGroup	 *listGroup;
	
	while ((listGroup = [enumerator nextObject])) {
		[listGroup setPreference:[NSNumber numberWithBool:[listGroup isExpanded]]
						  forKey:@"IsExpanded"
						   group:PREF_GROUP_CONTACT_LIST];
	}
	
	NSMutableArray *bookmarks = [NSMutableArray array];
	AIListObject *listObject;
	enumerator = [[self allBookmarks] objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		if ([listObject isKindOfClass:[AIListBookmark class]]) {
			[bookmarks addObject:[NSKeyedArchiver archivedDataWithRootObject:listObject]];
		}
	}
	
	[[adium preferenceController] setPreference:bookmarks
										 forKey:KEY_BOOKMARKS
										  group:PREF_GROUP_CONTACT_LIST];
}

- (void)_loadBookmarks
{
	NSEnumerator	*enumerator = [[[adium preferenceController] preferenceForKey:KEY_BOOKMARKS
																		 group:PREF_GROUP_CONTACT_LIST] objectEnumerator];
	NSData *data;
	while ((data = [enumerator nextObject])) {
		AIListBookmark	*bookmark;
		//As a bookmark is initialized, it will add itself to the contact list in the right place
		bookmark = [NSKeyedUnarchiver unarchiveObjectWithData:data];	
		
		//It's a newly created object, so set its initial attributes
		[contactPropertiesObserverManager _updateAllAttributesOfObject:bookmark];
	}
}

- (void)_loadMetaContactsFromArray:(NSArray *)array
{
	NSEnumerator	*enumerator = [array objectEnumerator];
	NSString		*identifier;
	
	while ((identifier = [enumerator nextObject])) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSNumber *objectID = [NSNumber numberWithInt:[[[identifier componentsSeparatedByString:@"-"] objectAtIndex:1] intValue]];
		[self metaContactWithObjectID:objectID];
		[pool release];
	}
}

//Flattened array of the contact list content
- (NSArray *)_arrayRepresentationOfListObjects:(NSArray *)listObjects
{
	NSMutableArray	*array = [NSMutableArray array];
	NSEnumerator	*enumerator = [listObjects objectEnumerator];;
	AIListObject	*object;
	
	//Create temporary strings outside the loop
	NSString	*Group = @"Group";
	NSString	*Type = @"Type";
	NSString	*Expanded = @"Expanded";
	
	while ((object = [enumerator nextObject])) {
		[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						  Group, Type,
						  [object UID], UID_KEY,
						  [NSNumber numberWithBool:[(AIListGroup *)object isExpanded]], Expanded,
						  nil]];
	}
	
	return array;
}


#pragma mark Contact Grouping
//Contact Grouping -----------------------------------------------------------------------------------------------------

//Redetermine the local grouping of a contact in response to server grouping information or an external change
- (void)listObjectRemoteGroupingChanged:(AIListContact *)inContact
{
	AIListObject<AIContainingObject>	*containingObject;
	NSString							*remoteGroupName = [inContact remoteGroupName];
	[inContact retain];
	
	containingObject = [inContact containingObject];
	
	if ([containingObject isKindOfClass:[AIMetaContact class]]) {
		
		/* If inContact's containingObject is a metaContact, and that metaContact has no containingObject,
		 * use inContact's remote grouping as the metaContact's grouping.
		 */
		if (![containingObject containingObject] && [remoteGroupName length]) {
			//If no similar objects exist, we add this contact directly to the list
			//Create a group for the contact even if contact list groups aren't on,
			//otherwise requests for all the contact list groups will return nothing
			AIListGroup *localGroup, *contactGroup = [self groupWithUID:remoteGroupName];
			
			localGroup = (useContactListGroups ?
						  ((useOfflineGroup && ![inContact online]) ? [self offlineGroup] : contactGroup) :
						  contactList);
			
			[localGroup addObject:containingObject];
			
			[self _listChangedGroup:localGroup object:containingObject];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"Contact_ListChanged"
																object:[localGroup containingObject]
															  userInfo:nil];
			//NSLog(@"listObjectRemoteGroupingChanged: %@ is in %@, which was moved to %@",inContact,containingObject,localGroup);
		}
		
	} else {
		//If we have a remoteGroupName, add the contact locally to the list
		if (remoteGroupName) {
			//Create a group for the contact even if contact list groups aren't on,
			//otherwise requests for all the contact list groups will return nothing
			AIListGroup *localGroup, *contactGroup = [self groupWithUID:remoteGroupName];
			
			localGroup = (useContactListGroups ?
						  ((useOfflineGroup && ![inContact online]) ? [self offlineGroup] : contactGroup) :
						  contactList);
			
			//NSLog(@"listObjectRemoteGroupingChanged: %@: remoteGroupName %@ --> %@",inContact,remoteGroupName,localGroup);
				
			[self _moveContactLocally:inContact
							  toGroup:localGroup];
			
			if([[localGroup containingObject] isKindOfClass:[AIListGroup class]])
				[(AIListGroup *)[localGroup containingObject] visibilityOfContainedObject:localGroup changedTo:YES];
			
		} else {
			//If !remoteGroupName, remove the contact from any local groups
			if (containingObject) {
				//Remove the object
				[(AIListGroup *)containingObject removeObject:inContact];
				
				[self _listChangedGroup:(AIListGroup *)containingObject object:inContact];
				
				//NSLog(@"listObjectRemoteGroupingChanged: %@: -- !remoteGroupName so removed from %@",inContact,containingObject);
			}
		}
	}
	
	BOOL	isCurrentlyAStranger = [inContact isStranger];
	if ((isCurrentlyAStranger && (remoteGroupName != nil)) ||
		(!isCurrentlyAStranger && (remoteGroupName == nil))) {
		[inContact setValue:(remoteGroupName ? [NSNumber numberWithBool:YES] : nil)
							forProperty:@"NotAStranger"
							notify:NotifyLater];
		[inContact notifyOfChangedPropertiesSilently:YES];
	}
	
	[inContact release];
}

- (void)_moveContactLocally:(AIListContact *)listContact toGroup:(AIListGroup *)localGroup
{
	AIListObject	*containingObject;
	AIListObject	*existingObject;
	BOOL			performedGrouping = NO;
	
	//Protect with a retain while we are removing and adding the contact to our arrays
	[listContact retain];
	
	//XXX
	//	AILog(@"Moving %@ to %@",listContact,localGroup);
	
	//Remove this object from any local groups we have it in currently
	if ((containingObject = [listContact containingObject]) &&
		([containingObject isKindOfClass:[AIListGroup class]])) {
		//Remove the object
		[(AIListGroup *)containingObject removeObject:listContact];
		[self _listChangedGroup:(AIListGroup *)containingObject object:listContact];
	}
	
	if ([listContact canJoinMetaContacts]) {
		if ((existingObject = [localGroup objectWithService:[listContact service] UID:[listContact UID]])) {
			//If an object exists in this group with the same UID and serviceID, create a MetaContact
			//for the two.
			[self groupListContacts:[NSArray arrayWithObjects:listContact,existingObject,nil]];
			performedGrouping = YES;
			
		} else {
			AIMetaContact	*metaContact;
			
			//If no object exists in this group which matches, we should check if there is already
			//a MetaContact holding a matching ListContact, since we should include this contact in it
			//If we found a metaContact to which we should add, do it.
			if ((metaContact = [contactToMetaContactLookupDict objectForKey:[listContact internalObjectID]])) {
				//XXX
				//			AILog(@"Found an existing metacontact; adding %@ to %@",listContact,metaContact);
				
				[self addListObject:listContact toMetaContact:metaContact];
				performedGrouping = YES;
			}
		}
	}
	
	if (!performedGrouping) {
		//If no similar objects exist, we add this contact directly to the list
		[localGroup addObject:listContact];
		
		//Add
		[self _listChangedGroup:localGroup object:listContact];
	}
	
	//Cleanup
	[listContact release];
}

- (AIListGroup *)remoteGroupForContact:(AIListContact *)inContact
{
	AIListGroup		*group;
	
	if ([inContact isKindOfClass:[AIMetaContact class]]) {
		//For a metaContact, the closest we have to a remote group is the group it is within locally
		group = [(AIMetaContact *)inContact parentGroup];
		
	} else {
		NSString	*remoteGroup = [inContact remoteGroupName];
		group = (remoteGroup ? [self groupWithUID:remoteGroup] : nil);
	}
	
	return group;
}

//Post a list grouping changed notification for the object and group
- (void)_listChangedGroup:(AIListObject *)group object:(AIListObject *)object
{
	if ([contactPropertiesObserverManager updatesAreDelayed]) {
		[contactPropertiesObserverManager noteContactChanged:object];

	} else {
		[[adium notificationCenter] postNotificationName:Contact_ListChanged
												  object:object
												userInfo:(group ? [NSDictionary dictionaryWithObject:group forKey:@"ContainingGroup"] : nil)];
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
	NSEnumerator	*enumerator;
	AIListObject	*listObject;
	
	[self delayListObjectNotifications];
	
	//Store the preference
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:!useContactListGroups]
										 forKey:KEY_HIDE_CONTACT_LIST_GROUPS
										  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	
	//Configure the sort controller to force ignoring of groups as appropriate
	[[self activeSortController] forceIgnoringOfGroups:(useContactListGroups ? NO : YES)];
	
	enumerator = [[[[contactList containedObjects] copy] autorelease] objectEnumerator];
	
	if (useContactListGroups) { /* We are now using contact list groups, but we weren't before. */
		
		//Restore the grouping of all root-level contacts
		while ((listObject = [enumerator nextObject])) {
			if ([listObject isKindOfClass:[AIListContact class]]) {
				[(AIListContact *)listObject restoreGrouping];
			}
		}
		
	} else { /* We are no longer using contact list groups, but we were before. */
		
		while ((listObject = [enumerator nextObject])) {
			if ([listObject isKindOfClass:[AIListGroup class]]) {
				NSArray			*containedObjects;
				NSEnumerator	*groupEnumerator;
				AIListObject	*containedListObject;
				
				containedObjects = [[(AIListGroup *)listObject containedObjects] copy];
				groupEnumerator = [containedObjects objectEnumerator];
				while ((containedListObject = [groupEnumerator nextObject])) {
					if ([containedListObject isKindOfClass:[AIListContact class]]) {
						[self _moveContactLocally:(AIListContact *)containedListObject
										  toGroup:contactList];
					}
				}
				[containedObjects release];
			}
		}
	}
	
	//Stop delaying object notifications; this will automatically resort the contact list, so we're done.
	[self endListObjectNotificationsDelay];
}

- (void)prepareShowHideGroups
{
	//Load the preference
	useContactListGroups = ![[[adium preferenceController] preferenceForKey:KEY_HIDE_CONTACT_LIST_GROUPS
																	  group:PREF_GROUP_CONTACT_LIST_DISPLAY] boolValue];
	
	//Show offline contacts menu item
    menuItem_showGroups = [[NSMenuItem alloc] initWithTitle:(useContactListGroups ? HIDE_GROUPS_MENU_TITLE : SHOW_GROUPS_MENU_TITLE)
													 target:self
													 action:@selector(toggleShowGroups:)
											  keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem_showGroups toLocation:LOC_View_Toggles];
	
	//Toolbar
	NSToolbarItem	*toolbarItem;
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:SHOW_GROUPS_IDENTIFER
														  label:AILocalizedString(@"Show Groups",nil)
												   paletteLabel:AILocalizedString(@"Toggle Groups Display",nil)
														toolTip:AILocalizedString(@"Toggle display of groups",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:(useContactListGroups ?
																					 @"togglegroups_transparent" :
																					 @"togglegroups")
																		   forClass:[self class]
																		 loadLazily:YES]
														 action:@selector(toggleShowGroupsToolbar:)
														   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ContactList"];
}

- (IBAction)toggleShowGroups:(id)sender
{
	//Flip-flop.
	useContactListGroups = !useContactListGroups;
	[menuItem_showGroups setTitle:(useContactListGroups ? HIDE_GROUPS_MENU_TITLE : SHOW_GROUPS_MENU_TITLE)];

	//Update the contact list.  Do it on the next run loop for better menu responsiveness, as it may be a lengthy procedure.
	[self performSelector:@selector(_performChangeOfUseContactListGroups)
			   withObject:nil
			   afterDelay:0.000001];
}

- (IBAction)toggleShowGroupsToolbar:(id)sender
{
	[self toggleShowGroups:sender];
	
	[sender setImage:[NSImage imageNamed:(useContactListGroups ?
										  @"togglegroups_transparent" :
										  @"togglegroups")
								forClass:[self class]]];
}

- (BOOL)useOfflineGroup
{
	return useOfflineGroup;
}

- (void)setUseOfflineGroup:(BOOL)inFlag
{
	if (inFlag != useOfflineGroup) {
		useOfflineGroup = inFlag;
		
		if (useOfflineGroup) {
			[self registerListObjectObserver:self];	
		} else {
			[self updateAllListObjectsForObserver:self];
			[self unregisterListObjectObserver:self];	
		}
	}
}

- (AIListGroup *)offlineGroup
{
	return [self groupWithUID:AILocalizedString(@"Offline", "Name of offline group")];
}

#pragma mark Meta Contacts
//Meta Contacts --------------------------------------------------------------------------------------------------------
/*!
 * @brief Create or load a metaContact
 *
 * @param inObjectID The objectID of an existing but unloaded metaContact, or nil to create and save a new metaContact
 */
- (AIMetaContact *)metaContactWithObjectID:(NSNumber *)inObjectID
{
	NSString		*metaContactDictKey;
	AIMetaContact   *metaContact;
	BOOL			shouldRestoreContacts = YES;
	
	//If no object ID is provided, use the next available object ID
	//(MetaContacts should always have an individually unique object id)
	if (!inObjectID) {
		int topID = [[[adium preferenceController] preferenceForKey:TOP_METACONTACT_ID
															  group:PREF_GROUP_CONTACT_LIST] intValue];
		inObjectID = [NSNumber numberWithInt:topID];
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:([inObjectID intValue] + 1)]
											 forKey:TOP_METACONTACT_ID
											  group:PREF_GROUP_CONTACT_LIST];
		
		//No reason to waste time restoring contacts when none are in the meta contact yet.
		shouldRestoreContacts = NO;
	}
	
	//Look for a metacontact with this object ID.  If none is found, create one
	//and add its contained contacts to it.
	metaContactDictKey = [AIMetaContact internalObjectIDFromObjectID:inObjectID];
	
	metaContact = [metaContactDict objectForKey:metaContactDictKey];
	if (!metaContact) {
		metaContact = [[AIMetaContact alloc] initWithObjectID:inObjectID];
		
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
	NSDictionary	*allMetaContactsDict = [[adium preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																				 group:PREF_GROUP_CONTACT_LIST];
	NSArray			*containedContactsArray = [allMetaContactsDict objectForKey:[metaContact internalObjectID]];
	BOOL			restoredContacts;
	
	if ([containedContactsArray count]) {
		[self _restoreContactsToMetaContact:metaContact
				 fromContainedContactsArray:containedContactsArray];
		
		restoredContacts = YES;
		
	} else {
		restoredContacts = NO;
	}
	
	return restoredContacts;
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
	NSEnumerator		*enumerator = [containedContactsArray objectEnumerator];
	NSDictionary		*containedContactDict;
	
	while ((containedContactDict = [enumerator nextObject])) {
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
- (void)addListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact
{
	if (!listObject || [listObject isKindOfClass:[AIListGroup class]]) {
		//I can't think of why one would want to add an entire group to a metacontact. Let's say you can't.
		NSLog(@"Warning: addListObject:toMetaContact: Attempted to add %@ to %@",listObject,metaContact);
		return;
	}
	
	if (listObject == metaContact) return;
	
	//If listObject contains other contacts, perform addListObject:toMetaContact: recursively
	if ([listObject conformsToProtocol:@protocol(AIContainingObject)]) {
		NSEnumerator	*enumerator = [[[[(AIListObject<AIContainingObject> *)listObject containedObjects] copy] autorelease] objectEnumerator];
		AIListObject	*someObject;
		
		while ((someObject = [enumerator nextObject]))
			[self addListObject:someObject toMetaContact:metaContact];
		
	} else {
		//Obtain any metaContact this listObject is currently within, so we can remove it later
		AIMetaContact *oldMetaContact = [contactToMetaContactLookupDict objectForKey:[listObject internalObjectID]];
		
		if ([self _performAddListObject:listObject toMetaContact:metaContact]) {
			//If this listObject was not in this metaContact in any form before, store the change
			if (metaContact != oldMetaContact) {
				//Remove the list object from any other metaContact it is in at present
				if (oldMetaContact)
					[self removeListObject:listObject fromMetaContact:oldMetaContact];
				
				[self _storeListObject:listObject inMetaContact:metaContact];

				//Do the update thing
				[contactPropertiesObserverManager _updateAllAttributesOfObject:metaContact];
			}
		}
	}
}

- (void)_storeListObject:(AIListObject *)listObject inMetaContact:(AIMetaContact *)metaContact
{
	//we only allow group->meta->contact, not group->meta->meta->contact
	NSParameterAssert(![listObject conformsToProtocol:@protocol(AIContainingObject)]);
	
	//	AILog(@"MetaContacts: Storing %@ in %@",listObject, metaContact);
	NSDictionary		*containedContactDict;
	NSMutableDictionary	*allMetaContactsDict;
	NSMutableArray		*containedContactsArray;
	
	NSString			*metaContactInternalObjectID = [metaContact internalObjectID];
	
	//Get the dictionary of all metaContacts
	allMetaContactsDict = [[[adium preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
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
							[[listObject service] serviceID],SERVICE_ID_KEY,
							[listObject UID],UID_KEY,nil];
	
	//Only add if this dict isn't already in the array
	if (containedContactDict && ([containedContactsArray indexOfObject:containedContactDict] == NSNotFound)) {
		[containedContactsArray addObject:containedContactDict];
		[allMetaContactsDict setObject:containedContactsArray forKey:metaContactInternalObjectID];
		
		//Save
		[self _saveMetaContacts:allMetaContactsDict];
		
		[[adium contactAlertsController] mergeAndMoveContactAlertsFromListObject:listObject
																  intoListObject:metaContact];
	}
	
	[allMetaContactsDict release];
	[containedContactsArray release];
}

//Actually adds a list object to a meta contact. No preferences are changed.
//Attempts to add the list object, causing group reassignment and updates our contactToMetaContactLookupDict
//for quick lookup of the MetaContact given a AIListContact uniqueObjectID if successful.
- (BOOL)_performAddListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact
{
	//we only allow group->meta->contact, not group->meta->meta->contact
	AIListObject<AIContainingObject>	*localGroup;
	BOOL								success;
	
	localGroup = [listObject containingObject];
	
	//Remove the object from its previous containing group
	if (localGroup && (localGroup != metaContact)) {
		[localGroup removeObject:listObject];
		[self _listChangedGroup:localGroup object:listObject];
	}
	
	//AIMetaContact will handle reassigning the list object's grouping to being itself
	if ((success = [metaContact addObject:listObject])) {
		[contactToMetaContactLookupDict setObject:metaContact forKey:[listObject internalObjectID]];
		
		[self _listChangedGroup:metaContact object:listObject];
		//If the metaContact isn't in a group yet, use the group of the object we just added
		if ((![metaContact containingObject]) && localGroup) {
			//Add the new meta contact to our list
			[(AIMetaContact *)localGroup addObject:metaContact];
			[self _listChangedGroup:localGroup object:metaContact];
		}
	}
	
	return success;
}

- (void)removeAllListObjectsMatching:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact
{
	NSEnumerator	*enumerator;
	AIListObject	*theObject;
	
	enumerator = [[self allContactsWithService:[listObject service]
										   UID:[listObject UID]
								  existingOnly:YES] objectEnumerator];
	
	//Remove from the contactToMetaContactLookupDict first so we don't try to reinsert into this metaContact
	[contactToMetaContactLookupDict removeObjectForKey:[listObject internalObjectID]];
	
	[self delayListObjectNotifications];
	while ((theObject = [enumerator nextObject])) {
		[self removeListObject:theObject fromMetaContact:metaContact];
	}
	[self endListObjectNotificationsDelay];
}

- (void)removeListObject:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact
{
	//we only allow group->meta->contact, not group->meta->meta->contact
	NSParameterAssert(![listObject conformsToProtocol:@protocol(AIContainingObject)]);
	
	NSEnumerator		*enumerator;
	NSArray				*containedContactsArray;
	NSDictionary		*containedContactDict = nil;
	NSMutableDictionary	*allMetaContactsDict;
	NSString			*metaContactInternalObjectID = [metaContact internalObjectID];
	
	//Get the dictionary of all metaContacts
	allMetaContactsDict = [[adium preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																   group:PREF_GROUP_CONTACT_LIST];
	
	//Load the array for the metaContact
	containedContactsArray = [allMetaContactsDict objectForKey:metaContactInternalObjectID];
	
	//Enumerate it, looking only for the appropriate type of containedContactDict
	enumerator = [containedContactsArray objectEnumerator];
	
	NSString	*listObjectUID = [listObject UID];
	NSString	*listObjectServiceID = [[listObject service] serviceID];
	
	while ((containedContactDict = [enumerator nextObject])) {
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
	
	//The listObject can be within the metaContact without us finding a containedContactDict if we are removing multiple
	//listContacts referring to the same UID & serviceID combination - that is, on multiple accounts on the same service.
	//We therefore request removal of the object regardless of the if (containedContactDict) check above.
	[metaContact removeObject:listObject];
	
	[self _listChangedGroup:metaContact object:listObject];
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
	int				count = [UIDsArray count];
	
	for (int i = 0; i < count; i++) {
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
	NSMutableSet	*internalObjectIDs = [[NSMutableSet alloc] init];
	AIMetaContact	*metaContact = nil;
	NSEnumerator	*enumerator;
	NSString		*internalObjectID;
	int				count = [UIDsArray count];
	int				i;
	
	/* Build an array of all contacts matching this description (multiple accounts on the same service listing
	 * the same UID mean that we can have multiple AIListContact objects with a UID/service combination)
	 */
	for (i = 0; i < count; i++) {
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
		
		enumerator = [internalObjectIDs objectEnumerator];
		while ((internalObjectID = [enumerator nextObject])) {
			AIListObject	*existingObject;
			if ((existingObject = [self existingListObjectWithUniqueID:internalObjectID])) {
				/* If there is currently an object (or multiple objects) matching this internalObjectID
				 * we should add immediately.
				 */
				[self addListObject:existingObject
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
- (AIMetaContact *)groupListContacts:(NSArray *)contactsToGroupArray
{
	NSEnumerator	*enumerator;
	AIListContact   *listContact;
	AIMetaContact   *metaContact = nil;

	//Look for a metacontact we were passed directly
	enumerator = [contactsToGroupArray objectEnumerator];
	while (!metaContact && (listContact = [enumerator nextObject])) {
		if ([listContact isKindOfClass:[AIMetaContact class]]) {
			metaContact = (AIMetaContact *)listContact;
		}
	}

	//If we weren't passed a metacontact, look for an existing metacontact associated with a passed contact
	if (!metaContact) {
		enumerator = [contactsToGroupArray objectEnumerator];
		while (!metaContact && (listContact = [enumerator nextObject])) {
			if (![listContact isKindOfClass:[AIMetaContact class]]) {
				metaContact = [contactToMetaContactLookupDict objectForKey:[listContact internalObjectID]];
			}
		}
	}

	//Create a new metaContact is we didn't find one.
	if (!metaContact) {
		AILogWithSignature(@"New metacontact to group %@", contactsToGroupArray);
		metaContact = [self metaContactWithObjectID:nil];
	}
	
	/* Add all these contacts to our MetaContact.
	 * Some may already be present, but that's fine, as nothing will happen.
	 */
	enumerator = [contactsToGroupArray objectEnumerator];
	while ((listContact = [enumerator nextObject])) {
		[self addListObject:listContact toMetaContact:metaContact];
	}
	
	return metaContact;
}

- (void)breakdownAndRemoveMetaContact:(AIMetaContact *)metaContact
{
	//Remove the objects within it from being inside it
	NSArray								*containedObjects = [[metaContact containedObjects] copy];
	NSEnumerator						*metaEnumerator = [containedObjects objectEnumerator];
	AIListObject<AIContainingObject>	*containingObject = [metaContact containingObject];
	AIListObject						*object;
	
	NSMutableDictionary *allMetaContactsDict = [[[adium preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																						 group:PREF_GROUP_CONTACT_LIST] mutableCopy];
	
	while ((object = [metaEnumerator nextObject])) {
		
		//Remove from the contactToMetaContactLookupDict first so we don't try to reinsert into this metaContact
		[contactToMetaContactLookupDict removeObjectForKey:[object internalObjectID]];
		
		[self removeListObject:object fromMetaContact:metaContact];
	}
	
	//Then, procede to remove the metaContact
	
	//Protect!
	[metaContact retain];
	
	//Remove it from its containing group
	[containingObject removeObject:metaContact];
	
	NSString	*metaContactInternalObjectID = [metaContact internalObjectID];
	
	//Remove our reference to it internally
	[metaContactDict removeObjectForKey:metaContactInternalObjectID];
	
	//Remove it from the preferences dictionary
	[allMetaContactsDict removeObjectForKey:metaContactInternalObjectID];
	
	//XXX - contactToMetaContactLookupDict
	
	//Post the list changed notification for the old containingObject
	[self _listChangedGroup:containingObject object:metaContact];
	
	//Save the updated allMetaContactsDict which no longer lists the metaContact
	[self _saveMetaContacts:allMetaContactsDict];
	
	//Protection is overrated.
	[metaContact release];
	[containedObjects release];
	[allMetaContactsDict release];
}

- (void)_saveMetaContacts:(NSDictionary *)allMetaContactsDict
{
	AILog(@"MetaContacts: Saving!");
	[[adium preferenceController] setPreference:allMetaContactsDict
										 forKey:KEY_METACONTACT_OWNERSHIP
										  group:PREF_GROUP_CONTACT_LIST];
	[[adium preferenceController] setPreference:[allMetaContactsDict allKeys]
										 forKey:KEY_FLAT_METACONTACTS
										  group:PREF_GROUP_CONTACT_LIST];
}

//Sort list objects alphabetically by their display name
int contactDisplayNameSort(AIListObject *objectA, AIListObject *objectB, void *context)
{
	return [[objectA displayName] caseInsensitiveCompare:[objectB displayName]];
}

//Return either the highest metaContact containing this list object, or the list object itself.  Appropriate for when
//preferences should be read from/to the most generalized contact possible.
- (AIListObject *)parentContactForListObject:(AIListObject *)listObject
{
	if ([listObject isKindOfClass:[AIListContact class]]) {
		//Find the highest-up metaContact
		AIListObject	*containingObject;
		while ([(containingObject = [listObject containingObject]) isKindOfClass:[AIMetaContact class]]) {
			listObject = (AIMetaContact *)containingObject;
		}
	}
	
	return listObject;
}

#pragma mark Preference observing
/*!
 * @brief Preferences changed
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[self setUseOfflineGroup:((![[prefDict objectForKey:KEY_HIDE_CONTACTS] boolValue] ||
							   [[prefDict objectForKey:KEY_SHOW_OFFLINE_CONTACTS] boolValue]) &&
							  [[prefDict objectForKey:KEY_USE_OFFLINE_GROUP] boolValue])];
}

/*!
 * @brief Move contacts to and from the offline group as necessary as their online state changes.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if (!inModifiedKeys ||
		[inModifiedKeys containsObject:@"Online"]) {
		
		if ([inObject isKindOfClass:[AIListContact class]]) {			
			//If this contact is not its own parent contact, don't bother since we'll get an update for the parent if appropriate
			if (inObject == [(AIListContact *)inObject parentContact]) {
				if (useOfflineGroup) {
					AIListObject *containingObject = [inObject containingObject];
					
					if ([inObject online] &&
						(containingObject == [self offlineGroup])) {
						[(AIListContact *)inObject restoreGrouping];
						
					} else if (![inObject online] &&
							   containingObject &&
							   (containingObject != [self offlineGroup])) {
						[self _moveContactLocally:(AIListContact *)inObject
										  toGroup:[self offlineGroup]];
					}
					
				} else {
					if ([inObject containingObject] == [self offlineGroup]) {
						[(AIListContact *)inObject restoreGrouping];
					}
				}
			}
		}
	}
	
	return nil;
}

//Contact Sorting --------------------------------------------------------------------------------
#pragma mark Contact Sorting
//Register sorting code
- (void)registerListSortController:(AISortController *)inController
{
    [sortControllerArray addObject:inController];
}
- (NSArray *)sortControllerArray
{
    return sortControllerArray;
}

//Set and get the active sort controller
- (void)setActiveSortController:(AISortController *)inController
{
    activeSortController = inController;
	
	[activeSortController didBecomeActive];
	
	//The newly-active sort controller needs to know whether it should be forced to ignore groups
	[[self activeSortController] forceIgnoringOfGroups:(useContactListGroups ? NO : YES)];
	
    //Resort the list
    [self sortContactList];
}
- (AISortController *)activeSortController
{
    return activeSortController;
}

//Sort the entire contact list
- (void)sortContactList
{
	[self sortContactLists:[detachedContactLists arrayByAddingObject:contactList]];
}

- (void)sortContactLists:(NSArray *)lists
{
	NSEnumerator *listEnum = [lists objectEnumerator];
	AIListGroup *list;
	while((list = [listEnum nextObject])) {
		[list sortGroupAndSubGroups:YES sortController:activeSortController];
	}
	[[adium notificationCenter] postNotificationName:Contact_OrderChanged object:nil];
}

//Sort an individual object
- (void)sortListObject:(AIListObject *)inObject
{
	if ([contactPropertiesObserverManager updatesAreDelayed]) {
		[contactPropertiesObserverManager noteContactChanged:inObject];

	} else {
		AIListObject		*group = [inObject containingObject];
		
		if ([group isKindOfClass:[AIListGroup class]]) {
			//Sort the groups containing this object
			[(AIListGroup *)group sortListObject:inObject sortController:activeSortController];
			[[adium notificationCenter] postNotificationName:Contact_OrderChanged object:inObject];
		}
	}
}

//Contact List Access --------------------------------------------------------------------------------------------------
#pragma mark Contact List Access
//Returns the main contact list group
- (AIListGroup *)contactList
{
    return contactList;
}

/*!
 * @brief Return an array of all contact list groups
 */
- (NSArray *)allGroups
{
	return [groupDict allValues];
}

/*!
 * @brief Returns a flat array of all contacts
 */
- (NSMutableArray *)allContacts
{
	return [self allContactsOnAccount:nil];
}

/*!
 * @brief Returns a flat array of all contacts on a given account
 * 
 * @param inAccount The account whose contacts are desired, or nil to match every account
 * @result Every contact in the global contactDict which isn't a metacontact and matches the specified account criterion
 */
- (NSMutableArray *)allContactsOnAccount:(AIAccount *)inAccount
{
	NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];
	
	NSEnumerator *enumerator = [self contactEnumerator];
	AIListContact *contact;
	while ((contact = [enumerator nextObject])) {
		if (!inAccount || ([contact account] == inAccount)) {
			/* We want only contacts, not metacontacts. For a given contact, -[contact parentContact] could be used to access the meta. */
			if (![contact conformsToProtocol:@protocol(AIContainingObject)])
				[result addObject:contact];
		}
	}
	
	return result;
}

//Return a flat array of all the objects in a group on an account (and all subgroups, if desired)
- (NSMutableArray *)allContactsInObject:(AIListObject<AIContainingObject> *)inGroup recurse:(BOOL)recurse onAccount:(AIAccount *)inAccount
{
	NSParameterAssert(inGroup != nil);
	
	NSMutableArray	*contactArray = [NSMutableArray array];    
	
	NSEnumerator *enumerator = [[inGroup containedObjects] objectEnumerator];
	AIListObject *object;
    while ((object = [enumerator nextObject])) {
        if (recurse && [object conformsToProtocol:@protocol(AIContainingObject)]) {
			[contactArray addObjectsFromArray:[self allContactsInObject:(AIListObject<AIContainingObject> *)object
																recurse:recurse
															  onAccount:inAccount]];
		} else if ([object isMemberOfClass:[AIListContact class]] && (!inAccount || ([(AIListContact *)object account] == inAccount)))
			[contactArray addObject:object];
	}
	
	return contactArray;
}

//Return a flat array of all the bookmarks in a group on an account (and all subgroups, if desired)
- (NSMutableArray *)allBookmarksInObject:(AIListObject<AIContainingObject> *)inGroup recurse:(BOOL)recurse onAccount:(AIAccount *)inAccount
{
	NSParameterAssert(inGroup != nil);
	
	NSMutableArray	*bookmarkArray = [NSMutableArray array];    
	
	NSEnumerator *enumerator = [[inGroup containedObjects] objectEnumerator];
	AIListObject *object;
    while ((object = [enumerator nextObject])) {
        if (recurse && [object conformsToProtocol:@protocol(AIContainingObject)]) {
			[bookmarkArray addObjectsFromArray:[self allBookmarksInObject:(AIListObject<AIContainingObject> *)object
																  recurse:recurse
																onAccount:inAccount]];
		} else if ([object isMemberOfClass:[AIListBookmark class]] && (!inAccount || ([(AIListBookmark *)object account] == inAccount))) {
			[bookmarkArray addObject:object];
		}
	}
	
	return bookmarkArray;
}

- (NSArray *)allBookmarks
{
	NSMutableArray *result = [self allBookmarksInObject:contactList recurse:YES onAccount:nil];
	
	/** Could be perfected I'm sure */
	NSEnumerator *enumerator = [detachedContactLists objectEnumerator];
	AIListGroup *detached;
	while((detached = [enumerator nextObject])){
		[result addObjectsFromArray:[self allBookmarksInObject:detached recurse:YES onAccount:nil]];
	}
	
	return result;	
}

//Contact List Menus- --------------------------------------------------------------------------------------------------
#pragma mark Contact List Menus

//Returns a menu containing all the groups within a group
//- Selector called on group selection is selectGroup:
//- The menu items represented object is the group it represents
- (NSMenu *)menuOfAllGroupsInGroup:(AIListGroup *)inGroup withTarget:(id)target
{
	NSMenu	*menu = [[NSMenu alloc] initWithTitle:@""];
	
	[menu setAutoenablesItems:NO];
	[self _menuOfAllGroups:menu forGroup:inGroup withTarget:target level:0];
	
	return [menu autorelease];
}
- (void)_menuOfAllGroups:(NSMenu *)menu forGroup:(AIListGroup *)group withTarget:(id)target level:(int)level
{
	NSMutableArray	*fromGroups;
	NSEnumerator	*detachedEnumerator;
	
	//Passing nil scans the entire contact list
	if (group == nil){
		fromGroups = [NSMutableArray arrayWithArray:detachedContactLists];
		[fromGroups addObject:contactList];
	}else{
		fromGroups = [NSMutableArray arrayWithObject:group];
	}
	
	detachedEnumerator = [fromGroups objectEnumerator];
	
	while((group = [detachedEnumerator nextObject])){
		//Enumerate this group and process all groups we find within it
		NSEnumerator	*enumerator;
		AIListObject	*object;
		enumerator = [[group containedObjects] objectEnumerator];
		while ((object = [enumerator nextObject])) {
			if ([object isKindOfClass:[AIListGroup class]] && object != [self offlineGroup]) {
				NSMenuItem	*menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[object displayName]
																							target:target
																							action:@selector(selectGroup:)
																					 keyEquivalent:@""];
				[menuItem setRepresentedObject:object];
				if ([menuItem respondsToSelector:@selector(setIndentationLevel:)]) {
					[menuItem setIndentationLevel:level];
				}
				[menu addItem:menuItem];
				[menuItem release];
				
				[self _menuOfAllGroups:menu forGroup:(AIListGroup *)object withTarget:target level:level+1];
			}
		}
	}
}


//Returns a menu containing all the objects in a group on an account
//- Selector called on contact selection is selectContact:
//- The menu item's represented object is the contact it represents
- (NSMenu *)menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)inObject withTarget:(id)target{
	return [self menuOfAllContactsInContainingObject:inObject withTarget:target firstLevel:YES];
}
- (NSMenu *)menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)inObject withTarget:(id)target firstLevel:(BOOL)firstLevel
{
    NSEnumerator				*enumerator;
    AIListObject				*object;
	
	//Prepare our menu
	NSMenu *menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];
	
	//Passing nil scans the entire contact list
	if (inObject == nil) inObject = contactList;
	
	//The pull down menu needs an extra item at the top of its root menu to handle the selection.
	if (firstLevel) [menu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	
	//All menu items for all contained objects
	enumerator = [[inObject listContacts] objectEnumerator];
    while ((object = [enumerator nextObject])) {
		NSImage		*menuServiceImage;
		NSMenuItem	*menuItem;
		BOOL		needToCreateSubmenu;
		BOOL		isGroup = [object isKindOfClass:[AIListGroup class]];
		BOOL		isValidGroup = (isGroup &&
									[(AIListGroup *)object containedObjectsCount]);
		
		//We don't want to include empty groups
		if (!isGroup || isValidGroup) {
			
			needToCreateSubmenu = (isValidGroup ||
								   ([object isKindOfClass:[AIMetaContact class]] && ([[(AIMetaContact *)object listContacts] count] > 1)));
			
			
			menuServiceImage = [AIUserIcons menuUserIconForObject:object];
			
			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:(needToCreateSubmenu ?
																					[object displayName] :
																					[object formattedUID])
																			target:target
																			action:@selector(selectContact:)
																	 keyEquivalent:@""];
			
			if (needToCreateSubmenu) {
				[menuItem setSubmenu:[self menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)object withTarget:target firstLevel:NO]];
			}
			
			[menuItem setRepresentedObject:object];
			[menuItem setImage:menuServiceImage];
			[menu addItem:menuItem];
			[menuItem release];
		}
	}
	
	return [menu autorelease];
}

//Retrieving Specific Contacts -----------------------------------------------------------------------------------------
#pragma mark Retrieving Specific Contacts

- (AIListContact *)contactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID
{
    return [self contactWithService:inService account:inAccount UID:inUID usingClass:[AIListContact class]];
}

//Retrieve a contact from the contact list (Creating if necessary)
- (AIListContact *)contactWithService:(AIService *)inService 
							  account:(AIAccount *)inAccount 
								  UID:(NSString *)inUID 
						   usingClass:(Class)ContactClass
{
	if (!(inUID && [inUID length] && inService)) return nil; //Ignore invalid requests
	
	AIListContact	*contact = nil;
	NSString		*key = [ContactClass internalUniqueObjectIDForService:inService
															account:inAccount
																UID:inUID];
	contact = [contactDict objectForKey:key];
	if (!contact) {
		//Create
		contact = [[ContactClass alloc] initWithUID:inUID account:inAccount service:inService];
		
		//Check to see if we should add to a metaContact
		AIMetaContact *metaContact = [contactToMetaContactLookupDict objectForKey:[contact internalObjectID]];
		if (metaContact) {
			/* We already know to add this object to the metaContact, since we did it before with another object,
			 but this particular listContact is new and needs to be added directly to the metaContact
			 (on future launches, the metaContact will obtain it automatically since all contacts matching this UID
			 and serviceID should be included). */
			[self _performAddListObject:contact toMetaContact:metaContact];
		}
		
		//Set the contact as mobile if it is a phone number
		if ([inUID characterAtIndex:0] == '+') {
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

- (void)account:(AIAccount *)account didStopTrackingContact:(AIListContact *)inContact
{
	[[inContact retain] autorelease];
	[contactDict removeObjectForKey:[inContact internalUniqueObjectID]];
}

- (AIListBookmark *)bookmarkForChat:(AIChat *)inChat
{
	AIListBookmark *bookmark = [[AIListBookmark alloc] initWithChat:inChat];
	
	//Do the update thing
	[contactPropertiesObserverManager _updateAllAttributesOfObject:bookmark];
	
	return [bookmark autorelease];
}

- (AIListContact *)existingContactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID usingClass:(Class)ContactClass
{
	if (inService && [inUID length]) {
		return [contactDict objectForKey:[ContactClass internalUniqueObjectIDForService:inService
																				account:inAccount
																					UID:inUID]];
	} else {
		return nil;
	}
}

- (AIListContact *)existingContactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID
{
	return [self existingContactWithService:inService account:inAccount UID:inUID usingClass:[AIListContact class]];
}

/*!
 * @brief Return a set of all contacts with a specified UID and service
 *
 * @param service The AIService in question
 * @param inUID The UID, which should be normalized (lower case, no spaces, etc.) as appropriate for the service
 * @param existingOnly If YES, only pre-existing contacts. If NO, an AIListContact is guaranteed to be returned
 *					   on each compatible account, even if one did not previously exist.
 */
- (NSSet *)allContactsWithService:(AIService *)service UID:(NSString *)inUID existingOnly:(BOOL)existingOnly
{
	NSEnumerator	*enumerator;
	AIAccount		*account;
	NSMutableSet	*returnContactSet = [NSMutableSet set];
	
	enumerator = [[[adium accountController] accountsCompatibleWithService:service] objectEnumerator];
	
	while ((account = [enumerator nextObject])) {
		AIListContact	*listContact;
		
		if (existingOnly) {
			listContact = [self existingContactWithService:service
												   account:account
													   UID:inUID];
		} else {
			listContact = [self contactWithService:service
										   account:account
											   UID:inUID];
		}
		
		if (listContact) {
			[returnContactSet addObject:listContact];
		}
	}
	
	return returnContactSet;
}

- (AIListObject *)existingListObjectWithUniqueID:(NSString *)uniqueID
{
	NSEnumerator	*enumerator;
	AIListObject	*listObject;
	
	//Contact
	enumerator = [contactDict objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		if ([[listObject internalObjectID] isEqualToString:uniqueID]) return listObject;
	}
	
	//Group
	enumerator = [groupDict objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		if ([[listObject internalObjectID] isEqualToString:uniqueID]) return listObject;
	}
	
	//Metacontact
	enumerator = [metaContactDict objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		if ([[listObject internalObjectID] isEqualToString:uniqueID]) return listObject;
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
	AIListContact   *returnContact = nil;
	AIAccount		*account;
	
	if ([inContact containsMultipleContacts]) {
		AIListObject	*preferredContact;
		NSString		*internalObjectID;
		
		/* If we've messaged this object previously, prefer the last contact we sent to if that
		 * contact is currently in the most-available status the metacontact can offer
		 */
        internalObjectID = [inContact preferenceForKey:KEY_PREFERRED_DESTINATION_CONTACT
												 group:OBJECT_STATUS_CACHE];
		
        if ((internalObjectID) &&
			(preferredContact = [self existingListObjectWithUniqueID:internalObjectID]) &&
			([preferredContact isKindOfClass:[AIListContact class]]) &&
			([preferredContact statusSummary] == [inContact statusSummary]) &&
			([inContact isMobile] || ![preferredContact isMobile]) && //Either the parent contact is mobile (so that's the best we have), or the preferred is not.
			([[(AIMetaContact *)inContact containedObjects] containsObject:preferredContact])) {

			returnContact = [self preferredContactForContentType:inType
												  forListContact:(AIListContact *)preferredContact];
        }
		
		/* If the last contact we sent to is not appropriate, use the following algorithm, which differs from -[AIMetaContact preferredContact]
		 * in that it doesn't "like" mobile contacts.
		 *
		 *  1) Prefer available contacts who are not mobile
		 *  2) If no available non-mobile contacts, use the first online contact
		 *  3) If no online contacts, use the metacontact's preferredContact
		 */
		if (!returnContact) {
			//Recurse into metacontacts if necessary
			AIListContact *firstAvailableContact = nil;
			AIListContact *firstNotOfflineContact = nil;
			
			AIListContact *thisContact;
			NSEnumerator *contactsEnum = [[(AIMetaContact *)inContact containedObjects] objectEnumerator];
			while ((thisContact = [contactsEnum nextObject])) {
				AIStatusType statusSummary = [thisContact statusSummary];
				
				if ((statusSummary != AIOfflineStatus) && (statusSummary != AIUnknownStatus)) {
					if (!firstNotOfflineContact) {
						firstNotOfflineContact = thisContact;
					}
					
					if (statusSummary == AIAvailableStatus && ![thisContact isMobile]) {
						if (!firstAvailableContact) {
							firstAvailableContact = thisContact;
						}
						
						break;
					}
				}
			}
			
			returnContact = (firstAvailableContact ?
							 firstAvailableContact :
							 (firstNotOfflineContact ? firstNotOfflineContact : [(AIMetaContact *)inContact preferredContact]));
			
			returnContact = [self preferredContactForContentType:inType forListContact:returnContact];
		}
		
	} else {
		//This contact doesn't contain multiple contacts... but it might still be a metacontact. Do NOT proceed with a metacontact.
		if ([inContact respondsToSelector:@selector(preferredContact)])
			inContact = [inContact performSelector:@selector(preferredContact)];
		
		/* Find the best account for talking to this contact, and return an AIListContact on that account.
		 * We'll get nil if no account can send inType to inContact.
		 */
		account = [[adium accountController] preferredAccountForSendingContentType:inType
																		 toContact:inContact];

		if (account) {
			if ([inContact account] == account) {
				returnContact = inContact;
			} else {
				returnContact = [self contactWithService:[inContact service]
												 account:account
													 UID:[inContact UID]];
			}
		}
 	}

	return returnContact;
}

//Retrieve a list contact matching the UID and serviceID of the passed contact but on the specified account.
//In many cases this will be the same as inContact.
- (AIListContact *)contactOnAccount:(AIAccount *)account fromListContact:(AIListContact *)inContact
{
	if (account && ([inContact account] != account)) {
		return [self contactWithService:[inContact service] account:account UID:[inContact UID]];
	} else {
		return inContact;
	}
}

//XXX - This is ridiculous.
- (AIListContact *)preferredContactWithUID:(NSString *)inUID andServiceID:(NSString *)inService forSendingContentType:(NSString *)inType
{
	AIService		*theService = [[adium accountController] firstServiceWithServiceID:inService];
	AIListContact	*tempListContact = [[AIListContact alloc] initWithUID:inUID
																service:theService];
	AIAccount		*account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
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
	AIListContact	*destContact = [chat listObject];
	AIListContact	*metaContact = [destContact parentContact];
	
	//it's not particularly obvious from the name, but -parentContact can return self
	if (metaContact == destContact) return;
	
	NSString	*destinationInternalObjectID = [destContact internalObjectID];
	NSString	*currentPreferredDestination = [metaContact preferenceForKey:KEY_PREFERRED_DESTINATION_CONTACT
																	group:OBJECT_STATUS_CACHE];
	
	if (![destinationInternalObjectID isEqualToString:currentPreferredDestination]) {
		[metaContact setPreference:destinationInternalObjectID
							forKey:KEY_PREFERRED_DESTINATION_CONTACT
							 group:OBJECT_STATUS_CACHE];
	}
}

//Retrieving Groups ----------------------------------------------------------------------------------------------------
#pragma mark Retrieving Groups

//Retrieve a group from the contact list (Creating if necessary)
- (AIListGroup *)groupWithUID:(NSString *)groupUID
{
	//Return our root group if it is requested. 
	//XXX: is this a good idea? it might semi-mask bugs where we accidentally pass nil
	if (!groupUID || ![groupUID length] || [groupUID isEqualToString:ADIUM_ROOT_GROUP_NAME])
		return [self contactList];
	
	AIListGroup		*group = nil;
	if (!(group = [groupDict objectForKey:[groupUID lowercaseString]])) {
		//Create
		group = [[AIListGroup alloc] initWithUID:groupUID];
		
		//Add
		[contactPropertiesObserverManager _updateAllAttributesOfObject:group];
		[groupDict setObject:group forKey:[groupUID lowercaseString]];
		
		//Add to the contact list
		[contactList addObject:group];
		[self _listChangedGroup:contactList object:group];
		[group release];
	}
	
	return group;
}

- (AIListGroup *)existingGroupWithUID:(NSString *)groupUID
{
	//Return our root group if it is requested
	//XXX: is this a good idea? it might semi-mask bugs where we accidentally pass nil
	if (!groupUID || ![groupUID length] || [groupUID isEqualToString:ADIUM_ROOT_GROUP_NAME])
		return [self contactList];
	
	return [groupDict objectForKey:groupUID];
}

//Contact list editing -------------------------------------------------------------------------------------------------
#pragma mark Contact list editing
- (void)removeListObjects:(NSArray *)objectArray
{
	NSEnumerator	*enumerator = [objectArray objectEnumerator];
	AIListObject	*listObject;
	
	while ((listObject = [enumerator nextObject])) {
		if ([listObject isKindOfClass:[AIMetaContact class]]) {
			NSSet	*objectsToRemove = nil;
			
			//If the metaContact only has one listContact, we will remove that contact from all accounts
			if ([[(AIMetaContact *)listObject listContacts] count] == 1) {
				AIListContact	*listContact = [[(AIMetaContact *)listObject listContacts] objectAtIndex:0];
				
				objectsToRemove = [self allContactsWithService:[listContact service]
														   UID:[listContact UID]
												  existingOnly:YES];
			}
			
			//And actually remove the single contact if applicable
			if (objectsToRemove) {
				[self removeListObjects:[objectsToRemove allObjects]];
			}
			
			//Now break the metaContact down, taking out all contacts and putting them back in the main list
			[self breakdownAndRemoveMetaContact:(AIMetaContact *)listObject];				
			
		} else if ([listObject isKindOfClass:[AIListGroup class]]) {
			AIListObject <AIContainingObject>	*containingObject = [listObject containingObject];
			NSEnumerator	*enumerator;
			AIAccount		*account;
			
			//If this is a group, delete all the objects within it
			[self removeListObjects:[(AIListGroup *)listObject containedObjects]];
			
			//Delete the list off of all active accounts
			enumerator = [[[adium accountController] accounts] objectEnumerator];
			while ((account = [enumerator nextObject])) {
				if ([account online]) {
					[account deleteGroup:(AIListGroup *)listObject];
				}
			}
			
			//Then, procede to delete the group
			[listObject retain];
			[containingObject removeObject:listObject];
			[groupDict removeObjectForKey:[[listObject UID] lowercaseString]];
			[self _listChangedGroup:containingObject object:listObject];
			[listObject release];
			
		} else {
			AIAccount	*account = [(AIListContact *)listObject account];
			if ([account online]) {
				[account removeContacts:[NSArray arrayWithObject:listObject]];
			}
		}
	}
}

- (void)addContacts:(NSArray *)contactArray toGroup:(AIListGroup *)group
{
	NSEnumerator	*enumerator;
	AIListContact	*listObject;
	
	[self delayListObjectNotifications];
	
	enumerator = [contactArray objectEnumerator];
	while ((listObject = [enumerator nextObject])) {
		if(![group containsObject:listObject]) //don't add it if it's already there.
			[[listObject account] addContacts:[NSArray arrayWithObject:listObject] toGroup:group];
	}
	
	[self endListObjectNotificationsDelay];
}

- (void)requestAddContactWithUID:(NSString *)contactUID service:(AIService *)inService account:(AIAccount *)inAccount
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:contactUID
																	   forKey:UID_KEY];
	if (inService) [userInfo setObject:inService forKey:@"AIService"];
	if (inAccount) [userInfo setObject:inAccount forKey:@"AIAccount"];
	
	[[adium notificationCenter] postNotificationName:Contact_AddNewContact
											  object:nil
											userInfo:userInfo];
}

- (void)moveListObjects:(NSArray *)objectArray intoObject:(AIListObject<AIContainingObject> *)group index:(int)index
{
	NSEnumerator	*enumerator;
	AIListContact	*listContact;
	
	[self delayListObjectNotifications];
	
	if ([group respondsToSelector:@selector(setDelayContainedObjectSorting:)]) {
		[(id)group setDelayContainedObjectSorting:YES];
	}
	
	enumerator = [objectArray objectEnumerator];
	while ((listContact = [enumerator nextObject])) {
		[self moveContact:listContact intoObject:group];
		
		//Set the new index / position of the object
		[self _positionObject:listContact atIndex:index inObject:group];
	}
	
	[self endListObjectNotificationsDelay];
	
	if ([group respondsToSelector:@selector(setDelayContainedObjectSorting:)]) {
		[(id)group setDelayContainedObjectSorting:NO];
	}
	
	/*
	 Resort the entire list if we are moving within or between AIListGroup objects
	 (other containing objects such as metaContacts will handle their own sorting).
	 */
	if ([group isKindOfClass:[AIListGroup class]]){
		[(AIListGroup *)group visibilityOfContainedObject:group changedTo:YES];
		[self sortContactLists:[NSArray arrayWithObject:group]];
	}
}

- (void)moveContact:(AIListContact *)listContact intoObject:(AIListObject<AIContainingObject> *)group
{
	//Move the object to the new group only if necessary
	if (group == [listContact containingObject]) return;
	
	if ([group isKindOfClass:[AIListGroup class]]) {
		//Move a contact into a new group
		if ([listContact isKindOfClass:[AIListBookmark class]]) {
			[self _moveContactLocally:listContact toGroup:(AIListGroup *)group];
			
		} else if ([listContact isKindOfClass:[AIMetaContact class]]) {
			//Move the meta contact to this new group
			[self _moveContactLocally:listContact toGroup:(AIListGroup *)group];
			
			NSEnumerator	*enumerator;
			AIListContact	*actualListContact;
			
			//This is a meta contact, move the objects within it.  listContacts will give us a flat array of AIListContacts.
			enumerator = [[(AIMetaContact *)listContact containedObjects] objectEnumerator];
			while ((actualListContact = [enumerator nextObject])) {
				//Only move the contact if it is actually listed on the account in question
				if (![actualListContact isStranger]) {
					[self _moveObjectServerside:actualListContact toGroup:(AIListGroup *)group];
				}
			}
		} else if ([listContact isKindOfClass:[AIListContact class]]) {
			//Move the object
			if ([[listContact parentContact] isKindOfClass:[AIMetaContact class]]) {
				[self removeAllListObjectsMatching:listContact fromMetaContact:(AIMetaContact *)[listContact parentContact]];
			}
			
			[self _moveObjectServerside:listContact toGroup:(AIListGroup *)group];

		} else if ([listContact isKindOfClass:[AIListGroup class]]) {
			// Move contact from one contact list to another
			[(AIListGroup *)listContact moveGroupFrom:[(AIListGroup *)listContact containingObject] to:group];
		} else {
			AILogWithSignature(@"I don't know what to do with %@",listContact);
		}
	} else if ([group isKindOfClass:[AIMetaContact class]]) {
		//Moving a contact into a meta contact
		[self addListObject:listContact toMetaContact:(AIMetaContact *)group];
	}
}

//Move an object to another group
- (void)_moveObjectServerside:(AIListObject *)listObject toGroup:(AIListGroup *)group
{
	AIAccount	*account = [(AIListContact *)listObject account];
	if ([account online]) {
		[account moveListObjects:[NSArray arrayWithObject:listObject] toGroup:group];
	}
}

//Rename a group
- (void)_renameGroup:(AIListGroup *)listGroup to:(NSString *)newName
{
	NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
	AIAccount		*account;
	
	//Since Adium has no memory of what accounts a group is on, we have to send this message to all available accounts
	//The accounts without this group will just ignore it
	while ((account = [enumerator nextObject])) {
		[account renameGroup:listGroup to:newName];
	}
	
	//Remove the old group if it's empty
	if ([listGroup containedObjectsCount] == 0) {
		[self removeListObjects:[NSArray arrayWithObject:listGroup]];
	}
}

//Position a list object within a group
- (void)_positionObject:(AIListObject *)listObject atIndex:(int)index inObject:(AIListObject<AIContainingObject> *)group
{
	if (index == 0) {
		//Moved to the top of a group.  New index is between 0 and the lowest current index
		[listObject setOrderIndex:([group smallestOrder] / 2.0)];
		
	} else if (index >= [group visibleCount]) {
		//Moved to the bottom of a group.  New index is one higher than the highest current index
		[listObject setOrderIndex:([group largestOrder] + 1.0)];
		
	} else {
		//Moved somewhere in the middle.  New index is the average of the next largest and smallest index
		AIListObject	*previousObject = [group objectAtIndex:index-1];
		AIListObject	*nextObject = [group objectAtIndex:index];
		float nextLowest = [previousObject orderIndex];
		float nextHighest = [nextObject orderIndex];
		
		/* XXX - Fixme as per below
		 * It's possible that nextLowest > nextHighest if ordering is not strictly based on the ordering indexes themselves.
		 * For example, a group sorted by status then manually could look like (status - ordering index):
		 *
		 * Away Contact - 100
		 * Away Contact - 120
		 * Offline Contact - 110
		 * Offline Contact - 113
		 * Offline Contact - 125
		 * 
		 * Dropping between Away Contact and Offline Contact should make an Away Contact be > 120 but an Offline Contact be < 110.
		 * Only the sort controller knows the answer as to where this contact should be positioned in the end.
		 */
		//
		[listObject setOrderIndex:((nextHighest + nextLowest) / 2.0)];
	}
}

#pragma mark Authorization
- (id)showAuthorizationRequestWithDict:(NSDictionary *)inDict forAccount:(AIAccount *)inAccount
{
	return [adiumAuthorization showAuthorizationRequestWithDict:inDict forAccount:inAccount];
}

//Detached Contact Lists ----------------------------------------------------------------------------------------------------
#pragma mark Detached Contact Lists

/*!
 * @returns Empty contact list
 */
- (AIListGroup *)createDetachedContactList
{
	static int count = 0;
	AIListGroup * list = [[AIListGroup alloc] initWithUID:[NSString stringWithFormat:@"Detached%d",count++]];
	[detachedContactLists addObject:list];
	[list release];
	return list;
}

/*!
 * @brief Removes detached contact list
 */
- (void)removeDetachedContactList:(AIListGroup *)detachedList
{
	[detachedContactLists removeObject:detachedList];
}

/*!
 * @brief Checks if a particular group is in a detached contact list 
 */
- (BOOL)isGroupDetached:(AIListObject *)inGroup
{
	NSEnumerator		*enumerator = [detachedContactLists objectEnumerator];
	AIListGroup			*group;
	
	while ((group = [enumerator nextObject])) {
		if ([group containsObject:inGroup]) {
			return YES;
		}
	}
	
	return NO;
}

/*!
 * @returns Number of contact lists (ie. both main contact list and all detached contact lists)
 */
- (unsigned)contactListCount
{
	return (contactList != nil) + [detachedContactLists count];
}

#pragma mark Contact Hiding
- (AIContactHidingController *)contactHidingController
{
	return contactHidingController;
}

#pragma mark Properties observation
- (void)delayListObjectNotifications
{
	[contactPropertiesObserverManager delayListObjectNotifications];
}
- (void)endListObjectNotificationsDelay
{
	[contactPropertiesObserverManager endListObjectNotificationsDelay];
}
- (void)delayListObjectNotificationsUntilInactivity
{
	[contactPropertiesObserverManager delayListObjectNotificationsUntilInactivity];	
}
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	[contactPropertiesObserverManager listObjectStatusChanged:inObject modifiedStatusKeys:inModifiedKeys silent:silent];	
}
- (void)listObjectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSSet *)inModifiedKeys
{
	[contactPropertiesObserverManager listObjectAttributesChanged:inObject modifiedKeys:inModifiedKeys];		
}
- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver
{
	[contactPropertiesObserverManager registerListObjectObserver:inObserver];
}
- (void)unregisterListObjectObserver:(id)inObserver
{
	[contactPropertiesObserverManager unregisterListObjectObserver:inObserver];
}
- (void)updateAllListObjectsForObserver:(id <AIListObjectObserver>)inObserver
{
	[contactPropertiesObserverManager updateAllListObjectsForObserver:inObserver];
}
- (void)updateContacts:(NSSet *)contacts forObserver:(id <AIListObjectObserver>)inObserver
{
	[contactPropertiesObserverManager updateContacts:contacts forObserver:inObserver];
}
- (void)updateListContactStatus:(AIListContact *)inContact
{
	[contactPropertiesObserverManager updateListContactStatus:inContact];
}

#pragma mark Address Book
//Address Book
- (void)setAddressBookController:(NSObject<AIAddressBookController> *)inAddressBookController
{
	if (addressBookController != inAddressBookController) {
		[addressBookController release];
		addressBookController = [inAddressBookController retain];
	}
}

- (ABPerson *)personForListObject:(AIListObject *)inObject
{
	return [addressBookController personForListObject:inObject];
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
@end
