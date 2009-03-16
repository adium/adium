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

#import "AIAddressBookController.h"
#import <Adium/AIControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIUserIcons.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/OWAddressBookAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIImageAdditions.h>

#import "AIAddressBookUserIconSource.h"

#define IMAGE_LOOKUP_INTERVAL   0.01
#define SHOW_IN_AB_CONTEXTUAL_MENU_TITLE AILocalizedString(@"Show In Address Book", "Show In Address Book Contextual Menu")
#define EDIT_IN_AB_CONTEXTUAL_MENU_TITLE AILocalizedString(@"Edit In Address Book", "Edit In Address Book Contextual Menu")
#define ADD_TO_AB_CONTEXTUAL_MENU_TITLE AILocalizedString(@"Add To Address Book", "Add To Address Book Contextual Menu")

#define CONTACT_ADDED_SUCCESS_TITLE		AILocalizedString(@"Success", "Title of a panel shown after adding successfully adding a contact to the address book.")
#define CONTACT_ADDED_SUCCESS_Message	AILocalizedString(@"%@ had been successfully added to the Address Book.\nWould you like to edit the card now?", nil)
#define CONTACT_ADDED_ERROR_TITLE		AILocalizedString(@"Error", nil)
#define CONTACT_ADDED_ERROR_Message		AILocalizedString(@"An error had occurred while adding %@ to the Address Book.", nil)

#define KEY_ADDRESS_BOOK_ACTIONS_INSTALLED	@"Adium:Installed Adress Book Actions 1.3"

#define KEY_AB_TO_METACONTACT_DICT			@"UniqueIDToMetaContactObjectIDDictionary"

@interface AIAddressBookController()
+ (ABPerson *)_searchForUID:(NSString *)UID serviceID:(NSString *)serviceID;
- (void)updateAllContacts;
- (void)updateSelfIncludingIcon:(BOOL)includeIcon;
- (NSString *)nameForPerson:(ABPerson *)person phonetic:(NSString **)phonetic;
- (void)rebuildAddressBookDict;
- (void)showInAddressBook;
- (void)editInAddressBook;
- (void)addToAddressBookDict:(NSArray *)people;
- (void)removeFromAddressBookDict:(NSArray *)UIDs;
- (void)installAddressBookActions;
@end

/*!
 * @class AIAddressBookController
 * @brief Provides Apple Address Book integration
 *
 * This class allows Adium to seamlessly interact with the Apple Address Book, pulling names and icons, storing icons
 * if desired, and generating metaContacts based on screen name grouping.  It relies upon cards having screen names listed
 * in the appropriate service fields in the address book.
 */
@implementation AIAddressBookController

static AIAddressBookController *addressBookController = nil;
static ABAddressBook				*sharedAddressBook;
static NSMutableDictionary		*addressBookDict;
static NSDictionary				*serviceDict;

NSString* serviceIDForOscarUID(NSString *UID);
NSString* serviceIDForJabberUID(NSString *UID);

+ (void) startAddressBookIntegration
{
	if(!addressBookController)
		addressBookController = [[self alloc] init];
}

- (id)init
{
	if ((self = [super init]))
	{
		meTag = -1;
		addressBookDict = nil;
		createMetaContacts = NO;
		
		personUniqueIdToMetaContactDict = [[NSMutableDictionary alloc] init];
		
		//Configure our preferences
		[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:AB_DISPLAYFORMAT_DEFAULT_PREFS forClass:[self class]]  
						      forGroup:PREF_GROUP_ADDRESSBOOK];
		
		//We want the enableImport preference immediately (without waiting for the preferences observer to be registered in adiumFinishedLaunching:)
		enableImport = [[adium.preferenceController preferenceForKey:KEY_AB_ENABLE_IMPORT
									 group:PREF_GROUP_ADDRESSBOOK] boolValue];
		
		//Services dictionary
		serviceDict = [[NSDictionary dictionaryWithObjectsAndKeys:kABAIMInstantProperty,@"AIM",
				kABJabberInstantProperty,@"Jabber",
				kABMSNInstantProperty,@"MSN",
				kABYahooInstantProperty,@"Yahoo!",
				kABICQInstantProperty,@"ICQ",nil] retain];
		
		//Shared Address Book
		[sharedAddressBook release]; sharedAddressBook = [[ABAddressBook sharedAddressBook] retain];
		
		[self installAddressBookActions];
		
		//Wait for Adium to finish launching before we build the address book so the contact list will be ready
		[[NSNotificationCenter defaultCenter] addObserver:self
					       selector:@selector(adiumFinishedLaunching:)
						   name:AIApplicationDidFinishLoadingNotification
						 object:nil];
		
		//Update self immediately so the information is available to plugins and interface elements as they load
		[self updateSelfIncludingIcon:YES];	
	}
	return self;
}

- (void)installAddressBookActions
{
	NSNumber		*installedActions = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_ADDRESS_BOOK_ACTIONS_INSTALLED];
	
	if (!installedActions || ![installedActions boolValue]) {
		NSEnumerator  *enumerator = [[NSArray arrayWithObjects:@"AIM", @"MSN", @"Yahoo", @"ICQ", @"Jabber", @"SMS", nil] objectEnumerator];
		NSString	  *name;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray		  *libraryDirectoryArray;
		NSString	  *libraryDirectory, *pluginDirectory;

		libraryDirectoryArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
		if ([libraryDirectoryArray count]) {
			libraryDirectory = [libraryDirectoryArray objectAtIndex:0];

		} else {
			//Ridiculous safety since everyone should have a Library folder...
			libraryDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
			[fileManager createDirectoryAtPath:libraryDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
		}

		pluginDirectory = [[libraryDirectory stringByAppendingPathComponent:@"Address Book Plug-Ins"] stringByAppendingPathComponent:@"/"];
		[fileManager createDirectoryAtPath:pluginDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
		
		while ((name = [enumerator nextObject])) {
			NSString *fullName = [NSString stringWithFormat:@"AdiumAddressBookAction_%@",name];
			NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:fullName ofType:@"scpt"];

			if (path) {
				NSString *destination = [pluginDirectory stringByAppendingPathComponent:[fullName stringByAppendingPathExtension:@"scpt"]];
				[fileManager trashFileAtPath:destination];
				[fileManager copyItemAtPath:path
							   toPath:destination
							  error:NULL];
				
				//Remove the old xtra if installed
				[fileManager trashFileAtPath:[pluginDirectory stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%@-Adium.scpt",name]]];
			} else {
				AILogWithSignature(@"Warning: Could not find %@",self, fullName);
			}
		}

		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES]
												  forKey:KEY_ADDRESS_BOOK_ACTIONS_INSTALLED];
	}
}

