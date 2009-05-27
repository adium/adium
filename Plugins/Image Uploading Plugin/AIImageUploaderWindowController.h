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
	IBOutlet NSProgressIndicator	*progressIndicator;
	IBOutlet NSButton				*button_cancel;
	
	AIChat						*chat;
	AIImageUploaderPlugin		*delegate;
}

@property (nonatomic) BOOL indeterminate;
@property (nonatomic) CGFloat progress;

+ (id)displayProgressInWindow:(NSWindow *)window
					 delegate:(id)inDelegate
						 chat:(AIChat *)inChat;
- (IBAction)cancel:(id)sender;

@end
