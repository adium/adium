//
//  ESPurpleSimpleAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 12/17/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESPurpleSimpleAccountViewController.h"
#import "ESPurpleSimpleAccount.h"

static NSSet *bindings;

@implementation ESPurpleSimpleAccountViewController
+ (void)initialize {
	if (self == [ESPurpleSimpleAccountViewController class]) {
		bindings = [[NSSet alloc] initWithObjects:
			@"publishStatus",
			@"useUDP",
			@"useSIPProxy",
			@"sipProxy",	
			@"authUser",		
			@"authDomain",
			nil];
		
		NSString	 *binding;
		for (binding in bindings) {
			[self exposeBinding:binding];
		}
	}
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *superSet = [super keyPathsForValuesAffectingValueForKey:key];
	if ([bindings containsObject:key])
		return [superSet setByAddingObject:@"account"];
	return superSet;
}

- (NSString *)nibName{
    return @"ESPurpleSimpleAccountView";
}

- (NSDictionary *)keyToKeyDict
{
	NSMutableDictionary *keyToKeyDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		KEY_SIMPLE_PUBLISH_STATUS, @"publishStatus",
		KEY_SIMPLE_USE_UDP, @"useUDP",
		KEY_SIMPLE_USE_SIP_PROXY, @"useSIPProxy",
		KEY_SIMPLE_SIP_PROXY, @"sipProxy",
		KEY_SIMPLE_AUTH_USER, @"authUser",
		KEY_SIMPLE_AUTH_DOMAIN, @"authDomain",
		nil];
	[keyToKeyDict addEntriesFromDictionary:[super keyToKeyDict]];
	
	return keyToKeyDict;
}

@end
