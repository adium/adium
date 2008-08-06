/*
 *  AIContactControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>

#define ListObject_AttributesChanged			@"ListObject_AttributesChanged"
#define ListObject_StatusChanged				@"ListObject_StatusChanged"
#define Contact_OrderChanged					@"Contact_OrderChanged"
#define Contact_ListChanged						@"Contact_ListChanged"
#define Contact_SortSelectorListChanged			@"Contact_SortSelectorListChanged"

#define Contact_ApplyDisplayName				@"Contact_ApplyDisplayName"
#define Contact_AddNewContact					@"Contact_AddNewContact"

//A unique group name for our root group
#define ADIUM_ROOT_GROUP_NAME					@"ROOTJKSHFOEIZNGIOEOP"	

//Preference groups and keys used for contacts throughout Adium
#define	PREF_GROUP_ALIASES						@"Aliases"			//Preference group in which to store aliases
#define PREF_GROUP_USERICONS					@"User Icons"
#define KEY_USER_ICON							@"User Icon"
#define PREF_GROUP_NOTES						@"Notes"			//Preference group to store notes in
#define PREF_GROUP_ADDRESSBOOK                  @"Address Book"
#define PREF_GROUP_ALWAYS_VISIBLE				@"Always Visible"


typedef enum {
	AIUserInfoLabelValuePair = 0 /* default */,
	AIUserInfoSectionHeader,
	AIUserInfoSectionBreak
}  AIUserInfoEntryType;

typedef enum {
    AIInfo_Profile = 1, 
    AIInfo_Accounts,
    AIInfo_Alerts,
    AIInfo_Settings
} AIContactInfoCategory;

typedef enum {
    AISortGroup = 0,
    AISortGroupAndSubGroups,
    AISortGroupAndSuperGroups
} AISortMode;

@protocol AIListObjectObserver;
@class AIListGroup, AIListObject, AIListContact, AIMetaContact, AIService, AIAccount, AISortController, AIListBookmark, AIContactHidingController;

@protocol AIAddressBookController
- (ABPerson *)personForListObject:(AIListObject *)inObject;
@end

@protocol AIContactController <AIController>
//Contact list access
- (AIListGroup *)contactList;
- (AIListContact *)contactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID;
- (AIListContact *)contactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID usingClass:(Class)ContactClass;
- (AIListContact *)contactOnAccount:(AIAccount *)account fromListContact:(AIListContact *)inContact;
- (AIListObject *)existingListObjectWithUniqueID:(NSString *)uniqueID;
- (AIListContact *)existingContactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID;
- (AIListContact *)existingContactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID usingClass:(Class)ContactClass;
- (AIListGroup *)groupWithUID:(NSString *)groupUID;
- (AIListGroup *)existingGroupWithUID:(NSString *)groupUID;
- (NSArray *)allGroups;
/*!
 * @brief Returns a flat array of all contacts
 */
- (NSMutableArray *)allContacts;
/*!
 * @brief Returns a flat array of all contacts on a given account
 * 
 * @param inAccount The account whose contacts are desired, or nil to match every account
 * @result Every contact in the global contactDict which isn't a metacontact and matches the specified account criterion
 */
- (NSMutableArray *)allContactsOnAccount:(AIAccount *)inAccount;
- (NSMutableArray *)allContactsInObject:(AIListObject<AIContainingObject> *)inGroup recurse:(BOOL)recurse onAccount:(AIAccount *)inAccount;
- (NSMutableArray *)allBookmarks;
- (NSMutableArray *)allBookmarksInObject:(AIListObject<AIContainingObject> *)inGroup recurse:(BOOL)recurse onAccount:(AIAccount *)inAccount;
- (NSMenu *)menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)inGroup withTarget:(id)target;
- (NSMenu *)menuOfAllGroupsInGroup:(AIListGroup *)inGroup withTarget:(id)target;
- (NSSet *)allContactsWithService:(AIService *)service UID:(NSString *)inUID existingOnly:(BOOL)existingOnly;
- (AIListGroup *)offlineGroup;
- (BOOL)useOfflineGroup;

