//
//  AIJSHTMLContentFilter.m
//  Adium
//
//  Created by Thijs Alkemade on 24-03-13.
//  Copyright (c) 2013 The Adium Team. All rights reserved.
//

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
    
    return [[(NSString *)resultString retain] autorelease];
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
