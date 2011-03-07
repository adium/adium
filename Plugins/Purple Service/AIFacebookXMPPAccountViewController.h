//
//  AIFacebookXMPPAccountViewController.h
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PurpleAccountViewController.h"
#import <WebKit/WebKit.h>

#define FACEBOOK_OAUTH_FINISHED @"FacebookOAuthFinishedNotification"

@class AIFacebookXMPPOAuthWebViewWindowController;

@interface AIFacebookXMPPAccountViewController : PurpleAccountViewController {
	AIFacebookXMPPOAuthWebViewWindowController *webViewWindowController;
	
	NSButton *button_OAuthStart;
	NSTextField *textField_OAuthStatus;
	NSProgressIndicator *spinner;
}

@property (assign) IBOutlet NSProgressIndicator *spinner;
@property (assign) IBOutlet NSTextField *textField_OAuthStatus;
@property (assign) IBOutlet NSButton *button_OAuthStart;

@end
