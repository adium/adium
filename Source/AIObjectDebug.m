/*
 *  AIObjectDebug.m
 *  Adium
 *
 * Created by David Smith on 5/24/2009
 * This class is explicitly released under the BSD license with the following modification:
 * It may be used without reproduction of its copyright notice within The Adium Project.
 *
 * This class was created for use in the Adium project, which is released under the GPL.
 * The release of this specific class (AIObjectDebug) under BSD in no way changes the licensing of any other portion
 * of the Adium project.
 *
 ****
 Copyright (c) 2008, Evan Schoenberg
 Copyright (c) 2009, The Adium Team
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
#ifdef DEBUG_BUILD

#import "AIObjectDebug.h"
#import <objc/objc-runtime.h>

char *__crashreporter_info__ = NULL;
asm(".desc ___crashreporter_info__, 0x10");

@implementation NSObject (AIObjectDebug)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (void)doesNotRecognizeSelector:(SEL)aSelector
{
	if (sel_isEqual(aSelector, @selector(description)) || sel_isEqual(aSelector, @selector(doesNotRecognizeSelector:))) {
		//we're hosed.
		NSLog(@"Avoiding infinite recursion in doesNotRecognizeSelector:");
		abort();
		return;
	} else {
		NSLog(@"%@ of class %@ does not respond to selector %@", self, [self class], NSStringFromSelector(aSelector));
	}
	__crashreporter_info__ = (char *)[[NSString stringWithFormat:@"Dear crash reporter team: We only put stuff here in debug builds of Adium. Don't Panic, it won't ship in a release unless there's public API for it.\n\n %@ of class %@ does not respond to selector %s", self, [self class], aSelector] cStringUsingEncoding:NSASCIIStringEncoding];
    abort();
}
#pragma clang diagnostic pop
@end
#endif
