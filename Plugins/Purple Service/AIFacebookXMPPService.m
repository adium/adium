//
//  AIFacebookXMPPService.m
//  Adium
//
//  Created by Colin Barrett on 11/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AIFacebookXMPPAccount.h"
#import "AIXMPPOAuthAccountViewController.h"
#import <AIUtilities/AIImageAdditions.h>

#import "AIFacebookXMPPService.h"

@implementation AIFacebookXMPPService

//Account Creation
- (Class)accountClass{
	return [AIFacebookXMPPAccount class];
}

- (AIAccountViewController *)accountViewController
{
    return [AIXMPPOAuthAccountViewController accountViewController];
}

- (NSString *)serviceCodeUniqueID{
    return FACEBOOK_XMPP_SERVICE_ID;
}

- (NSString *)serviceID{
    return @"Facebook";
}

- (NSString *)serviceClass{
	return @"Facebook";
}

- (NSString *)shortDescription{
    return @"Facebook";
}

- (NSString *)longDescription{
    return @"Facebook";
}

- (BOOL)isSocialNetworkingService
{
	return YES;
}

- (NSString *)userNameLabel{
    return AILocalizedString(@"Email", "Used as a label for a username specified by email address");
}
- (NSString *)contactUserNameLabel{
	return AILocalizedString(@"Facebook Email", "Label for the username for a Facebook contact");
}

/* Allow any characters; technically this should be the email-acceptable-characters regexp. */
- (NSCharacterSet *)allowedCharacters{
	return [[NSCharacterSet illegalCharacterSet] invertedSet];
}

- (AIServiceImportance)serviceImportance
{
	return AIServicePrimary;
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
	if ((iconType == AIServiceIconSmall) || (iconType == AIServiceIconList)) {
		return [NSImage imageNamed:@"facebook-small" forClass:[self class] loadLazily:YES];
	} else {
		return [NSImage imageNamed:@"facebook" forClass:[self class] loadLazily:YES];
	}
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
	if ((iconType == AIServiceIconSmall) || (iconType == AIServiceIconList)) {
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"facebook-small"];
	} else {
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"facebook"];		
	}
}


@end
