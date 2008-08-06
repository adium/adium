//
//  AIScannerDebug.m
//  Adium
//
//  Created by Evan Schoenberg on 9/27/06.
//

#import "AIScannerDebug.h"

@implementation AIScannerDebug

#ifdef DEBUG_BUILD

+ (void)load
{
	[self poseAsClass:[NSScanner class]];
}

+ (id)scannerWithString:(NSString *)aString
{
	NSParameterAssert(aString != nil);
	
	return [super scannerWithString:aString];	
}

- (id)initWithString:(NSString *)aString
{
	NSParameterAssert(aString != nil);

	return [super initWithString:aString];
}

#endif

@end