+ (void) stopAddressBookIntegration
{
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:addressBookController];
	[adium.preferenceController unregisterPreferenceObserver:addressBookController];
	[[NSNotificationCenter defaultCenter] removeObserver:addressBookController];

	[addressBookController release]; addressBookController = nil;
}

- (void)dealloc
{
	[serviceDict release]; serviceDict = nil;

	[sharedAddressBook release]; sharedAddressBook = nil;
	[personUniqueIdToMetaContactDict release]; personUniqueIdToMetaContactDict = nil;

	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

/*!
 * @brief Adium finished launching
 *
 * Register our observers for the address book changing externally and for the account list changing.
 * Register our preference observers. This will trigger initial building of the address book dictionary.
 */
- (void)adiumFinishedLaunching:(NSNotification *)notification
{	
	//Create our contextual menus
	showInABContextualMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:SHOW_IN_AB_CONTEXTUAL_MENU_TITLE
											   action:@selector(showInAddressBook)
										    keyEquivalent:@""] autorelease];
	[showInABContextualMenuItem setTarget:self];
	[showInABContextualMenuItem setTag:AIRequiresAddressBookEntry];
	
	editInABContextualMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:EDIT_IN_AB_CONTEXTUAL_MENU_TITLE
											   action:@selector(editInAddressBook)
										    keyEquivalent:@""] autorelease];
	[editInABContextualMenuItem setTarget:self];
	[editInABContextualMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[editInABContextualMenuItem setAlternate:YES];
	[editInABContextualMenuItem setTag:AIRequiresAddressBookEntry];
	
	addToABContexualMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADD_TO_AB_CONTEXTUAL_MENU_TITLE
											 action:@selector(addToAddressBook)
										  keyEquivalent:@""] autorelease];
	[addToABContexualMenuItem setTarget:self];
	[addToABContexualMenuItem setTag:AIRequiresNoAddressBookEntry];
	
	//Install our menus
	[adium.menuController addContextualMenuItem:addToABContexualMenuItem toLocation:Context_Contact_Action];
	[adium.menuController addContextualMenuItem:showInABContextualMenuItem toLocation:Context_Contact_Action];
	[adium.menuController addContextualMenuItem:editInABContextualMenuItem toLocation:Context_Contact_Action];
	
	//Observe external address book changes
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(addressBookChanged:)
												 name:kABDatabaseChangedExternallyNotification
											   object:nil];

	//Observe account changes
	[[NSNotificationCenter defaultCenter] addObserver:self
										selector:@selector(accountListChanged:)
									   name:Account_ListChanged
									 object:nil];

	//Observe preferences changes
	id<AIPreferenceController> preferenceController = adium.preferenceController;
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_ADDRESSBOOK];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_USERICONS];

	addressBookUserIconSource = [[AIAddressBookUserIconSource alloc] init];
	[AIUserIcons registerUserIconSource:addressBookUserIconSource];
}

/*!
 * @brief Used as contacts are created and icons are changed.
 *
 * When first created, load a contact's address book information from our dict.
 * When an icon as a property changes, if desired, write the changed icon out to the appropriate AB card.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	AIListContact	*listContact;
	NSSet			*modifiedAttributes = nil;

	//Just stop here if we don't have an address book dict to work with
	if (!addressBookDict) return nil;
	
	//We handle accounts separately; doing updates here causes chaos in addition to being inefficient.
	if ([inObject isKindOfClass:[AIAccount class]]) return nil;

	//Only contacts have associated address book info
	if (![inObject isKindOfClass:[AIListContact class]]) return nil;
	listContact = (AIListContact *)inObject;
	
    if (inModifiedKeys == nil) { //Only perform this when updating for all list objects or when a contact is created
        ABPerson *person = [listContact addressBookPerson];

		if (person) {
			if (enableImport) {
				//Load the name if appropriate
				AIMutableOwnerArray *displayNameArray, *phoneticNameArray;
				NSString			*displayName, *phoneticName = nil;
				
				displayNameArray = [listContact displayArrayForKey:@"Display Name"];
				
				displayName = [self nameForPerson:person phonetic:&phoneticName];
				
				//Apply the values 
				NSString *oldValue = [displayNameArray objectWithOwner:self];
				if (!oldValue || ![oldValue isEqualToString:displayName]) {
					[displayNameArray setObject:displayName withOwner:self];
					modifiedAttributes = [NSSet setWithObject:@"Display Name"];
				}
				
				if (phoneticName) {
					phoneticNameArray = [listContact displayArrayForKey:@"Phonetic Name"];

					//Apply the values 
					oldValue = [phoneticNameArray objectWithOwner:self];
					if (!oldValue || ![oldValue isEqualToString:phoneticName]) {
						[phoneticNameArray setObject:phoneticName withOwner:self];
						modifiedAttributes = [NSSet setWithObjects:@"Display Name", @"Phonetic Name", nil];
					}
				} else {
					phoneticNameArray = [listContact displayArrayForKey:@"Phonetic Name"
																 create:NO];
					//Clear any stored value
					if ([phoneticNameArray objectWithOwner:self]) {
						[displayNameArray setObject:nil withOwner:self];
						modifiedAttributes = [NSSet setWithObjects:@"Display Name", @"Phonetic Name", nil];
					}					
				}

			} else {
				AIMutableOwnerArray *displayNameArray, *phoneticNameArray;
				
				displayNameArray = [listContact displayArrayForKey:@"Display Name"
															create:NO];

				//Clear any stored value
				if ([displayNameArray objectWithOwner:self]) {
					[displayNameArray setObject:nil withOwner:self];
					modifiedAttributes = [NSSet setWithObject:@"Display Name"];
				}
				
				phoneticNameArray = [listContact displayArrayForKey:@"Phonetic Name"
															 create:NO];
				//Clear any stored value
				if ([phoneticNameArray objectWithOwner:self]) {
					[displayNameArray setObject:nil withOwner:self];
					modifiedAttributes = [NSSet setWithObjects:@"Display Name", @"Phonetic Name", nil];
				}					
				
			}

			//If we changed anything, request an update of the alias / long display name
			if (modifiedAttributes) {
				[[NSNotificationCenter defaultCenter] postNotificationName:Contact_ApplyDisplayName
														  object:listContact
														userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:silent]
																							 forKey:@"Notify"]];
			}

			//Add this contact to the ABPerson's metacontact if it's not already there.
			AIMetaContact *personMetaContact;
			if ((personMetaContact = [personUniqueIdToMetaContactDict objectForKey:[person uniqueId]]) &&
				![personMetaContact containsObject:listContact]) {
				[adium.contactController groupContacts:[NSArray arrayWithObjects:personMetaContact, listContact, nil]];
			}
		}
    }
    
    return modifiedAttributes;
}

- (void)listObjectAttributesChanged:(NSNotification *)notification
{
	if (!automaticUserIconSync) return;

	AIListObject	*inObject = [notification object];
	NSSet			*keys = [[notification userInfo] objectForKey:@"Keys"];
	
	if ([keys containsObject:KEY_USER_ICON] &&
		[inObject isKindOfClass:[AIListContact class]]) {
		AIListContact *listContact = (AIListContact *)inObject;
		ABPerson *person = [listContact addressBookPerson];
			
		if (person && (person != [sharedAddressBook me])) {
			NSData	*existingABImageData = [person imageData];
			NSImage	*existingABImage = (existingABImageData ? [[[NSImage alloc] initWithData:[person imageData]] autorelease] : nil);
			NSImage	*objectUserIcon = [listContact userIcon];
			
			if (!existingABImage || objectUserIcon) {
				NSData  *objectUserIconData = [objectUserIcon PNGRepresentation];
				
				if (![objectUserIconData isEqualToData:[existingABImage PNGRepresentation]]) {
					[person setImageData:objectUserIconData];
					
					[[sharedAddressBook class] cancelPreviousPerformRequestsWithTarget:sharedAddressBook
																			  selector:@selector(save)
																				object:nil];
					[sharedAddressBook performSelector:@selector(save)
											withObject:nil
											afterDelay:5.0];						
				}
			}
		}		
	}
}

/*!
 * @brief Return the name of an ABPerson in the way Adium should display it
 *
 * @param person An <tt>ABPerson</tt>
 * @param phonetic A pointer to an <tt>NSString</tt> which will be filled with the phonetic display name if available
 * @result A string based on the first name, last name, and/or nickname of the person, as specified via preferences.
 */
