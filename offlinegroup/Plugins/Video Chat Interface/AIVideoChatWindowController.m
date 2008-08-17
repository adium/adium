//
//  AIVideoChatWindowController.m
//  Adium
//
//  Created by Adam Iser on 12/4/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIVideoChatWindowController.h"

#define VIDEO_CHAT_NIB	@"VideoChat"

@implementation AIVideoChatWindowController

+ (id)windowForVideoChat:(AIVideoChat *)inVideoChat
{
	return [[[self alloc] initWithWindowNibName:VIDEO_CHAT_NIB videoChat:inVideoChat] autorelease];
}

- (id)initWithWindowNibName:(NSString *)windowNibName videoChat:(AIVideoChat *)inVideoChat
{
	[super initWithWindowNibName:windowNibName];

	videoChat = [inVideoChat retain];
	
	//Observe frames for this video chat
	[adium.videoChatController registerVideoChatObserver:self];
	
	return self;
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	NSWindow	*window = [self window];
	NSRect		frame = [window frame];
	
	[window setAspectRatio:NSMakeSize(frame.size.width, frame.size.height)];
}

- (BOOL)windowShouldClose:(id)sender
{
	[adium.videoChatController unregisterVideoChatObserver:self];
	[videoChat release];
	
}


//Frames
- (void)videoChatFrameChanged:(AIVideoChat *)inVideoChat
{
	[videoImageView setImage:[videoChat remoteFrame]];
}

@end






