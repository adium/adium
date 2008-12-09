//
//  RAOperationQueue.m
//  AudioHijackKit2
//
//  Created by Michael Ash on 11/9/08.
//  Copyright 2008 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "RAOperationQueue.h"

#import "RAAtomicList.h"
#import "RALatchTrigger.h"


@interface RAOperationQueueImpl : NSObject
{
	NSThread*		_thread;
	
	RALatchTrigger*	_trigger;
	
	// NOTE: operations in lists are explicitly retained, must be released when popping
	RAAtomicListRef	_operationList;
	RAAtomicListRef	_highPriorityOperationList;
}

- (void)addOperation: (RAOperation *)op;
- (void)addHighPriorityOperation: (RAOperation *)op;
- (void)stop;

@end

@implementation RAOperationQueueImpl

- (id)init
{
	if( (self = [super init]) )
	{
		_trigger = [[RALatchTrigger alloc] init];
		
		_thread = [[NSThread alloc] initWithTarget: self selector: @selector( _workThread ) object: nil];
		[_thread start];
	}
	return self;
}

- (RAOperation *)_popOperation: (RAAtomicListRef *)listPtr
{
	return [(id)RAAtomicListPop( listPtr ) autorelease];
}

- (void)dealloc
{
	[_thread release];
	[_trigger release];
	
	while( [self _popOperation: &_operationList] )
		;
	while( [self _popOperation: &_highPriorityOperationList] )
		;
	
	[super dealloc];
}

- (void)_addOperation: (RAOperation *)op toList: (RAAtomicListRef *)listPtr
{
	RAAtomicListInsert( listPtr, [op retain] );
	[_trigger signal];
}

- (void)addOperation: (RAOperation *)op
{
	[self _addOperation: op toList: &_operationList];
}

- (void)addHighPriorityOperation: (RAOperation *)op
{
	[self _addOperation: op toList: &_highPriorityOperationList];
}

- (void)stop
{
	[_thread cancel];
	[_trigger signal];
}

#pragma mark -

// pop an operation from the given list and run it
// if the list is empty, steal the source list into the given list and run an operation from it
// if both are empty, do nothing
// returns YES if an operation was executed, NO otherwise
- (BOOL)_runOperationFromList: (RAAtomicListRef *)listPtr sourceList: (RAAtomicListRef *)sourceListPtr
{
	RAOperation *op = [self _popOperation: listPtr];
	if( !op )
	{
		*listPtr = RAAtomicListSteal( sourceListPtr );
		// source lists are in LIFO order, but we want to execute operations in the order they were enqueued
		// so we reverse the list before we do anything with it
		RAAtomicListReverse( listPtr );
		op = [self _popOperation: listPtr];
	}
	
	if( op )
		[op run];
	
	return op != nil;
}

- (void)_workThread
{
	NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	RAAtomicListRef operations = NULL;
	RAAtomicListRef highPriorityOperations = NULL;
	
	NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
	
	BOOL didRun = NO;
	while( ![thread isCancelled] )
	{
		if( !didRun )
			[_trigger wait];
		
		// first attempt to run a high-priority operation
		didRun = [self _runOperationFromList: &highPriorityOperations
									   sourceList: &_highPriorityOperationList];
		// if no high priority operation could be run, then attempt to run a low-priority operation
		if( !didRun )
			didRun = [self _runOperationFromList: &operations
									  sourceList: &_operationList];
		
		[innerPool release];
		innerPool = [[NSAutoreleasePool alloc] init];
		
	}
	
	[innerPool release];
	
	while( [self _popOperation: &operations] )
		;
	while( [self _popOperation: &highPriorityOperations] )
		;
	
	[outerPool release];
}

@end


@implementation RAOperationQueue

- (id)init
{
	if( (self = [super init]) )
	{
		_impl = [[RAOperationQueueImpl alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_impl stop];
	[_impl release];
	
	[super dealloc];
}

- (void)addOperation: (RAOperation *)op
{
	[_impl addOperation: op];
}

- (void)addHighPriorityOperation: (RAOperation *)op
{
	[_impl addHighPriorityOperation: op];
}

@end
