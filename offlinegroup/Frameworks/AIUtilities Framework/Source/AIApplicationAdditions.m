//
//  AIApplicationAdditions.m
//  Adium
//
//  Created by Colin Barrett on Fri Nov 28 2003.
//

#import "AIApplicationAdditions.h"

@implementation NSApplication (AIApplicationAdditions)

- (BOOL)isWebKitAvailable
{
	static BOOL _initialized = NO;
	static BOOL _webkitAvailable = NO;

	if (_initialized == NO) {
		NSString		*webkitPath = @"/System/Library/Frameworks/WebKit.framework";
		BOOL			isDir;

		if ([[NSFileManager defaultManager] fileExistsAtPath:webkitPath isDirectory:&isDir] && isDir) {
			_webkitAvailable = YES;
		}

		_initialized = YES;
	}

	return _webkitAvailable;
}

- (NSString *)applicationVersion
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
}

@end
