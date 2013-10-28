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

#import "AIAutoLinkingPlugin.h"
#import <AutoHyperlinks/AutoHyperlinks.h>
 
/*!
 * @class AIAutoLinkingPlugin
 * @brief Filter component ta automatically create links within attributed strings as appropriate
 *
 * The bulk of this component's work is accomplished by SHHyperlinkScanner
 */
@implementation AIAutoLinkingPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	[adium.contentController registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterIncoming];
	[adium.contentController registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterIncoming];
	[adium.contentController registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterOutgoing];
}

- (void)uninstallPlugin
{
	[adium.contentController unregisterContentFilter:self];
}

/*!
 * @brief Filter an attributed string to add links as appropriate
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	if(!inAttributedString || ![inAttributedString length]) return inAttributedString;

	NSMutableAttributedString	*replacementMessage = [inAttributedString mutableCopy];
	NSRange						linkRange = NSMakeRange(0,0);
	NSUInteger					stringLength = [replacementMessage length];

	if([AHHyperlinkScanner isStringValidURI:[replacementMessage string] usingStrict:YES fromIndex:NULL withStatus:NULL schemeLength:NULL]){
		NSString *linkString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
													(__bridge CFStringRef)[replacementMessage string],
													(CFStringRef)@"#%",
													NULL,
													kCFStringEncodingUTF8);
		NSURL *linkURL = [NSURL URLWithString:linkString];
		if(nil != linkURL) {
			[replacementMessage addAttribute:NSLinkAttributeName
									value:linkURL
									range:NSMakeRange(0, [replacementMessage length])];
		}
	}
	
	for (NSInteger i = 0; i < stringLength; i += linkRange.length) {
		if (![replacementMessage attribute:NSLinkAttributeName atIndex:i longestEffectiveRange:&linkRange inRange:NSMakeRange(i, stringLength - i)]) {
			/* If there's no link at this index already, process it via the hyperlinkScanner to see if there should be one.
			 * We don't process existing links because (a) it would be duplicative effort and (b) we might mess up a link which had
			 * a linkable item within its text, such as "Check out the new story at adium.im" linked to an adium.im page.
			 */
			NSAttributedString	*replacementPart = [[AHHyperlinkScanner hyperlinkScannerWithAttributedString:[inAttributedString attributedSubstringFromRange:linkRange]] linkifiedString];
			[replacementMessage replaceCharactersInRange:linkRange
									withAttributedString:replacementPart];
			stringLength -= linkRange.length;
			linkRange.length = [replacementPart length];
			stringLength += linkRange.length;
		}
	}
	
    return replacementMessage;
}

/*!
 * @brief Filter priority
 *
 * Auto linking overrides other potential filters; do it first
 */
- (CGFloat)filterPriority
{
	return HIGHEST_FILTER_PRIORITY;
}

@end



