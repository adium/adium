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

#import "AIMoveCommand.h"
#import "NSStringScriptingAdditions.h"

@implementation AIMoveCommand
/**
 * @brief Checks if target responds to 'move<Key>:toIndex:'. If so, then uses that method to move. Otherwise, calls super.
 *
 * This class overrides NSMoveCommand, and is more useful for those cases when a move is not a remove/insert pair.
 * The target can specify exactly how to get the object into itself, in its own move<Key>:toIndex: method.
 */
- (id)performDefaultImplementation
{
	NSPositionalSpecifier *toLocation = [[self evaluatedArguments] objectForKey:@"ToLocation"];
	
	NSString *keyClassName = [[self keySpecifier] key];
	NSString *methodName = [NSString stringWithFormat:@"move%@:toIndex:",[keyClassName camelCase]];
	id target = [toLocation insertionContainer];
	id thingToMove = [target valueAtIndex:[toLocation insertionIndex] inPropertyWithKey:[toLocation insertionKey]];
	if ([thingToMove respondsToSelector:NSSelectorFromString(methodName)]) {
		target = thingToMove;
	}
	if ([target respondsToSelector:NSSelectorFromString(methodName)]) {
		NSMethodSignature *method = [target methodSignatureForSelector:NSSelectorFromString(methodName)];
		if (!method) {
			NSLog(@"%@ doesn't support %@!",NSStringFromClass([target class]),method);
			return nil;
		}
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:method];
		[invocation setSelector:NSSelectorFromString(methodName)];
		id chat = [[self keySpecifier] objectsByEvaluatingSpecifier];
		[invocation setArgument:&chat atIndex:2];
		NSUInteger idx = [toLocation insertionIndex];
		[invocation setArgument:&idx atIndex:3];
		[invocation invokeWithTarget:target];
		id r;
		[invocation getReturnValue:&r];
		return r;
	}
	else
		return [super performDefaultImplementation];
	return nil;
}
@end
