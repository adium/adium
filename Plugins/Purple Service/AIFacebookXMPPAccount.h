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
}

@property (nonatomic, retain) AIFacebookXMPPOAuthWebViewWindowController *oAuthWC;
- (void)requestFacebookAuthorization;
- (void)oAuthWebViewController:(AIFacebookXMPPOAuthWebViewWindowController *)wc didSucceedWithToken:(NSString *)token;
@end
