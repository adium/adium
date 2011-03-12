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

#import <Adium/AIContentControllerProtocol.h>
#import "CBActionSupportPlugin.h"
#import <Adium/AIContentObject.h>
#import <Adium/AIListObject.h>
#import <Adium/AIContentMessage.h>

#define AIActionMessageAttributeName @"AIActionMessage"

/*!
 * @class CBActionSupportPlugin
 * @brief Simple content filter to turn "/me blah" into "<span class='actionMessageUserName'>Name of contact </span><span class="actionMessageBody">blah</span>"
 */
@implementation CBActionSupportPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	[adium.contentController registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterOutgoing];
	[adium.contentController registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterIncoming];

	[adium.contentController registerHTMLContentFilter:self direction:AIFilterOutgoing];
	[adium.contentController registerHTMLContentFilter:self direction:AIFilterIncoming];
}

- (void)uninstallPlugin
{
	[adium.contentController unregisterHTMLContentFilter:self];
	[adium.contentController unregisterContentFilter:self];
}

#pragma mark -

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context;
{
	if( inAttributedString &&
	    [inAttributedString length] &&
	    [[inAttributedString string] rangeOfString:@"/me "
										   options:NSCaseInsensitiveSearch].location == 0 ) {
		NSMutableAttributedString *ourAttributedString = [[inAttributedString mutableCopy] autorelease];
		NSAttributedString *dots = [[[NSAttributedString alloc] initWithString:@"*" attributes:[ourAttributedString attributesAtIndex:[ourAttributedString length] - 1 effectiveRange:NULL]] autorelease];
		[ourAttributedString replaceCharactersInRange:NSMakeRange(0, 4)
										   withString:@"*"];
		[ourAttributedString appendAttributedString:dots];
		[ourAttributedString addAttribute:AIActionMessageAttributeName
									value:[NSNumber numberWithBool:YES]
									range:NSMakeRange(0, [ourAttributedString length])];

		if ([context isKindOfClass:[AIContentMessage class]]) {
			[context addDisplayClass:@"action"];
		}
		
		return ourAttributedString;
	}
	return inAttributedString;
}

/*!
 * @brief Transform the HTML from *foo* to the proper span structure
 */
- (NSString *)filterHTMLString:(NSString *)inHTMLString content:(AIContentObject*)content;
{	
	if ( [content isKindOfClass:[AIContentMessage class]] && content.message.length > 0) {
		AIContentMessage *message = (AIContentMessage *)content;
		if([[[message message] attribute:AIActionMessageAttributeName atIndex:0 effectiveRange:NULL] boolValue]) {

			NSMutableString *mutableHTML = [[inHTMLString mutableCopy] autorelease];
			NSString *replaceString = [NSString stringWithFormat:@"<span class='actionMessageUserName'>%@</span><span class='actionMessageBody'>", [[content source] displayName]];
			[mutableHTML replaceCharactersInRange:[mutableHTML rangeOfString:@"*"] withString:replaceString];
			[mutableHTML replaceCharactersInRange:[mutableHTML rangeOfString:@"*" options:NSBackwardsSearch] withString:@"</span>"];
			return mutableHTML;
		}
	}
	return inHTMLString;
}

/*!
 * @brief Filter priority
 */
- (CGFloat)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}

@end
