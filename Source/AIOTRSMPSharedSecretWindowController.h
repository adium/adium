//
//  AIOTRSMPSharedSecretWindowController.h
//  Adium
//
//  Created by Thijs Alkemade on 17-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIWindowController.h>
#import <Adium/AIListContact.h>

@interface AIOTRSMPSharedSecretWindowController : AIWindowController {
	IBOutlet	NSTextField *label_intro;
	IBOutlet	NSTextView	*field_secret;
	IBOutlet	NSPathControl *path_file;
	IBOutlet	NSImageView	*imageView_lock;
	IBOutlet	NSTabView	*tab_answer;
	
	BOOL isInitiator;
	NSString *secretQuestion;
	AIListContact *contact;
	void(^handler)(NSData *answer);
}

- (IBAction)okay:(id)sender;
- (IBAction)cancel:(id)sender;
- (id)initFrom:(AIListContact *)inContact completionHandler:(void(^)(NSData *answer))inHandler isInitiator:(BOOL)inInitiator;

@end
