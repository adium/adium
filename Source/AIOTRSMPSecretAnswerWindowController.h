//
//  AIOTRSMPSecretAnswerWindowController.h
//  Adium
//
//  Created by Thijs Alkemade on 17-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIWindowController.h>
#import <Adium/AIListContact.h>

@interface AIOTRSMPSecretAnswerWindowController : AIWindowController {
	IBOutlet	NSTextField *label_intro;
	IBOutlet	NSTextField	*label_answer;
	IBOutlet	NSTextView	*field_question;
	IBOutlet	NSTextView	*field_answer;
	
	BOOL isInitiator;
	NSString *secretQuestion;
	AIListContact *contact;
	void(^handler)(NSString *answer, NSString *question);
}

- (IBAction)okay:(id)sender;
- (IBAction)cancel:(id)sender;
- (id)initWithQuestion:(NSString *)inQuestion from:(AIListContact *)inContact completionHandler:(void(^)(NSString *answer, NSString *question))inHandler isInitiator:(BOOL)inInitiator;

@end
