//
//  ESPurpleSimpleAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 12/17/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESPurpleSimpleAccountViewController.h"
#import "ESPurpleSimpleAccount.h"

@implementation ESPurpleSimpleAccountViewController
+ (void)initialize {
	if (self == [ESPurpleSimpleAccountViewController class]) {
		NSArray *bindings = [NSArray arrayWithObjects:
			@"publishStatus",
			@"useUDP",
			@"useSIPProxy",
			@"sipProxy",	
			@"authUser",		
			@"authDomain",
			nil];
		
		NSEnumerator *enumerator = [bindings objectEnumerator];
		NSString	 *binding;
		while ((binding = [enumerator nextObject])) {
			[self exposeBinding:binding];

			//Notify for all our exposed bindings when the account changes
			[self setKeys:[NSArray arrayWithObject:@"account"] triggerChangeNotificationsForDependentKey:binding];
		}
	}
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
