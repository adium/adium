//
//  ESSimpleService.m
//  Adium
//
//  Created by Evan Schoenberg on 12/17/05.
//

#import "ESSimpleService.h"
#import "ESPurpleSimpleAccount.h"
#import "ESPurpleSimpleAccountViewController.h"
#import <Adium/AIStatusControllerProtocol.h>
#import <AIUtilities/AIImageAdditions.h>

@implementation ESSimpleService
//Account Creation
- (Class)accountClass{
	return [ESPurpleSimpleAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESPurpleSimpleAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return nil;
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libpurple-simple";
}
- (NSString *)serviceID{
	return @"SIMPLE";
}
- (NSString *)serviceClass{
	return @"SIMPLE";
}
- (NSString *)shortDescription{
	return @"SIMPLE";
}
- (NSString *)longDescription{
	return @"SIP / SIMPLE";
}
- (NSCharacterSet *)allowedCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._-@\\"];
}
- (NSUInteger)allowedLength{
	return 255;
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}
- (BOOL)canCreateGroupChats{
	return NO;
}

- (void)registerStatuses{
	[adium.statusController registerStatus:STATUS_NAME_AVAILABLE
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
									  ofType:AIAvailableStatusType
								  forService:self];
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
	return [NSImage imageNamed:@"simple" forClass:[self class] loadLazily:YES];
}

@end
