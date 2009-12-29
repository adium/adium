//
//  SetupAssistantBoxBackgroundView.m
//  Adium
//
//  Created by Brian Ganninger on 8/19/06.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "SetupAssistantBoxBackgroundView.h"


@implementation SetupAssistantBoxBackgroundView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    return self;
}

- (void)drawRect:(NSRect)rect {
	[[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] set]; // plain white for now
	NSRectFill(rect);
}

@end

