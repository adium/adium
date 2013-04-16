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

#import "AIJSHTMLContentFilter.h"
#import <Adium/AIContentControllerProtocol.h>
#import <JavaScriptCore/JavaScriptCore.h>

@implementation AIJSHTMLContentFilter

@synthesize chat, func, view, priority;

- (NSString *)filterHTMLString:(NSString *)inHTMLString content:(AIContentObject*)content
{
    if ([content chat] != self.chat) return inHTMLString;
    
    JSObjectRef ref = [self.func JSObject];
    JSContextRef ctx = [[self.view mainFrame] globalContext];
    JSStringRef str = JSStringCreateWithCFString((CFStringRef)inHTMLString);
    JSValueRef args[1] = { JSValueMakeString(ctx, str) };
    
    JSValueRef result = JSObjectCallAsFunction(ctx, ref, NULL, 1, args, NULL);
    
    JSStringRelease(str);
    
    if (!result) return inHTMLString;
    
    JSStringRef resultJSString = JSValueToStringCopy(ctx, result, NULL);
    CFStringRef resultString = JSStringCopyCFString(kCFAllocatorDefault, resultJSString);
    
    JSStringRelease(resultJSString);
    
    return [(NSString *)resultString autorelease];
}

- (CGFloat)filterPriority
{
    return priority;
}

- (void)dealloc
{
    [func release]; func = nil;
    [chat release]; chat = nil;
    [view release]; view = nil;
    
    [adium.contentController unregisterHTMLContentFilter:self];
    
    [super dealloc];
}

@end
