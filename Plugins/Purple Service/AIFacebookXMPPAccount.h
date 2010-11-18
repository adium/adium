//
//  AIFacebookXMPPAccount.h
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CBPurpleAccount.h"


@interface AIFacebookXMPPAccount : CBPurpleAccount {
    NSString *sessionSecret;
}

@property (retain) NSString *sessionSecret;

@end
