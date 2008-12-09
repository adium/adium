//
//  RAOperation.m
//  AudioHijackKit2
//
//  Created by Michael Ash on 11/9/08.
//  Copyright 2008 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "RAOperation.h"

#import <objc/message.h>

#import "RALatchTrigger.h"


@implementation RAOperation

- (void)run
{
	NSLog( @"RAOperation is an abstract class, implement -[%@ %@]", [self class], NSStringFromSelector( _cmd ) );
	[self doesNotRecognizeSelector: _cmd];
}

@end

@implementation RASelectorOperation

- (id)initWithTarget: (id)obj selector: (SEL)sel object: (id)arg
{
	if( (self = [super init]) )
	{
		_obj = [obj retain];
		_sel = sel;
		_arg = [arg retain];
	}
	return self;
}

- (void)dealloc
{
	[_obj release];
	[_arg release];
	[_result release];
	
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat: @"<%@:%p: %@ %@ %@>", [self class], self, _obj, NSStringFromSelector( _sel ), _arg];
}

- (void)run
{
	NSMethodSignature *sig = [_obj methodSignatureForSelector: _sel];
	if( [sig methodReturnType][0] == '@' )
		_result = [((id (*)(id, SEL, id))objc_msgSend)( _obj, _sel, _arg ) retain];
	else
		((void (*)(id, SEL, id))objc_msgSend)( _obj, _sel, _arg );
}

- (id)result
{
	return _result;
}

@end

@implementation RAWaitableSelectorOperation

- (id)initWithTarget: (id)obj selector: (SEL)sel object: (id)arg
{
	if( (self = [super initWithTarget: obj selector: sel object: arg]) )
	{
		_trigger = [[RALatchTrigger alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_trigger release];
	
	[super dealloc];
}

- (void)run
{
	[super run];
	[_trigger signal];
}

- (void)waitUntilDone
{
	[_trigger wait];
}

@end

