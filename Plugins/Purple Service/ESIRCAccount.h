//
//  ESIRCAccount.h
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import <AdiumLibpurple/CBPurpleAccount.h>

#define KEY_IRC_USE_SSL		@"IRC:Use SSL"
#define KEY_IRC_COMMANDS	@"IRC:Commands"
#define KEY_IRC_USERNAME	@"IRC:Username"
#define KEY_IRC_REALNAME	@"IRC:Realname"
#define KEY_IRC_ENCODING	@"IRC:Encoding"

@interface ESIRCAccount : CBPurpleAccount {

}

@property (readonly, nonatomic) NSString *defaultUsername;
@property (readonly, nonatomic) NSString *defaultRealname;

- (void)identifyForName:(NSString *)name password:(NSString *)inPassword;

@end
