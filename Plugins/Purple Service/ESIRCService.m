//
//  ESIRCService.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import "ESIRCService.h"
#import "ESIRCAccount.h"
#import "ESIRCAccountViewController.h"
#import "ESIRCJoinChatViewController.h"
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AICharacterSetAdditions.h>

@implementation ESIRCService
//Account Creation
- (Class)accountClass{
	return [ESIRCAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESIRCAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [ESIRCJoinChatViewController joinChatView];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libpurple-IRC";
}
- (NSString *)serviceID{
	return @"IRC";
}
- (NSString *)serviceClass{
	return @"IRC";
}
- (NSString *)shortDescription{
	return @"IRC";
}
- (NSString *)longDescription{
	return AILocalizedString(@"IRC (Internet Relay Chat)", nil);
}
- (NSCharacterSet *)allowedCharacters{
	//Per RFC-2812: http://www.ietf.org/rfc/rfc2812.txt
	NSMutableCharacterSet	*allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	NSCharacterSet			*returnSet;
	
	[allowedCharacters addCharactersInString:@"[]\\`_^{|}-"];
	returnSet = [allowedCharacters immutableCopy];
	[allowedCharacters release];

	return [returnSet autorelease];
}
- (BOOL)caseSensitive{
	return NO;
}
- (BOOL)canCreateGroupChats{
	return YES;
}
- (BOOL)supportsPassword{
	return YES;
}
//Passwords are supported but optional
- (BOOL)requiresPassword
{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}
/*!
 * @brief Placeholder string for the UID field
 */
- (NSString *)UIDPlaceholder
{
	return AILocalizedString(@"nickname","Sample name and server for new IRC accounts");
}
/*!
 * @brief Username label
 */
- (NSString *)userNameLabel
{
	return AILocalizedString(@"Nickname", "Name for IRC user names");
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
	NSImage *baseImage = [NSImage imageNamed:@"irc" forClass:[self class] loadLazily:YES];

	if (iconType == AIServiceIconSmall || iconType == AIServiceIconList) {
		baseImage = [baseImage imageByScalingToSize:NSMakeSize(16, 16)];
    }

	return baseImage;
}

@end
