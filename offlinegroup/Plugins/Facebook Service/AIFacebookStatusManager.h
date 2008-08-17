//
//  AIFacebookStatusManager.h
//  Adium
//
//  Created by Evan Schoenberg on 5/12/08.
//


@class AIFacebookAccount;

@interface AIFacebookStatusManager : NSObject {

}

+ (void)setFacebookStatusMessage:(NSString *)statusMessage forAccount:(AIFacebookAccount *)account;

@end
