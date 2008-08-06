//
//  AICustomSocialNetworkingStatusWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 6/7/08.
//  Copyright 2008 Adium X. All rights reserved.
//

#import <Adium/AIWindowController.h>

@class AIAccount;

@interface AICustomSocialNetworkingStatusWindowController : AIWindowController {
	AIAccount *account;
	id target;

	IBOutlet NSTextField *label_socialNetworkingStatus;
	IBOutlet NSTextView *textview_message;
	IBOutlet NSButton *button_okay;
	IBOutlet NSButton *button_cancel;
}

+ (void)showCustomSocialNetworkingStatusWindowWithInitialMessage:(NSAttributedString *)inMessage forAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;

- (void)setAccount:(AIAccount *)inAccount;
- (void)setTarget:(id)inTarget;
- (void)setMessage:(NSAttributedString *)inMessage;

@end

@interface NSObject (AICustomStatusWindowTarget)
- (void)setSocialNetworkingStatus:(NSAttributedString *)inStatusMessage forAccount:(AIAccount *)inAccount;
@end
