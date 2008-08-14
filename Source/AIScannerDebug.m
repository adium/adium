//
//  AIScannerDebug.m
//  Adium
//
//  Created by Evan Schoenberg on 9/27/06.
//
#ifdef DEBUG_BUILD

#import "AIScannerDebug.h"
#import <objc/objc-class.h>

@implementation AIScannerDebug

+ (void)load
{
	method_exchangeImplementations(class_getClassMethod(self, @selector(scannerWithString:)), class_getClassMethod([NSScanner class], @selector(scannerWithString:)));
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(initWithString:)), class_getInstanceMethod([NSScanner class], @selector(initWithString:)));
}

//These will be exchanged with the ones in NSScanner, so to get the originals we need to call the AIScannerDebug ones
+ (id)scannerWithString:(NSString *)aString
{
	NSParameterAssert(aString != nil);
	return method_invoke(self, class_getClassMethod([AIScannerDebug class], @selector(scannerWithString:)), aString);
}

- (id)initWithString:(NSString *)aString
{
	NSParameterAssert(aString != nil);
	return method_invoke(self, class_getInstanceMethod([AIScannerDebug class], @selector(initWithString:)), aString);
}

@end

#endif
