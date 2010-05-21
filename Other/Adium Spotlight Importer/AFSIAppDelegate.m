//
//  AFSIAppDelegate.m
//  AdiumSpotlightImporter
//
//  Created by Peter Hosey on 2009-09-12.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import "AFSIAppDelegate.h"

extern Boolean GetMetadataForFile(void* thisInterface, 
								  NSMutableDictionary *attributes, 
								  NSString *contentTypeUTI,
								  NSString *pathToFile);

@implementation AFSIAppDelegate

- (void) importOneChatlogFromPath:(NSString *)path numFilesProcessed:(inout NSUInteger *)numFilesProcessed {
	NSError *error = nil;
	GetMetadataForFile(NULL, [NSMutableDictionary dictionary], [[NSWorkspace sharedWorkspace] typeOfFile:path error:&error], path);
	++*numFilesProcessed;
}

- (void) importChatlogsFromDirectoryTreeRootedAtPath:(NSString *)rootPath numFilesProcessed:(inout NSUInteger *)numFilesProcessedPtr {
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSDirectoryEnumerator *dirEnum = [mgr enumeratorAtPath:rootPath];
	for (NSString *subpath in dirEnum) {
		NSString *path = [rootPath stringByAppendingPathComponent:subpath];
		NSString *ext = [path pathExtension];
		if ([ext caseInsensitiveCompare:@"chatlog"] == NSOrderedSame) {
			BOOL isDir = NO;
			if ([mgr fileExistsAtPath:path isDirectory:&isDir] && isDir)
				[dirEnum skipDescendents];
			[self importOneChatlogFromPath:path numFilesProcessed:numFilesProcessedPtr];
		} else if ([ext caseInsensitiveCompare:@"AdiumLog"] == NSOrderedSame)
			[self importOneChatlogFromPath:path numFilesProcessed:numFilesProcessedPtr];
		else if ([ext caseInsensitiveCompare:@"AdiumHTMLLog"] == NSOrderedSame)
			[self importOneChatlogFromPath:path numFilesProcessed:numFilesProcessedPtr];
	}
}

- (void) application:(NSApplication *)sender openFiles:(NSArray *)paths {
	NSUInteger numFilesProcessed = 0;
	NSDate *start, *end;
	start = [NSDate date];

	NSFileManager *mgr = [NSFileManager defaultManager];
	for (NSString *path in paths) {
		BOOL isDir = NO;
		if ([mgr fileExistsAtPath:path isDirectory:&isDir]) {
			if (isDir)
				[self importChatlogsFromDirectoryTreeRootedAtPath:path numFilesProcessed:&numFilesProcessed];
			else
				[self importOneChatlogFromPath:path numFilesProcessed:&numFilesProcessed];
		}
	}

	end = [NSDate date];
	NSTimeInterval timeTaken = [end timeIntervalSinceDate:start];

	NSBeep();
	NSLog(@"Job's done! Processed %lu files in %f seconds (%f seconds per file)", numFilesProcessed, timeTaken, timeTaken / numFilesProcessed);
}

@end
