//
//  AXCPreferenceController.h
//  XtrasCreator
//
//  Created by David Smith on 11/1/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#define STARTUP_ACTION_KEY @"AXCStartupAction"

#define STARTING_POINTS_STARTUP_ACTION @"Display Starting Points"
#define DO_NOTHING_STARTUP_ACTION @"Do Nothing"

@interface AXCPreferenceController : NSObject 
{
	IBOutlet NSUserDefaultsController * userDefaults;
	IBOutlet NSPopUpButton * startupActionPopup;
	IBOutlet NSWindow * prefsWindow;
	NSMutableArray * startupActions;
}

- (IBAction) showPrefs:(id)sender;
- (void) populateStartupActions;
- (NSArray *) startupActions;
@end
