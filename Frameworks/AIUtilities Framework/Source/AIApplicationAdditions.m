//
//  AIApplicationAdditions.m
//  Adium
//
//  Created by Colin Barrett on Fri Nov 28 2003.
//

#import "AIApplicationAdditions.h"

@implementation NSApplication (AIApplicationAdditions)

- (NSString *)applicationVersion
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
}

//Make sure the version number defines exist; when compiling in 10.5, NSAppKitVersionNumber10_5 isn't defined 
#ifndef NSAppKitVersionNumber10_5
#define NSAppKitVersionNumber10_5 949
#endif 

- (BOOL)isOnSnowLeopardOrBetter
{
	return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_5);
}


@end
