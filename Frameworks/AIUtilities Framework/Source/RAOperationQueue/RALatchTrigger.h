//
//  RALatchTrigger.h
//  AudioHijackKit2
//
//  Created by Michael Ash on 11/7/08.
//  Copyright 2008 Rogue Amoeba Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <mach/port.h>


/*
 
 A lockless mostly non-blocking latching trigger class.
 
 This class allows one thread to wait on actions from other threads. It is
 latching, meaning that a signal which arrives when nothing is waiting will
 cause the next waiter to immediately proceed. Multiple signals that are sent
 in succession when no thread is waiting will still only un-block a thread once.
 A signal sent when the latch is already triggered does nothing.
 
 A signaling thread is guaranteed never to block. A waiting thread only
 blocks if no signal has been sent. In other words, it is non-blocking
 except in cases where a thread really does have to wait.
 
 Examples:
 
 thread A waits, no signal has been sent so it blocks
 thread B signals, so thread A returns from waiting
 
 thread B signals
 thread A waits, sees the signal, and immediately returns
 
 thread B signals
 thread B signals again
 thread A waits, sees the signal, and immediately returns
 thread A waits again, and blocks waiting for a signal
 
 */
@interface RALatchTrigger : NSObject
{
	mach_port_t			_triggerPort;
}

- (id)init;

- (void)signal;
- (void)wait;

@end
