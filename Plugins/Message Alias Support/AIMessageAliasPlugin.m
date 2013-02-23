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

#import "AIMessageAliasPlugin.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>

@interface AIMessageAliasPlugin ()
- (NSMutableAttributedString *)replaceKeywordsInString:(NSAttributedString *)original context:(id)context;
@end

@implementation AIMessageAliasPlugin

- (void)installPlugin
{
    //Register us as a filter
	[adium.contentController registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterIncoming];
	[adium.contentController registerContentFilter:self ofType:AIFilterAutoReplyContent direction:AIFilterOutgoing];
	[adium.contentController registerContentFilter:self ofType:AIFilterTooltips direction:AIFilterIncoming];
	[adium.contentController registerContentFilter:self ofType:AIFilterContactList direction:AIFilterIncoming];
}

- (void)uninstallPlugin
{
	[adium.contentController unregisterContentFilter:self];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	if (!inAttributedString || ![inAttributedString length]) return inAttributedString;

	//Filter keywords in the message
	NSMutableAttributedString	*filteredMessage = [self replaceKeywordsInString:inAttributedString context:context];;

	//Filter keywords in URLs (For AIM subprofile links, mostly)
	NSInteger	length = [(filteredMessage ? filteredMessage : inAttributedString) length];
	NSRange scanRange = NSMakeRange(0, 0);
	while (NSMaxRange(scanRange) < length) {
		id linkURL = [(filteredMessage ? filteredMessage : inAttributedString) attribute:NSLinkAttributeName
																				 atIndex:NSMaxRange(scanRange)
																		  effectiveRange:&scanRange];
		if (linkURL) {
			NSString	*linkURLString;
			
			if ([linkURL isKindOfClass:[NSURL class]]) {
				linkURLString = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault,
																					   (__bridge CFStringRef)[(NSURL *)linkURL absoluteString],
																					   /* characters to leave escaped */ CFSTR(""));
				
			} else {
				linkURLString = (NSString *)linkURL;
			}
			
			if (linkURLString) {
				//If we found a URL, replace any keywords within it
				NSString	*result = [[self replaceKeywordsInString:[NSAttributedString stringWithString:linkURLString]
															 context:context] string];
				
				if (result) {
					NSURL		*newURL;
					NSString	*escapedLinkURLString;
					NSString	*charactersToLeaveUnescaped = @"#";
					
					if (!filteredMessage) filteredMessage = [inAttributedString mutableCopy];
					escapedLinkURLString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(/* allocator */ kCFAllocatorDefault,
																							   (__bridge CFStringRef)result,
																							   (__bridge CFStringRef)charactersToLeaveUnescaped,
																							   /* legal characters to escape */ NULL,
																							   kCFStringEncodingUTF8);
					newURL = [NSURL URLWithString:escapedLinkURLString];
					
					if (newURL) {
						[filteredMessage addAttribute:NSLinkAttributeName
												value:newURL
												range:scanRange];
					}
				}
			}
		}
	}
	
    return (filteredMessage ? filteredMessage : inAttributedString);
}

- (CGFloat)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}

- (BOOL)string:(NSString *)str containsValidKeyword:(NSString *)keyword
{
	NSRange	range = [str rangeOfString:keyword options:NSLiteralSearch];
	BOOL	validKeyword = NO;

	if (range.location != NSNotFound) {
		if ((range.location == 0) || ((NSMaxRange(range) == [str length]))) {
			/* At the beginning or end of the line */
			validKeyword = YES;
		} else {
			NSCharacterSet *alphanumericCharacterSet = [NSCharacterSet alphanumericCharacterSet];
			if (![alphanumericCharacterSet characterIsMember:[str characterAtIndex:(range.location - 1)]] &&
				![alphanumericCharacterSet characterIsMember:[str characterAtIndex:NSMaxRange(range)]]) {
				validKeyword = YES;
			}
		}
	}

	return validKeyword;
}

/*!
 * @brief Replace any AIM-style keywords (%n, %d, %t) in the passed string
 *
 * @param attributedString The string
 * @param context The object for which we are filtering, if known
 *
 * @result A mutable version of the passed string if keywords have been replaced.  Otherwise returns nil.
 */
- (NSMutableAttributedString *)replaceKeywordsInString:(NSAttributedString *)attributedString context:(id)context
{
	NSString					*str = [attributedString string];
	NSMutableAttributedString	*newAttributedString = nil;

	//Abort early if there are no potential keywords
	if ([str rangeOfString:@"%" options:NSLiteralSearch].location == NSNotFound)
		return nil;

	//Our Name
	//If we're passed content, our account will be the destination of that content
	//If we're passed a list object, we can use the name of the preferred account for that object
	if ([self string:str containsValidKeyword:@"%n"]) {
		NSString	*replacement = nil;

		if ([context isKindOfClass:[AIContentObject class]]) {
			replacement = [[context destination] UID]; //This exists primarily for AIM compatibility; AIM uses the UID (no formatting).
		} else if ([context isKindOfClass:[AIListContact class]]) {
			replacement = [[adium.accountController preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																				  toContact:context] formattedUID];
		}

		if (replacement) {
			if (!newAttributedString) newAttributedString = [attributedString mutableCopy];
			
			[newAttributedString replaceOccurrencesOfString:@"%n"
												 withString:replacement
													options:NSLiteralSearch
													  range:NSMakeRange(0, [newAttributedString length])];
		}
	}

	//Current Date
	if ([self string:str containsValidKeyword:@"%d"]) {
		NSCalendarDate	*currentDate = [NSCalendarDate calendarDate];
		__block NSString *calendarFormat;
		[NSDateFormatter withLocalizedShortDateFormatterPerform:^(NSDateFormatter *dateFormatter){
			calendarFormat = [dateFormatter dateFormat];
		}];

		if (!newAttributedString) newAttributedString = [attributedString mutableCopy];
		
		[newAttributedString replaceOccurrencesOfString:@"%d"
											 withString:[currentDate descriptionWithCalendarFormat:calendarFormat]
												options:NSLiteralSearch
												  range:NSMakeRange(0, [newAttributedString length])];
	}
	
	//Current Time
	if ([self string:str containsValidKeyword:@"%t"]) {
		NSCalendarDate 	*currentDate = [NSCalendarDate calendarDate];
		
		if (!newAttributedString) newAttributedString = [attributedString mutableCopy];

		[NSDateFormatter withLocalizedDateFormatterShowingSeconds:YES showingAMorPM:YES perform:^(NSDateFormatter *localDateFormatter){
			[newAttributedString replaceOccurrencesOfString:@"%t"
												 withString:[localDateFormatter stringFromDate:currentDate]
													options:NSLiteralSearch
													  range:NSMakeRange(0, [newAttributedString length])];
		}];
	}
	
	return newAttributedString;
}

@end

