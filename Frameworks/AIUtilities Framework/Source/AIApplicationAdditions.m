//
//  AIApplicationAdditions.m
//  Adium
//
//  Created by Colin Barrett on Fri Nov 28 2003.
//

#import "AIApplicationAdditions.h"

@implementation NSApplication (AIApplicationAdditions)

//Make sure the version number defines exist; when compiling in 10.3, NSAppKitVersionNumber10_3 isn't defined 
#ifndef NSAppKitVersionNumber10_3 
#define NSAppKitVersionNumber10_3 743 
#endif 
	 	 
//Make sure the version number defines exist; when compiling in 10.4, NSAppKitVersionNumber10_4 isn't defined 
#ifndef NSAppKitVersionNumber10_4 
#define NSAppKitVersionNumber10_4 824 
#endif


- (BOOL)isOnTigerOrBetter
{
	return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3);
}

- (BOOL)isOnLeopardOrBetter
{
	return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4);
}

-(BOOL)isTiger
{
	return (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_4);
}

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
