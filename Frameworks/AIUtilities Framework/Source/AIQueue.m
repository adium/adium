//
//  AIQueue.m
//  AIUtilities.framework
//
//  Created by Sam McCandlish on 9/7/05.
//  Copyright 2005 the Adium Team. All rights reserved.
//

#import "AIQueue.h"


@implementation AIQueue
- (void)enqueue:(id)object {
	@synchronized(self) {
		[self insertObjectAtEnd:object];
	}
}

- (id)dequeue {
	id theObject;
	@synchronized(self) {
		theObject = [self removeObjectAtEnd];
	}
	return theObject;
}
@end
