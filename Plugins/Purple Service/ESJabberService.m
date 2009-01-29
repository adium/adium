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
	return @"Jabber";
}
- (NSString *)longDescription{
	return @"Jabber";
}

/*!
 * @brief Placeholder string for the UID field
 */
- (NSString *)UIDPlaceholder
{
	return AILocalizedString(@"username@jabber.org","Sample name and server for new Jabber accounts");
}

/*!
 * @brief Allowed characters
 * 
 * Jabber IDs are generally of the form username@server.org
 *
 * Some rare Jabber servers assign actual IDs with %. Allow this for transport names such as
 * username%hotmail.com@msn.blah.jabber.org as well.
 */
- (NSCharacterSet *)allowedCharacters{
	NSMutableCharacterSet	*allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	NSCharacterSet			*returnSet;

	[allowedCharacters addCharactersInString:@"._@-()[]^%#|\\`="];
	returnSet = [allowedCharacters immutableCopy];
	[allowedCharacters release];

	return [returnSet autorelease];
}

/*!
 * @brief Allowed characters for UIDs
 *
 * Same as allowedCharacters, but also allow / for specifying a resource.
 */
- (NSCharacterSet *)allowedCharactersForUIDs{
	NSMutableCharacterSet	*allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	NSCharacterSet			*returnSet;

	[allowedCharacters addCharactersInString:@"._@-()[]^%#|\\/+`="];
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
