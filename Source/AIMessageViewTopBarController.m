//
//  AIMessageViewTopBarController.m
//  AutoHyperlinks.framework
//
//  Created by Thijs Alkemade on 20-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import "AIMessageViewTopBarController.h"
#import "AIMessageViewController.h"

@implementation AIMessageViewTopBarController

@synthesize owner;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)close:(id)sender
{
    [owner hideTopBarController:self];
}

@end
