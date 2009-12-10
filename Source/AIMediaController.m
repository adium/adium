//
//  AIMediaController.m
//  Adium
//
//  Created by Zachary West on 2009-12-10.
//  Copyright 2009  . All rights reserved.
//

#import "AIMediaController.h"

#import <Adium/AIMedia.h>

@implementation AIMediaController
- (void)controllerDidLoad
{
	openMedias = [[NSMutableArray alloc] init];
}

- (void)controllerWillClose
{
	[openMedias release]; openMedias = nil;
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
	return nil;
}

- (void)media:(AIMedia *)media didSetState:(AIMediaState)state
{
	
}

- (void)showMedia:(AIMedia *)media
{
	
}

@end
