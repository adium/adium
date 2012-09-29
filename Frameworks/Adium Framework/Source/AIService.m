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

#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIAccountViewController.h>
#import "AICreateCommand.h"

#define ADIUM_ACCOUNT_CREATION_PAGE @"http://trac.adium.im/wiki/CreatingAnAccount#Sigingupforanaccount"

/*!
 * @class AIService
 * @brief An IM Service
 *
 * This abstract class represents a service that Adium supports.  Subclass this for every service.
 */
@implementation AIService

+ (void)registerService
{
	[[[self alloc] init] autorelease];
}

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		//Register this service with Adium
		[adium.accountController registerService:self];
		
		[self registerStatuses];
	}
	
	return self;
}


//Account Creation -----------------------------------------------------------------------------------------------------
#pragma mark Account Creation
/*!
 * @brief Create a new account for this service
 *
 * Creates a new account of this service.  Accounts are identified by a unique number.  We can't use service or
 * UID, since both those values may change.
 * @param inUID A unique identifier for the account being created.
 * @param inInternalObjectID A unique internalObjectID for the account being created.
 * @return An AIAccount object for this service.
 */
- (id)accountWithUID:(NSString *)inUID internalObjectID:(NSString *)inInternalObjectID
{
	return [[[[self accountClass] alloc] initWithUID:[self normalizeUID:inUID removeIgnoredCharacters:YES]
									internalObjectID:inInternalObjectID
											 service:self] autorelease];
}

/*!
 * @brief Account class associated with this service
 *
 * Subclass to return the account class associated with this service ([AISomethingAccount class]).
 * @return The account class associated with this service.
 */
- (Class)accountClass
{
	return nil;
}

/*!
 * @brief Account view controller for this service
 *
 * Subclass to return an account view controller which provides the necessary controls for configuring an account
 * on this service.
 * @return An AIAccountViewController or subclass for this service.
 */
- (AIAccountViewController *)accountViewController
{
	return [AIAccountViewController accountViewController];
}

/*!
 * @brief Join chat view controller for this service
 *
 * Subclass to return a join chat view controller which provides the necessary controls for joining a chat on this
 * service.
 * @return An DCJoinChatViewController or subclass for this service.
 */
- (DCJoinChatViewController *)joinChatView
{
	return nil;
}


//Service Description --------------------------------------------------------------------------------------------------
#pragma mark Service Description
/*!
 * @brief Unique ID for this class
 *
 * Subclass to return a unique string ID which identifies this class.  No two classes should have the same uniqueID.
 * This value is used to determine which protocol code to use for the user's accounts.
 * Examples: "libgaim-aim", "aim-toc2", "imservices-aim-.mac"
 * @return NSString unique ID
 */
- (NSString *)serviceCodeUniqueID{
    return @"";
}

/*!
 * @brief Service ID for this service
 *
 * Subclass to return a string which identifies this service.  If multiple service classes are supporting the same
 * service they should have the same serviceID.  Not for user-display.
 * Examples: "AIM", "MSN", "Jabber", "ICQ", "Mac"
 * @return NSString service ID
 */
- (NSString *)serviceID{
    return @"";
}

/*!
 * @brief Service class for this service
 *
 * Some separate services can communicate with eachother.  These services, while they have separate serviceID's,
 * are all part of a common service class.  For instance, AIM, ICQ, and .Mac are all part of the "AIM" service class.
 * For many services, the serviceClass will be identical to the serviceID.  Not for user-display.
 * Service classes may change, do not use them for any permenant storage (logs, preferences, etc).
 * Examples: "AIM-compatible", "Jabber", "MSN"
 * @return NSString service class
 */
- (NSString *)serviceClass{
	return @"";
}

/*!
 * @brief Human readable short description
 *
 * Human readable, short description of this service
 * This value is used in tooltips and the message window.
 * Examples: "Jabber", "MSN", "AIM", ".Mac"
 * @return NSString short description
 */
- (NSString *)shortDescription{
    return @"";
}

/*!
 * @brief Human readable long description
 *
 * Human readable, long description of this service
 * If there are multiple classes available for the same service, this description should briefly show the difference
 * between the implementations.  This value is used in the account preferences service menu.
 * Examples: "Jabber", "MSN", "AOL Instant Messenger", ".Mac"
 * @return NSString long description
 */
