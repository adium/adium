//
//  AIJavaController.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-31.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIObject.h"
#import <Adium/AIJavaControllerProtocol.h>

@class NSJavaVirtualMachine;

@interface AIJavaController : AIObject <AIJavaController> {
    NSJavaVirtualMachine *vm;
    Class JavaCocoaAdapter;
}

@end
