//
//  AIFacebookXMPPOAuthWebViewWindowController.h
//  Adium
//
//  Created by Colin Barrett on 11/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIWindowController.h>
#import <WebKit/WebKit.h>

@class AIFacebookXMPPAccount;

@interface AIFacebookXMPPOAuthWebViewWindowController : AIWindowController {
    IBOutlet WebView *webView;
	IBOutlet NSProgressIndicator *spinner;
    NSMutableSet *cookies;
	
	AIFacebookXMPPAccount *account;
}

@property (nonatomic, retain) IBOutlet WebView *webView;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *spinner;

@property (nonatomic, retain) NSMutableSet *cookies;
@property (nonatomic, retain) AIFacebookXMPPAccount *account;

@end
