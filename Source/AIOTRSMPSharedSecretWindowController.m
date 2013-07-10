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
	
	[imageView_lock setImage:[NSImage imageNamed:@"lock-locked" forClass:[adium class]]];
    
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
		answer = [NSData dataWithContentsOfURL:file];
	}
	
	handler(answer);
	
	[self close];
	[self release];
}

- (IBAction)cancel:(id)sender
{
	if (!isInitiator) handler(nil);
	
	[self close];
	[self release];
}

- (IBAction)selectFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	
	NSInteger result = [openPanel runModal];
	
	if (result == NSOKButton && [openPanel URLs].count > 0) {
		[file release];
		file = [[[openPanel URLs] objectAtIndex:0] retain];
		
		NSMutableAttributedString *fileName = [[[NSMutableAttributedString alloc] init] autorelease];
		
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[file path]];
		
		[icon setSize:NSMakeSize(16, 16)];
		
		NSTextAttachmentCell *cell = [[[NSTextAttachmentCell alloc] initImageCell:icon] autorelease];
		
		NSTextAttachment *attachment = [[[NSTextAttachment alloc] init] autorelease];
		
		[attachment setAttachmentCell:cell];
		
		[fileName appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
		
		[fileName appendString:[file lastPathComponent] withAttributes:@{}];
		
		[label_filename setAttributedStringValue:fileName];
	}
}

@end