- (NSString *)nameForPerson:(ABPerson *)person phonetic:(NSString **)phonetic
{
	NSString *firstName, *middleName, *lastName, *phoneticFirstName, *phoneticLastName;	
	NSString *nickName;
	NSString *displayName = nil;
	NSNumber *flags;
	NameStyle thisDisplayFormat = displayFormat;
	
	// If the record is for a company, return the company name if present
	if ((flags = [person valueForProperty:kABPersonFlags])) {
		if (([flags integerValue] & kABShowAsMask) == kABShowAsCompany) {
			NSString *companyName = [person valueForProperty:kABOrganizationProperty];
			if (companyName && [companyName length]) {
				return companyName;
			}
		}

		if (([flags integerValue] & kABNameOrderingMask) == kABLastNameFirst) {
			if (thisDisplayFormat == FirstLast) {
				thisDisplayFormat = LastFirstNoComma;
			}
		}
	}
		
	firstName = [person valueForProperty:kABFirstNameProperty];
	middleName = [person valueForProperty:kABMiddleNameProperty];
	lastName = [person valueForProperty:kABLastNameProperty];
	phoneticFirstName = [person valueForProperty:kABFirstNamePhoneticProperty];
	phoneticLastName = [person valueForProperty:kABLastNamePhoneticProperty];
	
	//
	if (useMiddleName && middleName)
		firstName = [NSString stringWithFormat:@"%@ %@", firstName, middleName];

	if (useNickName && (nickName = [person valueForProperty:kABNicknameProperty])) {
		displayName = nickName;

	} else if (!lastName || (thisDisplayFormat == First)) {  
		/* If no last name is available, use the first name */
		displayName = firstName;
		if (phonetic != NULL) *phonetic = phoneticFirstName;

	} else if (!firstName) {
		/* If no first name is available, use the last name */
		displayName = lastName;
		if (phonetic != NULL) *phonetic = phoneticLastName;

	} else {
		BOOL havePhonetic = ((phonetic != NULL) && (phoneticFirstName || phoneticLastName));

		/* Look to the preference setting */
		switch (thisDisplayFormat) {
			case FirstLast:
				displayName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
				if (havePhonetic) {
					*phonetic = [NSString stringWithFormat:@"%@ %@",
						(phoneticFirstName ? phoneticFirstName : firstName),
						(phoneticLastName ? phoneticLastName : lastName)];
				}
				break;
			case LastFirst:
				displayName = [NSString stringWithFormat:@"%@, %@",lastName,firstName]; 
				if (havePhonetic) {
					*phonetic = [NSString stringWithFormat:@"%@, %@",
						(phoneticLastName ? phoneticLastName : lastName),
						(phoneticFirstName ? phoneticFirstName : firstName)];
				}
				break;
			case LastFirstNoComma:
				displayName = [NSString stringWithFormat:@"%@ %@",lastName,firstName]; 
				if (havePhonetic) {
					*phonetic = [NSString stringWithFormat:@"%@ %@",
						(phoneticLastName ? phoneticLastName : lastName),
						(phoneticFirstName ? phoneticFirstName : firstName)];
				}					
				break;
			case FirstLastInitial:
				displayName = [NSString stringWithFormat:@"%@ %@",firstName,[lastName substringToIndex:1]]; 
				if (havePhonetic) {
					*phonetic = [NSString stringWithFormat:@"%@ %@",
								 (phoneticFirstName ? phoneticFirstName : firstName),
								 [lastName substringToIndex:1]];
				}
			case First:
				//No action; handled before we reach the switch statement
				break;
		}
	}

	return displayName;
}

