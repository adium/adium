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

@protocol AIContactController <AIController>
//Contact list access
- (AIListGroup *)contactList;
- (AIListContact *)contactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID;
- (AIListContact *)contactOnAccount:(AIAccount *)account fromListContact:(AIListContact *)inContact;
- (AIListObject *)existingListObjectWithUniqueID:(NSString *)uniqueID;
- (AIListContact *)existingContactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID;
- (AIListContact *)existingContactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID usingClass:(Class)ContactClass;
- (AIListGroup *)groupWithUID:(NSString *)groupUID;
- (NSArray *)allGroups;
/*!
 * @brief Returns a flat array of all contacts
 */
- (NSArray *)allContacts;
- (NSArray *)allContactsInObject:(AIListObject<AIContainingObject> *)inGroup recurse:(BOOL)recurse onAccount:(AIAccount *)inAccount;
- (NSArray *)allBookmarks;
- (NSArray *)allBookmarksInObject:(AIListObject<AIContainingObject> *)inGroup recurse:(BOOL)recurse onAccount:(AIAccount *)inAccount;
- (NSMenu *)menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)inGroup withTarget:(id)target;
- (NSMenu *)groupMenuWithTarget:(id)target;
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
- (void)listObjectRemoteGroupingChanged:(AIListContact *)inObject;

//Contact list sorting
- (void)sortContactList;
- (void)sortListObject:(AIListObject *)inObject;

//Preferred contacts
- (AIListContact *)preferredContactForContentType:(NSString *)inType forListContact:(AIListContact *)inContact;
- (AIListContact *)preferredContactWithUID:(NSString *)UID andServiceID:(NSString *)serviceID forSendingContentType:(NSString *)inType;

//Editing
- (void)addContacts:(NSArray *)contactArray toGroup:(AIListGroup *)group;
- (void)removeListObjects:(NSArray *)objectArray;
- (void)requestAddContactWithUID:(NSString *)contactUID service:(AIService *)inService account:(AIAccount *)inAccount;
- (void)moveListObjects:(NSArray *)objectArray intoObject:(AIListObject<AIContainingObject> *)group index:(NSUInteger)index;
- (void)moveContact:(AIListContact *)listContact intoObject:(AIListObject<AIContainingObject> *)group;
- (void)_moveContactLocally:(AIListContact *)listContact toGroup:(AIListGroup *)group;
- (BOOL)useContactListGroups;

//For Accounts
- (void)account:(AIAccount *)account didStopTrackingContact:(AIListContact *)listContact;

- (id)showAuthorizationRequestWithDict:(NSDictionary *)inDict forAccount:(AIAccount *)inAccount;

//Contact List 
- (AIListGroup *)createDetachedContactList;
- (void)removeDetachedContactList:(AIListGroup *)detachedList;
- (BOOL)isGroupDetached:(AIListObject *)group;
- (NSUInteger)contactListCount;

@end

//Empty protocol to allow easy checking for if a particular object is a contact list outline view
@protocol ContactListOutlineView
@end
