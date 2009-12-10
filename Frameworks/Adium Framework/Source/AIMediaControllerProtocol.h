//
//  AIMediaControllerProtocol.h
//  Adium
//
//  Created by Zachary West on 2009-12-10.
//  Copyright 2009  . All rights reserved.
//

#import <Adium/AIControllerProtocol.h>

typedef enum {
	AIMediaStateWaiting = 1, 	/* Waiting for response */
	AIMediaStateRequested,		/* Got request */
	AIMediaStateAccepted,		/* Accepted call */
	AIMediaStateRejected,		/* Rejected call */
} AIMediaState;

typedef enum {
	AIMediaPropertyMedia = 1,	/* A pointer to the PurpleMedia* */
	AIMediaPropertyScreenName	/* The screen name of the user */
} AIMediaProperty;

@class AIMedia, AIListContact, AIAccount;

@protocol AIMediaController <AIController>
- (AIMedia *)mediaWithContact:(AIListContact *)contact
					onAccount:(AIAccount *)account;

- (AIMedia *)existingMediaWithContact:(AIListContact *)contact
							onAccount:(AIAccount *)account;

- (void)showMedia:(AIMedia *)media;

@end
