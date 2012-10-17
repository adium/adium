//
//  AIOTRSMPSecretQuestionWindowController.h
//  Adium
//
//  Created by Thijs Alkemade on 17-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIWindowController.h>
#import <Adium/AIListContact.h>

@interface AIOTRSMPSecretQuestionWindowController : AIWindowController {
	IBOutlet	NSTextField *label_intro;
	IBOutlet	NSTextField *label_question;
	IBOutlet	NSTextField	*field_answer;
	
	NSString *secretQuestion;
	AIListContact *contact;
	void(^handler)(NSString *answer);
}

- (IBAction)okay:(id)sender;
- (IBAction)cancel:(id)sender;
- (id)initWithQuestion:(NSString *)inQuestion from:(AIListContact *)inContact completionHandler:(void(^)(NSString *answer))inHandler;

@end
