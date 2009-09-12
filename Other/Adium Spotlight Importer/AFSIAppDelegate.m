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

- (void) importOneChatlogFromPath:(NSString *)path {
	NSError *error = nil;
	GetMetadataForFile(NULL, [NSMutableDictionary dictionary], [[NSWorkspace sharedWorkspace] typeOfFile:path error:&error], path);
}

- (void) importChatlogsFromDirectoryTreeRootedAtPath:(NSString *)rootPath {
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSDirectoryEnumerator *dirEnum = [mgr enumeratorAtPath:rootPath];
	for (NSString *subpath in dirEnum) {
		NSString *path = [rootPath stringByAppendingPathComponent:subpath];
		NSString *ext = [path pathExtension];
		if ([ext caseInsensitiveCompare:@"chatlog"] == NSOrderedSame) {
			BOOL isDir = NO;
			if ([mgr fileExistsAtPath:path isDirectory:&isDir] && isDir)
				[dirEnum skipDescendents];
			[self importOneChatlogFromPath:path];
		} else if ([ext caseInsensitiveCompare:@"AdiumLog"] == NSOrderedSame)
			[self importOneChatlogFromPath:path];
		else if ([ext caseInsensitiveCompare:@"AdiumHTMLLog"] == NSOrderedSame)
			[self importOneChatlogFromPath:path];
	}
}

- (void) application:(NSApplication *)sender openFiles:(NSArray *)paths {
	NSFileManager *mgr = [NSFileManager defaultManager];
	for (NSString *path in paths) {
		BOOL isDir = NO;
		if ([mgr fileExistsAtPath:path isDirectory:&isDir]) {
			if (isDir)
				[self importChatlogsFromDirectoryTreeRootedAtPath:path];
			else
				[self importOneChatlogFromPath:path];
		}
	}

	NSBeep();
	NSLog(@"Job's done!");
}

@end
