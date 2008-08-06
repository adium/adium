/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <QuickTime/QuickTime.h>

@interface AIVideoCapture : NSObject
{
	long				uniqueID;		//Unique ID number identifying this instance of AIVideoCapture
	NSSize				captureSize;
	NSTimeInterval		captureInterval;
	
	NSTimer				*captureTimer;
	id					delegate;
	
	GWorldPtr 			gWorld;
    ImageSequence 		decodeSeq;
    SeqGrabComponent	seqGrab;
    SGChannel			channel;
}

- (id)initWithSize:(NSSize)inSize captureInterval:(NSTimeInterval)inInterval delegate:(id)inDelegate;
- (void)beginCapturingVideo;
- (void)stopCapturingVideo;

@end

@interface NSObject (AIVideoCaptureDelegate)
- (void)videoCapture:(AIVideoCapture *)videoCapture frameReady:(NSImage *)frame;
@end
