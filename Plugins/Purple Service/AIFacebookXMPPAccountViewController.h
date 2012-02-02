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
	AILocalizationButton *__unsafe_unretained button_OAuthStart;
	NSTextField *__unsafe_unretained textField_OAuthStatus;
	NSProgressIndicator *__unsafe_unretained spinner;
	
	NSButton *__unsafe_unretained button_help;
}

@property (unsafe_unretained) IBOutlet NSProgressIndicator *spinner;
@property (unsafe_unretained) IBOutlet NSTextField *textField_OAuthStatus;
@property (unsafe_unretained) IBOutlet NSButton *button_OAuthStart;
@property (unsafe_unretained) IBOutlet NSButton *button_help;

- (IBAction)showHelp:(id)sender;

@end