/*!
 * @brief Observe preference changes
 *
 * On first call, this method builds the addressBookDict. Subsequently, it rebuilds the dict only if the "create metaContacts"
 * option is toggled, as metaContacts are created while building the dict.
 *
 * If the user set a new image as a preference for an object, write it out to the contact's AB card if desired.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (object) {
		[[AIContactObserverManager sharedManager] updateContacts:[NSSet setWithObject:object] forObserver:self];
		return;
	}

	if (![group isEqualToString:PREF_GROUP_ADDRESSBOOK] || [key isEqualToString:KEY_AB_TO_METACONTACT_DICT])
		return;
	
	BOOL			oldCreateMetaContacts = createMetaContacts;

	//load new displayFormat
	enableImport = [[prefDict objectForKey:KEY_AB_ENABLE_IMPORT] boolValue];
	displayFormat = [[prefDict objectForKey:KEY_AB_DISPLAYFORMAT] integerValue];
	automaticUserIconSync = [[prefDict objectForKey:KEY_AB_IMAGE_SYNC] boolValue];
	useNickName = [[prefDict objectForKey:KEY_AB_USE_NICKNAME] boolValue];
	useMiddleName = [[prefDict objectForKey:KEY_AB_USE_MIDDLE] boolValue];

	createMetaContacts = [[prefDict objectForKey:KEY_AB_CREATE_METACONTACTS] boolValue];
	
	if (firstTime) {
		//Build the address book dictionary, which will also trigger metacontact grouping as appropriate
		[self rebuildAddressBookDict];
		
		//Register ourself as a listObject observer, which will update all objects
		[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
		
		//Note: we don't need to call updateSelfIncludingIcon: because it was already done in installPlugin			
	} else {
		//This isn't the first time through

		//If we weren't creating meta contacts before but we are now
		if (!oldCreateMetaContacts && createMetaContacts) {
			/*
			 Build the address book dictionary, which will also trigger metacontact grouping as appropriate
			 Delay to the next run loop to give better UI responsiveness
			 */
			[self performSelector:@selector(rebuildAddressBookDict)
					   withObject:nil
					   afterDelay:0];
		}
		
		//Update all contacts, which will update objects and then our "me" card information
		[self updateAllContacts];
	}
	
	if (automaticUserIconSync) {
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(listObjectAttributesChanged:)
										   name:ListObject_AttributesChanged
										 object:nil];
	} else {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:ListObject_AttributesChanged object:nil];
	}
}

/*!
 * @brief Returns the appropriate service for the property.
 *
 * @param property - an ABPerson property.
 */
+ (AIService *)serviceFromProperty:(NSString *)property
{
	NSString	*serviceID = nil;
	
	if ([property isEqualToString:kABAIMInstantProperty])
		serviceID = @"AIM";
	
	else if ([property isEqualToString:kABICQInstantProperty])
		serviceID = @"ICQ";
	
	else if ([property isEqualToString:kABMSNInstantProperty])
		serviceID = @"MSN";
	
	else if ([property isEqualToString:kABJabberInstantProperty])
		serviceID = @"Jabber";
	
	else if ([property isEqualToString:kABYahooInstantProperty])
		serviceID = @"Yahoo!";

	return (serviceID ? [adium.accountController firstServiceWithServiceID:serviceID] : nil);
}

/*!
 * @brief Returns the appropriate property for the service.
 */
+ (NSString *)propertyFromService:(AIService *)inService
{
	NSString *result;
	NSString *serviceID = inService.serviceID;

	result = [serviceDict objectForKey:serviceID];

	//Check for some special cases
	if (!result) {
		if ([serviceID isEqualToString:@"GTalk"]) {
			result = kABJabberInstantProperty;
		} else if ([serviceID isEqualToString:@"LiveJournal"]) {
			result = kABJabberInstantProperty;
		} else if ([serviceID isEqualToString:@"Mac"]) {
			result = kABAIMInstantProperty;
		} else if ([serviceID isEqualToString:@"MobileMe"]) {
			result = kABAIMInstantProperty;
		}
	}
	
	return result;
}

/*!
 * @brief Called when the address book completes an asynchronous image lookup
 *
 * @param inData NSData representing an NSImage
 * @param tag A tag indicating the lookup with which this call is associated.
 */
- (void)consumeImageData:(NSData *)inData forTag:(NSInteger)tag
{
	if (tag == meTag) {
		[adium.preferenceController setPreference:inData
											 forKey:KEY_DEFAULT_USER_ICON 
											  group:GROUP_ACCOUNT_STATUS];
		meTag = -1;
	}
}
		
#pragma mark Searching
/*!
 * @brief Find an ABPerson corresponding to an AIListObject
 *
 * @param inObject The object for which it search
 * @result An ABPerson is one is found, or nil if none is found
 */
+ (ABPerson *)personForListObject:(AIListObject *)inObject
{
	ABPerson	*person = nil;
	NSString	*uniqueID = [inObject preferenceForKey:KEY_AB_UNIQUE_ID group:PREF_GROUP_ADDRESSBOOK];
	if (!uniqueID) uniqueID = [inObject valueForProperty:KEY_AB_UNIQUE_ID];
	ABRecord	*record = nil;
	
	if (uniqueID)
		record = [sharedAddressBook recordForUniqueId:uniqueID];
	
	if (record && [record isKindOfClass:[ABPerson class]]) {
		person = (ABPerson *)record;
	} else {
		if ([inObject isKindOfClass:[AIMetaContact class]]) {
			NSEnumerator	*enumerator;
			AIListContact	*listContact;
			
			//Search for an ABPerson for each listContact within the metaContact; first one we find is
			//the lucky winner.
			enumerator = [[(AIMetaContact *)inObject listContactsIncludingOfflineAccounts] objectEnumerator];
			while ((listContact = [enumerator nextObject]) && (person == nil)) {
				person = [self personForListObject:listContact];
			}
			
		} else {
			NSString		*UID = inObject.UID;
			NSString		*serviceID = inObject.service.serviceID;
			
			person = [self _searchForUID:UID serviceID:serviceID];
			
			/* If we don't find anything yet, look at alternative service possibilities:
			 *    AIM <--> ICQ
			 */
			if (!person) {
				if ([serviceID isEqualToString:@"AIM"]) {
					person = [self _searchForUID:UID serviceID:@"ICQ"];
				} else if ([serviceID isEqualToString:@"ICQ"]) {
					person = [self _searchForUID:UID serviceID:@"AIM"];
				}
			}
		}
	}

	return person;
}

