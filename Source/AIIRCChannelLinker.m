//
//  AIIRCChannelLinker.m
//  Adium
//
//  Created by Zachary West on 2009-04-02.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AIIRCChannelLinker.h"
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIChat.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
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
 * Valid channel names are converted into irc://(account host)/(channel name)
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	if (![context isKindOfClass:[AIContentObject class]] ||
		![((AIContentObject *)context).chat.account.service.serviceClass isEqualToString:@"IRC"]) {
		return inAttributedString;
	}
	
	NSScanner					*scanner = [NSScanner scannerWithString:[inAttributedString string]];
	NSMutableAttributedString	*newString = [inAttributedString mutableCopy];
	NSCharacterSet				*channelStart = [NSCharacterSet characterSetWithCharactersInString:@"&#"];
	NSMutableCharacterSet		*validValues;
	
	[scanner setCharactersToBeSkipped:nil];
	
	// Start out with newline and whitespace characters.
	validValues = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
	// Add in comma and space
	[validValues addCharactersInString:@", "];
	// Add in all control characters.
	[validValues formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
	// Now invert.
	[validValues invert];
	
	NSString *trash;
	
	[newString beginEditing];
	
	while(!scanner.isAtEnd) {
		[scanner scanUpToCharactersFromSet:channelStart intoString:&trash];
		
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
		
		// Grab any valid characters we can - # and & are both valid channel names.
		BOOL anyCharacters = [scanner scanCharactersFromSet:validValues intoString:&linkText];

		// If we're at the start *or* the channel name begins after a space or newline, this is a valid link.
		if((scanner.scanLocation - linkText.length) == 1 || 
		   [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[scanner.string characterAtIndex:(scanner.scanLocation - linkText.length - 2)]]) {
			
			NSString *channelName = [scanner.string substringWithRange:NSMakeRange(startLocation, 1)];
			
			// Only append if we have text.
			if (linkText.length) {
				channelName = [channelName stringByAppendingString:linkText];
				
				// If the last character is a punctuation character, drop it.
				if ([[NSCharacterSet punctuationCharacterSet] characterIsMember:[channelName characterAtIndex:channelName.length-1]]) {
					channelName = [channelName substringToIndex:channelName.length-1];
				}
			}
			
			NSString *linkURL = [NSString stringWithFormat:@"irc://%@/%@",
								 ((AIContentObject *)context).chat.account.host,
								 channelName];

			[newString addAttribute:NSLinkAttributeName
							  value:linkURL
							  range:NSMakeRange(startLocation, channelName.length)];
		}
		
		// If we didn't read any characters in following the channel start, advance.
		if (!anyCharacters && scanner.scanLocation + 1 < scanner.string.length) {
			scanner.scanLocation++;
		}
	}
	
	[newString endEditing];
	
	return [newString autorelease];
}

/*!
 * @brief When should this filter run?
 */
- (CGFloat)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}

@end
