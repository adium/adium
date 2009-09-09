//
//  ESOTRFingerprintDetailsWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 5/11/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIWindowController.h>

@interface ESOTRFingerprintDetailsWindowController : AIWindowController {
	IBOutlet	NSTextField	*textField_UID;
	IBOutlet	NSTextField	*textField_fingerprint;
	
	IBOutlet	NSImageView	*imageView_service;
	IBOutlet	NSImageView	*imageView_lock;
	
	IBOutlet	NSButton	*button_OK;
	
	NSDictionary	*fingerprintDict;
}

+ (void)showDetailsForFingerprintDict:(NSDictionary *)inFingerprintDict;

@end