/*!
 * @brief Find an ABPerson for a given UID and serviceID combination
 * 
 * Uses our addressBookDict cache created in rebuildAddressBook.
 *
 * @param UID The UID for the contact
 * @param serviceID The serviceID for the contact
 * @result A corresponding <tt>ABPerson</tt>
 */
+ (ABPerson *)_searchForUID:(NSString *)UID serviceID:(NSString *)serviceID
{
	ABPerson		*person = nil;
	NSDictionary	*dict;
	
	if ([serviceID isEqualToString:@"Mac"] ||
		[serviceID isEqualToString:@"MobileMe"]) {
		dict = [addressBookDict objectForKey:@"AIM"];

	} else if ([serviceID isEqualToString:@"GTalk"]) {
		dict = [addressBookDict objectForKey:@"Jabber"];

	} else if ([serviceID isEqualToString:@"LiveJournal"]) {
		dict = [addressBookDict objectForKey:@"Jabber"];
		
	} else if ([serviceID isEqualToString:@"Yahoo! Japan"]) {
		dict = [addressBookDict objectForKey:@"Yahoo!"];
		
	} else {
		dict = [addressBookDict objectForKey:serviceID];
	} 
	
	if (dict) {
		NSString *uniqueID = [dict objectForKey:[UID compactedString]];
		if (uniqueID) {
			person = (ABPerson *)[sharedAddressBook recordForUniqueId:uniqueID];
		}
	}
	
	return person;
}

#pragma mark -

- (NSSet *)contactsForPerson:(ABPerson *)person
{
	NSArray			*allServiceKeys = [serviceDict allKeys];
	NSString		*serviceID;
	NSMutableSet	*contactSet = [NSMutableSet set];
	ABMultiValue	*emails;
	NSInteger				i, emailsCount;

	//An ABPerson may have multiple emails; iterate through them looking for @mac.com addresses
	{
		emails = [person valueForProperty:kABEmailProperty];
		emailsCount = [emails count];
		
		for (i = 0; i < emailsCount ; i++) {
			NSString	*email;
			
			email = [emails valueAtIndex:i];
			if ([email hasSuffix:@"@mac.com"]) {
				//Retrieve all appropriate contacts
				NSSet	*contacts = [adium.contactController allContactsWithService:[adium.accountController firstServiceWithServiceID:@"Mac"]
																				  UID:email];

				//Add them to our set
				[contactSet unionSet:contacts];

			} else if ([email hasSuffix:@"me.com"]) {
					//Retrieve all appropriate contacts
					NSSet	*contacts = [adium.contactController allContactsWithService:[adium.accountController firstServiceWithServiceID:@"MobileMe"]
																					UID:email];
					
					//Add them to our set
					[contactSet unionSet:contacts];

			} else if ([email hasSuffix:@"gmail.com"] || [email hasSuffix:@"googlemail.com"]) {
				//Retrieve all appropriate contacts
				NSSet	*contacts = [adium.contactController allContactsWithService:[adium.accountController firstServiceWithServiceID:@"GTalk"]
																				UID:email];
				
				//Add them to our set
				[contactSet unionSet:contacts];
			} else if ([email hasSuffix:@"hotmail.com"]) {
				//Retrieve all appropriate contacts
				NSSet	*contacts = [adium.contactController allContactsWithService:[adium.accountController firstServiceWithServiceID:@"MSN"]
																				UID:email];
				
				//Add them to our set
				[contactSet unionSet:contacts];
			}
		}
	}
	
	//Now go through the instant messaging keys
	for (serviceID in allServiceKeys) {
		NSString		*addressBookKey = [serviceDict objectForKey:serviceID];
		ABMultiValue	*names;
		NSInteger				nameCount;

		//An ABPerson may have multiple names; iterate through them
		names = [person valueForProperty:addressBookKey];
		nameCount = [names count];
		
		//Continue to the next serviceID immediately if no names are found
		if (nameCount == 0) continue;
		
		BOOL					isOSCAR = ([serviceID isEqualToString:@"AIM"] || 
										   [serviceID isEqualToString:@"ICQ"]);
		BOOL					isJabber = [serviceID isEqualToString:@"Jabber"] ||
                                           [serviceID isEqualToString:@"XMPP"];
		
		for (i = 0 ; i < nameCount ; i++) {
			NSString	*UID = [[names valueAtIndex:i] compactedString];
			if ([UID length]) {
				if (isOSCAR) {
					serviceID = serviceIDForOscarUID(UID);
					
				} else if (isJabber) {
					serviceID = serviceIDForJabberUID(UID);
				}
				
				NSSet	*contacts = [adium.contactController allContactsWithService:[adium.accountController firstServiceWithServiceID:serviceID]
																				  UID:UID];
				
				//Add them to our set
				[contactSet unionSet:contacts];
			}
		}
	}

	return contactSet;
}

#pragma mark Address book changed
/*!
 * @brief Address book changed externally
 *
 * As a result we add/remove people to/from our address book dictionary cache and update all contacts based on it
 */
