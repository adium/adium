//
//  AdiumAuthorization.m
//  Adium
//
//  Created by Evan Schoenberg on 1/18/06.
//

#import "AdiumAuthorization.h"
#import <Adium/AIAuthorizationRequestsWindowController.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
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
	
	[handle release];
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
	if (!eventImage) eventImage = [[NSImage imageNamed:@"DefaultIcon" forClass:[self class]] retain];
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
