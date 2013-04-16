//
//  AIJSHTMLContentFilter.h
//  Adium
//
//  Created by Thijs Alkemade on 24-03-13.
//  Copyright (c) 2013 The Adium Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdiumContentFiltering.h"
#import <WebKit/WebKit.h>

@interface AIJSHTMLContentFilter : NSObject <AIHTMLContentFilter> {
    CGFloat priority;
    WebScriptObject *func;
    AIChat *chat;
    
    WebView *view;
}

@property (nonatomic, retain) WebScriptObject *func;
@property (nonatomic, retain) AIChat *chat;
@property (nonatomic, retain) WebView *view;
@property (assign) CGFloat priority;

@end
