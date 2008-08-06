//
//  AITwitterIMPlugin.m
//  Adium
//
//  Created by Colin Barrett on 5/14/08.

#import "AITwitterIMPlugin.h"

@implementation AITwitterIMPlugin

- (void)installPlugin
{
	[[adium contactController] registerListObjectObserver:self];
}

- (void)dealloc
{
	[[adium contactController] unregisterListObjectObserver:self];
	[super dealloc];
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if (!inModifiedKeys) {
		if ([[inObject UID] isEqualToString:@"twitter@twitter.com"] &&
			[[inObject serviceClass] isEqualToString:@"Jabber"]) {
			
			[inObject setValue:[NSNumber numberWithInt:140] forProperty:@"Character Counter Max" notify:YES];
		}
	}
	
	return [NSSet setWithObject:@"Character Counter Max"];
}

@end
