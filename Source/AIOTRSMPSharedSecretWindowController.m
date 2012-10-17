//
//  AIOTRSMPSharedSecretWindowController.m
//  Adium
//
//  Created by Thijs Alkemade on 17-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import "AIOTRSMPSharedSecretWindowController.h"

@implementation AIOTRSMPSharedSecretWindowController

- (id)initFrom:(AIListContact *)inContact completionHandler:(void(^)(NSString *answer))inHandler isInitiator:(BOOL)inInitiator
{
	if (self = [super initWithWindowNibName:@"AIOTRSMPSharedSecretWindowController"]) {
		contact = [inContact retain];
		handler = Block_copy(inHandler);
		isInitiator = inInitiator;
	}
	
	return self;
}

- (void)dealloc
{
	[contact release];
	Block_release(handler);
	
	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	if (isInitiator)
		[label_intro setStringValue:[NSString stringWithFormat:AILocalizedString(@"%@ asks you to confirm your identity by giving your shared secret:", nil), contact.UID]];
	else
		[label_intro setStringValue:[NSString stringWithFormat:AILocalizedString(@"Enter a shared secret to use to verify %@'s identity:", nil), contact.UID]];
}

- (IBAction)okay:(id)sender
{
	handler([[field_secret textStorage] string]);
	
	[self close];
	[self release];
}

- (IBAction)cancel:(id)sender
{
	handler(nil);
	
	[self close];
	[self release];
}

@end
