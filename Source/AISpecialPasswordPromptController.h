//
//  AISpecialPasswordPromptController.h
//  Adium
//
//  Created by Zachary West on 2009-03-28.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIPasswordPromptController.h>
#import <Adium/AIAccountControllerProtocol.h>

@interface AISpecialPasswordPromptController : AIPasswordPromptController {
	IBOutlet	NSTextField				*label_server;
	IBOutlet	NSTextField				*label_username;
	IBOutlet	NSTextField				*label_pleaseEnter;
	IBOutlet	NSImageView				*imageView_service;
	
	AISpecialPasswordType	type;
	AIAccount				*account;
	NSString				*name;
}

+ (void)showPasswordPromptForType:(AISpecialPasswordType)inType
						  account:(AIAccount *)inAccount
							 name:(NSString *)inName
						 password:(NSString *)password
				  notifyingTarget:(id)inTarget
						 selector:(SEL)inSelector
						  context:(id)inContext;

@end
