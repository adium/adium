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
    __unsafe_unretained IBOutlet WebView *webView;
	__unsafe_unretained IBOutlet NSProgressIndicator *spinner;
    NSMutableDictionary *cookies;
	
	__unsafe_unretained AIFacebookXMPPAccount *account;
	
	__unsafe_unretained NSString *autoFillUsername;
	__unsafe_unretained NSString *autoFillPassword;
    BOOL     isMigrating;
    
    BOOL notifiedAccount;
}

@property (nonatomic, assign) IBOutlet WebView *webView;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *spinner;

@property (nonatomic, strong) NSMutableDictionary *cookies;
@property (nonatomic, assign) AIFacebookXMPPAccount *account;

@property (nonatomic, assign) NSString *autoFillUsername;
@property (nonatomic, assign) NSString *autoFillPassword;
@property (nonatomic)         BOOL     isMigrating;

@end
