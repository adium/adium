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

#import "AILaconicaAccount.h"
#import "AITwitterURLParser.h"

@implementation AILaconicaAccount

- (void)connect
{	
	if (!self.host) {
		[self setLastDisconnectionError:AILocalizedString(@"No Host set", nil)];
		[self didDisconnect];
	} else {
		[super connect];
	}
}

/*!
 * @brief Our default server if none is provided.
 *
 * Do not set a default server.
 */
- (NSString *)defaultServer
{
	return nil;
}

/*!
 * @brief API path
 *
 * The API path extension for the given host.
 */
- (NSString *)apiPath
{
	// We need to guarantee this is an NSString, so -stringByAppendingPathComponent works.
	NSString *path = [self preferenceForKey:LACONICA_PREFERENCE_PATH group:LACONICA_PREF_GROUP] ?: @"";
	
	return [path stringByAppendingPathComponent:@"api"];
}

/*!
 * @brief Our source token
 *
 * On Laconica, our given source token is "adium".
 */
- (NSString *)sourceToken
{
	return @"adium";
}

/*!
 * @brief Our explicit formatted UID
 * 
 * This includes "additional necessary identifying information".
 */
- (NSString *)explicitFormattedUID
{
	if (self.host) {
		return [NSString stringWithFormat:@"%@ (%@)", self.UID, self.host];
	} else {
		return self.UID;
	}
}

/*!
 * @brief Use our host for the servername when storing password
 */
- (BOOL)useHostForPasswordServerName
{
	return YES;
}

/*!
 * @brief Laconica does not yet support OAuth.
 */
- (BOOL)useOAuth
{
	return NO;
}

/*!
 * @brief Returns the link URL for a specific type of link
 */
- (NSString *)addressForLinkType:(AITwitterLinkType)linkType
						  userID:(NSString *)userID
						statusID:(NSString *)statusID
						 context:(NSString *)context
{
	NSString *address = [super addressForLinkType:linkType userID:userID statusID:statusID context:context];
	
	NSString *fullAddress = [self.host stringByAppendingPathComponent:[self preferenceForKey:LACONICA_PREFERENCE_PATH group:LACONICA_PREF_GROUP]];
	
	if (linkType == AITwitterLinkStatus) {
		address = [NSString stringWithFormat:@"https://%@/notice/%@", fullAddress, statusID];
	} else if (linkType == AITwitterLinkFriends) {
		address = [NSString stringWithFormat:@"https://%@/%@/subscriptions", fullAddress, userID];
	} else if (linkType == AITwitterLinkFollowers) {
		address = [NSString stringWithFormat:@"https://%@/%@/subscribers", fullAddress, userID]; 
	} else if (linkType == AITwitterLinkUserPage) {
		address = [NSString stringWithFormat:@"https://%@/%@", fullAddress, userID]; 
	} else if (linkType == AITwitterLinkSearchHash) {
		address = [NSString stringWithFormat:@"http://%@/tag/%@", fullAddress, context];
	} else if (linkType == AITwitterLinkGroup) {
		address = [NSString stringWithFormat:@"http://%@/group/%@", fullAddress, context];
	}
	
	return address;
}

/*!
 * @brief Parse an attributed string into a linkified version.
 */
- (NSAttributedString *)linkifiedAttributedStringFromString:(NSAttributedString *)inString
{	
	NSAttributedString *attributedString = [super linkifiedAttributedStringFromString:inString];
	
	static NSCharacterSet *groupCharacters = nil;
	
	if (!groupCharacters) {
		NSMutableCharacterSet	*disallowedCharacters = [[NSCharacterSet punctuationCharacterSet] mutableCopy];
		[disallowedCharacters formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
		
		groupCharacters = [[disallowedCharacters invertedSet] retain];
		
		[disallowedCharacters release];	
	}
	
	attributedString = [AITwitterURLParser linkifiedStringFromAttributedString:attributedString
															forPrefixCharacter:@"!"
																   forLinkType:AITwitterLinkGroup
																	forAccount:self
															 validCharacterSet:groupCharacters];
	
	return attributedString;
}

@end
