/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIObjectAdditions.h"

// Clever addition by Jonathan Jansson found on cocoadev.com (http://www.cocoadev.com/index.pl?ThreadCommunication)
@implementation NSObject (RunLoopMessenger)

//Included to allow uniform coding
- (void)mainPerformSelector:(SEL)aSelector
{
	[self mainPerformSelector:aSelector waitUntilDone:NO];
}
//Included to allow uniform coding - wrapped for performSelectorOnMainThread:withObject:waitUntilDone:
- (void)mainPerformSelector:(SEL)aSelector waitUntilDone:(BOOL)flag
{
	[self performSelectorOnMainThread:aSelector withObject:nil waitUntilDone:flag];
}

- (id)mainPerformSelector:(SEL)aSelector returnValue:(BOOL)flag
{
	id returnValue;
	
	if (flag) {
		NSInvocation *invocation;
		
		invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
		[invocation setSelector:aSelector];
		
		[self performSelectorOnMainThread:@selector(handleInvocation:)
							   withObject:invocation
							waitUntilDone:YES];
		
		[invocation getReturnValue:&returnValue];
		
	} else {
		returnValue = nil;
		[self performSelectorOnMainThread:aSelector 
							   withObject:nil
							waitUntilDone:NO];
	}

	return returnValue;
}

//Included to allow uniform coding
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1
{
	[self mainPerformSelector:aSelector withObject:argument1 waitUntilDone:NO];
}

//Included to allow uniform coding - wrapped for performSelectorOnMainThread:withObject:waitUntilDone:
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 waitUntilDone:(BOOL)flag
{
	[self performSelectorOnMainThread:aSelector withObject:argument1 waitUntilDone:flag];
}

//Perform a selector on the main thread, optionally taking an argument, and return its return value
- (id)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 returnValue:(BOOL)flag
{
	id returnValue;
	
	if (flag) {
		NSInvocation *invocation;
		
		invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
		[invocation setSelector:aSelector];
		[invocation setArgument:&argument1 atIndex:2];
		
		[self performSelectorOnMainThread:@selector(handleInvocation:)
							   withObject:invocation
							waitUntilDone:YES];

		[invocation getReturnValue:&returnValue];
		
	} else {
		returnValue = nil;
		[self performSelectorOnMainThread:aSelector withObject:argument1 waitUntilDone:NO];
	}
	
	return returnValue;
}

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2
{
	[self mainPerformSelector:aSelector withObject:argument1 withObject:argument2 waitUntilDone:NO];
}

//Perform a selector on the main thread, taking 0-2 arguments, and return its return value
- (id)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 returnValue:(BOOL)flag
{
	id returnValue;
	
	if (flag) {
		NSInvocation *invocation;
		
		invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
		[invocation setSelector:aSelector];
		[invocation setArgument:&argument1 atIndex:2];
		[invocation setArgument:&argument2 atIndex:3];
		
		[self performSelectorOnMainThread:@selector(handleInvocation:)
							   withObject:invocation
							waitUntilDone:YES];
		
		[invocation getReturnValue:&returnValue];
		
	} else {
		returnValue = nil;
		[self mainPerformSelector:aSelector withObject:argument1 withObject:argument2 waitUntilDone:NO];
	}
	
	return returnValue;
}

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 waitUntilDone:(BOOL)flag
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation retainArguments];
	
	[self performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:flag];
}

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 
{
	[self mainPerformSelector:aSelector withObject:argument1 withObject:argument2 withObject:argument3 waitUntilDone:NO];
}
//Perform a selector on the main thread, taking 0-3 arguments, and return its return value
- (id)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 returnValue:(BOOL)flag
{
	id returnValue;
	
	if (flag) {
		NSInvocation *invocation;
		
		invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
		[invocation setSelector:aSelector];
		[invocation setArgument:&argument1 atIndex:2];
		[invocation setArgument:&argument2 atIndex:3];
		[invocation setArgument:&argument3 atIndex:4];
		
		[self performSelectorOnMainThread:@selector(handleInvocation:)
							   withObject:invocation
							waitUntilDone:YES];
		
		[invocation getReturnValue:&returnValue];
		
	} else {
		returnValue = nil;
		[self mainPerformSelector:aSelector withObject:argument1 withObject:argument2 withObject:argument3 waitUntilDone:NO];
	}
	
	return returnValue;
}

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 waitUntilDone:(BOOL)flag
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation setArgument:&argument3 atIndex:4];
	[invocation retainArguments];
	
	[self performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:flag];
}

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 withObject:(id)argument4
{
	[self mainPerformSelector:aSelector withObject:argument1 withObject:argument2 withObject:argument3 withObject:argument4 waitUntilDone:NO];
}
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 withObject:(id)argument4 waitUntilDone:(BOOL)flag
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation setArgument:&argument3 atIndex:4];
	[invocation setArgument:&argument4 atIndex:5];
	[invocation retainArguments];
	
	[self performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:flag];
}

//nil terminated
- (void)mainPerformSelector:(SEL)aSelector withObjects:(id)argument1, ...
{	
	NSInvocation	*invocation;
	va_list			args;
	int				idx = 2;

	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:idx++];

	va_start(args, argument1);
	
	id anArgument;
	while ((anArgument = va_arg(args, id))) {
		[invocation setArgument:&anArgument atIndex:idx++];
	}

	va_end(args);

	[invocation retainArguments];
	
	[self performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:NO];	
}

- (void)performSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 afterDelay:(NSTimeInterval)delay
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation retainArguments];
	
	[self performSelector:@selector(handleInvocation:) withObject:invocation afterDelay:delay];	
}

- (void)performSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 afterDelay:(NSTimeInterval)delay
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation setArgument:&argument3 atIndex:4];
	[invocation retainArguments];
	
	[self performSelector:@selector(handleInvocation:) withObject:invocation afterDelay:delay];	
}

- (void)performSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation setArgument:&argument3 atIndex:4];
	[invocation retainArguments];
	
	[self performSelector:@selector(handleInvocation:) withObject:invocation];	
}

- (void)performSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 withObject:(id)argument4 afterDelay:(NSTimeInterval)delay
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation setArgument:&argument3 atIndex:4];
	[invocation setArgument:&argument4 atIndex:5];
	[invocation retainArguments];
	
	[self performSelector:@selector(handleInvocation:) withObject:invocation afterDelay:delay];	
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:self];
}

@end
