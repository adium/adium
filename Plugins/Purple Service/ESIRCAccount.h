//
//  ESIRCAccount.h
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import <AdiumLibpurple/CBPurpleAccount.h>

#define KEY_IRC_USE_SSL	@"IRC:Use SSL"

@interface ESIRCAccount : CBPurpleAccount {

}

- (void)identifyForNickServName:(NSString *)name password:(NSString *)inPassword;

@end
