//
//  AIOTRSMPSharedSecretWindowController.m
//  Adium
//
//  Created by Thijs Alkemade on 17-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import "AIOTRSMPSharedSecretWindowController.h"
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

@implementation AIOTRSMPSharedSecretWindowController

- (id)initFrom:(AIListContact *)inContact completionHandler:(void(^)(NSData *answer))inHandler isInitiator:(BOOL)inInitiator
{
	if (self = [super initWithWindowNibName:@"AIOTRSMPSharedSecretWindowController"]) {
		contact = inContact;
		handler = inHandler;
		isInitiator = inInitiator;
	}
	
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[imageView_lock setImage:[NSImage imageNamed:@"lock-locked" forClass:[adium class]]];
	
	path_file.URL = nil;
    
	if (!isInitiator)
		[label_intro setStringValue:[NSString stringWithFormat:AILocalizedString(@"%@ asks you to confirm your identity by giving your shared secret:", nil), contact.UID]];
	else
		[label_intro setStringValue:[NSString stringWithFormat:AILocalizedString(@"Enter a shared secret you have established with %@:", nil), contact.UID]];
}

- (IBAction)okay:(id)sender
{
	NSData *answer;
	
	if ([tab_answer indexOfTabViewItem:[tab_answer selectedTabViewItem]] == 0) {
		answer = [[[field_secret textStorage] string] dataUsingEncoding:NSUTF8StringEncoding];
	} else {
		answer = [NSData dataWithContentsOfURL:path_file.URL];
	}
	
	handler(answer);
	
	[self close];
}

- (IBAction)cancel:(id)sender
{
	if (!isInitiator) handler(nil);
	
	[self close];
}

- (IBAction)selectFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	
	NSInteger result = [openPanel runModal];
	
	if (result == NSOKButton && [openPanel URLs].count > 0) {
		path_file.URL = [[openPanel URLs] objectAtIndex:0];
	}
}

@end
