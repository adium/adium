/*
 *  AIContactControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

@class AIListObject, AIListContact, AIChat;
@protocol AIContainingObject;

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

#define	KEY_EXPANDED							@"IsExpanded"

#define	KEY_HIDE_CONTACTS				@"Hide Contacts"
#define KEY_SHOW_OFFLINE_CONTACTS		@"Show Offline Contacts"
#define KEY_SHOW_BLOCKED_CONTACTS		@"Show Blocked Contacts"
#define	KEY_SHOW_IDLE_CONTACTS			@"Show Idle Contacts"
#define KEY_SHOW_MOBILE_CONTACTS		@"Show Mobile Contacts"
#define KEY_SHOW_AWAY_CONTACTS			@"Show Away Contacts"
#define KEY_HIDE_ACCOUNT_CONTACTS		@"Hide Account Contacts"

#define	KEY_USE_OFFLINE_GROUP			@"Use Offline Group"
#define	KEY_HIDE_CONTACT_LIST_GROUPS	@"Hide Contact List Groups"
#define	PREF_GROUP_CONTACT_LIST_DISPLAY	@"Contact List Display"
#define PREF_GROUP_CONTACT_LIST			@"Contact List"

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
@class AIListGroup, AIContactList, AIListObject, AIListContact, AIMetaContact, AIService, AIAccount, AISortController, AIListBookmark, AIContactHidingController;

@protocol AIContactController <AIController>
//Contact list access
@property (readonly, nonatomic) AIContactList *contactList;
- (AIListContact *)contactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID;
- (void)setUID:(NSString *)UID forContact:(AIListContact *)contact;
- (AIListObject *)existingListObjectWithUniqueID:(NSString *)uniqueID;
- (AIListContact *)existingContactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID;
- (AIListGroup *)groupWithUID:(NSString *)groupUID;
@property (readonly, nonatomic) NSArray *allGroups;
/*!
 * @brief Returns a flat array of all contacts
 */
@property (readonly, nonatomic) NSArray *allContacts;
- (NSArray *)allContactsInObject:(AIListObject<AIContainingObject> *)inGroup onAccount:(AIAccount *)inAccount;
@property (readonly, nonatomic) NSArray *allBookmarks;
@property (readonly, nonatomic) NSArray *allMetaContacts;
- (NSMenu *)groupMenuWithTarget:(id)target;
- (NSSet *)allContactsWithService:(AIService *)service UID:(NSString *)inUID;
@property (readonly, nonatomic) AIListGroup *offlineGroup;
@property (readonly, nonatomic) BOOL useOfflineGroup;

- (AIListBookmark *)existingBookmarkForChat:(AIChat *)inChat;
- (AIListBookmark *)existingBookmarkForChatName:(NSString *)inName
									  onAccount:(AIAccount *)inAccount
							   chatCreationInfo:(NSDictionary *)inCreationInfo;
- (AIListBookmark *)bookmarkForChat:(AIChat *)inChat inGroup:(AIListGroup *)group;
- (void)removeBookmark:(AIListBookmark *)listBookmark;

- (AIMetaContact *)knownMetaContactForGroupingUIDs:(NSArray *)UIDsArray forServices:(NSArray *)servicesArray;
- (AIMetaContact *)groupUIDs:(NSArray *)UIDsArray forServices:(NSArray *)servicesArray usingMetaContactHint:(AIMetaContact *)metaContactHint;
- (AIMetaContact *)metaContactWithObjectID:(NSNumber *)inObjectID;

- (AIMetaContact *)groupContacts:(NSArray *)contactsToGroupArray;
- (void)clearAllMetaContactData;

//Contact list sorting
- (void)sortContactList;
- (void)sortListObject:(AIListObject *)inObject;

//Preferred contacts
- (AIListContact *)preferredContactForContentType:(NSString *)inType forListContact:(AIListContact *)inContact;
- (AIListContact *)preferredContactWithUID:(NSString *)UID andServiceID:(NSString *)serviceID forSendingContentType:(NSString *)inType;

//Editing
- (void)explodeMetaContact:(AIMetaContact *)metaContact; //Unpack contained contacts and then remove the meta
- (void)removeListGroup:(AIListGroup *)listGroup;
- (void)requestAddContactWithUID:(NSString *)contactUID service:(AIService *)inService account:(AIAccount *)inAccount;
- (void)moveGroup:(AIListGroup *)group fromContactList:(AIContactList *)oldContactList toContactList:(AIContactList *)contactList;
- (void)moveContact:(AIListObject *)listContact fromGroups:(NSSet *)oldGroups intoGroups:(NSSet *)groups;
- (void)_moveContactLocally:(AIListContact *)listContact fromGroups:(NSSet *)oldGroups toGroups:(NSSet *)groups;
@property (readonly, nonatomic) BOOL useContactListGroups;

//For Accounts
- (void)accountDidStopTrackingContact:(AIListContact *)listContact;

//Contact List 
- (AIContactList *)createDetachedContactList;
- (void)removeDetachedContactList:(AIContactList *)detachedList;

@end

//Empty protocol to allow easy checking for if a particular object is a contact list outline view
@protocol ContactListOutlineView
@end
