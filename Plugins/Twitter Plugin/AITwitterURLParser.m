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

#import "AITwitterURLParser.h"
#import "AITwitterAccount.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@implementation AITwitterURLParser

+(NSAttributedString *)linkifiedStringFromAttributedString:(NSAttributedString *)inString
										forPrefixCharacter:(NSString *)prefixCharacter
											   forLinkType:(AITwitterLinkType)linkType
												forAccount:(AITwitterAccount *)account
										 validCharacterSet:(NSCharacterSet *)validValues
{
	NSMutableAttributedString	*newString = [inString mutableCopy];
	
	NSScanner		*scanner = [NSScanner scannerWithString:[inString string]];
	
	[scanner setCharactersToBeSkipped:nil];
	
	[newString beginEditing];
	
	while(!scanner.isAtEnd) {
		[scanner scanUpToString:prefixCharacter intoString:NULL];
		
		if(scanner.isAtEnd) {
			break;
		}
		
		NSUInteger	startLocation = scanner.scanLocation;
		NSString	*linkText = nil;

		// Advance to the start of the string we want.
		// Check to make sure we aren't exceeding the string bounds.
		if(startLocation + 1 < scanner.string.length) {
			scanner.scanLocation++;
		} else {
			break;
		}
		
		// Grab any valid characters we can.
		BOOL scannedCharacters = [scanner scanCharactersFromSet:validValues intoString:&linkText];
		
		if(scannedCharacters) {
			if((scanner.scanLocation - linkText.length) == prefixCharacter.length || 
			   [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[scanner.string characterAtIndex:(scanner.scanLocation - linkText.length - prefixCharacter.length - 1)]]) {
				
				NSString *linkURL = nil;
				if(linkType == AITwitterLinkUserPage) {
					linkURL = [account addressForLinkType:linkType userID:[linkText stringByEncodingURLEscapes] statusID:nil context:nil];
				} else if (linkType == AITwitterLinkSearchHash) {
					linkURL = [account addressForLinkType:linkType userID:nil statusID:nil context:[linkText stringByEncodingURLEscapes]];
				} else if (linkType == AITwitterLinkGroup) {
					linkURL = [account addressForLinkType:linkType userID:nil statusID:nil context:[linkText stringByEncodingURLEscapes]];
				}
				
				if(linkURL) {
					[newString addAttribute:NSLinkAttributeName
									  value:linkURL
									  range:NSMakeRange(startLocation + 1, linkText.length)];
				}
			}
		} else {
			scanner.scanLocation++;
		}
	}
	
	[newString endEditing];
	
	return [newString autorelease];
}

@end
