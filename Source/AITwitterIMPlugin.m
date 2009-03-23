//
//  AITwitterIMPlugin.m
//  Adium
//
//  Created by Colin Barrett on 5/14/08.

#import "AITwitterIMPlugin.h"
#import <Adium/AIListObject.h>
#import <Adium/AIService.h>

@implementation AITwitterIMPlugin

- (void)installPlugin
{
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

- (void)dealloc
{
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[super dealloc];
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	NSSet *returnSet = nil;
	
	if (!inModifiedKeys) {
		if (([inObject.UID isEqualToString:@"twitter@twitter.com"] &&
			 [inObject.service.serviceClass isEqualToString:@"Jabber"]) ||
			([inObject.service.serviceClass isEqualToString:@"Twitter"] || 
			 [inObject.service.serviceClass isEqualToString:@"Laconica"])) {
			
			if (![inObject valueForProperty:@"Character Counter Max"]) {
				[inObject setValue:[NSNumber numberWithInteger:140] forProperty:@"Character Counter Max" notify:YES];
				returnSet = [NSSet setWithObjects:@"Character Counter Max", nil];
			}
		}
	}
	
	return returnSet;
}

@end
