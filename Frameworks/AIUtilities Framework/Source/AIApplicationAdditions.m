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

@end
