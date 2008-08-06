//
//  ESAuthorizationRequestWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 5/18/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIWindowController.h>

@class AIAccount;

@interface ESAuthorizationRequestWindowController : AIWindowController {
	IBOutlet	NSTextField		*textField_header;
	IBOutlet	NSTextView		*textView_message;

	IBOutlet	NSButton		*button_authorize;
	IBOutlet	NSButton		*button_deny;
	IBOutlet	NSButton		*checkBox_addToList;
	
	NSDictionary				*infoDict;
	
	AIAccount					*account;
	
	BOOL						windowIsClosing;
	BOOL						postedAuthorizationResponse;
}

+ (ESAuthorizationRequestWindowController *)showAuthorizationRequestWithDict:(NSDictionary *)inInfoDict  forAccount:(AIAccount *)inAccount;
- (IBAction)authorize:(id)sender;
- (IBAction)deny:(id)sender;

@end
