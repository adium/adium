//
//  AIFacebookXMPPAccount.h
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CBPurpleAccount.h"

@class AIFacebookXMPPOAuthWebViewWindowController;

#define ADIUM_APP_ID "164063256994618"
#define ADIUM_API_KEY "add7b04ecedcd84645f3c32e7884682d"

/* deprecated? This is called the 'App Secret' on Facebook's developer page.  */
#define ADIUM_API_SECRET "bb9d2d9771790e69a0e943771ddf33c8"

#define AIFacebookXMPPAuthProgressNotification @"AIFacebookXMPPAuthProgressNotification"
#define KEY_FB_XMPP_AUTH_STEP @"AuthStep"

typedef enum {
	AIFacebookXMPPAuthProgressPromptingUser,
	AIFacebookXMPPAuthProgressContactingServer,
	AIFacebookXMPPAuthProgressPromotingForChat,
	AIFacebookXMPPAuthProgressSuccess,
	AIFacebookXMPPAuthProgressFailure
} AIFacebookXMPPAuthProgressStep;


@interface AIFacebookXMPPAccount : CBPurpleAccount {
	AIFacebookXMPPOAuthWebViewWindowController *oAuthWC;
    
    NSString *oAuthToken;
    NSUInteger networkState;
    
    NSURLConnection *__weak connection;
    NSURLResponse *__weak connectionResponse;
    NSMutableData *connectionData;
	
	NSDictionary *__weak migrationData;
}

+ (BOOL)uidIsValidForFacebook:(NSString *)inUID;

@property (nonatomic, strong) AIFacebookXMPPOAuthWebViewWindowController *oAuthWC;
- (void)requestFacebookAuthorization;

- (void)oAuthWebViewController:(AIFacebookXMPPOAuthWebViewWindowController *)wc didSucceedWithToken:(NSString *)token;
- (void)oAuthWebViewControllerDidFail:(AIFacebookXMPPOAuthWebViewWindowController *)wc;

@property (weak, nonatomic) NSDictionary *migrationData;
@end

@interface AIFacebookXMPPAccount (ForSubclasses)
- (void)didCompleteFacebookAuthorization;
@end
