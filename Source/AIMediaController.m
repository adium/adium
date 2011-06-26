/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

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
	
	AIMediaWindowController *windowController = [AIMediaWindowController mediaWindowControllerForMedia:media];
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
