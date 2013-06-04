//
//  STTwitterRequest.h
//  STTwitterRequests
//
//  Created by Nicolas Seriot on 9/5/12.
//  Copyright (c) 2012 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STTwitterOAuthProtocol.h"

/*
 Based on the following documentation
 http://oauth.net/core/1.0/
 https://dev.twitter.com/docs/auth/authorizing-request
 https://dev.twitter.com/docs/auth/implementing-sign-twitter
 https://dev.twitter.com/docs/auth/creating-signature
 https://dev.twitter.com/docs/api/1/post/oauth/request_token
 https://dev.twitter.com/docs/oauth/xauth
 ...
 */

@interface STTwitterOAuth : NSObject <STTwitterOAuthProtocol> {
	NSString *_username;
	NSString *_password;
	NSString *_oauthConsumerName;
	NSString *_oauthConsumerKey;
	NSString *_oauthConsumerSecret;
	NSString *_oauthRequestToken;
	NSString *_oauthRequestTokenSecret;
	NSString *_oauthAccessToken;
	NSString *_oauthAccessTokenSecret;
	NSString *_testOauthNonce;
	NSString *_testOauthTimestamp;
}

+ (STTwitterOAuth *)twitterServiceWithConsumerName:(NSString *)consumerName
                                       consumerKey:(NSString *)consumerKey
                                    consumerSecret:(NSString *)consumerSecret;

+ (STTwitterOAuth *)twitterServiceWithConsumerName:(NSString *)consumerName
                                       consumerKey:(NSString *)consumerKey
                                    consumerSecret:(NSString *)consumerSecret
                                        oauthToken:(NSString *)oauthToken
                                  oauthTokenSecret:(NSString *)oauthTokenSecret;

+ (STTwitterOAuth *)twitterServiceWithConsumerName:(NSString *)consumerName
                                       consumerKey:(NSString *)consumerKey
                                    consumerSecret:(NSString *)consumerSecret
                                          username:(NSString *)username
                                          password:(NSString *)password;

- (void)postTokenRequest:(void(^)(NSURL *url, NSString *oauthToken))successBlock
           oauthCallback:(NSString *)oauthCallback
              errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postAccessTokenRequestWithPIN:(NSString *)pin
                         successBlock:(void(^)(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postXAuthAccessTokenRequestWithUsername:(NSString *)username
                                       password:(NSString *)password
                                   successBlock:(void(^)(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName))successBlock
                                     errorBlock:(void(^)(NSError *error))errorBlock;

- (BOOL)canVerifyCredentials;

- (void)verifyCredentialsWithSuccessBlock:(void(^)(NSString *username))successBlock errorBlock:(void(^)(NSError *error))errorBlock;

@end

@interface NSString (STTwitterOAuth)
+ (NSString *)random32Characters;
- (NSString *)signHmacSHA1WithKey:(NSString *)key;
- (NSDictionary *)parametersDictionary;
- (NSString *)urlEncodedString;
@end

@interface NSURL (STTwitterOAuth)
- (NSString *)normalizedForOauthSignatureString;
- (NSArray *)getParametersDictionaries;
@end
