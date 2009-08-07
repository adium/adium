//
//  AIColorStringTransformer.m
//  Adium
//
//  Created by Evan Schoenberg on 8/29/07.
//

#import "AIColorStringTransformer.h"
#import <AIUtilities/AIColorAdditions.h>

@implementation AIColorStringTransformer

+ (void)load
{
	if (self == [AIColorStringTransformer class]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[self setValueTransformer:[[[AIColorStringTransformer alloc] init] autorelease]
						  forName:@"AIColorStringTransformer"];
		[pool release];
	}
}

+ (Class)transformedValueClass
{ 
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)value
{
	return ([value isKindOfClass:[NSString class]] ? [value representedColor] : value);
}

- (id)reverseTransformedValue:(id)value
{
	return ([value isKindOfClass:[NSColor class]] ? [value stringRepresentation] : value);
}

@end
