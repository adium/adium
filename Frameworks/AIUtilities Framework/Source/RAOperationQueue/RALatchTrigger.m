//
//  RALatchTrigger.m
//  AudioHijackKit2
//
//  Created by Michael Ash on 11/7/08.
//  Copyright 2008 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "RALatchTrigger.h"

#import <libkern/OSAtomic.h>
#import <mach/mach.h>
#import <mach/port.h>


@implementation RALatchTrigger

- (id)init
{
	if( (self = [super init]) )
	{
		kern_return_t ret;
		ret = mach_port_allocate( mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &_triggerPort );
		if( ret == KERN_SUCCESS )
		{
			mach_port_limits_t limits = { 1 };
			ret = mach_port_set_attributes( mach_task_self(), _triggerPort, MACH_PORT_LIMITS_INFO, (mach_port_info_t)&limits, sizeof( limits ) / sizeof( natural_t ) );
		}
		if( ret != KERN_SUCCESS )
		{
			NSString *reason = [NSString stringWithFormat: @"RALatchTrigger: could not allocate mach port: %x", ret];
			@throw [NSException exceptionWithName: NSInternalInconsistencyException reason: reason userInfo: nil];
		}
	}
	return self;
}

- (void)dealloc
{
	mach_port_deallocate( mach_task_self(), _triggerPort );
	
	[super dealloc];
}

- (void)signal
{
	kern_return_t result;
	mach_msg_header_t header;
	header.msgh_bits = MACH_MSGH_BITS_REMOTE(MACH_MSG_TYPE_MAKE_SEND);
	header.msgh_size = sizeof( header );
	header.msgh_remote_port = _triggerPort;
	header.msgh_local_port = MACH_PORT_NULL;
	header.msgh_id = 0;
	result = mach_msg(&header, MACH_SEND_MSG | MACH_SEND_TIMEOUT, header.msgh_size, 0, MACH_PORT_NULL, 0, MACH_PORT_NULL);
	if( result != MACH_MSG_SUCCESS && result != MACH_SEND_TIMED_OUT )
	{
		NSString *reason = [NSString stringWithFormat: @"RALatchTrigger: mach port send failed with code %x", result];
		@throw [NSException exceptionWithName: NSInternalInconsistencyException reason: reason userInfo: nil];
	}
}

- (void)wait
{
	mach_msg_header_t msg;
	kern_return_t result = mach_msg(&msg, MACH_RCV_MSG, 0, sizeof(msg), _triggerPort, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
	
	if( result != MACH_MSG_SUCCESS && result != MACH_RCV_TOO_LARGE )
	{
		NSString *reason = [NSString stringWithFormat: @"RALatchTrigger: mach port receive failed with code %x", result];
		@throw [NSException exceptionWithName: NSInternalInconsistencyException reason: reason userInfo: nil];
	}
}

@end
