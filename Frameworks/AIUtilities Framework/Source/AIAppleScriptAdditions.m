//
//  AIAppleScriptAdditions.m
//  Adium
//
//  Created by Adam Iser on Mon Feb 16 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIAppleScriptAdditions.h"
#import <Carbon/Carbon.h>

@implementation NSAppleScript (AIAppleScriptAdditions)

//Execute an applescript function
- (NSAppleEventDescriptor *)executeFunction:(NSString *)functionName error:(NSDictionary **)errorInfo
{
	return [self executeFunction:functionName withArguments:nil error:errorInfo];
}

- (NSAppleEventDescriptor *)executeFunction:(NSString *)functionName withArguments:(NSArray *)argumentArray error:(NSDictionary **)errorInfo
{
	NSAppleEventDescriptor	*thisApplication;
	NSAppleEventDescriptor	*containerEvent;

	//Get a descriptor for ourself
	int pid = [[NSProcessInfo processInfo] processIdentifier];
	thisApplication = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID
																	 bytes:&pid
																	length:sizeof(pid)];
	
	//Create the container event
	containerEvent = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
															  eventID:kASSubroutineEvent
													 targetDescriptor:thisApplication
															 returnID:kAutoGenerateReturnID
														transactionID:kAnyTransactionID];
	
	//Set the target function
	[containerEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:functionName]
							forKeyword:keyASSubroutineName];
	
	//Pass arguments - arguments is expecting an NSArray with only NSString objects
	if ([argumentArray count]) {
		NSAppleEventDescriptor  *arguments = [[[NSAppleEventDescriptor alloc] initListDescriptor] autorelease];
		NSEnumerator			*enumerator = [argumentArray objectEnumerator];
		NSString				*object;

		while ((object = [enumerator nextObject])) {
			[arguments insertDescriptor:[NSAppleEventDescriptor descriptorWithString:object]
								atIndex:[arguments numberOfItems]+1]; //This +1 seems wrong... but it's not :)
		}
		
		[containerEvent setParamDescriptor:arguments forKeyword:keyDirectObject];
	}
	
	//Execute the event
	return [self executeAppleEvent:containerEvent error:nil];
}

@end
