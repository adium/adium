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

#import "AITwitterActionsHTMLFilter.h"
#import "AITwitterAccount.h"
#import <Adium/AIContentMessage.h>

@implementation AITwitterActionsHTMLFilter

- (void)installPlugin
{
	// Twitter only sends incoming text, so we don't have to worry about outgoing.
	[adium.contentController registerHTMLContentFilter:self direction:AIFilterIncoming];	
}

- (void)uninstallPlugin
{
	[adium.contentController unregisterHTMLContentFilter:self];
}

/*!
 * @brief Convert action link areas to proper HTML.
 *
 * (…) at the end of a message is converted into properly-formatted spans.
 */
- (NSString *)filterHTMLString:(NSString *)inHTMLString content:(AIContentObject*)content
{
	if ([content isKindOfClass:[AIContentMessage class]] && content.message.length) {
		NSDictionary *attributes = [content.message attributesAtIndex:content.message.length-1 effectiveRange:nil];

		if ([[attributes objectForKey:AITwitterActionLinksAttributeName] boolValue]) {
			// We're in a valid message; let's replace!
			
			NSMutableString *mutableHTML = [inHTMLString mutableCopy];
			
			NSRange startRange = [mutableHTML rangeOfString:@" (" options:NSBackwardsSearch];
			
			// Replace the start with <span class="twitter_actions"><span class="twitter_actionStart>(</span>
			// This overall span will be ended next.
			[mutableHTML replaceOccurrencesOfString:@"("
										 withString:@"<span class=\"twitter_actions\"><span class=\"twitter_actionStart\">(</span>"
											options:NSBackwardsSearch
											  range:startRange];
			
			// Replace the end with <span class="twitter_actionEnd">)</span></span>
			// The second </span> finishes off the overall actions links span.
			[mutableHTML replaceOccurrencesOfString:@")"
										 withString:@"<span class=\"twitter_actionEnd\">)</span></span>"
											options:NSBackwardsSearch
											  range:NSMakeRange(mutableHTML.length - 1, 1)];
			
			return mutableHTML;
		}
	}
	
	return inHTMLString;
}

/*!
 * @brief We don't really care when we're processed.
 */
- (CGFloat)filterPriority
{
	return LOWEST_FILTER_PRIORITY;
}

@end
