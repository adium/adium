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

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	if (!inAttributedString || ![inAttributedString length]) return inAttributedString;
	
	NSMutableAttributedString *mutableString = [inAttributedString mutableCopy];
		
	if (!defaultRemovedAttributes) {
		NSFont *defaultFont = [[adium.preferenceController defaultPreferenceForKey:KEY_FORMATTING_FONT
																			 group:PREF_GROUP_FORMATTING
																			object:nil] representedFont];
		
		defaultRemovedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									 defaultFont, NSFontAttributeName,
									 [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f], NSBackgroundColorAttributeName,
									 nil];
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
	
	return mutableString;
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
