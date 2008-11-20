//
//  AIEventsInspectorPane.m
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//

#import "AIEventsInspectorPane.h"
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/ESContactAlertsViewController.h>

#define EVENTS_NIB_NAME (@"AIEventsInspectorPane")

@implementation AIEventsInspectorPane

- (id) init
{
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:[self nibName] owner:self];
		//Other init goes here.
	}
	return self;
}

- (void)dealloc
{
	[inspectorContentView release];
	[alertsController release];
	
	[super dealloc];
}

-(NSString *)nibName
{
	return EVENTS_NIB_NAME;
}

-(NSView *)inspectorContentView
{
	return inspectorContentView;
}

-(void)updateForListObject:(AIListObject *)inObject
{
	[alertsController configureForListObject:inObject];
}

@end
