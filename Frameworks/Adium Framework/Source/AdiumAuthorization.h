//
//  AdiumAuthorization.h
//  Adium
//
//  Created by Evan Schoenberg on 1/18/06.
//

#import <Adium/AIContactAlertsControllerProtocol.h>

@class AIAccount;

@interface AdiumAuthorization : NSObject <AIEventHandler> {

}

+ (void)start;
+ (id)showAuthorizationRequestWithDict:(NSDictionary *)inDict forAccount:(AIAccount *)inAccount;
+ (void)closeAuthorizationForUIHandle:(id)handle;

@end
