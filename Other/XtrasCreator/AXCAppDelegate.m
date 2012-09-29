//
//  LMXAppDelegate.m
//  LMX
//
//  Created by Mac-arena the Bored Zo on 2005-10-17.
//  Copyright 2005 Mac-arena the Bored Zo. All rights reserved.
//

#import "AXCAppDelegate.h"

#include <sys/types.h>
#include <unistd.h>
#import <ExceptionHandling/NSExceptionHandler.h>

#import "AXCStartingPointsController.h"
#import "AXCPreferenceController.h"

@implementation AXCAppDelegate

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication
{
	[startingPointsController setStartingPointsVisible:YES];
	return YES;
}

#pragma mark Ganked from LMXAppDelegate (in LMX)

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
#pragma unused(notification)
	NSExceptionHandler *excHandler = [NSExceptionHandler defaultExceptionHandler];
	[excHandler setExceptionHandlingMask:NSLogUncaughtExceptionMask | NSLogUncaughtSystemExceptionMask | NSLogUncaughtRuntimeErrorMask | NSLogTopLevelExceptionMask | NSLogOtherExceptionMask];
	[excHandler setDelegate:self];
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(unsigned int)aMask {
	NSMutableArray *symbols = [[[[exception userInfo] objectForKey:NSStackTraceKey] componentsSeparatedByString:@"  "] mutableCopy];

	[symbols insertObject:@"-p" atIndex:0U];
	[symbols insertObject:[[NSNumber numberWithInt:getpid()] stringValue] atIndex:1U];

	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/atos"];
	[task setArguments:symbols];
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];

	[task launch];
	[task waitUntilExit];

	NSFileHandle *fh = [pipe fileHandleForReading];
	NSData *data = [fh readDataToEndOfFile];
	NSString *stackTrace = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

	[task release];

	NSLog(@"got %@ with reason %@; stack trace follows\n%@", [exception name], [exception reason], stackTrace);

	return NO; //because we just did
}

@end
