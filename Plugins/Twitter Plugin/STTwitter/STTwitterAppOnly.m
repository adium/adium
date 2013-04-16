//
//  STTwitterAppOnly.m
//  STTwitter
//
//  Created by Nicolas Seriot on 3/13/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import "STTwitterAppOnly.h"
#import "STHTTPRequest.h"
#import "NSString+STTwitter.h"
#import "NSData+Base64.h"

@implementation STTwitterAppOnly

@synthesize consumerKey = _consumerKey;
@synthesize consumerSecret = _consumerSecret;
@synthesize bearerToken = _bearerToken;


- (void)dealloc {
    [_consumerKey release];
    [_consumerSecret release];
    [_bearerToken release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    
    [STHTTPRequest clearSession]; // former cookies may result in mixed-up kind of authentication
    
    return self;
}

#pragma mark STTwitterOAuthProtocol

- (BOOL)canVerifyCredentials {
    return YES;
}

- (void)invalidateBearerTokenWithSuccessBlock:(void(^)())successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock {
    
    if(_bearerToken == nil) {
        errorBlock(nil);
        return;
    }
    
    [self postResource:@"oauth2/invalidate_token"
         baseURLString:@"https://api.twitter.com"
            parameters:@{ @"access_token" : _bearerToken }
          useBasicAuth:YES
          successBlock:^(NSString *body) {
              
              NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
              
              NSError *error = nil;
              id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
              
              if([json isKindOfClass:[NSDictionary class]] == NO) {
                  errorBlock(error);
                  return;
              }
              
              self.bearerToken = [json valueForKey:@"access_token"];
              
              NSString *oldToken = self.bearerToken;
              
              self.bearerToken = nil;
              
              successBlock(oldToken);
              
          } errorBlock:^(NSError *error) {
              errorBlock(error);
          }];
    
    // POST /oauth2/invalidate_token HTTP/1.1
    // Authorization: Basic eHZ6MWV2RlM0d0VFUFRHRUZQSEJvZzpMOHFxOVBaeVJn
    // NmllS0dFS2hab2xHQzB2SldMdzhpRUo4OERSZHlPZw==
    // User-Agent: My Twitter App v1.0.23
    // Host: api.twitter.com
    // Accept: */*
    //
    // Content-Length: 119
    // Content-Type: application/x-www-form-urlencoded
    //
    // access_token=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAAAAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    
    // HTTP/1.1 200 OK
    // Content-Type: application/json; charset=utf-8
    // Content-Length: 127
    // ...
    //
    // {"access_token":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAAAAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}
}

+ (NSString *)base64EncodedBearerTokenCredentialsWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret {
    NSString *encodedConsumerToken = [consumerKey st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedConsumerSecret = [consumerSecret st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *bearerTokenCredentials = [NSString stringWithFormat:@"%@:%@", encodedConsumerToken, encodedConsumerSecret];
    NSData *data = [bearerTokenCredentials dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedString];
}

- (void)verifyCredentialsWithSuccessBlock:(void(^)(NSString *username))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock {
    
    
    [self postResource:@"oauth2/token"
         baseURLString:@"https://api.twitter.com"
            parameters:@{ @"grant_type" : @"client_credentials" }
          useBasicAuth:YES
          successBlock:^(NSString *body) {
              
              NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
              
              NSError *error = nil;
              id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
              
              if([json isKindOfClass:[NSDictionary class]] == NO) {
                  errorBlock(error);
                  return;
              }
              
              NSString *tokenType = [json valueForKey:@"token_type"];
              if([tokenType isEqualToString:@"bearer"] == NO) {
                  errorBlock(nil);
                  return;
              }
              
              self.bearerToken = [json valueForKey:@"access_token"];
              
              successBlock(_bearerToken);
              
          } errorBlock:^(NSError *error) {
              errorBlock(error);
          }];
}

- (void)getResource:(NSString *)resource
         parameters:(NSDictionary *)params
       successBlock:(void(^)(id json))successBlock
         errorBlock:(void(^)(NSError *error))errorBlock {
    
    /*
     GET /1.1/statuses/user_timeline.json?count=100&screen_name=twitterapi HTTP/1.1
     Host: api.twitter.com
     User-Agent: My Twitter App v1.0.23
     Authorization: Bearer AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAA
     AAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
     Accept-Encoding: gzip
     */
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"https://api.twitter.com/1.1/%@", resource];
    
    NSMutableArray *parameters = [NSMutableArray array];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *s = [NSString stringWithFormat:@"%@=%@", key, obj];
        [parameters addObject:s];
    }];
    
    if([parameters count]) {
        NSString *parameterString = [parameters componentsJoinedByString:@"&"];
        
        [urlString appendFormat:@"?%@", parameterString];
    }
    
    __block STHTTPRequest *r = [STHTTPRequest requestWithURLString:urlString];
    
    r.completionBlock = ^(NSDictionary *headers, NSString *body) {
        
        NSError *jsonError = nil;
        id json = [NSJSONSerialization JSONObjectWithData:r.responseData options:NSJSONReadingMutableLeaves error:&jsonError];
        NSLog(@"-- jsonError: %@", [jsonError localizedDescription]);
        
        if(json == nil) {
            errorBlock(jsonError);
            return;
        }
        
        NSLog(@"** %@", json);
        
        successBlock(json);
    };
    
    r.errorBlock = ^(NSError *error) {
        NSLog(@"-- body: %@", r.responseString);
        errorBlock(error);
    };
    
    if(_bearerToken) {
        [r setHeaderWithName:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", _bearerToken]];
    }
    
    [r startAsynchronous];
}

- (void)postResource:(NSString *)resource
       baseURLString:(NSString *)baseURLString // no trailing slash
          parameters:(NSDictionary *)params
        useBasicAuth:(BOOL)useBasicAuth
        successBlock:(void(^)(NSString *body))successBlock
          errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", baseURLString, resource];
    
    __block STHTTPRequest *r = [STHTTPRequest requestWithURLString:urlString];
    
    r.POSTDictionary = params;
    
    NSMutableDictionary *mutableParams = [[params mutableCopy] autorelease];
    
    r.encodePOSTDictionary = NO;
    
    r.POSTDictionary = mutableParams ? mutableParams : @{};
    
    r.completionBlock = ^(NSDictionary *headers, NSString *body) {
        successBlock(body);
    };
    
    r.errorBlock = ^(NSError *error) {
        
        // do our best to extract Twitter error message from responseString
        
        NSError *regexError = nil;
        NSString *errorString = [r.responseString firstMatchWithRegex:@"<error>(.*)</error>" error:&regexError];
        if(errorString == nil) {
            NSLog(@"-- regexError: %@", [regexError localizedDescription]);
        }
        
        if(errorString) {
            error = [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:@{NSLocalizedDescriptionKey : errorString}];
        } else if ([r.responseString length] > 0 && [r.responseString length] < 64) {
            error = [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:@{NSLocalizedDescriptionKey : r.responseString}];
        }
        
        NSLog(@"-- body: %@", r.responseString);
        errorBlock(error);
    };
    
    if(useBasicAuth) {
        NSString *base64EncodedTokens = [[self class] base64EncodedBearerTokenCredentialsWithConsumerKey:_consumerKey consumerSecret:_consumerSecret];
        
        [r setHeaderWithName:@"Authorization" value:[NSString stringWithFormat:@"Basic %@", base64EncodedTokens]];
    } else if(_bearerToken) {
        [r setHeaderWithName:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", _bearerToken]];
        r.encodePOSTDictionary = YES;
    }
    
    [r startAsynchronous];
}

- (void)postResource:(NSString *)resource
          parameters:(NSDictionary *)params
        successBlock:(void(^)(id json))successBlock
          errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self postResource:resource baseURLString:@"https://api.twitter.com/1.1/" parameters:params useBasicAuth:NO successBlock:successBlock errorBlock:errorBlock];
}

@end
