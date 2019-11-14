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
+ (instancetype)scannerWithString:(NSString *)aString
{
	NSParameterAssert(aString != nil);
    
    static id (*_scannerWithString_method_invoke)(id, Method, NSString *) = (id (*)(id, Method, NSString *)) method_invoke;
	return _scannerWithString_method_invoke(self, class_getClassMethod([AIScannerDebug class], @selector(scannerWithString:)), aString);
}

- (instancetype)initWithString:(NSString *)aString
{
	NSParameterAssert(aString != nil);
    
    static id (*_initWithString_method_invoke)(id, Method, NSString *) = (id (*)(id, Method, NSString *)) method_invoke;
	return _initWithString_method_invoke(self, class_getInstanceMethod([AIScannerDebug class], @selector(initWithString:)), aString);
}

@end

#endif
