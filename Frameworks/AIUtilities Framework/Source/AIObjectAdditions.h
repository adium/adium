//
//  AIObjectAdditions.h
//  Adium
//
//  Created by Colin Barrett on Mon Sep 22 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

@interface NSObject (RunLoopMessenger)
- (void)mainPerformSelector:(SEL)aSelector;
- (id)mainPerformSelector:(SEL)aSelector returnValue:(BOOL)flag;
- (void)mainPerformSelector:(SEL)aSelector waitUntilDone:(BOOL)flag;

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1;
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 waitUntilDone:(BOOL)flag;
- (id)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 returnValue:(BOOL)flag;

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2;
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 waitUntilDone:(BOOL)flag;
- (id)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 returnValue:(BOOL)flag;

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3;
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 waitUntilDone:(BOOL)flag;
- (id)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 returnValue:(BOOL)flag;

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 withObject:(id)argument4;
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 withObject:(id)argument4 waitUntilDone:(BOOL)flag;

- (void)mainPerformSelector:(SEL)aSelector withObjects:(id)argument1, ... NS_REQUIRES_NIL_TERMINATION;

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 withObject:(id)argument4 waitUntilDone:(BOOL)flag;
- (void)performSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 afterDelay:(NSTimeInterval)delay;

- (void)performSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 afterDelay:(NSTimeInterval)delay;
- (void)performSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3;

- (void)handleInvocation:(NSInvocation *)anInvocation;
@end
