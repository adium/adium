//
//  AIFacebookXMPPAccount.h
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AIPurpleOAuthJabberAccount.h"
#import "AIXMPPOAuthWebViewWindowController.h"

#define ADIUM_APP_ID "164063256994618"
#define ADIUM_API_KEY "add7b04ecedcd84645f3c32e7884682d"

/* deprecated? This is called the 'App Secret' on Facebook's developer page.  */
#define ADIUM_API_SECRET "bb9d2d9771790e69a0e943771ddf33c8"

@interface AIFacebookXMPPAccount : AIPurpleOAuthJabberAccount {
	NSDictionary *migrationData;
}

@property (nonatomic, retain) NSDictionary *migrationData;
@end