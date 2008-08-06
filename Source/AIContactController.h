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

#import <Adium/AIControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>

#define	KEY_HIDE_CONTACTS				@"Hide Contacts"
#define KEY_SHOW_OFFLINE_CONTACTS		@"Show Offline Contacts"
#define KEY_SHOW_BLOCKED_CONTACTS		@"Show Blocked Contacts"
#define	KEY_SHOW_IDLE_CONTACTS			@"Show Idle Contacts"
#define KEY_SHOW_MOBILE_CONTACTS		@"Show Mobile Contacts"

#define	KEY_USE_OFFLINE_GROUP			@"Use Offline Group"
#define	KEY_HIDE_CONTACT_LIST_GROUPS	@"Hide Contact List Groups"
#define	PREF_GROUP_CONTACT_LIST_DISPLAY	@"Contact List Display"

@class AISortController, AdiumAuthorization, AIContactHidingController, AdiumContactPropertiesObserverManager;

@interface AIContactController : NSObject <AIContactController, AIListObjectObserver> {
	//Contacts and metaContacts
	NSMutableDictionary		*contactDict;
	NSMutableDictionary		*metaContactDict;
	NSMutableDictionary		*contactToMetaContactLookupDict;
	
	//Contact List and Groups
    AIListGroup				*contactList;
	NSMutableDictionary		*groupDict;
	BOOL					useContactListGroups;
	NSMenuItem				*menuItem_showGroups;
	BOOL					useOfflineGroup;
	NSMenuItem				*menuItem_useOfflineGroup;
	
	//Detached Contact Lists
	NSMutableArray			*detachedContactLists;
	
	//Sorting
    NSMutableArray			*sortControllerArray;
    AISortController	 	*activeSortController;
	
	//Authorization
	AdiumAuthorization		*adiumAuthorization;
	
	//hiding
	AIContactHidingController	*contactHidingController;
	
	AdiumContactPropertiesObserverManager *contactPropertiesObserverManager;
	
	NSObject<AIAddressBookController> *addressBookController;
}

- (void)sortContactLists:(NSArray *)lists;
- (void)loadContactList;

- (AIContactHidingController *)contactHidingController;

@end

@interface AIContactController (ContactControllerHelperAccess)
- (NSEnumerator *)contactEnumerator;
- (NSEnumerator *)groupEnumerator;
@end
