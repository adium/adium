//
//  AIQueue.h
//  AIUtilities.framework
//
//  Created by Sam McCandlish on 9/7/05.
//  Copyright 2005 the Adium Team. All rights reserved.
//

#import <AIUtilities/AILinkedList.h>


@interface AIQueue : AILinkedList {
	
}
- (void)enqueue:(id)object;
- (id)dequeue;
@end
