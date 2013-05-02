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

#import "AdiumAuthorization.h"
#import <Adium/AIAuthorizationRequestsWindowController.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>

#define	CONTACT_REQUESTED_AUTHORIZATION @"Contact Requested Authorization"

@implementation AdiumAuthorization

static AdiumAuthorization *sharedInstance;

+ (void)start
{
	if(!sharedInstance)
		sharedInstance = [[AdiumAuthorization alloc] init];
}

- (id)init
{
	if ((self = [super init])) {
		[adium.contactAlertsController registerEventID:CONTACT_REQUESTED_AUTHORIZATION
											 withHandler:self
												 inGroup:AIContactsEventHandlerGroup
											  globalOnly:YES];
	}
	
	return self;
}

+ (id)showAuthorizationRequestWithDict:(NSDictionary *)inDict forAccount:(AIAccount *)inAccount
{
	AIListContact	*listContact = [adium.contactController contactWithService:inAccount.service
																		 account:inAccount
																			 UID:[inDict objectForKey:@"Remote Name"]];

	if (listContact.isBlocked) {
		// Always ignore requests from blocked contacts. Don't even show it to the user.
		AILogWithSignature(@"Authorization request with dict %@ ignored due to %@ being blocked", inDict, listContact);
		[inAccount authorizationWithDict:inDict response:AIAuthorizationNoResponse];
		
		return nil;
	}
	
	AILogWithSignature(@"Adding auth request with dict %@", inDict);
	
	[adium.contactAlertsController generateEvent:CONTACT_REQUESTED_AUTHORIZATION
									 forListObject:(AIListObject *)listContact
										  userInfo:nil
					  previouslyPerformedActionIDs:nil];
	
	NSMutableDictionary *dictWithAccount = [inDict mutableCopy];
	
	[dictWithAccount setObject:inAccount forKey:@"Account"];

	[[AIAuthorizationRequestsWindowController sharedController] addRequestWithDict:dictWithAccount];

	// We intentionally continue to retain the dictWithAccount so we can possibly remove it later.
	return dictWithAccount;
}

+ (void)closeAuthorizationForUIHandle:(id)handle
{
	[[AIAuthorizationRequestsWindowController sharedController] removeRequest:handle];
}

#pragma mark Event descriptions

- (NSString *)shortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:CONTACT_REQUESTED_AUTHORIZATION]) {
		description = AILocalizedString(@"Requests authorization",nil);
	} else {
		description = @"";
	}
	
	return description;
}

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:CONTACT_REQUESTED_AUTHORIZATION]) {
		description = AILocalizedString(@"Contact requests authorization",nil);
	} else {
		description = @"";
	}
	
	return description;
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:CONTACT_REQUESTED_AUTHORIZATION]) {
		description = @"Authorization Requested";
	} else {
		description = @"";
	}
	
	return description;
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	NSString	*description = nil;
	
	if (listObject) {
		NSString	*name;
		NSString	*format;
		
		if ([eventID isEqualToString:CONTACT_REQUESTED_AUTHORIZATION]) {
			format = AILocalizedString(@"When %@ requests authorization",nil);
		} else {
			format = nil;
		}
		
		if (format) {
			name = ([listObject isKindOfClass:[AIListGroup class]] ?
					[NSString stringWithFormat:AILocalizedString(@"a member of %@",nil),listObject.displayName] :
					listObject.displayName);
			
			description = [NSString stringWithFormat:format, name];
		}
		
	} else {
		if ([eventID isEqualToString:CONTACT_REQUESTED_AUTHORIZATION]) {
			description = AILocalizedString(@"When a contact requests authorization",nil);
		}
	}
	
	return description;
}

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	NSString	*description = nil;
	
	if (includeSubject) {
		description = [NSString stringWithFormat:AILocalizedString(@"%@ requested authorization", "Event: <A contact's name> requested authorization"), listObject.formattedUID];

	} else {
		description = AILocalizedString(@"requested authorization", "Event: requested authorization (follows a contact's name displayed as a header)");
	}
	
	return description;
}

- (NSImage *)imageForEventID:(NSString *)eventID
{
	static NSImage	*eventImage = nil;
	if (!eventImage) eventImage = [NSImage imageNamed:@"default-icon" forClass:[self class]];
	return eventImage;
}

- (NSString *)descriptionForCombinedEventID:(NSString *)eventID
							  forListObject:(AIListObject *)listObject
									forChat:(AIChat *)chat
								  withCount:(NSUInteger)count
{
	return [NSString stringWithFormat:AILocalizedString(@"%u authorization requests", nil), count];
}

@end
