//
//  AIFlexibleToolbarItem.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/16/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "AIFlexibleToolbarItem.h"

@implementation AIFlexibleToolbarItem

- (id)initWithItemIdentifier:(NSString *)itemIdentifier
{
	if ((self = [super initWithItemIdentifier:itemIdentifier])) {
		validationDelegate = nil;
	}

	return self;
}

- (void)setValidationDelegate:(id)inDelegate
{
	validationDelegate = inDelegate;
}

- (void)validate
{
	[validationDelegate validateFlexibleToolbarItem:self];
	[super validate];
}

@end
