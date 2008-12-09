//
//  RAOperationQueue.h
//  AudioHijackKit2
//
//  Created by Michael Ash on 11/9/08.
//  Copyright 2008 Rogue Amoeba Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class RAOperation;
@class RAOperationQueueImpl;

@interface RAOperationQueue : NSObject
{
	RAOperationQueueImpl*	_impl;
}

- (id)init;

- (void)addOperation: (RAOperation *)op;
- (void)addHighPriorityOperation: (RAOperation *)op;

@end
