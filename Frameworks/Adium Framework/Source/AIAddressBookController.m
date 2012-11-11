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

- (void)adiumFinishedLaunching:(NSNotification *)notification;
- (void)addToAddressBook;
- (void)addressBookChanged:(NSNotification *)notification;
- (void)accountListChanged:(NSNotification *)notification;
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

static AIAddressBookController	*addressBookController = nil;
static ABAddressBook			*sharedAddressBook;
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
		
		//If Address Book integration is enabled, we need those preferences to determine contact's names
		if (enableImport) {
			displayFormat = [adium.preferenceController preferenceForKey:KEY_AB_DISPLAYFORMAT
																	group:PREF_GROUP_ADDRESSBOOK];
			useFirstName = [[adium.preferenceController preferenceForKey:KEY_AB_USE_FIRSTNAME
																   group:PREF_GROUP_ADDRESSBOOK] boolValue];
			useNickNameOnly = [[adium.preferenceController preferenceForKey:KEY_AB_USE_NICKNAME
																	  group:PREF_GROUP_ADDRESSBOOK] boolValue];
		}
		
		//If old format-menu preference is set, perform migration
		if ([adium.preferenceController preferenceForKey:@"AB Display Format" group:PREF_GROUP_ADDRESSBOOK]) {

			NSInteger oldPreference = [[adium.preferenceController preferenceForKey:@"AB Display Format" group:PREF_GROUP_ADDRESSBOOK] integerValue];
			
			switch (oldPreference) {
				case 0: //firstlast
					displayFormat = [[NSString alloc] initWithFormat:@"%@ %@", FORMAT_FIRST_FULL, FORMAT_LAST_FULL];
					break;
				case 1: //first
					displayFormat = FORMAT_FIRST_FULL;
					break;
				case 2: //lastfirst
					displayFormat = [[NSString alloc] initWithFormat:@"%@, %@", FORMAT_LAST_FULL, FORMAT_FIRST_FULL];
					break;
				case 3: //lastfirstnocomma
					displayFormat = [[NSString alloc] initWithFormat:@"%@ %@", FORMAT_LAST_FULL, FORMAT_FIRST_FULL];
					break;
				case 4: //firstlastinitial
					displayFormat = [[NSString alloc] initWithFormat:@"%@ %@", FORMAT_FIRST_FULL, FORMAT_LAST_INITIAL];
					break;
				default:
					displayFormat = [[NSString alloc] initWithFormat:@"%@ %@", FORMAT_FIRST_FULL, FORMAT_LAST_FULL];
			}
			
			[adium.preferenceController setPreference:nil forKey:@"AB Display Format" group:PREF_GROUP_ADDRESSBOOK];
			[adium.preferenceController setPreference:displayFormat 
											   forKey:KEY_AB_DISPLAYFORMAT
												group:PREF_GROUP_ADDRESSBOOK];
		}
		
		//Services dictionary
		serviceDict = [NSDictionary dictionaryWithObjectsAndKeys:kABInstantMessageServiceAIM,@"AIM",
				kABInstantMessageServiceJabber,@"Jabber",
				kABInstantMessageServiceMSN,@"MSN",
				kABInstantMessageServiceYahoo,@"Yahoo!",
				kABInstantMessageServiceICQ,@"ICQ",
				kABInstantMessageServiceFacebook,@"Facebook", nil];
		
		//Shared Address Book
		sharedAddressBook = [ABAddressBook sharedAddressBook];
		
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
		
		for (NSString *name in [NSArray arrayWithObjects:@"AIM", @"MSN", @"Yahoo", @"ICQ", @"Jabber", @"SMS", nil]) {
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
				AILogWithSignature(@"Warning: %@ Could not find %@",self, fullName);
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

	addressBookController = nil;
}

