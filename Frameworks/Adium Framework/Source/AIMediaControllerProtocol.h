//
//  AIMediaControllerProtocol.h
//  Adium
//
//  Created by Zachary West on 2009-12-10.
//  Copyright 2009  . All rights reserved.
//

#import <Adium/AIControllerProtocol.h>

typedef enum {
	AIMediaTypeAudio,
	AIMediaTypeVideo
} AIMediaType;

typedef enum {
	AIMediaStateWaiting = 1, 	/* Waiting for response */
	AIMediaStateRequested,		/* Got request */
	AIMediaStateAccepted,		/* Accepted call */
	AIMediaStateRejected,		/* Rejected call */
} AIMediaState;

@class AIMedia, AIListContact, AIAccount;

@protocol AIMediaWindowController
@property (readwrite, retain, nonatomic) AIMedia *media;
@property (readwrite, retain, nonatomic) NSView *outgoingVideo;
@property (readwrite, retain, nonatomic) NSView *incomingVideo;
@end

@protocol AIMediaController <AIController>
- (AIMedia *)mediaWithContact:(AIListContact *)contact
					onAccount:(AIAccount *)account;

- (AIMedia *)existingMediaWithContact:(AIListContact *)contact
							onAccount:(AIAccount *)account;

- (NSWindowController <AIMediaWindowController> *)windowControllerForMedia:(AIMedia *)media;
- (void)closeMediaWindowController:(NSWindowController <AIMediaWindowController> *)mediaWindowController;

- (void)media:(AIMedia *)media didSetState:(AIMediaState)state;

@end
