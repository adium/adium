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
	IBOutlet	NSTextField	*label_tips;
	IBOutlet	NSTextView	*field_question;
	IBOutlet	NSTextView	*field_answer;
	IBOutlet	NSImageView	*imageView_lock;
	
	BOOL isInitiator;
	NSString *secretQuestion;
	AIListContact *contact;
	void(^handler)(NSString *answer, NSString *question);
}

- (IBAction)okay:(id)sender;
- (IBAction)cancel:(id)sender;
- (id)initWithQuestion:(NSString *)inQuestion from:(AIListContact *)inContact completionHandler:(void(^)(NSString *answer, NSString *question))inHandler isInitiator:(BOOL)inInitiator;

@end
