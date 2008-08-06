//
//  NSTaskAdditions.m
//  buildchlog
//
//  Created by Ofri Wolfus on 09/07/07.
//  Copyright 2007 Ofri Wolfus. All rights reserved.
//

#import "NSTaskAdditions.h"
#import "NSStringAdditions.h"


@implementation NSTask (DPExtensions)

+ (NSString *)fullPathToExecutable:(NSString *)execName {
	return [self fullPathToExecutable:execName
				additionalSearchPaths:[NSArray arrayWithObjects:@"/usr/local/bin",
																		  @"/usr/local/sbin",
																		  @"/opt/local/bin",
																		  @"/opt/local/sbin", nil]];
}

+ (NSString *)fullPathToExecutable:(NSString *)execName additionalSearchPaths:(NSArray *)paths {
	NSString *result = nil;
	NSPipe *pipe = [NSPipe pipe];
	NSTask *task = [[NSTask alloc] init];
	NSMutableDictionary *env = [[[NSProcessInfo processInfo] environment] mutableCopy];
	NSMutableString *path_var = [[env objectForKey:@"PATH"] mutableCopy];
	NSEnumerator *enumerator = [paths objectEnumerator];
	NSString *searchPath;
	
	// Add any additional search paths
	while ((searchPath = [enumerator nextObject])) {
		if ([path_var rangeOfString:searchPath].location == NSNotFound)
			[path_var appendFormat:@":%@", searchPath];
	}
	
	// Set the new PATH variable
	[env setObject:path_var forKey:@"PATH"];
	
	// Initialize our task
	[task setLaunchPath:@"/usr/bin/which"];
	[task setEnvironment:env];
	[task setArguments:[NSArray arrayWithObject:execName]];
	[task setStandardOutput:pipe];
	// Launch and wait
	[task launch];
	[task waitUntilExit];
	
	if ([task terminationStatus] == 0) {
		result = [NSString stringWithData:[[pipe fileHandleForReading] readDataToEndOfFile]
								 encoding:NSUTF8StringEncoding];
		result = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		// Some error occured, and we didn't get a full path
		if (![result isAbsolutePath])
			result = nil;
	}
	
	// Clean up
	[path_var release];
	[env release];
	[task release];
	
	return result;
}

@end
