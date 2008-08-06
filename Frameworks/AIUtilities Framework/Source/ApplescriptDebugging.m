//
//  ApplescriptDebugging.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 24 2004.
//

#import "ApplescriptDebugging.h"

#if APPLESCRIPT_DEBUGGING_ENABLED

@implementation AIScriptClassDescription

+ (void)load
{
    //Anything you can do, I can do better...
    [self poseAsClass: [NSScriptClassDescription class]];
}

- (short)_readClass:(void *)someSortOfInput
{
	NSLog(@"NSScriptClassDescription: Reading %@",[self className]);
	return ([super _readClass:someSortOfInput]);
}

@end

@implementation AIScriptCommand

+ (void)load
{
    //Anything you can do, I can do better...
    [self poseAsClass: [NSScriptCommand class]];
}

- (id)initWithCommandDescription:(NSScriptCommandDescription *)commandDesc
{
	NSLog(@"NSScriptCommand: Command from desc %@",commandDesc);
	return ([super initWithCommandDescription:commandDesc]);
}

@end

@implementation AIScriptCommandDescription
+ (void)load
{
	[self poseAsClass: [NSScriptCommandDescription class]];
}

- (id)initWithSuiteName:(NSString *)suiteName commandName:(NSString *)commandName dictionary:(NSDictionary *)commandDescriptions
{
	NSLog(@"NSScriptCommandDescription: %@ ; %@ ; %@",suiteName,commandName,commandDescriptions);
	return ([super initWithSuiteName:suiteName commandName:commandName dictionary:commandDescriptions]);
}
@end
#endif
