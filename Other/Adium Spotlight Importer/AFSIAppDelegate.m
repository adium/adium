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