- (NSString *)longDescription{
    return @"";
}

/*!
 * @brief Label for user name (general)
 *
 * String to use for describing the UID/username of this service.  This value varies by service, but should be something
 * along the lines of "User name", "Account name", "Screen name", "Member name", etc.
 *
 * This will be used for the account preferences to indicate the field for the account's user name.  By default, contactUserNameLabel
 * will return this value, as well.
 *
 * @return NSString label for username
 */
- (NSString *)userNameLabel
{
    return AILocalizedStringFromTableInBundle(@"User Name", nil, [NSBundle bundleForClass:[AIService class]], nil);    
}

/*!
 * @brief Label for user name
 *
 * String to use for describing the UID/username of contacts for this service.  This value varies by service, but should be something
 * along the lines of "User name", "Account name", "Screen name", "Member name", etc.
 *
 * By default, this returns -[self userNameLabel]; only override this method if contacts are named differently than own-account usernames.
 *
 * @return NSString label for username
 */
- (NSString *)contactUserNameLabel
{
	return [self userNameLabel];
}

/*!
 * @brief Placeholder string for the UID field
 */
- (NSString *)UIDPlaceholder
{
	return @"";
}

/*!
 * @brief Account creation URL
 *
 * URL to a page at which the user can sign up to an account on this service or a page that explains how one can sign up for an account
 *
 * This will be used for the button in the account setup pane
 *
 * By default, returns a URL to the account signup page on the Adium wiki
 *
 * @return NSURL for account creation
 */
- (NSURL *)serviceAccountSetupURL
{
	return [NSURL URLWithString:ADIUM_ACCOUNT_CREATION_PAGE];
}

/*!
 * @brief Label for account setup
 *
 * String to use for describing the page that the account creation URL leads to. This value varies according to the nature of the page linked to.
 * Examples "Get AIM Account", "About Lotus", "Get Google Account"
 *
 * This will be used for the button in the account setup pane
 *
 * By default, return a localized string for "Sign up for an account"
 *
 * @return NSString label for account setup
 */
- (NSString *)accountSetupLabel
{
	return AILocalizedString(@"Sign up for an account", @"Defualt label for account registration button in account setup pane.");
}

/*!
 * @brief Service importance
 *
 * Importance grouping of this service.  Used to make service listings and menus more organized by placing more important
 * services at the top of lists or displaying them with more visibility.
 * @return AIServiceImportance importance of this service
 */
- (AIServiceImportance)serviceImportance
{
	return AIServiceUnsupported;
}

/*!
 * @brief Default icon
 *
 * Service Icon packs should always include images for all the built-in Adium services.  This method allows external
 * service plugins to specify an image which will be used when the service icon pack does not specify one.  It will
 * also be useful if new services are added to Adium itself after a significant number of Service Icon packs exist
 * which do not yet have an image for this service.  If the active Service Icon pack provides an image for this service,
 * this method will not be called.
 *
 * The service should _not_ cache this icon internally; multiple calls should return unique NSImage objects.
 *
 * @param iconType The AIServiceIconType of the icon to return. This specifies the desired size of the icon.
 * @return NSImage to use for this service by default
 */
- (NSImage *)defaultServiceIconOfType:(AIServiceIconType)iconType
{
	return nil;
}

/*!
 * @brief Path for default icon
 *
 * For use in message views, this is the path to a default icon as described above.
 *
 * @param iconType The AIServiceIconType of the icon to return.
 * @return The path to the image, otherwise nil.
 */
- (NSString *)pathForDefaultServiceIconOfType:(AIServiceIconType)iconType
{
	return nil;
}

//Service Properties ---------------------------------------------------------------------------------------------------
#pragma mark Service Properties
/*!
 * @brief Allowed characters
 *
 * Characters allowed in user names on this service.  The user will not be allowed to type any characters not in this
 * set as a contact or account name.
 * @return NSCharacterSet of allowed characters
 */
- (NSCharacterSet *)allowedCharacters
{
    return [[NSCharacterSet illegalCharacterSet] invertedSet];
}

/*!
 * @brief Allowed characters for our account name
 *
 * Offers further distinction of allowed characters, for situations where certain characters are allowed
 * for our account name only, or characters which are allowed in user names are forbidden in our own account name.
 * If this distinction is not made, do not subclass this methods and instead subclass allowedCharacters.
 * @return NSCharacterSet of allowed characters
 */