- (void)addressBookChanged:(NSNotification *)notification
{
	/* In case of a single person, these will be NSStrings.
	 * In case of more then one, they are will be NSArrays containing NSStrings.
	 */	
	id				addedPeopleUniqueIDs, modifiedPeopleUniqueIDs, deletedPeopleUniqueIDs;
	NSMutableSet	*allModifiedPeople = [[NSMutableSet alloc] init];
	ABPerson		*me = [sharedAddressBook me];
	BOOL			modifiedMe = NO;;

	//Delay listObjectNotifications to speed up metaContact creation
	[[AIContactObserverManager sharedManager] delayListObjectNotifications];

	//Addition of new records
	if ((addedPeopleUniqueIDs = [[notification userInfo] objectForKey:kABInsertedRecords])) {
		NSArray	*peopleToAdd;

		if ([addedPeopleUniqueIDs isKindOfClass:[NSArray class]]) {
			//We are dealing with multiple records
			peopleToAdd = [sharedAddressBook peopleFromUniqueIDs:(NSArray *)addedPeopleUniqueIDs];
		} else {
			//We have only one record
			peopleToAdd = [NSArray arrayWithObject:(ABPerson *)[sharedAddressBook recordForUniqueId:addedPeopleUniqueIDs]];
		}
		AILogWithSignature(@"Adding %@ to address book", peopleToAdd);
		[allModifiedPeople addObjectsFromArray:peopleToAdd];
		[self addToAddressBookDict:peopleToAdd];
	}
	
	//Modification of existing records
	if ((modifiedPeopleUniqueIDs = [[notification userInfo] objectForKey:kABUpdatedRecords])) {
		NSArray	*peopleToAdd;

		if ([modifiedPeopleUniqueIDs isKindOfClass:[NSArray class]]) {
			//We are dealing with multiple records
			[self removeFromAddressBookDict:modifiedPeopleUniqueIDs];
			peopleToAdd = [sharedAddressBook peopleFromUniqueIDs:modifiedPeopleUniqueIDs];
		} else {
			//We have only one record
			[self removeFromAddressBookDict:[NSArray arrayWithObject:modifiedPeopleUniqueIDs]];
			peopleToAdd = [NSArray arrayWithObject:(ABPerson *)[sharedAddressBook recordForUniqueId:modifiedPeopleUniqueIDs]];
		}
		AILogWithSignature(@"Modified unique IDs %@, which correspond to people %@", modifiedPeopleUniqueIDs, peopleToAdd);
		[allModifiedPeople addObjectsFromArray:peopleToAdd];
		[self addToAddressBookDict:peopleToAdd];
	}
	
	//Deletion of existing records
	if ((deletedPeopleUniqueIDs = [[notification userInfo] objectForKey:kABDeletedRecords])) {
		if ([deletedPeopleUniqueIDs isKindOfClass:[NSArray class]]) {
			//We are dealing with multiple records
			[self removeFromAddressBookDict:deletedPeopleUniqueIDs];
		} else {
			//We have only one record
			[self removeFromAddressBookDict:[NSArray arrayWithObject:deletedPeopleUniqueIDs]];
		}
		
		//Note: We have no way of retrieving the records of people who were removed, so we really can't do much here.
		AILogWithSignature(@"Removed %@", deletedPeopleUniqueIDs);
	}
	
	ABPerson		*person;
	
	//Do appropriate updates for each updated ABPerson
	for (person in allModifiedPeople) {
		if (person == me) {
			modifiedMe = YES;
		}

		//It's tempting to not do this if (person == me), but the 'me' contact may also be in the contact list
		[[AIContactObserverManager sharedManager] updateContacts:[self contactsForPerson:person]
									  forObserver:self];
	}

	//Update us if appropriate
	if (modifiedMe) {
		[self updateSelfIncludingIcon:YES];
	}
	
	//Stop delaying list object notifications since we are done
	[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
	[allModifiedPeople release];
}

/*!
 * @brief Update all existing contacts and accounts
 */
- (void)updateAllContacts
{
	[[AIContactObserverManager sharedManager] updateAllListObjectsForObserver:self];
    [self updateSelfIncludingIcon:YES];
}

/*!
 * @brief Account list changed: Update all existing accounts
 */
- (void)accountListChanged:(NSNotification *)notification
{
	[self updateSelfIncludingIcon:NO];
}

/*!
 * @brief Update all existing accounts
 *
 * We use the "me" card to determine the default icon and account display name
 */
- (void)updateSelfIncludingIcon:(BOOL)includeIcon
{
	@try
	{
        //Begin loading image data for the "me" address book entry, if one exists
        ABPerson *me;
        if ((me = [sharedAddressBook me])) {
			
			//Default buddy icon
			if (includeIcon) {
				//Begin the image load
				meTag = [me beginLoadingImageDataForClient:self];
			}
			
			//Set account display names
			if (enableImport) {
				NSString		*myDisplayName, *myPhonetic = nil;
				
				myDisplayName = [self nameForPerson:me phonetic:&myPhonetic];
				
				NSEnumerator	*accountsArray = [[adium.accountController accounts] objectEnumerator];
				AIAccount		*account;
				
				while ((account = [accountsArray nextObject])) {
					if (![account isTemporary]) {
						[[account displayArrayForKey:@"Display Name"] setObject:myDisplayName
																	  withOwner:self
																  priorityLevel:Low_Priority];
						
						if (myPhonetic) {
							[[account displayArrayForKey:@"Phonetic Name"] setObject:myPhonetic
																		   withOwner:self
																	   priorityLevel:Low_Priority];										
						}
					}
				}

				[adium.preferenceController registerDefaults:[NSDictionary dictionaryWithObject:[[NSAttributedString stringWithString:myDisplayName] dataRepresentation]
																						   forKey:KEY_ACCOUNT_DISPLAY_NAME]
													  forGroup:GROUP_ACCOUNT_STATUS];
			}
        }
	}
	@catch(id exc)
	{
		NSLog(@"ABIntegration: Caught %@", exc);
	}
}

#pragma mark Address book caching
/*!
 * @brief rebuild our address book lookup dictionary
 */
- (void)rebuildAddressBookDict
{
	//Delay listObjectNotifications to speed up metaContact creation
	[[AIContactObserverManager sharedManager] delayListObjectNotifications];
	
	[addressBookDict release]; addressBookDict = [[NSMutableDictionary alloc] init];
	
	[self addToAddressBookDict:[sharedAddressBook people]];

	//Stop delaying list object notifications since we are done
	[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
}


/*!
 * @brief Service ID for an OSCAR UID
 *
 * If we are on an OSCAR service we need to resolve our serviceID into the appropriate string
 * because we may have a .Mac, an ICQ, or an AIM name in the field
 */
NSString* serviceIDForOscarUID(NSString *UID)
{
	NSString	*serviceID;

	const char	firstCharacter = [UID characterAtIndex:0];
	
	//Determine service based on UID
	if ([UID hasSuffix:@"@mac.com"]) {
		serviceID = @"Mac";
	} else if ([UID hasSuffix:@"@me.com"]) {
		serviceID = @"MobileMe";
	} else if (firstCharacter >= '0' && firstCharacter <= '9') {
		serviceID = @"ICQ";
	} else {
		serviceID = @"AIM";
	}
	
	return serviceID;
}

/*!
 * @brief Service ID for a Jabber UID
 *
 * If we are on the Jabber server, we need to distinguish between Google Talk (GTalk), LiveJournal, and the rest of the
 * Jabber world. serviceID is already Jabber, so we only need to change if we have a special UID.
 */
NSString* serviceIDForJabberUID(NSString *UID)
{
	NSString	*serviceID;

	if ([UID hasSuffix:@"@gmail.com"] ||
		[UID hasSuffix:@"@googlemail.com"]) {
		serviceID = @"GTalk";
	} else if ([UID hasSuffix:@"@livejournal.com"]) {
		serviceID = @"LiveJournal";
	} else {
		serviceID = @"Jabber";
	}
	
	return serviceID;
}

/*!
 * @brief add people to our address book lookup dictionary
 *
 * Rather than continually searching the address book, a lookup dictionary addressBookDict provides an quick and easy
 * way to look up a unique record ID for an ABPerson based on the service and UID of a contact. addressBookDict contains
 * NSDictionary objects keyed by service ID. Each of these NSDictionary objects contains unique record IDs keyed by compacted
 * (that is, no spaces and no all lowercase) UID. This means we can search while ignoring spaces, which normal AB searching
 * does not allow.
 *
 * In the process of building we look for cards which have multiple screen names listed and, if desired, automatically
 * create metaContacts baesd on this information.
 */
- (void)addToAddressBookDict:(NSArray *)people
{
	NSArray				*allServiceKeys = [serviceDict allKeys];
	ABPerson			*person;
	
	for (person in people) {
		NSString			*serviceID;
		
		NSMutableArray		*UIDsArray = [NSMutableArray array];
		NSMutableArray		*servicesArray = [NSMutableArray array];
		
		NSMutableDictionary	*dict;
		ABMultiValue		*emails;
		NSInteger					i, emailsCount;
		
		//An ABPerson may have multiple emails; iterate through them looking for @mac.com addresses
		{
			emails = [person valueForProperty:kABEmailProperty];
			emailsCount = [emails count];
			
			for (i = 0; i < emailsCount ; i++) {
				NSString	*email;
				
				email = [emails valueAtIndex:i];
				if ([email hasSuffix:@"@mac.com"]) {
					//@mac.com UIDs go into the AIM dictionary
					if (!(dict = [addressBookDict objectForKey:@"AIM"])) {
						dict = [[[NSMutableDictionary alloc] init] autorelease];
						[addressBookDict setObject:dict forKey:@"AIM"];
					}
					
					[dict setObject:[person uniqueId] forKey:email];
					
					//Internally we distinguish them as .Mac addresses (for metaContact purposes below)
					[UIDsArray addObject:email];
					[servicesArray addObject:@"Mac"];

				} else if ([email hasSuffix:@"me.com"]) {
					//@me.com UIDs go into the AIM dictionary
					if (!(dict = [addressBookDict objectForKey:@"AIM"])) {
						dict = [[[NSMutableDictionary alloc] init] autorelease];
						[addressBookDict setObject:dict forKey:@"AIM"];
					}
					
					[dict setObject:[person uniqueId] forKey:email];
					
					//Internally we distinguish them as .Mac addresses (for metaContact purposes below)
					[UIDsArray addObject:email];
					[servicesArray addObject:@"MobileMe"];
					
				} else if ([email hasSuffix:@"gmail.com"] || [email hasSuffix:@"googlemail.com"]) {
					//GTalk UIDs go into the Jabber dictionary
					if (!(dict = [addressBookDict objectForKey:@"Jabber"])) {
						dict = [[[NSMutableDictionary alloc] init] autorelease];
						[addressBookDict setObject:dict forKey:@"Jabber"];
					}
					
					[dict setObject:[person uniqueId] forKey:email];
					
					//Internally we distinguish them as Google Talk addresses (for metaContact purposes below)
					[UIDsArray addObject:email];
					[servicesArray addObject:@"GTalk"];
					
				} else if ([email hasSuffix:@"hotmail.com"]) {
					//GTalk UIDs go into the Jabber dictionary
					if (!(dict = [addressBookDict objectForKey:@"MSN"])) {
						dict = [[[NSMutableDictionary alloc] init] autorelease];
						[addressBookDict setObject:dict forKey:@"MSN"];
					}
					
					[dict setObject:[person uniqueId] forKey:email];
					
					[UIDsArray addObject:email];
					[servicesArray addObject:@"MSN"];
				}
			}
		}
		
		//Now go through the instant messaging keys
		for (serviceID in allServiceKeys) {
			NSString			*addressBookKey = [serviceDict objectForKey:serviceID];
			ABMultiValue		*names;
			NSInteger					nameCount;
			
			//An ABPerson may have multiple names; iterate through them
			names = [person valueForProperty:addressBookKey];
			nameCount = [names count];
			
			//Continue to the next serviceID immediately if no names are found
			if (nameCount == 0) continue;
			
			//One or more names were found, so we'll need a dictionary
			if (!(dict = [addressBookDict objectForKey:serviceID])) {
				dict = [[NSMutableDictionary alloc] init];
				[addressBookDict setObject:dict forKey:serviceID];
				[dict release];
			}
			
			BOOL	isOSCAR = ([serviceID isEqualToString:@"AIM"] || 
							   [serviceID isEqualToString:@"ICQ"]);
			BOOL	isJabber = [serviceID isEqualToString:@"Jabber"] ||
			[serviceID isEqualToString:@"XMPP"];
			
			for (i = 0 ; i < nameCount ; i++) {
				NSString	*UID = [[names valueAtIndex:i] compactedString];
				if ([UID length]) {
					[dict setObject:[person uniqueId] forKey:UID];
					
					[UIDsArray addObject:UID];
					
					if (isOSCAR) {
						serviceID = serviceIDForOscarUID(UID);
						
					} else if (isJabber) {
						serviceID = serviceIDForJabberUID(UID);
					}
					
					[servicesArray addObject:serviceID];
				}
			}
		}

		if (([UIDsArray count] > 1) && createMetaContacts) {
			/* Got a record with multiple names. Group the names together, adding them to the meta contact. */
			AIMetaContact *metaContact, *metaContactHint;
			NSString *uniqueId = [person uniqueId];

			metaContactHint = [adium.contactController knownMetaContactForGroupingUIDs:UIDsArray
																		 forServices:servicesArray];
			if (!metaContactHint) {
				/* Find a metacontact we used previously but which wasn't saved, if possible. This keeps us from creating a 
				 * new metacontact with every launch when the metacontact is created by the address book rather than the user.
				 *
				 * We don't make address book metacontacts actually persistent because then we would persist them even if the address
				 * book card were modified or deleted or if the user disabled "Conslidate contacts listed on the card."
				 */
				NSDictionary *dict = [adium.preferenceController preferenceForKey:KEY_AB_TO_METACONTACT_DICT
																			  group:PREF_GROUP_ADDRESSBOOK];
				NSNumber *metaContactObjectID = [dict objectForKey:uniqueId];
				if (metaContactObjectID)
					metaContactHint = [adium.contactController metaContactWithObjectID:metaContactObjectID];
			}
				
			metaContact = [adium.contactController groupUIDs:UIDsArray 
												   forServices:servicesArray
										  usingMetaContactHint:metaContactHint];
			if (metaContact) {
				[metaContact setValue:uniqueId
						  forProperty:KEY_AB_UNIQUE_ID
							   notify:NotifyNever];

				[personUniqueIdToMetaContactDict setObject:metaContact
													forKey:uniqueId];
				if (metaContact != metaContactHint) {
					//Keep track of the use of this metacontact for this address book card
					NSMutableDictionary *dict = [[[adium.preferenceController preferenceForKey:KEY_AB_TO_METACONTACT_DICT
																						   group:PREF_GROUP_ADDRESSBOOK] mutableCopy] autorelease];
					if (!dict) dict = [NSMutableDictionary dictionary];
					[dict setObject:[metaContact objectID]
							 forKey:uniqueId];
					[adium.preferenceController setPreference:dict
														 forKey:@"UniqueIDToMetaContactObjectIDDictionary"
														  group:PREF_GROUP_ADDRESSBOOK];
				}
			}
		}
	}
}

/*!
 * @brief remove people from our address book lookup dictionary
 */
- (void)removeFromAddressBookDict:(NSArray *)uniqueIDs
{
	NSArray				*allServiceKeys = [serviceDict allKeys];
	NSString			*uniqueID;
	
	for (uniqueID in uniqueIDs) {
		NSString			*serviceID;
		NSMutableDictionary	*dict;
		
		//The same person may have multiple services; iterate through them and remove each one.
		for (serviceID in allServiceKeys) {
			NSEnumerator *keysEnumerator;
			NSString *key;
			
			dict = [addressBookDict objectForKey:serviceID];
			keysEnumerator = [[dict allKeysForObject:uniqueID] objectEnumerator];
			
			//The same person may have multiple accounts from the same service; we should remove them all.
			while ((key = [keysEnumerator nextObject])) {
				[dict removeObjectForKey:key];
			}
		}
	}	
}

#pragma mark AB contextual menu
/*!
 * @brief Validate menu item
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	BOOL	hasABEntry = ([[self class] personForListObject:adium.menuController.currentContextMenuObject] != nil);
	BOOL	result = NO;
	
	if ([menuItem tag] == AIRequiresAddressBookEntry) {
		result = hasABEntry;
	} else if ([menuItem tag] == AIRequiresNoAddressBookEntry) {
		result = !hasABEntry;
	}
	
	return result;
}

/*!
 * @brief Shows the selected contact in Address Book
 */
- (void)showInAddressBook
{
	ABPerson *selectedPerson = [[self class] personForListObject:adium.menuController.currentContextMenuObject];
	NSString *url = [NSString stringWithFormat:@"addressbook://%@", [selectedPerson uniqueId]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

/*!
 * @brief Edits the selected contact in Address Book
 */
- (void)editInAddressBook
{
	ABPerson *selectedPerson = [[self class] personForListObject:adium.menuController.currentContextMenuObject];
	NSString *url = [NSString stringWithFormat:@"addressbook://%@?edit", [selectedPerson uniqueId]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (void)addToAddressBook
{
	AIListObject			*contact = adium.menuController.currentContextMenuObject;
	NSString				*serviceProperty = [AIAddressBookController propertyFromService:contact.service];
	
	if (serviceProperty) {
		ABPerson				*person = [[ABPerson alloc] init];
		
		//Set the name
		[person setValue:contact.displayName forKey:kABFirstNameProperty];
		if (![[contact phoneticName] isEqualToString:contact.displayName])
			[person setValue:[contact phoneticName] forKey:kABFirstNamePhoneticProperty];

		NSString				*UID = contact.formattedUID;
	
		NSEnumerator * containedContactEnu = [contact isKindOfClass:[AIMetaContact class]] ? [[(AIMetaContact *)contact uniqueContainedObjects] objectEnumerator] : [[NSArray arrayWithObject:contact] objectEnumerator];
		AIListObject *c;
		ABMutableMultiValue		*multiValue;
		
		while((c = [containedContactEnu nextObject]))
		{
			multiValue = [[ABMutableMultiValue alloc] init];
			UID = c.formattedUID;
			serviceProperty = [AIAddressBookController propertyFromService:c.service];
			
			//Set the IM property
			[multiValue addValue:UID withLabel:serviceProperty];
			[person setValue:multiValue forKey:serviceProperty];
			
			[multiValue release];
		}

		//Set the image
		[person setImageData:[contact userIconData]];
		
		//Set the notes
		[person setValue:[contact notes] forKey:kABNoteProperty];
		
		//Add our newly created person to the AB database
		if ([sharedAddressBook addRecord:person] && [sharedAddressBook save]) {
			//Save the uid of the new person
			[contact setPreference:[person uniqueId]
							forKey:KEY_AB_UNIQUE_ID
							 group:PREF_GROUP_ADDRESSBOOK];
			
			//Ask the user whether it would like to edit the new contact
			NSInteger result = NSRunAlertPanel(CONTACT_ADDED_SUCCESS_TITLE,
										 CONTACT_ADDED_SUCCESS_Message,
										 AILocalizedString(@"Yes", nil),
										 AILocalizedString(@"No", nil), nil, UID);
			
			if (result == NSOKButton) {
				NSString *url = [[NSString alloc] initWithFormat:@"addressbook://%@?edit", [person uniqueId]];
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
				[url release];
			}
		} else {
			NSRunAlertPanel(CONTACT_ADDED_ERROR_TITLE, CONTACT_ADDED_ERROR_Message, nil, nil, nil);
		}
		
		//Clean up
		[person release];
	}
}

@end
