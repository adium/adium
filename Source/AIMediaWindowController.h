//
//  AIMediaWindowController.h
//  Adium
//
//  Created by Zachary West on 2009-12-10.
//  Copyright 2009  . All rights reserved.
//

#import <Adium/AIWindowController.h>
#import <Adium/AIMediaControllerProtocol.h>

@interface AIMediaWindowController : AIWindowController <AIMediaWindowController> {
	AIMedia	*media;
	
	NSView	*outgoingVideo;
	NSView	*incomingVideo;
}

@property (readwrite, retain, nonatomic) AIMedia *media;
@property (readwrite, retain, nonatomic) NSView *outgoingVideo;
@property (readwrite, retain, nonatomic) NSView *incomingVideo;

@end
