//
//  AIContactInfoContentController.m
//  Adium
//
//  Created by Elliott Harris on 1/13/08.
//  Copyright 2008 Adium. All rights reserved.
//

#import "AIContactInfoContentController.h"

@interface AIContactInfoContentController ()
-(void)_setLoadedPanes:(NSArray *)anArray;
@end

@implementation AIContactInfoContentController

+ (AIContactInfoContentController *)defaultInfoContentController
{
	return [[[self alloc] initWithContentPanes:[self defaultPanes]] autorelease];
}

- (id)initWithContentPanes:(NSArray *)panes
{
	if ((self = [self init])) {
		[self loadContentPanes:panes];
	}

	return self;
}

- (void)dealloc
{
	[loadedPanes release];
	
	[super dealloc];
}

+(NSArray *)defaultPanes
{
	return [NSArray arrayWithObjects:@"AIInfoInspectorPane", @"AIAddressBookInspectorPane", @"AIEventsInspectorPane",
			@"AIAdvancedInspectorPane", nil];
}

-(NSArray *)loadedPanes
{
	return loadedPanes;
}

-(void)_setLoadedPanes:(NSArray *)newPanes
{
	if (loadedPanes != newPanes)
	{
		[loadedPanes release];
		loadedPanes = [newPanes retain];
	}
}

-(void)loadContentPanes:(NSArray *)contentPanes
{
	NSMutableArray *contentArray = [NSMutableArray array];
	//Allocate and initalize each class, then stick it in the array.
	id currentPane = nil;
	
	for(currentPane in contentPanes) {
		Class paneClass = nil;
		if(!(paneClass = NSClassFromString(currentPane))) {
			AILogWithSignature(@"Warning: Could not obtain a class for %@", currentPane);
			return;
		}
		
		[contentArray addObject:[[[paneClass alloc] init] autorelease]];
	}

	[self _setLoadedPanes:contentArray];
}

-(IBAction)segmentSelected:(id)sender
{
#warning Needs implementation
}

@end