- (NSCharacterSet *)allowedCharactersForAccountName
{
	return ([self allowedCharacters]);
}

/*!
 * @brief Allowed characters for UIDs
 *
 * Offers further distinction of allowed characters, for situations where certain characters are allowed
 * for our account name only, or characters which are allowed in user names are forbidden in our own account name.
 * If this distinction is not made, do not subclass this methods and instead subclass allowedCharacters.
 *
 * @return NSCharacterSet of allowed characters, or nil if all characters are allowed
 */
- (NSCharacterSet *)allowedCharactersForUIDs
{
	return [self allowedCharacters];
}

/*!
 * @brief Ignored characters
 *
 * Ignored characters for user names on this service.  Ignored characters are stripped from account and contact names
 * before they are used, but the user is free to type them and they may be used by the service code.  For instance, 
 * spaces are allowed in AIM usernames, but "ad am" is treated as equal to "adam" because space is an ignored character.
 *
 * @return NSCharacterSet of ignored characters, or nil if no characters are ignored
 */
- (NSCharacterSet *)ignoredCharacters
{
    return nil;
}

/*!
 * @brief Allowed name length
 *
 * Max allowed length of user names of this service.  Account and contact names longer than this will not be allowed.
 * @return Max name length
 */
- (NSUInteger)allowedLength
{
    return NSUIntegerMax;
}

/*!
 * @brief Allowed account name length
 *
 * Offers further distinction of allowed name length, for situations where our account name has a different
 * length restriction than the names of our contacts.  If this distinction is not made, do not subclass these methods
 * and instead subclass allowedLength.
 * @return Max name length
 */
- (NSUInteger)allowedLengthForAccountName
{
	return [self allowedLength];
}

/*!
 * @brief Allowed UID length
 *
 * Offers further distinction of allowed name length, for situations where our account name has a different
 * length restriction than the names of our contacts.  If this distinction is not made, do not subclass these methods
 * and instead subclass allowedLength.
 * @return Max name length
 */
- (NSUInteger)allowedLengthForUIDs
{
	return [self allowedLength];
}

/*!
 * @brief Case sensitivity of names
 *
 * Determines if usernames such as "Adam" and "adam" are unique.
 * @return Case sensitivity
 */
- (BOOL)caseSensitive
{
    return NO;
}

/*!
 * @brief Can create group chats?
 *
 * Does this service support group chats (Also known as multi-user chats, chat rooms, conferences, etc)?  Services
 * which do not support group chats are automatically excluded from the group chat interface elements.
 * @return Can create group chats
 */
- (BOOL)canCreateGroupChats
{
	return NO;
}

/*!
 * @brief Can register accounts?
 *
 * Does this service support registering new accounts from within Adium?  This is here for Jabber.
 * @return Can register accounts
 */
- (BOOL)canRegisterNewAccounts
{
	return NO;
}

/*!
 * @brief Supports proxy settings?
 *
 * Does this service support connecting via a proxy?
 * @return Supports proxy settings
 */
- (BOOL)supportsProxySettings
{
	return YES;
}
/*!
 * @brief Supports password
 *
 * Subclasses should return NO if this service does not use passwords at all for connectivity.
 * If NO, all fields related to passwords will be hidden for this service and the user will never be prompted to
 * enter passwords.
 */
- (BOOL)supportsPassword
{
	return YES;
}

/*!
 * @brief Requires Password
 *
 * Subclasses should return NO if this service does not require a password.  Returning NO from this method will use the password if
 * entered but allow a conection to be initiated with no password without prompting for one.
 * If YES, Adium will insist upon a password being entered before a connection can begin.
 *
 * By default, the service requires a password if it is supported. See -[AIService supportsPassword].
 */
- (BOOL)requiresPassword
{
	return [self supportsPassword];
}

/*!
 * @brief Register statuses
 *
 * Called automatically.  Services should register any supported status with the statusController.
 */
- (void)registerStatuses{};

/*!
 * @brief Default user name 
 * 
 * The default user name for a service is set for all new accounts. As it's not 
 * possible to guess the user name for most service types (AIM, MSN, etc.), the 
 * base class returns @"".
 *
 * @return The default user name for this service, or @"" for no default 
 */ 
- (NSString *)defaultUserName 
{ 
	return @""; 
}

