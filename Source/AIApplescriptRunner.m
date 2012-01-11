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

#import <xpc/xpc.h>
#import <Foundation/Foundation.h>

static void AIApplescriptRunner_peer_event_handler(xpc_connection_t peer, xpc_object_t event) 
{
	xpc_type_t type = xpc_get_type(event);
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID) {
			NSLog(@"Our connection terminated!");
		}
	} else {
		assert(type == XPC_TYPE_DICTIONARY);
		
		NSString *path = [NSString stringWithUTF8String:xpc_dictionary_get_string(event, "path")];
		NSString *functionName = [NSString stringWithUTF8String:xpc_dictionary_get_string(event, "function")];
		
		xpc_object_t array = xpc_dictionary_get_value(event, "arguments");
		
		assert(xpc_get_type(array) == XPC_TYPE_ARRAY);
		
		NSInteger count = xpc_array_get_count(array);
		
		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
																			error:NULL];
		NSAppleEventDescriptor *thisApplication, *containerEvent;
		NSString *resultString = nil;
		
		if (appleScript) {
			if (functionName && [functionName length]) {
				/* If we have a functionName (and potentially arguments), we build
				 * an NSAppleEvent to execute the script. */
				
				//Get a descriptor for ourself
				int pid = [[NSProcessInfo processInfo] processIdentifier];
				thisApplication = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID
																				 bytes:&pid
																				length:sizeof(pid)];
				
				//Create the container event
				
				//We need these constants from the Carbon OpenScripting framework, but we don't actually need Carbon.framework...
#define kASAppleScriptSuite	'ascr'
#define kASSubroutineEvent	'psbr'
#define keyASSubroutineName 'snam'
				containerEvent = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
																		  eventID:kASSubroutineEvent
																 targetDescriptor:thisApplication
																		 returnID:kAutoGenerateReturnID
																	transactionID:kAnyTransactionID];
				
				//Set the target function
				[containerEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:functionName]
										forKeyword:keyASSubroutineName];
				
				//Pass arguments
				if (count) {
					NSAppleEventDescriptor  *arguments = [[NSAppleEventDescriptor alloc] initListDescriptor];
					
					NSInteger i;
					for (i = 0; i < count; i++) {
						[arguments insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[NSString stringWithUTF8String:xpc_array_get_string(array, i)]]
											atIndex:([arguments numberOfItems] + 1)]; //This +1 seems wrong... but it's not
					}
					
					[containerEvent setParamDescriptor:arguments forKeyword:keyDirectObject];
					[arguments release];
				}
				
				//Execute the event
				resultString = [[appleScript executeAppleEvent:containerEvent error:NULL] stringValue];
				
			} else {
				resultString = [[appleScript executeAndReturnError:NULL] stringValue];
			}
		}
		
		xpc_object_t reply = xpc_dictionary_create_reply(event);
		
		xpc_dictionary_set_string(reply, "result", (resultString ? [resultString UTF8String] : ""));
		
		xpc_connection_t connection = xpc_dictionary_get_remote_connection(reply);
		
		xpc_connection_send_message(connection, reply);
		
		xpc_release(reply);
		
		[appleScript release];
	}
}

static void AIApplescriptRunner_event_handler(xpc_connection_t peer) 
{
	xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
		AIApplescriptRunner_peer_event_handler(peer, event);
	});
	
	xpc_connection_resume(peer);
}

int main(int argc, const char *argv[])
{
	xpc_main(AIApplescriptRunner_event_handler);
	
	return 0;
}
