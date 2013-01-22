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
	IBOutlet	NSImageView	*imageView_lock;
	
	BOOL isInitiator;
	AIListContact *contact;
	void(^handler)(NSString *secret);
}

- (IBAction)okay:(id)sender;
- (IBAction)cancel:(id)sender;
- (id)initFrom:(AIListContact *)inContact completionHandler:(void(^)(NSString *answer))inHandler isInitiator:(BOOL)inInitiator;

@end
