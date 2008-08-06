//
//  AIDeveloperLinksPlugin.m
//  Adium
//
//  Created by Stephen Holt on 6/2/08.
//

#import "AIDeveloperLinksPlugin.h"
#import <Adium/AISharedAdium.h>

@implementation AIDeveloperLinksPlugin
- (void)installPlugin
{
	tracLinkScanner = [[AIDLLinkScanner alloc] init];
	
	[[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
	[[adium contentController] registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterIncoming];
	[[adium contentController] registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterIncoming];
	[[adium contentController] registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterOutgoing];
}

- (void)uninstallPlugin
{
	[[adium contentController] unregisterContentFilter:self];
}

- (void)dealloc
{
	[tracLinkScanner release];
	
	[super dealloc];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	if(!inAttributedString || ![inAttributedString length]) return inAttributedString;
	
	NSMutableAttributedString	*replacementMessage = [inAttributedString mutableCopy];
	NSRange						linkRange = NSMakeRange(0,0);
	unsigned					stringLength = [replacementMessage length];
	
	for (int i = 0; i < stringLength; i += linkRange.length) {
		if (![replacementMessage attribute:NSLinkAttributeName atIndex:i longestEffectiveRange:&linkRange inRange:NSMakeRange(i, stringLength - i)]) {
			NSAttributedString	*replacementPart = [tracLinkScanner linkifyString:[inAttributedString attributedSubstringFromRange:linkRange]];
			[replacementMessage replaceCharactersInRange:linkRange
									withAttributedString:replacementPart];
			stringLength -= linkRange.length;
			linkRange.length = [replacementPart length];
			stringLength += linkRange.length;
		}
	}
	
	return [replacementMessage autorelease];
}

- (float)filterPriority
{
	return HIGHEST_FILTER_PRIORITY;
}

@end
