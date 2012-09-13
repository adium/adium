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

#import <Adium/AIStatusControllerProtocol.h>
#import "DCPurpleJabberJoinChatViewController.h"
#import "ESPurpleJabberAccount.h"
#import "ESPurpleJabberAccountViewController.h"
#import "ESJabberService.h"
#import "AMPurpleJabberMoodTooltip.h"
#import <AIUtilities/AICharacterSetAdditions.h>
#import <libpurple/jabber.h>

@interface ESJabberService ()

- (NSCharacterSet *)allowedCharactersInNode;
- (NSCharacterSet *)allowedCharactersInDomain;
- (NSCharacterSet *)allowedCharactersInResource;

@end


@implementation ESJabberService

- (id)init
{
	if ((self = [super init])) {
		moodTooltip = [[AMPurpleJabberMoodTooltip alloc] init];
		[adium.interfaceController registerContactListTooltipEntry:moodTooltip secondaryEntry:YES];
	}

	return self;
}

- (void)dealloc
{
	[adium.interfaceController unregisterContactListTooltipEntry:moodTooltip secondaryEntry:YES];
	[moodTooltip release]; moodTooltip = nil;
	[charactersInNode release]; charactersInNode = nil;
	[charactersInDomain release]; charactersInDomain = nil;
	[charactersInResource release]; charactersInResource = nil;
	
	[super dealloc];
}