- (AIListBookmark *)bookmarkForChat:(AIChat *)inChat;

- (AIMetaContact *)knownMetaContactForGroupingUIDs:(NSArray *)UIDsArray forServices:(NSArray *)servicesArray;
- (AIMetaContact *)groupUIDs:(NSArray *)UIDsArray forServices:(NSArray *)servicesArray usingMetaContactHint:(AIMetaContact *)metaContactHint;
- (AIMetaContact *)metaContactWithObjectID:(NSNumber *)inObjectID;

- (AIMetaContact *)groupListContacts:(NSArray *)contactsToGroupArray;
- (void)removeAllListObjectsMatching:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact;
- (AIListGroup *)remoteGroupForContact:(AIListContact *)inContact;
- (void)clearAllMetaContactData;

//Contact status & Attributes
- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver;
- (void)unregisterListObjectObserver:(id)inObserver;
- (void)updateAllListObjectsForObserver:(id <AIListObjectObserver>)inObserver;
- (void)updateContacts:(NSSet *)contacts forObserver:(id <AIListObjectObserver>)inObserver;
- (void)delayListObjectNotifications;
- (void)endListObjectNotificationsDelay;
- (void)delayListObjectNotificationsUntilInactivity;
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
- (void)listObjectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSSet *)inModifiedKeys;

- (void)listObjectRemoteGroupingChanged:(AIListContact *)inObject;

//Contact list sorting
- (NSArray *)sortControllerArray;
- (void)registerListSortController:(AISortController *)inController;
- (void)setActiveSortController:(AISortController *)inController;
- (AISortController *)activeSortController;
- (void)sortContactList;
- (void)sortListObject:(AIListObject *)inObject;

//Preferred contacts
- (AIListContact *)preferredContactForContentType:(NSString *)inType forListContact:(AIListContact *)inContact;
- (AIListContact *)preferredContactWithUID:(NSString *)UID andServiceID:(NSString *)serviceID forSendingContentType:(NSString *)inType;

//Editing
- (void)addContacts:(NSArray *)contactArray toGroup:(AIListGroup *)group;
- (void)removeListObjects:(NSArray *)objectArray;
- (void)requestAddContactWithUID:(NSString *)contactUID service:(AIService *)inService account:(AIAccount *)inAccount;
- (void)moveListObjects:(NSArray *)objectArray intoObject:(AIListObject<AIContainingObject> *)group index:(int)index;
- (void)moveContact:(AIListContact *)listContact intoObject:(AIListObject<AIContainingObject> *)group;
- (void)_moveContactLocally:(AIListContact *)listContact toGroup:(AIListGroup *)group;
- (BOOL)useContactListGroups;

//For Accounts
- (void)account:(AIAccount *)account didStopTrackingContact:(AIListContact *)listContact;

- (id)showAuthorizationRequestWithDict:(NSDictionary *)inDict forAccount:(AIAccount *)inAccount;

//Contact info
- (void)updateListContactStatus:(AIListContact *)inContact;

//Contact List 
- (AIListGroup *)createDetachedContactList;
- (void)removeDetachedContactList:(AIListGroup *)detachedList;
- (BOOL)isGroupDetached:(AIListObject *)group;
- (unsigned)contactListCount;

//Contact hiding
- (AIContactHidingController *)contactHidingController;

//Address Book
- (void)setAddressBookController:(NSObject<AIAddressBookController> *)inAddressBookController;
- (ABPerson *)personForListObject:(AIListObject *)inObject;

@end

//Observer which receives notifications of changes in list object status
@protocol AIListObjectObserver
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
@end

//Empty protocol to allow easy checking for if a particular object is a contact list outline view
@protocol ContactListOutlineView
@end
