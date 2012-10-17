//
//  AIOTRSMPSecretAnswerWindowController.m
//  Adium
//
//  Created by Thijs Alkemade on 17-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import "AIOTRSMPSecretAnswerWindowController.h"

@implementation AIOTRSMPSecretAnswerWindowController

- (id)initWithQuestion:(NSString *)inQuestion from:(AIListContact *)inContact completionHandler:(void(^)(NSString *answer, NSString *question))inHandler isInitiator:(BOOL)inInitiator
{
	if (self = [super initWithWindowNibName:@"AIOTRSMPSecretAnswerWindowController"]) {
		secretQuestion = [inQuestion retain];
		contact = [inContact retain];
		handler = Block_copy(inHandler);
		isInitiator = inInitiator;
	}
	
	return self;
}

- (void)dealloc
{
	[secretQuestion release];
	[contact release];
	Block_release(handler);
	
	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	if (isInitiator) {
		[label_intro setStringValue:[NSString stringWithFormat:AILocalizedString(@"Enter a question to use to verify %@'s identity:", nil), contact.UID]];
		[label_answer setStringValue:AILocalizedString(@"Correct answer:", nil)];
	} else {
		[label_intro setStringValue:[NSString stringWithFormat:AILocalizedString(@"%@ asks you to answer the following secret question to confirm your identity:", nil), contact.UID]];
		
		NSAttributedString *question = [[[NSAttributedString alloc] initWithString:secretQuestion ?: @""] autorelease];
		
		[[field_question textStorage] setAttributedString:question];
		[field_question setEditable:NO];
	}
}

- (IBAction)okay:(id)sender
{
	handler([[field_answer textStorage] string], [[field_question textStorage] string]);
	
	[self close];
	[self release];
}

- (IBAction)cancel:(id)sender
{
	if (!isInitiator) handler(nil, nil);
	
	[self close];
	[self release];
}

@end
