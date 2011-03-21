//
//  AIFacebookXMPPAccount.h
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CBPurpleAccount.h"

@class AIFacebookXMPPOAuthWebViewWindowController;

@interface AIFacebookXMPPAccount : CBPurpleAccount {
	AIFacebookXMPPOAuthWebViewWindowController *oAuthWC;
	AIAccount *migratingAccount;
	NSString *sessionKey;
	
	NSURLConnection *meConnection;
	NSURLConnection *secretConnection;
}

@property (nonatomic, retain) AIFacebookXMPPOAuthWebViewWindowController *oAuthWC;
@property (nonatomic, assign) AIAccount *migratingAccount;
- (void)requestFacebookAuthorization;
- (void)oAuthWebViewController:(AIFacebookXMPPOAuthWebViewWindowController *)wc didSucceedWithToken:(NSString *)token;
@end
