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
