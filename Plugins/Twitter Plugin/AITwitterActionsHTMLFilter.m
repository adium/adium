//
//  AITwitterActionsHTMLFilter.m
//  Adium
//
//  Created by Zachary West on 2009-05-23.
//  Copyright 2009 Adium. All rights reserved.
//

#import "AITwitterActionsHTMLFilter.h"
#import "AITwitterAccount.h"
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <AIUtilities/AIMutableStringAdditions.h>

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
			
			return [mutableHTML autorelease];
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
