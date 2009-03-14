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
	if (![self preferenceForKey:LACONICA_PREFERENCE_HOST group:LACONICA_PREF_GROUP]) {
		[self setLastDisconnectionError:AILocalizedString(@"No Host set", nil)];
		[self didDisconnect];
	} else if (![self preferenceForKey:LACONICA_PREFERENCE_APIPATH group:LACONICA_PREF_GROUP]) {
		[self setLastDisconnectionError:AILocalizedString(@"No API Path set", nil)];
		[self didDisconnect];		
	} else {
		[super connect];
	}
}

/*!
 * @brief The Host set by the user.
 */
- (NSString *)host
{
	return [self preferenceForKey:LACONICA_PREFERENCE_HOST group:LACONICA_PREF_GROUP];
}

/*!
 * @brief API path
 *
 * The API path extension for the given host.
 */
- (NSString *)apiPath
{
	return [self preferenceForKey:LACONICA_PREFERENCE_APIPATH group:LACONICA_PREF_GROUP];
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
	
	if (linkType == AITwitterLinkStatus) {
		address = [NSString stringWithFormat:@"https://%@/notice/%@", self.host, statusID];
	} else if (linkType == AITwitterLinkFriends) {
		address = [NSString stringWithFormat:@"https://%@/%@/subscriptions", self.host, userID];
	} else if (linkType == AITwitterLinkFollowers) {
		address = [NSString stringWithFormat:@"https://%@/%@/subscribers", self.host, userID]; 
	} else if (linkType == AITwitterLinkUserPage) {
		address = [NSString stringWithFormat:@"https://%@/%@", self.host, userID]; 
	} else if (linkType == AITwitterLinkSearchHash) {
		address = [NSString stringWithFormat:@"http://%@/tag/%@", self.host, context];
	} else if (linkType == AITwitterLinkGroup) {
		address = [NSString stringWithFormat:@"http://%@/group/%@", self.host, context];
	}
	
	return address;
}

/*!
 * @brief Parse an attributed string into a linkified version.
 */
- (NSAttributedString *)linkifiedAttributedStringFromString:(NSAttributedString *)inString
{	
	NSAttributedString *attributedString = [super linkifiedAttributedStringFromString:inString];

	NSMutableCharacterSet	*disallowedCharacters = [[NSCharacterSet punctuationCharacterSet] mutableCopy];
	[disallowedCharacters formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
	
	attributedString = [AITwitterURLParser linkifiedStringFromAttributedString:attributedString
															forPrefixCharacter:@"!"
																   forLinkType:AITwitterLinkGroup
																	forAccount:self
															 validCharacterSet:[disallowedCharacters invertedSet]];
	
	return attributedString;
}

@end
