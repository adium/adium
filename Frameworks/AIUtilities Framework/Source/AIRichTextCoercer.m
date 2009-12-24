//
//  AIRichTextCoercer.m
//  AIUtilities.framework
//
//  Created by Peter Hosey on 2008-01-25.
//

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

	enum { RIGHTWARDS_ARROW = 0x2192 };
	NSLog(@"%s: Input '%@' %C Class %@ %C Result '%@'", __PRETTY_FUNCTION__, input, RIGHTWARDS_ARROW, class, RIGHTWARDS_ARROW, result);

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
