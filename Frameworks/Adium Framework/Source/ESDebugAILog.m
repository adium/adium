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

#import <Adium/ESDebugAILog.h>
#import <Adium/AIDebugControllerProtocol.h>
#include <stdarg.h>

extern CFRunLoopRef CFRunLoopGetMain(void);

/*!
 * @brief Adium debug log function
 *
 * Prints a message to the Adium debug window, which is only enabled in Debug and Development builds.  
 * In Deployment builds, this function is replaced by a #define which is just a comment, so there is no cost to
 * deployment to use it.
 *
 * @param format A printf-style format string
 * @param ... 0 or more arguments to the format string
 */
#ifdef DEBUG_BUILD
void AIAddDebugMessage(NSString *debugMessage)
{
	NSString *actualMessage = [[[NSDate date] descriptionWithCalendarFormat:@"%H:%M:%S: "
																   timeZone:nil
																	 locale:nil] stringByAppendingString:debugMessage];
	
	/* Be careful; we should only modify debugLogArray and the windowController's view on the main thread. */
	if (CFRunLoopGetCurrent() == CFRunLoopGetMain()) {
		[[adium debugController] addMessage:actualMessage];

	} else {
		[[adium debugController] performSelectorOnMainThread:@selector(addMessage:)
																		   withObject:actualMessage
																		waitUntilDone:NO];		
	}
}

void AILog (NSString *format, ...) {
	va_list		ap; /* Points to each unamed argument in turn */
	NSString	*debugMessage;
	
	va_start(ap, format); /* Make ap point to the first unnamed argument */
	
	debugMessage = [[NSString alloc] initWithFormat:format
										  arguments:ap];
	AIAddDebugMessage(debugMessage);
	[debugMessage release];

	va_end(ap); /* clean up when done */
}

void AILogWithPrefix (const char *prefix, NSString *format, ...) {
	va_list		ap; /* Points to each unamed argument in turn */
	NSString	*debugMessage, *actualMessage;
	
	va_start(ap, format); /* Make ap point to the first unnamed argument */
	
	debugMessage = [[NSString alloc] initWithFormat:format
										  arguments:ap];
	actualMessage = [NSString stringWithFormat:@"%s: %@", prefix, debugMessage];
	AIAddDebugMessage(actualMessage);
	[debugMessage release];

	va_end(ap); /* clean up when done */
}
#else
//Insert a fake symbol so that plugins using AILog() don't crash.
#undef AILog
void AILog (NSString *format, ...) {};
#undef AILogWithPrefix
void AILogWithPrefix (char *sig, NSString *format, ...) {};
#endif