/*!
 * @brief Is this a social networking service like Twitter or Facebook?
 *
 * If YES, accounts on this service treat status very differently than non-social-networking accounts.
 * For example, global status messages dont apply to social networking services, and their status is handled uniquely.
 */
- (BOOL)isSocialNetworkingService
{
	return NO;
}

/*!
 * @brief Is this service hidden?
 *
 * If YES, it will not appear in service dropdowns.
 * This is useful for allowing a legacy service to stick around seamlessly.
 */
- (BOOL)isHidden
{
	return NO;
}

//Utilities ------------------------------------------------------------------------------------------------------------
#pragma mark Utilities
/*!
 * @brief Normalize a UID
 *
 * Normalizes a UID.  All invalid characters and ignored characters are removed.
 * UID's are ONLY filtered when creating contacts, and when renaming contacts.
 * - When changing ownership of a contact, a filter is not necessary, since all the accounts should have the same service
 *   types and requirements.
 * - When account code retrieves contacts from the contact list, filtering is NOT done.  It is up to the account to
 *   ensure it passes UIDs in the proper format for its service type.
 * - Filter UIDs only when the user has entered or mucked with them in some way... UID's TO and FROM account code
 *   SHOULD ALWAYS BE VALID.
 * @return NSString filtered UID
 */
- (NSString *)normalizeUID:(NSString *)inUID removeIgnoredCharacters:(BOOL)removeIgnored
{
	NSString		*workingString = ([self caseSensitive] ? inUID : [inUID lowercaseString]);
	NSCharacterSet	*allowedCharacters = [self allowedCharactersForUIDs];
	NSCharacterSet	*ignoredCharacters = [self ignoredCharacters];

	/* If all characters are allowed, and we're either not removing ignored characters OR there are none, no change
	 * needed. */
	if (!allowedCharacters && (!removeIgnored || !ignoredCharacters))
		return [[inUID copy] autorelease];

	//Prepare a little buffer for our filtered UID
	NSUInteger	destLength = 0;
	NSUInteger	workingStringLength = [workingString length];
	unichar			*dest = malloc(workingStringLength * sizeof(unichar));

	//Filter the UID
	unsigned	pos;
	for (pos = 0; pos < workingStringLength; pos++) {
		unichar c = [workingString characterAtIndex:pos];
		
        if ([allowedCharacters characterIsMember:c] && (!removeIgnored || ![ignoredCharacters characterIsMember:c])) {
            dest[destLength] = (removeIgnored ? c : [inUID characterAtIndex:pos]);
			destLength++;
		}
	}

	//Turn it back into a string and return
    NSString *filteredString = [NSString stringWithCharacters:dest length:destLength];
	free(dest);

	return filteredString;
}

/*!
 * @brief Normalize a chat name
 *
 * The default implementation only lowercases the name.
 */
- (NSString *)normalizeChatName:(NSString *)inChatName
{
	return [inChatName lowercaseString];
}

/*!
 * @brief Compare this service to another, ranking by long description
 */
- (NSComparisonResult)compareLongDescription:(AIService *)inService
{
	return [[self longDescription] compare:[inService longDescription]];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: serviceCodeUniqueID = %@; serviceID = %@; serviceClass = %@; longDescription = %@>",
		NSStringFromClass([self class]), self.serviceCodeUniqueID, self.serviceID, self.serviceClass, self.longDescription];
	
}

#pragma mark AppleScript

/**
 * @brief Returns a list of all accounts that use this service.
 */
- (NSArray *)accounts
{
	NSMutableArray *accountsForThisService = [[[NSMutableArray alloc] init] autorelease];
	for (AIAccount *account in adium.accountController.accounts) {
		if (account.service == self)
			[accountsForThisService addObject:account];
	}
	return accountsForThisService;
}

/**
 * @brief This class is specified using the 'services' key of AIApplication
 */
- (NSScriptObjectSpecifier *)objectSpecifier
{
	NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];
	return [[[NSNameSpecifier alloc]
		   initWithContainerClassDescription:containerClassDesc
		   containerSpecifier:nil key:@"services"
		   name:self.serviceID] autorelease];
}

- (NSData *)image
{
	return [[AIServiceIcons serviceIconForService:self type:AIServiceIconLarge direction:AIIconNormal] TIFFRepresentation];
}

@end
