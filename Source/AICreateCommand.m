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
 
#import "AICreateCommand.h"
#import "NSStringScriptingAdditions.h"

@interface NSScriptObjectSpecifier(NSPrivate)
+ (NSScriptObjectSpecifier *)_objectSpecifierFromDescriptor:(NSAppleEventDescriptor *)desc inCommandConstructionContext:(id)context;
@end

@implementation AICreateCommand
/**
 * @brief Overrides default NSCreateCommand behavior when creating an object; rather than calling alloc/init, calls make<Key>WithProperties:
 *
 * make<Key>WithProperties: is responsible for parsing all options passed to it during creation.
 * As well, it must insert the new object into the correct container, looking at the Location key if necessary.
 */
- (id)performDefaultImplementation
{
#warning This uses a Private API
	NSScriptClassDescription *newObjectDescription = [self createClassDescription];	
	id target = [self subjectsSpecifier];

	if (!target)
		target = NSApp;

	id r;
	NSString *methodName = [NSString stringWithFormat:@"make%@WithProperties:",[[newObjectDescription className] camelCase]];
	SEL customMethod = NSSelectorFromString(methodName);

	if ([target respondsToSelector:customMethod]) {
		//this can do the insert, based on the parameters, methinks.
		NSMethodSignature *method = [target methodSignatureForSelector:customMethod];
		if (!method)
			return nil;
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:method];
		[invocation setSelector:customMethod];
		NSDictionary *resolvedKeyDictionary = [self evaluatedArguments];
		[invocation setArgument:&resolvedKeyDictionary atIndex:2];
		[invocation invokeWithTarget:target];
		[invocation getReturnValue:&r];
	}
	else
		r = [super performDefaultImplementation];
	
	if ([r isKindOfClass:[NSScriptObjectSpecifier class]])
		return r;
	
	return [r objectSpecifier];
}

/**
 * @brief returns the object in the 'subj' key in this apple event.
 *
 * This uses a private API. It's the only way I've found to get the target of the 'make' command, which is necessary 
 * in order to override performDefaultImplementation.
 */
- (id)subjectsSpecifier
{
	NSAppleEventDescriptor *subjDesc = [[self appleEvent] attributeDescriptorForKeyword: 'subj'];
	if ([subjDesc aeDesc] && [subjDesc aeDesc]->descriptorType == typeNull)
		return nil;
	NSScriptObjectSpecifier *subjSpec = [NSScriptObjectSpecifier _objectSpecifierFromDescriptor: subjDesc inCommandConstructionContext: nil];
	return [subjSpec objectsByEvaluatingSpecifier];
}
@end
