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

#import "AdiumApplescriptRunner.h"

@implementation AdiumApplescriptRunner

- (void)dealloc
{
	if (applescriptRunner) {
		xpc_connection_cancel(applescriptRunner);
		applescriptRunner = NULL;
	}
	
	[super dealloc];
}

/*!
 * @brief Run an applescript, optinally calling a function with arguments, and notify a target/selector with its output when it is done
 */
- (void)runApplescriptAtPath:(NSString *)path function:(NSString *)function arguments:(NSArray *)arguments notifyingTarget:(id)target selector:(SEL)selector userInfo:(id)userInfo
{
	if (!applescriptRunner) {
		applescriptRunner = xpc_connection_create("im.adium.AIApplescriptRunner", NULL);
		xpc_connection_set_event_handler(applescriptRunner, ^(xpc_object_t obj){
			AILogWithSignature(@"Received something.");
			
			xpc_type_t type = xpc_get_type(obj);
			if (type == XPC_TYPE_ERROR) {
				AILogWithSignature(@"Received an error");
				if (obj == XPC_ERROR_CONNECTION_INVALID) {
					AILogWithSignature(@"Our connection terminated!");
				} else if (obj == XPC_ERROR_CONNECTION_INTERRUPTED) {
					AILogWithSignature(@"Our connection was interrupted!");
				}
			}
		});
		
		xpc_connection_resume(applescriptRunner);
	}
	
	xpc_object_t obj = xpc_dictionary_create(NULL, NULL, 0);
	
	xpc_dictionary_set_string(obj, "path", [path UTF8String]);
	xpc_dictionary_set_string(obj, "function", (function ? [function UTF8String] : ""));
	xpc_object_t array = xpc_array_create(NULL, 0);
	
	for (NSString *argument in arguments) {
		xpc_object_t argObject = xpc_string_create([argument UTF8String]);
		
		xpc_array_set_value(array, XPC_ARRAY_APPEND, argObject);
		
		xpc_release(argObject);
	}
	
	xpc_dictionary_set_value(obj, "arguments", array);
	xpc_release(array);
	
	xpc_connection_send_message_with_reply(applescriptRunner, obj, dispatch_get_main_queue(), ^(xpc_object_t reply){
		if (target && selector) {
			const char *resultStr = xpc_dictionary_get_string(reply, "result");
			NSString *result = (resultStr ? [NSString stringWithUTF8String:resultStr] : @"");
			[target performSelector:selector withObject:userInfo withObject:result];
		}
	});
	
	xpc_release(obj);
}

@end
