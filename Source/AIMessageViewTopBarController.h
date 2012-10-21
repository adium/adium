//
//  AIMessageViewTopBarController.h
//  AutoHyperlinks.framework
//
//  Created by Thijs Alkemade on 20-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIMessageViewController;

@interface AIMessageViewTopBarController : NSViewController {
    AIMessageViewController *owner;
}

@property (assign) AIMessageViewController *owner;
- (IBAction)close:(id)sender;

@end
