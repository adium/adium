//
//  AIImageUploaderWindowController.h
//  Adium
//
//  Created by Zachary West on 2009-05-26.
//  Copyright 2009 Adium. All rights reserved.
//

#import <Adium/AIWindowController.h>
#import "AIImageUploaderPlugin.h"

@interface AIImageUploaderWindowController : AIWindowController {
	IBOutlet NSTextField			*label_uploadingImage;
	IBOutlet NSTextField			*label_uploadProgress;
	IBOutlet NSProgressIndicator	*progressIndicator;
	IBOutlet NSButton				*button_cancel;
	
	AIChat						*chat;
	AIImageUploaderPlugin		*delegate;
}

@property (nonatomic) BOOL indeterminate;

+ (id)displayProgressInWindow:(NSWindow *)window
					 delegate:(id)inDelegate
						 chat:(AIChat *)inChat;
- (IBAction)cancel:(id)sender;
- (void)updateProgress:(NSUInteger)uploaded total:(NSUInteger)total;

@end
