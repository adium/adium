//
//  ESAwayStatusWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 4/12/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIWindowController.h>

@interface ESAwayStatusWindowController : AIWindowController {
	IBOutlet	NSButton					*button_return;
	IBOutlet	NSTabView					*tabView_configuration;
	
	//Single status tab
	IBOutlet	NSTextView					*textView_singleStatus;
	
	//Multiple statuses tab
	IBOutlet NSTableView	*tableView_multiStatus;
	
	NSMutableArray							*_awayAccounts;
}

+ (void)updateStatusWindowWithVisibility:(BOOL)shouldBeVisibile;
+ (void)setAlwaysOnTop:(BOOL)flag;
+ (void)setHideInBackground:(BOOL)flag;

- (IBAction)returnFromAway:(id)sender;

@end
