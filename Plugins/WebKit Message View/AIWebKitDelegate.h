//
//  AIWebKitDelegate.h
//  Adium
//
//  Created by David Smith on 5/9/07.
//  Copyright 2007 The Adium Team. All rights reserved.
//

#import <WebKit/WebKit.h>

@class ESWebView;

//This class is a workaround for a crash that occurs in 10.4.9 that we think has to do with webkit delegates being deallocated. Note that this crash is definitely not possible.

@class AIWebKitMessageViewController;

@interface AIWebKitDelegate : NSObject {
	NSMutableDictionary *mapping;
}

+ (AIWebKitDelegate *)sharedWebKitDelegate;
- (void) addDelegate:(AIWebKitMessageViewController *)controller forView:(ESWebView *)wv;
- (void) removeDelegate:(AIWebKitMessageViewController *)controller;

@end
