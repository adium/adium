//
//  AIXtraPreviewImageController.m
//  Adium
//
//  Created by David Smith on 3/6/06.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "AIXtraPreviewImageController.h"


@implementation AIXtraPreviewImageController

- (void)setXtra:(AIXtraInfo *)xtraInfo
{
	//Load the preview and set it.
	NSImage *previewImage = [xtraInfo previewImage];
	[previewView setImage:previewImage];
}

- (NSView *) previewView
{
	return previewView;
}

@end
