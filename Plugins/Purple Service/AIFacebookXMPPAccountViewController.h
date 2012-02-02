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
	AILocalizationTextField *label_instructions;
	AILocalizationButton *__weak button_OAuthStart;
	NSTextField *__weak textField_OAuthStatus;
	NSProgressIndicator *__weak spinner;
	
	NSButton *__weak button_help;
}

@property (weak) IBOutlet NSProgressIndicator *spinner;
@property (weak) IBOutlet NSTextField *textField_OAuthStatus;
@property (weak) IBOutlet NSButton *button_OAuthStart;
@property (weak) IBOutlet NSButton *button_help;

- (IBAction)showHelp:(id)sender;

@end
