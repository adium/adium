//
//  PurpleFacebookAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 1/15/09.
//  Copyright 2009 Adium X. All rights reserved.
//

#import "PurpleFacebookAccount.h"
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/AIAccountControllerProtocol.h>
#import "AIFacebookXMPPService.h"
#import "AIFacebookXMPPAccount.h"

@implementation PurpleFacebookAccount

- (void)connect
{
	[self disconnect];
	[self migrate];
}

- (void)migrate
{
	AIAccount *newFB = [adium.accountController createAccountWithService:[adium.accountController firstServiceWithServiceID:@"FBXMPP"]
																	 UID:@"migration"];
	[(AIFacebookXMPPAccount *)newFB setMigratingAccount:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIEditAccount"
														object:newFB];
}

- (const char*)protocolPlugin
{
    return "prpl-bigbrownchunx-facebookim";
}

@end
