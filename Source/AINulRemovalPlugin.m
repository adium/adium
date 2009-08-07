//
//  AINulRemovalPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 9/10/06.
//

#import "AINulRemovalPlugin.h"
#import <Adium/AIContentControllerProtocol.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

@implementation AINulRemovalPlugin

- (void)installPlugin
{
    //Register us as a filter
	[adium.contentController registerContentFilter:self ofType:AIFilterContent direction:AIFilterIncoming];
	[adium.contentController registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
}

- (void)uninstallPlugin
{
	[adium.contentController unregisterContentFilter:self];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	if (!inAttributedString || ![inAttributedString length]) return inAttributedString;

	//Don't allow embedded NULs
	static NSString *nulString = nil;
	if (!nulString) {
		UInt8 bytes[1];
		bytes[0] = '\0';
		nulString = (NSString *)CFStringCreateWithBytes(kCFAllocatorDefault, bytes, 1, kCFStringEncodingASCII, false);
	}

	NSAttributedString *nulFreeAttributedString;

	if ([[inAttributedString string] rangeOfString:nulString options:NSLiteralSearch].location != NSNotFound) {
		NSMutableAttributedString *temporaryString = [inAttributedString mutableCopy];
		[temporaryString replaceOccurrencesOfString:nulString
										 withString:@""
											options:NSLiteralSearch
											  range:NSMakeRange(0, [temporaryString length])];
		nulFreeAttributedString = [temporaryString autorelease];

	} else {
		nulFreeAttributedString = inAttributedString;
	}

	return nulFreeAttributedString;
}

/*!
 * @brief When should this filter run?
 *
 * Run this filter as early as possible to remove NULs in case other filters want to use the UTF8String of the filtered string.
 */
- (CGFloat)filterPriority
{
	return HIGHEST_FILTER_PRIORITY;
}

@end