//Account Creation
- (Class)accountClass{
	return [ESPurpleJabberAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESPurpleJabberAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [DCPurpleJabberJoinChatViewController joinChatView];
}

- (BOOL)canCreateGroupChats{
	return YES;
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libpurple-Jabber";
}
- (NSString *)serviceID{
	return @"Jabber";
}
- (NSString *)serviceClass{
	return @"Jabber";
}
- (NSString *)shortDescription{
	return @"XMPP";
}
- (NSString *)longDescription{
	return @"XMPP";
}

/*!
 * @brief Placeholder string for the UID field
 */
- (NSString *)UIDPlaceholder
{
	return AILocalizedString(@"username@jabber.org","Sample name and server for new Jabber accounts");
}

/*!
 * @brief Allowed characters in node of jid
 *
 * Jabber IDs are of the form [<node>"@"]<domain>["/"<resource>]
 *
 * This method returns a character set valid for the node part of a jid.
 */
- (NSCharacterSet *)allowedCharactersInNode
{
	/*
	 * Valid unicode characters in node
	 * <node> ::= <conforming-char>[<conforming-char>]*
	 * <conforming-char> ::= #x21 | [#x23-#x25] | [#x28-#x2E] |
	 * [#x30-#x39] | #x3B | #x3D | #x3F |
	 * [#x41-#x7E] | [#x80-#xD7FF] |
	 * [#xE000-#xFFFD] | [#x10000-#x10FFFF]
	 */

	if (!charactersInNode) {
		NSRange x0021;
		x0021.location			= (unsigned int)'!';
		x0021.length			= 1;

		NSRange x0023_0025;
		x0023_0025.location		= (unsigned int)'#';
		x0023_0025.length		= 3;

		NSRange x0028_002E;
		x0028_002E.location		= (unsigned int)'(';
		x0028_002E.length		= 7;

		NSRange x0030_0039;
		x0030_0039.location		= (unsigned int)'0';
		x0030_0039.length		= 10;

		NSRange x003B;
		x003B.location			= (unsigned int)';';
		x003B.length			= 1;

		NSRange x003D;
		x003D.location			= (unsigned int)'=';
		x003D.length			= 1;

		NSRange x003F;
		x003F.location			= (unsigned int)'?';
		x003F.length			= 1;

		NSRange x0041_007E;
		x0041_007E.location		= (unsigned int)'A';
		x0041_007E.length		= 62;

		NSRange x0080_D7FF;
		x0080_D7FF.location		= (unsigned int)0x0080;
		x0080_D7FF.length		= 55168;

		NSRange xE000_FFFD;
		xE000_FFFD.location		= (unsigned int)0xe000;
		xE000_FFFD.length		= 8190;

		NSRange x10000_10FFFF;
		x10000_10FFFF.location	= (unsigned int)0x10000;
		x10000_10FFFF.length	= 1048576;


		NSMutableCharacterSet *allowedCharactersInNode = [[NSMutableCharacterSet alloc] init];
		[allowedCharactersInNode addCharactersInRange:x0021];
		[allowedCharactersInNode addCharactersInRange:x0023_0025];
		[allowedCharactersInNode addCharactersInRange:x0028_002E];
		[allowedCharactersInNode addCharactersInRange:x0030_0039];
		[allowedCharactersInNode addCharactersInRange:x003B];
		[allowedCharactersInNode addCharactersInRange:x003D];
		[allowedCharactersInNode addCharactersInRange:x003F];
		[allowedCharactersInNode addCharactersInRange:x0041_007E];
		[allowedCharactersInNode addCharactersInRange:x0080_D7FF];
		[allowedCharactersInNode addCharactersInRange:xE000_FFFD];
		[allowedCharactersInNode addCharactersInRange:x10000_10FFFF];


		charactersInNode = [allowedCharactersInNode immutableCopy];
		[allowedCharactersInNode release];
	}

	return charactersInNode;
}

/*!
 * @brief Allowed characters in domain of jid
 *
 * Jabber IDs are of the form [<node>"@"]<domain>["/"<resource>]
 *
 * This method returns a character set valid for the domain part of a jid.
 */
- (NSCharacterSet *)allowedCharactersInDomain
{
	/*
	 * <domain> ::= <hname>["."<hname>]*
	 * <hname> ::= <let>|<dig>[[<let>|<dig>|"-"]*<let>|<dig>]
	 * <let> ::= [a-z] | [A-Z]
	 * <dig> ::= [0-9]
	 */

	if (!charactersInDomain) {
		NSRange lowerCaseLetters;
		lowerCaseLetters.location	= (unsigned int)'a';
		lowerCaseLetters.length		= 26;

		NSRange upperCaseLatters;
		upperCaseLatters.location	= (unsigned int)'A';
		upperCaseLatters.length		= 26;

		NSMutableCharacterSet *allowedCharactersInDomain = [[NSMutableCharacterSet alloc] init];
		[allowedCharactersInDomain addCharactersInRange:lowerCaseLetters];
		[allowedCharactersInDomain addCharactersInRange:upperCaseLatters];
		[allowedCharactersInDomain addCharactersInString:@"-."];

		charactersInDomain = [allowedCharactersInDomain immutableCopy];
		[allowedCharactersInDomain release];
	}

	return charactersInDomain;
}

/*!
 * @brief Allowed characters in resource of jid
 *
 * Jabber IDs are of the form [<node>"@"]<domain>["/"<resource>]
 *
 * This method returns a character set valid for the resource part of a jid.
 */
- (NSCharacterSet *)allowedCharactersInResource
{
	/*
	 * <resource> ::= <any-char>[<any-char>]*
	 * <any-char> ::= [#x20-#xD7FF] | [#xE000-#xFFFD] |
	 * [#x10000-#x10FFFF]
	 */

	if (!charactersInResource) {
		NSRange x0020_D7FF;
		x0020_D7FF.location	= (unsigned int)0x0020;
		x0020_D7FF.length	= 55264;

		NSRange xE000_FFFD;
		xE000_FFFD.location	= (unsigned int)0xe000;
		xE000_FFFD.length	= 8190;

		NSRange x10000_10FFFF;
		x10000_10FFFF.location	= (unsigned int)0x10000;
		x10000_10FFFF.length	= 1048576;

		NSMutableCharacterSet *allowedCharactersInResource = [[NSMutableCharacterSet alloc] init];
		[allowedCharactersInResource addCharactersInRange:x0020_D7FF];
		[allowedCharactersInResource addCharactersInRange:xE000_FFFD];
		[allowedCharactersInResource addCharactersInRange:x10000_10FFFF];

		charactersInResource = [allowedCharactersInResource immutableCopy];
		[allowedCharactersInResource release];
	}

	return charactersInResource;
}

/*!
 * @brief Allowed characters
 * 
 * Jabber IDs are generally of the form username@server.org
 *
 * Some rare Jabber servers assign actual IDs with %. Allow this for transport names such as
 * username%hotmail.com@msn.blah.jabber.org as well.
 */
- (NSCharacterSet *)allowedCharacters
{
	NSMutableCharacterSet	*allowedCharacters = [[NSMutableCharacterSet alloc] init];
	NSCharacterSet			*nodeSet = [self allowedCharactersInNode];
	NSCharacterSet			*domainSet = [self allowedCharactersInDomain];
	NSCharacterSet			*returnSet;

	[allowedCharacters formUnionWithCharacterSet:nodeSet];
	[allowedCharacters addCharactersInString:@"@"];
	[allowedCharacters formUnionWithCharacterSet:domainSet];
	returnSet = [allowedCharacters immutableCopy];
	[allowedCharacters release];

	return [returnSet autorelease];
}

/*!
 * @brief Allowed characters for UIDs
 *
 * Same as allowedCharacters, but also allow / for specifying a resource.
 */
- (NSCharacterSet *)allowedCharactersForUIDs
{
	NSMutableCharacterSet	*allowedCharacters = [[self allowedCharacters] mutableCopy];
	NSCharacterSet			*resourceSet = [self allowedCharactersInResource];
	NSCharacterSet			*returnSet;

	[allowedCharacters addCharactersInString:@"/"];
	[allowedCharacters formUnionWithCharacterSet:resourceSet];
	returnSet = [allowedCharacters immutableCopy];
	[allowedCharacters release];
	
	return [returnSet autorelease];
}

- (NSUInteger)allowedLength{
	return 129;
}

//Passwords are supported but optional
- (BOOL)requiresPassword
{
	return NO;
}

//Generally, Jabber is NOT case sensitive, but handles in group chats are case sensitive, so return YES
//and do custom handling as needed in the account code
- (BOOL)caseSensitive{
	return YES;
}
- (AIServiceImportance)serviceImportance{
	return AIServicePrimary;
}
- (BOOL)canRegisterNewAccounts{
	return YES;
}
- (NSString *)userNameLabel{
    return AILocalizedString(@"Jabber ID",nil); //Jabber ID
}

- (void)registerStatuses{
	[adium.statusController registerStatus:STATUS_NAME_AVAILABLE
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_AWAY
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_FREE_FOR_CHAT
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_FREE_FOR_CHAT]
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_DND
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_DND]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_EXTENDED_AWAY
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_EXTENDED_AWAY]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_INVISIBLE
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_INVISIBLE]
									  ofType:AIInvisibleStatusType
								  forService:self];
}

@end
