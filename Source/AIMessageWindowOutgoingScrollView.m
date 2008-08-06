//
//  AIMessageWindowOutgoingScrollView.m
//  Adium
//
//  Created by Evan Schoenberg on 1/13/08.
//  Copyright 2008 The Adium Team. All rights reserved.
//

#import "AIMessageWindowOutgoingScrollView.h"


@implementation AIMessageWindowOutgoingScrollView

- (BOOL)accessibilityIsIgnored
{
	return YES;
}

- (void)setAccessibilityChild:(id)inChild
{
	accessibilityChild = inChild;
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
    if ([attribute isEqualToString:NSAccessibilityChildrenAttribute])
        return [NSArray arrayWithObject:accessibilityChild];

	else if ([attribute isEqualToString:NSAccessibilityParentAttribute])
		return NSAccessibilityUnignoredAncestor([self superview]);

	else
        return [super accessibilityAttributeValue:attribute];
}
@end
