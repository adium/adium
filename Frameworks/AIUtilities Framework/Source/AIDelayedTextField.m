//
//  AIDelayedTextField.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.

#import "AIDelayedTextField.h"

//  A text field that groups changes, sending its action to its target when 0.5 seconds elapses without a change

@interface AIDelayedTextField ()
- (id)_init;
@end

@implementation AIDelayedTextField

//Init the field
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		self = [self _init];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self _init];
	}
	return self;
}

- (id)_init
{
	delayInterval = 0.5f;
	
	return self;
}

- (void)setDelayInterval:(float)inInterval
{
	delayInterval = inInterval;
}
- (float)delayInterval
{
	return delayInterval;
}

- (void)fireImmediately
{
	[NSObject cancelPreviousPerformRequestsWithTarget:[self target]
											 selector:[self action]
											   object:self];
	
	[[self target] performSelector:[self action] 
						withObject:self];
}

- (void)textDidChange:(NSNotification *)notification
{
	[super textDidChange:notification];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:[self target]
											 selector:[self action]
											   object:self];
	
	[[self target] performSelector:[self action] 
						withObject:self
						afterDelay:delayInterval];
}

- (void)textDidEndEditing:(NSNotification *)notification
{
	//Don't trigger our delayed changes timer after the field ends editing.
	[NSObject cancelPreviousPerformRequestsWithTarget:[self target]
											 selector:[self action]
											   object:self];
	
	[super textDidEndEditing:notification];
}

@end
