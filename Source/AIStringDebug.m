/*
 *  AIStringDebug.m
 *  Adium
 *
 * Created by Evan Schoenberg on 6/9/08.
 * This class is explicitly released under the BSD license with the following modification:
 * It may be used without reproduction of its copyright notice within The Adium Project.
 *
 * This class was created for use in the Adium project, which is released under the GPL.
 * The release of this specific class (AIStringDebug) under BSD in no way changes the licensing of any other portion
 * of the Adium project.
 *
 ****
 Copyright (c) 2008, Evan Schoenberg
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer 
 in the documentation and/or other materials provided with the distribution.
 Neither the name of Adium nor the names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#import "AIStringDebug.h"

#ifdef DEBUG_BUILD
#import <objc/objc-class.h>
#endif

@implementation AIStringDebug

#ifdef DEBUG_BUILD

+ (void)load
{
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(stringByAppendingString:)), class_getInstanceMethod(NSClassFromString(@"NSCFString"), @selector(stringByAppendingString:)));
}

+ (void)breakpoint
{
	NSLog(@"Invalid NSString access. Set a breakpoint at +[NSString breakpoint] to debug");
}

- (NSString *)stringByAppendingString:(NSString *)string
{
	if (!string) [AIStringDebug breakpoint];
	return method_invoke(self, class_getInstanceMethod([AIStringDebug class], @selector(stringByAppendingString:)), string);
}

#endif
@end