- (void)dealloc
{
	serviceDict = nil;

	sharedAddressBook = nil;
	personUniqueIdToMetaContactDict = nil;

	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	displayFormat = nil;
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
	showInABContextualMenuItem = [[NSMenuItem alloc] initWithTitle:SHOW_IN_AB_CONTEXTUAL_MENU_TITLE
											   action:@selector(showInAddressBook)
										    keyEquivalent:@""];
	[showInABContextualMenuItem setTarget:self];
	[showInABContextualMenuItem setTag:AIRequiresAddressBookEntry];
	
	editInABContextualMenuItem = [[NSMenuItem alloc] initWithTitle:EDIT_IN_AB_CONTEXTUAL_MENU_TITLE
											   action:@selector(editInAddressBook)
										    keyEquivalent:@""];
	[editInABContextualMenuItem setTarget:self];
	[editInABContextualMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[editInABContextualMenuItem setAlternate:YES];
	[editInABContextualMenuItem setTag:AIRequiresAddressBookEntry];
	
	addToABContexualMenuItem = [[NSMenuItem alloc] initWithTitle:ADD_TO_AB_CONTEXTUAL_MENU_TITLE
											 action:@selector(addToAddressBook)
										  keyEquivalent:@""];
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

		if (person && enableImport) {
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
				[phoneticNameArray setObject:nil withOwner:self];
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
		if (person) {
			AIMetaContact *personMetaContact;
			if ((personMetaContact = [personUniqueIdToMetaContactDict objectForKey:[person uniqueId]]) &&
				(personMetaContact != listContact) &&
				![personMetaContact containsObject:listContact]) {
				AILog(@"AIAddressBookController: personMetaContact = %@; listContact = %@; performing metacontact grouping",
					  personMetaContact, listContact);
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
			NSImage	*existingABImage = (existingABImageData ? [[NSImage alloc] initWithData:[person imageData]] : nil);
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
 * @result A string based on the first name, middle name, last name, and/or nickname of the person, as specified via preferences.
 */
- (NSString *)nameForPerson:(ABPerson *)person phonetic:(NSString **)phonetic
{
	NSString *firstName = [person valueForProperty:kABFirstNameProperty];
	NSString *middleName = [person valueForProperty:kABMiddleNameProperty];
	NSString *lastName = [person valueForProperty:kABLastNameProperty];
	NSString *nickName = [person valueForProperty:kABNicknameProperty]; 
	NSString *phoneticFirstName = [person valueForProperty:kABFirstNamePhoneticProperty]; 
	NSString *phoneticMiddleName = [person valueForProperty:kABMiddleNamePhoneticProperty];
	NSString *phoneticLastName = [person valueForProperty:kABLastNamePhoneticProperty];
	
	NSString *displayName = displayFormat;

	// Fallback if format string is empty or unexpected
	if (!displayName || ![displayName isKindOfClass:[NSString class]] || [displayName isEqualToString:@""]) {
		displayName = FORMAT_FIRST_FULL;
	}
	
	// If the record is for a company, return the company name if present
	if (([[person valueForProperty:kABPersonFlags] integerValue] & kABShowAsMask) == kABShowAsCompany) {
		NSString *companyName = [person valueForProperty:kABOrganizationProperty];
		if (companyName && [companyName length]) {
			return companyName;
		}
	}

	BOOL havePhonetic = ((phonetic != NULL) && (phoneticFirstName || phoneticMiddleName || phoneticLastName));
	
	if (useNickNameOnly && nickName && [nickName length] != 0)
		return nickName;
	
	if (useFirstName && (!nickName || [nickName isEqualToString:@""]) && firstName)
		nickName = firstName;


	displayName = [displayName stringByReplacingOccurrencesOfString:FORMAT_FIRST_FULL
														 withString:firstName ? firstName : @""];
	displayName = [displayName stringByReplacingOccurrencesOfString:FORMAT_FIRST_INITIAL
														 withString:([firstName length] > 0) ? [firstName substringToIndex:1] : @""];
	
	displayName = [displayName stringByReplacingOccurrencesOfString:FORMAT_MIDDLE_FULL
														 withString:middleName ? middleName : @""];
	displayName = [displayName stringByReplacingOccurrencesOfString:FORMAT_MIDDLE_INITIAL
														 withString:([middleName length] > 0) ? [middleName substringToIndex:1] : @""];
	
	displayName = [displayName stringByReplacingOccurrencesOfString:FORMAT_LAST_FULL
														 withString:lastName ? lastName : @""];
	displayName = [displayName stringByReplacingOccurrencesOfString:FORMAT_LAST_INITIAL
														 withString:([lastName length] > 0) ? [lastName substringToIndex:1] : @""];

	displayName = [displayName stringByReplacingOccurrencesOfString:FORMAT_NICK_FULL
														 withString:nickName ? nickName : @""];
	displayName = [displayName stringByReplacingOccurrencesOfString:FORMAT_NICK_INITIAL
														 withString:([nickName length] > 0) ? [nickName substringToIndex:1] : @""];

	if (havePhonetic) {
		*phonetic = displayFormat;
		
		*phonetic = [*phonetic stringByReplacingOccurrencesOfString:FORMAT_FIRST_FULL
														 withString:phoneticFirstName ? phoneticFirstName : @""];
		*phonetic = [*phonetic stringByReplacingOccurrencesOfString:FORMAT_FIRST_INITIAL
														 withString:([phoneticFirstName length] > 0) ? [phoneticFirstName substringToIndex:1] : @""];
		
		*phonetic = [*phonetic stringByReplacingOccurrencesOfString:FORMAT_MIDDLE_FULL
														 withString:phoneticMiddleName ? phoneticMiddleName : @""];
		*phonetic = [*phonetic stringByReplacingOccurrencesOfString:FORMAT_MIDDLE_INITIAL
														 withString:([phoneticMiddleName length] > 0) ? [phoneticMiddleName substringToIndex:1] : @""];
		
		*phonetic = [*phonetic stringByReplacingOccurrencesOfString:FORMAT_LAST_FULL
														 withString:phoneticLastName ? phoneticLastName : @""];
		*phonetic = [*phonetic stringByReplacingOccurrencesOfString:FORMAT_LAST_INITIAL
														 withString:([phoneticLastName length] > 0) ? [phoneticLastName substringToIndex:1] : @""];
		
		*phonetic = [*phonetic stringByReplacingOccurrencesOfString:FORMAT_NICK_FULL withString:@""];
		*phonetic = [*phonetic stringByReplacingOccurrencesOfString:FORMAT_NICK_INITIAL withString:@""];
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
	automaticUserIconSync = [[prefDict objectForKey:KEY_AB_IMAGE_SYNC] boolValue];
	useFirstName = [[prefDict objectForKey:KEY_AB_USE_FIRSTNAME] boolValue];
	useNickNameOnly = [[prefDict objectForKey:KEY_AB_USE_NICKNAME] boolValue];
	displayFormat = [prefDict objectForKey:KEY_AB_DISPLAYFORMAT];


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
	
	if ([property isEqualToString:kABInstantMessageServiceAIM])
		serviceID = @"AIM";
	
	else if ([property isEqualToString:kABInstantMessageServiceICQ])
		serviceID = @"ICQ";
	
	else if ([property isEqualToString:kABInstantMessageServiceMSN])
		serviceID = @"MSN";
	
	else if ([property isEqualToString:kABInstantMessageServiceJabber])
		serviceID = @"Jabber";
	
	else if ([property isEqualToString:kABInstantMessageServiceYahoo])
		serviceID = @"Yahoo!";
	
	else if ([property isEqualToString:kABInstantMessageServiceFacebook])
		serviceID = @"Facebook";

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
			result = kABInstantMessageServiceGoogleTalk;
		} else if ([serviceID isEqualToString:@"LiveJournal"]) {
			result = kABInstantMessageServiceJabber;
		} else if ([serviceID isEqualToString:@"Mac"]) {
			result = kABInstantMessageServiceAIM;
		} else if ([serviceID isEqualToString:@"MobileMe"]) {
			result = kABInstantMessageServiceAIM;
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
			//Search for the first ABPerson for a listContact within the metaContact
			for (AIListContact *listContact in [(AIMetaContact *)inObject listContactsIncludingOfflineAccounts]) {
				person = [self personForListObject:listContact];
				if (person)
					break;
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
	ABMultiValue	*homepages;
	NSInteger				i, emailsCount, homepagesCount;

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
	
	//An ABPerson may have multiple hompages; iterate through them looking for fb:// addresses
	{
		homepages = [person valueForProperty:kABURLsProperty];
		homepagesCount = [homepages count];
		
		for (i = 0; i < homepagesCount ; i++) {
			NSURL	*homepage = [NSURL URLWithString:(NSString*)[homepages valueAtIndex:i]];
			if ([[homepage scheme] isEqualToString:@"fb"]) {
				//Retrieve all appropriate contacts
				//This will be fb://profile/XXX where XXX is the UID
				NSString	*facebookNumber = (NSString*)[(NSString*)homepage lastPathComponent];
				NSString	*facebookUID = [NSString stringWithFormat:@"-%@@chat.facebook.com", facebookNumber];

				NSSet		*contacts = [adium.contactController allContactsWithService:[adium.accountController firstServiceWithServiceID:@"Facebook"]
																					UID:facebookUID];
				
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
				NSString *myPhonetic = nil;
				NSString *myDisplayName = [self nameForPerson:me phonetic:&myPhonetic];
				
				for (AIAccount *account in adium.accountController.accounts) {
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
	
	addressBookDict = [[NSMutableDictionary alloc] init];
	
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
		[UID hasSuffix:@"@googlemail.com"] ||
        [UID hasSuffix:@"@public.talk.google.com"]) {
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
		ABMultiValue		*homepages;
		NSInteger					i, emailsCount, homepagesCount;
		
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
						dict = [[NSMutableDictionary alloc] init];
						[addressBookDict setObject:dict forKey:@"AIM"];
					}
					
					[dict setObject:[person uniqueId] forKey:email];
					
					//Internally we distinguish them as .Mac addresses (for metaContact purposes below)
					[UIDsArray addObject:email];
					[servicesArray addObject:@"Mac"];

				} else if ([email hasSuffix:@"me.com"]) {
					//@me.com UIDs go into the AIM dictionary
					if (!(dict = [addressBookDict objectForKey:@"AIM"])) {
						dict = [[NSMutableDictionary alloc] init];
						[addressBookDict setObject:dict forKey:@"AIM"];
					}
					
					[dict setObject:[person uniqueId] forKey:email];
					
					//Internally we distinguish them as .Mac addresses (for metaContact purposes below)
					[UIDsArray addObject:email];
					[servicesArray addObject:@"MobileMe"];
					
				} else if ([email hasSuffix:@"gmail.com"] || [email hasSuffix:@"googlemail.com"]) {
					//GTalk UIDs go into the Jabber dictionary
					if (!(dict = [addressBookDict objectForKey:@"Jabber"])) {
						dict = [[NSMutableDictionary alloc] init];
						[addressBookDict setObject:dict forKey:@"Jabber"];
					}
					
					[dict setObject:[person uniqueId] forKey:email];
					
					//Internally we distinguish them as Google Talk addresses (for metaContact purposes below)
					[UIDsArray addObject:email];
					[servicesArray addObject:@"GTalk"];
					
				} else if ([email hasSuffix:@"hotmail.com"]) {
					//GTalk UIDs go into the Jabber dictionary
					if (!(dict = [addressBookDict objectForKey:@"MSN"])) {
						dict = [[NSMutableDictionary alloc] init];
						[addressBookDict setObject:dict forKey:@"MSN"];
					}
					
					[dict setObject:[person uniqueId] forKey:email];
					
					[UIDsArray addObject:email];
					[servicesArray addObject:@"MSN"];
				}
			}
		}
		
		//An ABPerson may have multiple hompages; iterate through them looking for fb:// addresses
		{
			homepages = [person valueForProperty:kABURLsProperty];
			homepagesCount = [homepages count];
			
			for (i = 0; i < homepagesCount ; i++) {
				NSURL	*homepage = [NSURL URLWithString:(NSString*)[homepages valueAtIndex:i]];
				if ([[homepage scheme] isEqualToString:@"fb"]) {
					//Retrieve all appropriate contacts
					//This will be fb://profile/XXX where XXX is the UID
					NSString	*facebookNumber = (NSString*)[(NSString*)homepage lastPathComponent];
					NSString	*facebookUID = [NSString stringWithFormat:@"-%@@chat.facebook.com", facebookNumber];
					if (!(dict = [addressBookDict objectForKey:@"Facebook"])) {
						dict = [[NSMutableDictionary alloc] init];
						[addressBookDict setObject:dict forKey:@"Facebook"];
					}
												
					[dict setObject:[person uniqueId] forKey:facebookUID];
												
					//Add them to our set
					[UIDsArray addObject:facebookUID];
					[servicesArray addObject:@"Facebook"];
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
				NSDictionary *prefsDict = [adium.preferenceController preferenceForKey:KEY_AB_TO_METACONTACT_DICT
																			  group:PREF_GROUP_ADDRESSBOOK];
				NSNumber *metaContactObjectID = [prefsDict objectForKey:uniqueId];
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
					NSMutableDictionary *prefsDict = [[adium.preferenceController preferenceForKey:KEY_AB_TO_METACONTACT_DICT
																						   group:PREF_GROUP_ADDRESSBOOK] mutableCopy];
					if (!prefsDict) prefsDict = [NSMutableDictionary dictionary];
					[prefsDict setObject:[metaContact objectID]
                                  forKey:uniqueId];
					[adium.preferenceController setPreference:prefsDict
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
	for (NSString *uniqueID in uniqueIDs) {
		
		//The same person may have multiple services; iterate through them and remove each one.
		for (NSString *serviceID in [serviceDict allKeys]) {
			
			NSMutableDictionary *dict = [addressBookDict objectForKey:serviceID];
			
			//The same person may have multiple accounts from the same service; we should remove them all.
			for (NSString *key in [dict allKeysForObject:uniqueID]) {
				[dict removeObjectForKey:key];
			}
		}
	}	
}

#pragma mark AB contextual menu

/*!
 * @brief Does the specified listObject have information valid to be added to the address book?
 *
 * Specifically, this requires one or more contacts in the listObject to be on a service we know how
 * to parse into an ABPerson.
 */
- (BOOL)contactMayBeAddedToAddressBook:(AIListObject *)contact
{
	BOOL mayBeAdded = NO;
	if ([contact isKindOfClass:[AIMetaContact class]]) {
		for (AIListObject *c in [(AIMetaContact *)contact uniqueContainedObjects]) {
			if ([AIAddressBookController propertyFromService:c.service] != nil) {
				mayBeAdded = YES;
				break;
			}
		}

	} else {
		mayBeAdded = ([AIAddressBookController propertyFromService:contact.service] != nil);
	}
	
	return mayBeAdded;
}



/*!
 * @brief Validate menu item
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	AIListObject *listObject = adium.menuController.currentContextMenuObject;
	BOOL		 hasABEntry = ([[self class] personForListObject:listObject] != nil);
	BOOL		 result = NO;
	
	if ([menuItem tag] == AIRequiresAddressBookEntry) {
		result = hasABEntry;
	} else if ([menuItem tag] == AIRequiresNoAddressBookEntry) {
		result = (!hasABEntry && [self contactMayBeAddedToAddressBook:listObject]);
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

/*!
 * @brief Adds the selected contact to the Address Book
 */
- (void)addToAddressBook
{
	AIListObject *contact = adium.menuController.currentContextMenuObject;
	ABPerson	 *person = [[ABPerson alloc] init];
	NSArray		 *contacts = ([contact isKindOfClass:[AIMetaContact class]] ? 
							  [(AIMetaContact *)contact uniqueContainedObjects] :
							  [NSArray arrayWithObject:contact]);
	BOOL		 validForAddition = NO;
	BOOL		 success = NO;
	
	//Set the name
	[person setValue:contact.displayName forKey:kABFirstNameProperty];
	if (![[contact phoneticName] isEqualToString:contact.displayName])
		[person setValue:[contact phoneticName] forKey:kABFirstNamePhoneticProperty];

	for (AIListObject *c in contacts) {
		NSString *UID = c.formattedUID;
		NSString *serviceProperty = [AIAddressBookController propertyFromService:c.service];
		
		/* We may get here with a metacontact which contains one or more contacts ineligible for addition to the Address
		 * Book; skip these entries.
		 */		
		if (!UID || !serviceProperty)
			continue;
		
		/* Reuse a previously added multivalue for this property if present;
		 * this happens if a metacontact has multiple UIDs for a single service, e.g. multiple AIM names
		 */
		ABMutableMultiValue *multiValue = [person valueForKey:serviceProperty];
		if (!multiValue)
			multiValue = [[ABMutableMultiValue alloc] init];
		
		[multiValue addValue:UID withLabel:serviceProperty];
		[person setValue:multiValue forKey:serviceProperty];
		
		validForAddition = YES;		
	}
	
	if (validForAddition) {
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
											   AILocalizedString(@"No", nil), nil, contact.displayName);
			
			if (result == NSOKButton) {
				NSString *url = [[NSString alloc] initWithFormat:@"addressbook://%@?edit", [person uniqueId]];
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
			}
			
			success = YES;
		}
	}
	
	
	if (!success)
		NSRunAlertPanel(CONTACT_ADDED_ERROR_TITLE, CONTACT_ADDED_ERROR_Message, nil, nil, nil);
}

@end
