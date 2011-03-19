//
//  AIFacebookXMPPAccountViewController.h
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PurpleAccountViewController.h"
#import <WebKit/WebKit.h>

@interface AIFacebookXMPPAccountViewController : PurpleAccountViewController {	
	NSButton *button_OAuthStart;
	NSView *view_migration;
	NSTextField *textField_migrationStatus;
	NSButton *button_migrationHelp;
	NSButton *button_migrationOAuthStart;
	NSProgressIndicator *migrationSpinner;
	NSTextField *textField_OAuthStatus;
	NSProgressIndicator *spinner;
}

@property (assign) IBOutlet NSProgressIndicator *spinner;
@property (assign) IBOutlet NSTextField *textField_OAuthStatus;
@property (assign) IBOutlet NSButton *button_OAuthStart;

@property (assign) IBOutlet NSView *view_migration;
@property (assign) IBOutlet NSTextField *textField_migrationStatus;
@property (assign) IBOutlet NSButton *button_migrationHelp;
@property (assign) IBOutlet NSButton *button_migrationOAuthStart;
@property (assign) IBOutlet NSProgressIndicator *migrationSpinner;

@end
