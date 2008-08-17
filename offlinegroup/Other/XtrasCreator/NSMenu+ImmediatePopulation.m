//
//  NSMenu+ImmediatePopulation.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-11-08.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "NSMenu+ImmediatePopulation.h"

@implementation NSMenu (ImmediatePopulation)

- (void) populateFromDelegate
{
	id delegate = [self delegate];

	signed newCount = [delegate numberOfItemsInMenu:self];
	if (newCount < 0)
		return;

	int existingCount = [self numberOfItems];
	if (existingCount > newCount) {
		//remove some items.
		while (existingCount-- > newCount)
			[self removeItemAtIndex:existingCount];
	} else {
		//add some items.
		while (existingCount++ < newCount) {
			NSMenuItem *item = [[NSMenuItem alloc] init];
			[self addItem:item];
			[item release];
		}
	}

	for (int i = 0; i < newCount; ++i) {
		NSMenuItem *item = [self itemAtIndex:i];
		BOOL keepGoing = [delegate menu:self
							 updateItem:item
								atIndex:i
						   shouldCancel:NO];
		if (!keepGoing)
			break;
	}
}

@end
