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
    NSMutableDictionary *cookies;
	
	AIFacebookXMPPAccount *account;
	
	NSString *autoFillUsername;
	NSString *autoFillPassword;
    BOOL     isMigrating;
    
    BOOL notifiedAccount;
}

@property (nonatomic, retain) IBOutlet WebView *webView;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *spinner;

@property (nonatomic, retain) NSMutableDictionary *cookies;
@property (nonatomic, retain) AIFacebookXMPPAccount *account;

@property (nonatomic, retain) NSString *autoFillUsername;
@property (nonatomic, retain) NSString *autoFillPassword;
@property (nonatomic)         BOOL     isMigrating;

@end
