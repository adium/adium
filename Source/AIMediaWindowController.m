//
//  AIMediaWindowController.m
//  Adium
//
//  Created by Zachary West on 2009-12-10.
//  Copyright 2009  . All rights reserved.
//

#import "AIMediaWindowController.h"

@interface AIMediaWindowController()
- (id)initWithMedia:(AIMedia *)inMedia;
@end

@implementation AIMediaWindowController

@synthesize incomingVideo, outgoingVideo, media;

+ (AIMediaWindowController *)mediaWindowControllerForMedia:(AIMedia *)media
{
	return [[[self alloc] initWithMedia:media] autorelease];
}

- (id)initWithMedia:(AIMedia *)inMedia
{
	if ((self = [super initWithWindowNibName:@"AIMediaWindow"])) {
		self.media = inMedia;
	}
	return self;
}

@end
