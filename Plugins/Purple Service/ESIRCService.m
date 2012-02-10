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
	if ((iconType == AIServiceIconSmall) || (iconType == AIServiceIconList)) {
		return [NSImage imageNamed:@"irc-small" forClass:[self class] loadLazily:YES];
	} else {
		return [NSImage imageNamed:@"irc" forClass:[self class] loadLazily:YES];
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
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"irc-small"];
	} else {
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"irc"];
	}
}

@end
