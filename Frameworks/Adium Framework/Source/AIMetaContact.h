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

#import <Adium/AIListContact.h>

#define	KEY_PREFERRED_DESTINATION_CONTACT	@"Preferred Destination Contact"

@interface AIMetaContact : AIListContact <AIContainingObject> {
	NSNumber				*objectID;

	AIListContact			*_preferredContact;
	NSArray					*_listContacts;
	NSArray					*_listContactsIncludingOfflineAccounts;
	
	BOOL					containsOnlyOneUniqueContact;
	BOOL					containsOnlyOneService;

	NSMutableArray			*containedObjects;			//Manually ordered array of contents
	BOOL					containedObjectsNeedsSort;
	BOOL					delayContainedObjectSorting;
	BOOL					saveGroupingChanges;
	
    BOOL					expanded;			//Exanded/Collapsed state of this object
	BOOL					isExpandable;
}

//The objectID is unique to a meta contact and is used as the UID for purposes of AIListContact inheritance
- (id)initWithObjectID:(NSNumber *)objectID;
- (NSNumber *)objectID;
+ (NSString *)internalObjectIDFromObjectID:(NSNumber *)inObjectID;

- (AIListContact *)preferredContact;
- (AIListContact *)preferredContactWithCompatibleService:(AIService *)inService;

- (void)remoteGroupingOfContainedObject:(AIListObject *)inListObject changedTo:(NSString *)inRemoteGroupName;

/*
 * @brief Does this metacontact contains multiple contacts?
 *
 * For a metacontact, this is YES if the metaContact contains more than one contact.
 *
 * Note that a metacontact may contain multiple AIListContacts (as returned by its containedObjects), but
 * if this returns NO, all those AIListContacts represent the same UID/Service combination (but on different accounts).
 * In that case, listContacts will return a single contact.
 */
- (BOOL)containsMultipleContacts;

//Similarly, YES if the metaContact has only one serviceID within it.
- (BOOL)containsOnlyOneService;
- (unsigned)uniqueContainedObjectsCount;
- (AIListObject *)uniqueObjectAtIndex:(int)inIndex;

- (NSDictionary *)dictionaryOfServiceClassesAndListContacts;
- (NSArray *)servicesOfContainedObjects;

// (PRIVATE: For contact controller ONLY)
- (BOOL)addObject:(AIListObject *)inObject;
- (void)removeObject:(AIListObject *)inObject;

/*
 * @brief A flat array of AIListContacts each with a different internalObjectID
 *
 * If multiple AIListContacts with the same UID/Service are within this metacontact (i.e. from multiple accounts),
 * only one will be included in this array, and that one will be the most available of them.
 * Only contacts (regardless of status) for accounts which are currently connected are included.
 */
- (NSArray *)listContacts;

/*
 * @brief A flat array of AIListContacts each with a different internalObjectID
 *
 * If multiple AIListContacts with the same UID/Service are within this metacontact (i.e. from multiple accounts),
 * only one will be included in this array, and that one will be the most available of them.
 * Contacts from all accounts, including offline ones, will be included.
 */
- (NSArray *)listContactsIncludingOfflineAccounts;


/*!
 * @brief An array of all objects within this metacontact
 *
 * Implemented as required by the AIContainingObject protocol.
 * This returns an array of all AIListContact objects within the metacontact; the same UID/service may be represented
 * multiple times, an AIListContact for each account on that service.
 */
- (NSArray *)containedObjects;


//Delay sorting the contained object list; this should only be used by the contactController. Be sure to set it back to YES when operations are done
- (void)setDelayContainedObjectSorting:(BOOL)flag;

@end
