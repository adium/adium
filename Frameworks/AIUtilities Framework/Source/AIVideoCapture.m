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
#import <Carbon/Carbon.h>
#import "AIVideoCapture.h"
#import "AIImageAdditions.h"

static NSMutableDictionary	*videoCaptureInstances = nil;
pascal OSErr videoCaptureDataCallback(SGChannel c, Ptr p, long len, long *offset, long chRefCon, TimeValue time,
									  short writeType,  long refCon);

static long instanceCounter = 0L;

@interface AIVideoCapture (PRIVATE)
- (void)_initVideoCapture;
- (void)_deallocVideoCapture;
- (void)_primeDecompression;
- (void)_captureFrameReadyInGWorld;
- (ImageSequence)_decodeSeq;
@end

@implementation AIVideoCapture

//Init
- (id)initWithSize:(NSSize)inSize captureInterval:(NSTimeInterval)inInterval delegate:(id)inDelegate
{
	if ((self = [super init])) {
		delegate = inDelegate;
		uniqueID = 0;
		gWorld = NULL;
		decodeSeq = 0;
		captureSize = inSize;
		captureInterval = inInterval;
	
		//Delegate must implement frameReady
		if (delegate) {
			NSParameterAssert([delegate respondsToSelector:@selector(videoCapture:frameReady:)]);
		}
	
		//Init our video capture (Reserve the device and prepare for capture)
		[self _initVideoCapture];
	}
	return self;
}

//Dealloc
- (void)dealloc
{
	[self stopCapturingVideo];
	[self _deallocVideoCapture];
	[super dealloc];
}

//Init the video capture mechanisms
- (void)_initVideoCapture
{
	Rect	boundsRect = {0, 0, captureSize.height, captureSize.width};
	
    EnterMovies();
	
    //Grab the default sequence grabber
	seqGrab = OpenDefaultComponent(SeqGrabComponentType, 0);
	SGInitialize(seqGrab);
    
	//Configure it for our import	
	SGSetDataRef(seqGrab, 0, 0, seqGrabDontMakeMovie);
    SGNewChannel(seqGrab, VideoMediaType, &channel);
	SGSetChannelBounds(seqGrab, &boundsRect);
	
	//Create a gWorld for the sequence grabber to dump our frames into
    QTNewGWorld(&gWorld, k32ARGBPixelFormat, &boundsRect, 0, NULL, 0);
    LockPixels(GetPortPixMap(gWorld));
	
	//Configure the sequence grabber for our gworld
    SGSetGWorld(seqGrab, gWorld, GetMainDevice());
    SGSetChannelBounds(channel, &boundsRect);
    SGSetChannelUsage(channel, (seqGrabPreview | seqGrabRecord | seqGrabPlayDuringRecord));
}

//Shut down the video capture mechanisms
- (void)_deallocVideoCapture
{
    CDSequenceEnd(decodeSeq);
    CloseComponent(seqGrab);
    DisposeGWorld(gWorld);
	SGRelease(seqGrab);
}

//Prime the decompression (We call this the first time only)
- (void)_primeDecompression
{
	Rect					sourceRect = {0, 0, captureSize.height, captureSize.width};
	ImageDescriptionHandle	imageDesc = (ImageDescriptionHandle)NewHandle(0);
	MatrixRecord			scaleMatrix;	

	//Setup correct scaling of our image
	SGGetChannelSampleDescription(channel, (Handle)imageDesc);
	sourceRect.right = (**imageDesc).width;
	sourceRect.bottom = (**imageDesc).height;
	RectMatrix(&scaleMatrix, &sourceRect, &sourceRect);

	//Begin
	DecompressSequenceBegin(&decodeSeq, imageDesc, gWorld, NULL, NULL, &scaleMatrix, srcCopy, NULL,
							0, codecNormalQuality, bestSpeedCodec);
	
	DisposeHandle((Handle)imageDesc);
}

//Being capturing frames
- (void)beginCapturingVideo
{
	if (!captureTimer) {
		//Unique ID for this object
		//Since our callback is C code, we'll need a way to find our AIVideoCapture instance from within the callback.
		//We achieve this by keeping track of all the open AIVideoCapture instances, where each instance has a unique
		//identifier.  The callback can lookup the instance it wants by this unique ID.
		if (!videoCaptureInstances) videoCaptureInstances = [[NSMutableDictionary alloc] init];
		if (!uniqueID) {
			uniqueID = ++instanceCounter;
			if (uniqueID <= 0) {
				//we overflowed the long
				uniqueID = instanceCounter = 1;
			}
		}
		[videoCaptureInstances setObject:self forKey:[NSNumber numberWithLong:uniqueID]];
		
		//Start recording
		//Set our data callback function (Sequencer will call this when a frame is complete)
		SGSetDataProc(seqGrab, NewSGDataUPP(&videoCaptureDataCallback), uniqueID);
		SGPrepare(seqGrab, false, true);
		SGStartRecord(seqGrab);
		captureTimer = [[NSTimer scheduledTimerWithTimeInterval:captureInterval
														 target:self
													   selector:@selector(captureFrame:)	
													   userInfo:nil
														repeats:YES] retain];
	}	
}

//Stop capturing frames
- (void)stopCapturingVideo
{
	[videoCaptureInstances removeObjectForKey:[NSNumber numberWithLong:uniqueID]];
	uniqueID = 0;
	
	[captureTimer invalidate];
	[captureTimer release];
	captureTimer = nil;

	SGStop(seqGrab);
}

//Begin capturing a frame of video, delegate is notified when capture if complete
- (void)captureFrame:(NSTimer *)timer
{
	if (decodeSeq == 0) [self _primeDecompression];
	SGIdle(seqGrab);
}

//Called by the video data callback when a frame is ready for extraction from our gWorld
- (void)_captureFrameReadyInGWorld
{
	[delegate videoCapture:self frameReady:[NSImage imageFromGWorld:gWorld]];
}

//Accessor for our sequence ID so we can use it in the non-instanced callback function
- (ImageSequence)_decodeSeq{
	return decodeSeq;
}

@end

//Video capture new data callback
pascal OSErr videoCaptureDataCallback(SGChannel c, Ptr p, long len, long *offset, long chRefCon, TimeValue time,
									  short writeType,  long refCon)
{    
	AIVideoCapture	*videoCapture = [videoCaptureInstances objectForKey:[NSNumber numberWithLong:refCon]];
    CodecFlags 		ignore;
    
	//Process the new data
	[videoCapture _captureFrameReadyInGWorld];
	
	//Request another frame
	DecompressSequenceFrameS([videoCapture _decodeSeq], p, len, 0, &ignore, NULL);

	return noErr;
}

