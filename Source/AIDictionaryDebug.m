/*
 * AIDictionaryDebug.m
 *
 * Created by Evan Schoenberg on 7/26/05.
 *
 * This class is explicitly released under the BSD license with the following modification:
 * It may be used without reproduction of its copyright notice within The Adium Project.
 *
 * This class was created for use in the Adium project, which is released under the GPL.
 * The release of this specific class (AIDictionaryDebug) under BSD in no way changes the licensing of any other portion
 * of the Adium project.
 *
 ****
 Copyright (c) 2005, Evan Schoenberg
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
#import "AIDictionaryDebug.h"

#ifdef DEBUG_BUILD
#import <objc/objc-class.h>

@interface AIDictionaryDebug (PRIVATE)
+ (IMP)replaceSelector:(SEL)sel ofClass:(Class)oldClass withClass:(Class)newClass;
@end

#endif

@implementation AIDictionaryDebug

#ifdef DEBUG_BUILD

typedef void (*SetObjectForKeyIMP)(id, SEL, id, id);
SetObjectForKeyIMP	originalSetObjectForKey = nil;

typedef void (*RemoveObjectForKeyIMP)(id, SEL, id);
RemoveObjectForKeyIMP	originalRemoveObjectForKey = nil;

extern void _objc_flush_caches(Class);

+ (void)load
{
	originalSetObjectForKey = (SetObjectForKeyIMP)[AIDictionaryDebug replaceSelector:@selector(setObject:forKey:)
																			 ofClass:NSClassFromString(@"NSCFDictionary")
																		   withClass:[AIDictionaryDebug class]];
	originalRemoveObjectForKey = (RemoveObjectForKeyIMP)[AIDictionaryDebug replaceSelector:@selector(removeObjectForKey:)
																				ofClass:NSClassFromString(@"NSCFDictionary")
																			  withClass:[AIDictionaryDebug class]];
}

+ (void)breakpoint
{
	NSLog(@"Invalid NSDictionary access. Set a breakpoint at +[AIDictionaryDebug breakpoint] to debug");
}

- (void)setObject:(id)object forKey:(id)key
{
	if (!object || !key) [AIDictionaryDebug breakpoint];
	NSAssert3(object != nil, @"%@: Attempted to set %@ for %@",self,object,key);
	NSAssert3(key != nil, @"%@: Attempted to set %@ for %@",self,object,key);

	originalSetObjectForKey(self, @selector(setObject:forKey:),object,key);
}

- (void)removeObjectForKey:(id)key
{
	if (!key) [AIDictionaryDebug breakpoint];
	NSAssert1(key != nil, @"%@: Attempted to remove a nil key",self);

	originalRemoveObjectForKey(self, @selector(removeObjectForKey:),key);
}

+ (IMP)replaceSelector:(SEL)sel ofClass:(Class)oldClass withClass:(Class)newClass
{
	IMP original = [oldClass instanceMethodForSelector:sel];

	if (!original) {
		NSLog(@"Cannot find implementation for '%@' in %@",
		      NSStringFromSelector(sel),
		      NSStringFromClass(oldClass));
		return NULL;
	}

	Method method = class_getInstanceMethod(oldClass, sel); 

	// original to change
	if (!method) {
		NSLog(@"Cannot find method for '%@' in %@",
		      NSStringFromSelector(sel),
		      NSStringFromClass(oldClass));
		return NULL;
	}

	IMP new = class_getMethodImplementation(newClass, sel); // new method to use
	if (!new) {
		NSLog(@"Cannot find implementation for '%@' in %@",
		      NSStringFromSelector(sel),
		      NSStringFromClass(newClass));
		return NULL;
	}

	method_setImplementation(method, new);
	_objc_flush_caches(oldClass);

	return original;
}

#endif
@end
