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

#import "AIRichTextCoercer.h"

@interface AIRichTextCoercer (PRIVATE)
+ (id)coerceRichText:(NSTextStorage *)input toClass:(Class)class;
+ (id)coercePlainText:(NSString *)input toClass:(Class)class;
@end

@implementation AIRichTextCoercer

+ (void)enableRichTextCoercion
{
	Class richTextClass = [NSTextStorage class];
	Class textClass = [NSString class];

	//Quoth the docs: “coercer should typically be a class object.”
	NSScriptCoercionHandler *handler = [NSScriptCoercionHandler sharedCoercionHandler];
	[handler registerCoercer:self
					selector:@selector(coerceRichText:toClass:)
		  toConvertFromClass:richTextClass
					 toClass:textClass];
	[handler registerCoercer:self
					selector:@selector(coercePlainText:toClass:)
		  toConvertFromClass:textClass
					 toClass:richTextClass];
	NSLog(@"%s: Registered as coercion handler", __PRETTY_FUNCTION__);
}

#pragma mark Coercer methods

+ (id)coerceRichText:(NSTextStorage *)input toClass:(Class)class
{
	NSString *result = nil;

	if([class isSubclassOfClass:[NSString class]]) {
		result = [input string];
		if([input isKindOfClass:[NSMutableAttributedString class]]) {
			//The input string is mutable, so make a copy of the string.
			result = [[result copy] autorelease];
		}
	}

    /*
	enum { RIGHTWARDS_ARROW = 0x2192 };
	NSLog(@"%s: Input '%@' %C Class %@ %C Result '%@'", __PRETTY_FUNCTION__, input, RIGHTWARDS_ARROW, class, RIGHTWARDS_ARROW, result);
     */
    
	return result;
}
+ (id)coercePlainText:(NSString *)input toClass:(Class)class
{
	if([class isSubclassOfClass:[NSAttributedString class]]) {
		return [[[class alloc] initWithString:input] autorelease];
	}
	return nil;
}

@end
