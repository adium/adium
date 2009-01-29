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
	if (!inModifiedKeys) {
		if ([inObject.UID isEqualToString:@"twitter@twitter.com"] &&
			[inObject.service.serviceClass isEqualToString:@"Jabber"]) {
			
			[inObject setValue:[NSNumber numberWithInteger:140] forProperty:@"Character Counter Max" notify:YES];
		}
	}
	
	return [NSSet setWithObject:@"Character Counter Max"];
}

@end
