//
//  AIMediaController.m
//  Adium
//
//  Created by Zachary West on 2009-12-10.
//  Copyright 2009  . All rights reserved.
//

#import "AIMediaController.h"

#import <Adium/AIMediaControllerProtocol.h>
#import <Adium/AIMedia.h>

#import "AIMediaWindowController.h"

@implementation AIMediaController
- (void)controllerDidLoad
{
	openMedias = [[NSMutableArray alloc] init];
	openMediaControllers = [[NSMutableArray alloc] init];
}

- (void)controllerWillClose
{
	[openMedias release]; openMedias = nil;
	[openMediaControllers release]; openMediaControllers = nil;
}

- (AIMedia *)mediaWithContact:(AIListContact *)contact
					onAccount:(AIAccount *)account
{
	AIMedia *media = [AIMedia mediaWithContact:contact onAccount:account];
	
	[openMedias addObject:media];
	
	return media;
}

- (AIMedia *)existingMediaWithContact:(AIListContact *)contact
							onAccount:(AIAccount *)account
{
	for (AIMedia *media in openMedias) {
		if (media.account == account && media.listContact == contact) {
			return media;
		}
	}
	
	return nil;
}

- (NSWindowController <AIMediaWindowController> *)windowControllerForMedia:(AIMedia *)media
{
	for (NSWindowController <AIMediaWindowController> *windowController in openMediaControllers) {
		if (windowController.media == media)
			return windowController;
	}
	
	NSWindowController *windowController = [AIMediaWindowController mediaWindowControllerForMedia:media];
	[openMediaControllers addObject:windowController];
	
	return windowController;
}

- (void)closeMediaWindowController:(NSWindowController <AIMediaWindowController> *)mediaWindowController
{
	[[mediaWindowController retain] autorelease];
	
	[openMediaControllers removeObject:mediaWindowController];
}

- (void)media:(AIMedia *)media didSetState:(AIMediaState)state
{
	
}

@end
