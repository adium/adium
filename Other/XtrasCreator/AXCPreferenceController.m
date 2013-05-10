//
//  AXCPreferenceController.m
//  XtrasCreator
//
//  Created by David Smith on 11/1/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AXCPreferenceController.h"

@implementation AXCPreferenceController

- (IBAction) showPrefs:(id)sender
{
	if(!prefsWindow)
		[NSBundle loadNibNamed:@"Preferences.nib" owner:self];
	[self populateStartupActions];
	[[startupActionPopup menu] setDelegate:self];
	[prefsWindow makeKeyAndOrderFront:nil];
}

+ (void) initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		STARTING_POINTS_STARTUP_ACTION, STARTUP_ACTION_KEY,
		nil]];
}

- (void) populateStartupActions
{
	[startupActions autorelease];
	startupActions = [[NSMutableArray alloc] init];
	[startupActions addObject:STARTING_POINTS_STARTUP_ACTION];
	[startupActions addObject:DO_NOTHING_STARTUP_ACTION];
}

- (NSArray *) startupActions
{
	return startupActions;
}

#pragma mark Menu Delegate Methods

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel
{
	[item setTitle:[[self startupActions] objectAtIndex:index]];
	if ([[item title] isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:STARTUP_ACTION_KEY]])
		[item setState:NSOnState];
	else
		[item setState:NSOffState];
	return YES;
}

- (int)numberOfItemsInMenu:(NSMenu *)menu
{
	return [[self startupActions] count];
}
@end
