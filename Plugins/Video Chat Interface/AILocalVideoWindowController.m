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

#import "AILocalVideoWindowController.h"
#import <AIUtilities/AIVideoCapture.h>

@implementation AILocalVideoWindowController

AILocalVideoWindowController	*sharedLocalVideoWindowInstance = nil;

+ (void)showLocalVideoWindow
{
	if (!sharedLocalVideoWindowInstance) {
		sharedLocalVideoWindowInstance = [[self alloc] initWithWindowNibName:@"LocalVideoWindow"];
		[sharedLocalVideoWindowInstance showWindow:nil];
	}
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[super initWithWindowNibName:windowNibName];

	//Observe local video
	localVideo = [[AIVideoCapture alloc] initWithSize:NSMakeSize(320,240)
									  captureInterval:(1.0/24.0)
											 delegate:self];
	[localVideo beginCapturingVideo];
	
	return self;
}

- (void)dealloc
{
	[localVideo stopCapturingVideo];
	[localVideo release];
	[super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[[self window] setAspectRatio:[[self window] frame].size];
	[[self window] setBackgroundColor:[NSColor blackColor]];
}

//Close our shared instance
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[sharedLocalVideoWindowInstance autorelease];
	sharedLocalVideoWindowInstance = nil;
}

//Update video frame
- (void)videoCapture:(AIVideoCapture *)videoCapture frameReady:(NSImage *)image
{
	[videoImageView setImage:image];
}

@end
