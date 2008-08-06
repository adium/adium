//
//  AIFacebookAccount.h
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//

#import <Adium/AIAccount.h>

@class WebView;
@class AIFacebookBuddyListManager, AIFacebookIncomingMessageManager;

@interface AIFacebookAccount : AIAccount {
	NSURLConnection *loginConnection;
	WebView *webView;
	BOOL sentLogin;
	
	NSString *facebookUID;
	NSString *channel;
	NSString *postFormID;
	
	AIFacebookBuddyListManager		 *buddyListManager;
	AIFacebookIncomingMessageManager *incomingMessageManager;
}

+ (NSData *)postDataForDictionary:(NSDictionary *)inDict;
- (BOOL)isSigningOn;

- (void)reconnect;

- (NSString *)facebookUID;
- (NSString *)channel;
- (NSString *)postFormID;

@end
