//
//  AIImageUploaderWindowController.m
//  Adium
//
//  Created by Zachary West on 2009-05-26.
//  Copyright 2009 Adium. All rights reserved.
//

#import "AIImageUploaderWindowController.h"

#import <AIUtilities/AIStringAdditions.h>

#import <AIUtilities/AIStringAdditions.h>

@interface AIImageUploaderWindowController()
- (id)initWithWindowNibName:(NSString *)nibName
				   delegate:(id)inDelegate
					   chat:(AIChat *)inChat;
@end

@implementation AIImageUploaderWindowController
+ (id)displayProgressInWindow:(NSWindow *)window
					 delegate:(id)inDelegate
						 chat:(AIChat *)inChat
{
	AIImageUploaderWindowController *newController = [[self alloc] initWithWindowNibName:@"ImageUploaderProgress"
																				delegate:inDelegate
																					chat:inChat];

	[NSApp beginSheet:newController.window
	   modalForWindow:window
		modalDelegate:newController
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
	
	return newController;
}

- (id)initWithWindowNibName:(NSString *)nibName
				   delegate:(id)inDelegate
					   chat:(AIChat *)inChat
{
	if ((self = [super initWithWindowNibName:nibName])) {
		chat = inChat;
		delegate = inDelegate;
	}
	
	return self;
}

- (void)dealloc
{
	NSLog(@"Dealloc");
	[super dealloc];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[label_uploadingImage setLocalizedString:[AILocalizedString(@"Uploading image to server", nil) stringByAppendingEllipsis]];
	[button_cancel setLocalizedString:AILocalizedStringFromTable(@"Cancel", @"Buttons", nil)];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:nil];
}

- (IBAction)cancel:(id)sender
{
	[delegate cancelForChat:chat];
	[self closeWindow:nil];
}

- (BOOL)indeterminate
{
	return progressIndicator.isIndeterminate;
}

- (void)setIndeterminate:(BOOL)indeterminate
{
	[progressIndicator setIndeterminate:indeterminate];
}

- (CGFloat)progress
{
	return progressIndicator.doubleValue;
}

- (void)setProgress:(CGFloat)percent
{
	[progressIndicator setDoubleValue:percent];
}

@end
