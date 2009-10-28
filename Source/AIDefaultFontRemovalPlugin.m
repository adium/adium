//
//  AIDefaultFontRemoval.m
//  Adium
//
//  Created by Zachary West on 2009-10-28.
//  Copyright 2009  . All rights reserved.
//

#import "AIDefaultFontRemovalPlugin.h"
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIColorAdditions.h>

@implementation AIDefaultFontRemovalPlugin
- (void)installPlugin
{
	// We only monitor outgoing messages.
	[adium.contentController registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];	
}

- (void)uninstallPlugin
{
	[adium.contentController unregisterContentFilter:self];
}

- (void)dealloc
{
	[defaultRemovedAttributes release];
	[super dealloc];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	if (!inAttributedString || ![inAttributedString length]) return inAttributedString;
	
	NSMutableAttributedString *mutableString = [inAttributedString mutableCopy];
		
	if (!defaultRemovedAttributes) {
		NSFont *defaultFont = [[adium.preferenceController defaultPreferenceForKey:KEY_FORMATTING_FONT
																			 group:PREF_GROUP_FORMATTING
																			object:nil] representedFont];
		
		defaultRemovedAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
									 defaultFont, NSFontAttributeName,
									 [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0], NSBackgroundColorAttributeName,
									 nil] retain];
	}
	
	for (NSString *attributeName in defaultRemovedAttributes.allKeys) {
		NSUInteger position = 0;
		
		while (position < mutableString.length) {
			NSRange attributeRange;
			id attributeValue = [mutableString attribute:attributeName
												 atIndex:position
										  effectiveRange:&attributeRange];

			if (attributeValue && [attributeValue isEqualTo:[defaultRemovedAttributes objectForKey:attributeName]]) {
				[mutableString removeAttribute:attributeName range:attributeRange];
			}
			
			position += attributeRange.length;
		}
	}
	
	return [mutableString autorelease];
}

/*!
 * @brief When should this run?
 *
 * We want this font removal to occur as early as possible, in case any other filters try and modify the fonts.
 */
- (CGFloat)filterPriority
{
	return HIGHEST_FILTER_PRIORITY;
}

@end
