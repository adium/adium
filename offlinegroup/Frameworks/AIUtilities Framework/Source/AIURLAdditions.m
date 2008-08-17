//
//  AIURLAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Feb 17 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIURLAdditions.h"

@implementation NSURL (AIURLAdditions)

- (NSUInteger)length
{
	return [[self absoluteString] length];
}

- (NSString *)queryArgumentForKey:(NSString *)key
{
	NSString		*delimiter;
    NSString		*obj = nil;
	NSEnumerator	*enumerator;
	
	// The arguments in query strings can be delimited with a semicolon (';') or an ampersand ('&'). Since it's not
	// likely a single URL would use both types of delimeters, we'll attempt to pick one and use it.
	if ([[self query] rangeOfString:@";"].location != NSNotFound) {
		delimiter = @";";
	} else {
		// Assume '&' by default, since that's more common
		delimiter = @"&";
	}
	
	enumerator = [[[self query] componentsSeparatedByString:delimiter] objectEnumerator];
    
    while ((obj = [enumerator nextObject])) {
        NSArray *keyAndValue = [obj componentsSeparatedByString:@"="];

        if (([keyAndValue count] >= 2) &&
		   ([[keyAndValue objectAtIndex:0] caseInsensitiveCompare:key] == NSOrderedSame)) {
			return [keyAndValue objectAtIndex:1];
		}
    }
	
	return nil;
}

@end
