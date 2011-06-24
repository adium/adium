//
//  AIFacebookXMPPAccount.h
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CBPurpleAccount.h"

@class AIFacebookXMPPOAuthWebViewWindowController;

#define APP_ID "164063256994618"
#define API_KEY "add7b04ecedcd84645f3c32e7884682d"
#define APP_SECRET "bb9d2d9771790e69a0e943771ddf33c8"

@interface AIFacebookXMPPAccount : CBPurpleAccount {
	AIFacebookXMPPOAuthWebViewWindowController *oAuthWC;
	AIAccount *migratingAccount; // weak
    
    NSString *oAuthToken;
    NSUInteger networkState;
    
    NSURLConnection *connection; // weak
    NSURLResponse *connectionResponse;
    NSMutableData *connectionData;
}

@property (nonatomic, retain) AIFacebookXMPPOAuthWebViewWindowController *oAuthWC;
@property (nonatomic, assign) AIAccount *migratingAccount;
- (void)requestFacebookAuthorization;
- (void)oAuthWebViewController:(AIFacebookXMPPOAuthWebViewWindowController *)wc didSucceedWithToken:(NSString *)token;
@end
