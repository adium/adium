//
//  AIPurpleOAuthJabberAccount.h
//  Adium
//
//  Created by Thijs Alkemade on 18-09-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import "ESPurpleJabberAccount.h"
#import "AIXMPPOAuthWebViewWindowController.h"

#define AIXMPPAuthProgressNotification @"AIXMPPAuthProgressNotification"
#define KEY_XMPP_OAUTH_STEP @"OAuthStep"

typedef enum {
	AIXMPPOAuthProgressPromptingUser,
	AIXMPPOAuthProgressContactingServer,
	AIXMPPOAuthProgressPromotingForChat,
	AIXMPPOAuthProgressSuccess,
	AIXMPPOAuthProgressFailure
} AIXMPPOAuthProgressStep;

enum {
    AINoNetworkState,
    AIMeGraphAPINetworkState,
    AIPromoteSessionNetworkState
};

@interface AIPurpleOAuthJabberAccount : ESPurpleJabberAccount {
	AIXMPPOAuthWebViewWindowController *oAuthWC;
    
    NSString *oAuthToken;
    NSUInteger networkState;
    
    NSURLConnection *connection; // weak
    NSURLResponse *connectionResponse;
    NSMutableData *connectionData;
}

@property (nonatomic, retain) AIXMPPOAuthWebViewWindowController *oAuthWC;
- (void)requestAuthorization;

- (void)oAuthWebViewController:(AIXMPPOAuthWebViewWindowController *)wc didSucceedWithToken:(NSString *)token;
- (void)oAuthWebViewControllerDidFail:(AIXMPPOAuthWebViewWindowController *)wc;

- (void)didCompleteAuthorization;

@property (nonatomic, copy) NSString *oAuthToken;
@property (nonatomic, assign) NSUInteger networkState;
@property (nonatomic, assign) NSURLConnection *connection; // assign because NSURLConnection retains its delegate.
@property (nonatomic, retain) NSURLResponse *connectionResponse;
@property (nonatomic, retain) NSMutableData *connectionData;

- (void)meGraphAPIDidFinishLoading:(NSData *)graphAPIData response:(NSURLResponse *)response error:(NSError *)inError;
- (void)promoteSessionDidFinishLoading:(NSData *)secretData response:(NSURLResponse *)response error:(NSError *)inError;

+ (BOOL)uidIsValid:(NSString *)inUID;

// For subclasses
- (NSString *)graphURLForToken:(NSString *)token;
- (NSString *)promoteURLForToken:(NSString *)token;
- (NSString *)authorizeURL;
- (NSString *)frameURLHost;
- (NSString *)frameURLPath;

@end
