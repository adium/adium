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

#import "AIIRCChannelLinker.h"
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIChat.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIListContact.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

@implementation AIIRCChannelLinker

- (void)installPlugin
{
    //Register us as a filter
	[adium.contentController registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterIncoming];
	[adium.contentController registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterOutgoing];
	
	[adium.contentController registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterIncoming];
	[adium.contentController registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterOutgoing];
}

- (void)uninstallPlugin
{
	[adium.contentController unregisterContentFilter:self];
}

/*!
 * @brief Parse the channel names into links.
 *
 * RFC 1459 parsing:
 * <channel>    ::= ('#' | '&') <chstring>
 * <chstring>   ::= <any 8bit code except SPACE, BELL, NUL, CR, LF and comma (',')>
 *
 * We ignore &channels (local channels) since & is commonly used in text, and we do not
 * consider channels with quotes in their name since it will mess up linking.
 *
 * Valid channel names are converted into irc://(account host)/(channel name)
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	AIAccount	*account = nil;
	if ([context isKindOfClass:[AIContentObject class]]) {
		account = ((AIContentObject *)context).chat.account;
	} else if ([context isKindOfClass:[AIListContact class]]) {
		account = ((AIListContact *)context).account;
	}
	
	if (!account || ![account.service.serviceClass isEqualToString:@"IRC"]) {
		return inAttributedString;
	}

	NSScanner					*scanner = [NSScanner scannerWithString:[inAttributedString string]];
	NSMutableAttributedString	*newString = [inAttributedString mutableCopy];

	// Set our character sets static, since we do this _a lot_.
	static NSMutableCharacterSet	*validPrefix = nil;
	static NSCharacterSet			*channelStart = nil;
	static NSMutableCharacterSet	*validValues = nil;
	
	if (!validPrefix) {
		// Characters valid before a channel's start character are all of the mode flags.
		validPrefix = [[NSCharacterSet characterSetWithCharactersInString:@"@+%."] mutableCopy];
		[validPrefix formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	
	if (!channelStart) {
		channelStart = [NSCharacterSet characterSetWithCharactersInString:@"#"];
	}
	
	if (!validValues) {
		// Start out with newline and whitespace characters.
		validValues = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
		// Add in comma, space and quotation marks (technically valid but messes up linking).
		[validValues addCharactersInString:@", \""];
		// Add in all control characters.
		[validValues formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
		// Now invert.
		[validValues invert];
	}
	
	[scanner setCharactersToBeSkipped:nil];
	
	[newString beginEditing];
	
	while(!scanner.isAtEnd) {
		[scanner scanUpToCharactersFromSet:channelStart intoString:NULL];
		
		if(scanner.isAtEnd) {
			break;
		}
		
		NSUInteger	startLocation = scanner.scanLocation;
		NSString	*linkText = nil;
		
		// Advance to the start of the channel name.
		// Check to make sure we aren't exceeding the string bounds.
		if(startLocation < scanner.string.length) {
			scanner.scanLocation++;
		} else {
			break;
		}
		
		// Grab any valid characters we can - # is a valid channel names.
		BOOL anyCharacters = [scanner scanCharactersFromSet:validValues intoString:&linkText];

		// If we're at the start *or* the channel name begins after a space or newline, this is a valid link.
		if((scanner.scanLocation - linkText.length) == 1 || 
		   [validPrefix characterIsMember:[scanner.string characterAtIndex:(scanner.scanLocation - linkText.length - 2)]]) {
			
			if (![inAttributedString attribute:NSLinkAttributeName atIndex:startLocation effectiveRange:NULL]) {
				NSString *channelName = [scanner.string substringWithRange:NSMakeRange(startLocation, 1)];
				
				// Only append if we have text.
				if (linkText.length) {
					channelName = [channelName stringByAppendingString:linkText];
					
					// If the last character is a punctuation character, drop it.
					if ([[NSCharacterSet punctuationCharacterSet] characterIsMember:[channelName characterAtIndex:channelName.length-1]]) {
						channelName = [channelName substringToIndex:channelName.length-1];
					}
				}
				
				NSString *linkURL = [NSString stringWithFormat:@"irc://%@:%d/%@",
									 account.host,
									 account.port,
									 channelName];

				[newString addAttribute:NSLinkAttributeName
								  value:linkURL
								  range:NSMakeRange(startLocation, channelName.length)];
			}
		}
		
		// If we didn't read any characters in following the channel start, advance.
		if (!anyCharacters && scanner.scanLocation + 1 < scanner.string.length) {
			scanner.scanLocation++;
		}
	}
	
	[newString endEditing];
	
	return newString;
}

/*!
 * @brief When should this filter run?
 */
- (CGFloat)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}

@end
