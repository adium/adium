//
//  AINewMessageSearchField.m
//  Adium
//
//  Created by Thijs Alkemade on 23-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import "AINewMessageSearchField.h"

@implementation AINewMessageSearchField

- (BOOL)becomeFirstResponder
{
	[table_results setNeedsDisplay];
	
	return [super becomeFirstResponder];
}

@end
