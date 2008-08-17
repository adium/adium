//
//  AILinkedListObject.h
//  AIUtilities.framework
//
//  Created by Sam McCandlish on 9/6/05.
//  Copyright 2005 the Adium Team. All rights reserved.
//

#import <Foundation/NSObject.h>

/* For use by AILinkedList, you probably don't need this. */
@interface AILinkedListObject : NSObject {
	id object;
	AILinkedListObject *last, *next;
}
- (AILinkedListObject *)initWithObject:(id)theObject;

- (id)object;

- (void)setNextObject:(AILinkedListObject *)theObject;

- (AILinkedListObject *)lastObject;
- (AILinkedListObject *)nextObject;
@end
