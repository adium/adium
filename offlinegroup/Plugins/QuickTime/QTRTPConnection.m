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

#import <QuickTime/QuickTime.h>

#import "AIVideoConf.h"
#import "QTConnection.h"
#import "QTRTPConnection.h"


@implementation QTRTPConnection

////////////////////////////////////////////////////////////////////////////////
#pragma mark                Constructors / Initialization
////////////////////////////////////////////////////////////////////////////////

+ (id) createWithProtocol:(VCProtocol)proto payload:(VCPayload*)pt from:(VCTransport*)local to:(VCTransport*)remote;
{
	return [[[self alloc] initWithProtocol:proto payload:pt from:local to:remote] autorelease];
}

- (id) initWithProtocol:(VCProtocol)proto payload:(VCPayload*)pt from:(VCTransport*)local to:(VCTransport*)remote;
{
	NSAssert(proto == VC_RTP, @"QTRTPConnection initilized with a protocol different from RTP.");
	
	self = [super init];
	
	if (self)
	{
		mPayload = pt;
		mProtocol = proto;
		mLocal = local;
		mRemote = remote;
	}
	
	return self;	
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark                    SDP Generation
////////////////////////////////////////////////////////////////////////////////
- (NSString*) generateSDPInStream
{
	// TODO
	return nil;
}


- (NSString*) generateSDPOutStream
{

	// Constants
	const char	*strSessionName = "outrtpstream";
	const char	*strDescription = "Audio output RTP stream";
	const char	*strUrl			= "http://www.adiumx.com";
	const char	*strEmail		= "none@adiumx.com";
	
	const int	 ipVersion		= 4;	// We only support IP version 4
	const int	 ttl			= 126;

	// Variables
	const char	*ipDestination	= [[mRemote valueForKey:@"mIP"] cString];
	const char	*ipSource		= [[mLocal valueForKey:@"mIP"] cString];
	int			 port			= (int)[mLocal valueForKey:@"mPort"];
	int			 payloadType	= (int)[((VCPayload*)[mLocal valueForKey:@"mPayload"]) valueForKey:@"mId"];
	
	char		*outStr;
	
	asprintf (&outStr,
			  "v=0\r\n"
			  "o=- * * IN IP%d %s\r\n"		// Source
			  "s=%s\r\n"					// Session name
			  "i=%s\r\n"					// Description
			  "u=%s\r\n"					// URL
			  "e=%s\r\n"					// Email
			  "t=0 0\r\n"					// Duration
			  "a=tool:Adium\r\n"			// Other
			  "c=IN IP%d %s/%d\r\n"			// Destination
			  "m=audio %d RTP/AVP %d\r\n",	// Content description
			  
			  ipVersion, ipSource,
			  strSessionName,
			  strDescription,
			  strUrl,
			  strEmail,
			  ipVersion, ipDestination, ttl,
			  port, payloadType);
	
	return [NSString stringWithCString:outStr];
}

@end


@implementation QTAudioRTPConnection


////////////////////////////////////////////////////////////////////////////////
#pragma mark                   Streams Handlers
////////////////////////////////////////////////////////////////////////////////

/*!
 * Broadcast notification handler.
 */
ComponentResult outAudioRTPStreamNotifHandler (ComponentResult inErr,
											   OSType inNotificationType,
											   void *inNotificationParams,
											   void *inRefCon) {
	QTSStatusParams* tempStatus;

	switch (inNotificationType) {
		case kQTSNewPresentationNotification:
			break;
			
		case kQTSPrerollAckNotification:
			QTSPresStart ((QTSPresentation)inRefCon, kQTSAllStreams, 0L );
			break;
			
		case kQTSStreamChangedNotification:
			break;
			
		case kQTSErrorNotification:
//			ShowErr (macWindow, inErr, ”kQTSErrorNotification”);
			break;
			
		case kQTSNewPresDetectedNotification:
		case kQTSNewStreamNotification:
		case kQTSStreamGoneNotification:
		case kQTSStartAckNotification:
		case kQTSStopAckNotification:
			break;
			
		case kQTSStatusNotification:
			tempStatus = (QTSStatusParams *)inNotificationParams;
			break;
		default:
			break;
	}
	
	return noErr;	
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark                   Streams Management
////////////////////////////////////////////////////////////////////////////////

/*!
 * Create the output stream.
 * This method creates and starts the output stream for broadcasting audio withb RTP.
 */
- (OSErr) startOutAudioRTPStream
{	
	QTSPresParams		 presParams;
	QTSMediaParams		 mediaParams;
	QTSNotificationUPP	 sNotificationUPP;
	NSString			*outStream = [self generateSDPOutStream];
	const char			*sdpDataPtr			= [outStream cString];
	SInt64				 sdpDataLength		= (SInt64)[outStream length];
	OSErr				 err				= noErr;
	
	// Note: this API is almost undocumented. There is only one example,
	// called "qtbroadcast"... [as]
	
	mOutputStream = kQTSInvalidPresentation;
	
	// Initialize the media params
	memset (&presParams, 0, sizeof(presParams));	
	err = QTSInitializeMediaParams (&mediaParams);
	if (err != noErr) {
		goto bail;		
	}
	
	// Video params: we don't have any video
	//
	// mediaParams.v.width = (Fixed)(myWidth<<16);
	// mediaParams.v.height = (Fixed)(myHeight<<16);
	//
	// set the window that Sequence Grabber will draw into:
	//
	// mediaParams.v.gWorld =  GetDialogPort(gMonitor);
	// mediaParams.v.gdHandle = myGD;

	// Audio params: simple volume params
	mediaParams.a.leftVolume = kFullVolume;
	mediaParams.a.rightVolume = kFullVolume;
	
	// Other parameters that can be set:
	//
	// mediaParams.a.bassLevel;
	// mediaParams.a.trebleLevel;
	// mediaParams.a.frequencyBandsCount;
	// mediaParams.a.frequencyBands;
	// mediaParams.a.levelMeteringEnabled;
	
	sNotificationUPP =
		(QTSNotificationUPP) NewQTSNotificationUPP (outAudioRTPStreamNotifHandler);
	
	presParams.version				= kQTSPresParamsVersion1;
	
	// Set the presentation flags: use Sequence Grabber, don't display blue Q movie, and send data
	presParams.flags				= kQTSAutoModeFlag
									| kQTSDontShowStatusFlag
									| kQTSSendMediaFlag;
	presParams.timeScale			= 0; // kDefaultPresTimeScale;
	presParams.mediaParams			= &mediaParams;
	
	// Fill these in to get status notifications
	presParams.notificationProc		= sNotificationUPP;
	presParams.notificationRefCon	= 0L;	// no refcon yet
	
	// Create the presentation
	err = QTSNewPresentationFromData (kQTSSDPDataType,
									  sdpDataPtr,
									  &sdpDataLength,
									  &presParams,
									  &mOutputStream);
	if (err != noErr) {
		goto bail;		
	}
	
	// If you want to see what the Sequence Grabber is capturing, call
	// QTSPresPreview before starting the broadcast. As we are only capturing audio,
	// skip this step...
	//
	// err = QTSPresPreview (presentation, kQTSAllStreams, nil, kFixed1, 0);

bail:
	return err;
}

/*!
 * Destroy the output stream
 */
- (OSErr) stopOutAudioRTPStream
{
	OSErr err = noErr;
	
	if (mOutputStream != kQTSInvalidPresentation) {
		err = QTSPresStop(mOutputStream, kQTSAllStreams, 0L);
		
		if (err != noErr) {
			err = QTSDisposePresentation(mOutputStream, 0L);			
		}
		
		mOutputStream = kQTSInvalidPresentation;
	}
	
	return(err);	
}


/*!
 * Start the input audio RTP stream
 */
- (OSErr) startInAudioRTPStream
{
    OSErr					 err			= noErr;
	Movie					 sdpMovieInfo	= NULL;
	Handle					 dataRef		= NULL;
	ComponentInstance		 dataRefHandler	= NULL;
    OSType					 dataRefType;
    void					*sdpData		= NULL;
	Size					 sdpDataLen		= 0;
	PointerDataRefRecord	 ptrDataRefRec;
    unsigned char			 myChar			= 0;
    Handle					 fileNameHndl	= NULL;
	Str255					 fileName		= "instream.sdp";

	// TODO: Fille the sdpData and sdpDataLen
	
	ptrDataRefRec.data			= sdpData;
	ptrDataRefRec.dataLength	= sdpDataLen;
	
	// create a data reference handle for our data
	err = PtrToHand( &ptrDataRefRec, &dataRef, sizeof(PointerDataRefRecord));
	if (err != noErr) {
		goto bail;	
	}
	
	//  Get a data handler for our data reference
    err = OpenADataHandler (dataRef,                    /* data reference */
							PointerDataHandlerSubType,  /* data ref. type */
							NULL,                       /* anchor data ref. */
							(OSType)0,                  /* anchor data ref. type */
							NULL,                       /* time base for data handler */
							kDataHCanRead,              /* flag for data handler usage */
							&dataRefHandler);           /* returns the data handler */
	if (err != noErr) {
		goto bail;	
	}

    // create a handle with our file name string

    // if we were passed a null string, then we need to add this null
	// string (a single 0 byte) to the handle
    if (fileName == NULL) {
        err = PtrToHand (&myChar, &fileNameHndl, sizeof(myChar));		
	} else {
        err = PtrToHand (fileName, &fileNameHndl, fileName[0] + 1);		
	}
    if (err != noErr) {
		goto bail;	
	}	

    // set the data ref extension for the data ref handler
    err = DataHSetDataRefExtension (dataRefHandler,         /* data ref. handler */
									fileNameHndl,           /* data ref. extension to add */
									kDataRefExtensionFileName);
	
	// dispose old data ref handle because it does not contain our new changes
	DisposeHandle(dataRef);
	dataRef = NULL;

	// re-acquire data reference from the data handler to get the new changes
	err = DataHGetDataRef(dataRefHandler, &dataRef);
	if (err != noErr) {
		goto bail;	
	}	

	// This is the preferred system for QuickTime 6. QuickTime 7 includes
	// the new function NewMovieFromProperties, but we prefer to keep the
	// compatibility [as].
	err = NewMovieFromDataRef (&sdpMovieInfo,
							   newMovieActive, 
							   nil,
							   dataRef,
							   dataRefType); 		

bail:
	mInputStream = sdpMovieInfo;

	return err;
}

/*!
 * Destroy the output audio RTP stream
 */
- (OSErr) stopInAudioRTPStream
{
	// TODO
	return noErr;
}	

////////////////////////////////////////////////////////////////////////////////
#pragma mark                     Connection Protocol
////////////////////////////////////////////////////////////////////////////////
- (BOOL) start 
{
	[self startInAudioRTPStream];
	[self startOutAudioRTPStream];
	return TRUE;
}

- (BOOL) stop
{
	[self stopInAudioRTPStream];
	[self stopOutAudioRTPStream];
	return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark              Connection Properties: Volume, etc.
////////////////////////////////////////////////////////////////////////////////

/*!
 * Output Volume control.
 */
- (void) setOutVolumeTo:(int)vol 
{
	// TODO
}

/*!
 * Input Volume control.
 */
- (void) setMicVolumeTo:(int)vol
{
	// TODO
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark                  QuickTime General Information
////////////////////////////////////////////////////////////////////////////////
+ (NSArray*) getSupportedAudioPayloads
{
	// List of audio payload types supported by default by QuickTime for audio.
	// It can be obtained from QTStreamingComponents.h
	//
	// NOTE: There should be some function that gives the list by quering the
	//       codecs installed on the system...
	//
	NSArray* res = [NSArray arrayWithObjects:
		/* 8kHz PCM mu-law mono */
		[VCAudioPayload createWithId:kRTPPayload_PCMU name:@"PCMU" channels:1 clockrate:8000],
		/* 8kHz CELP (Fed Std 1016) mono */
		[VCAudioPayload createWithId:kRTPPayload_1016 name:@"1016" channels:1 clockrate:8000],
		/* 8kHz G.721 ADPCM mono */
		[VCAudioPayload createWithId:kRTPPayload_G721 name:@"G721" channels:1 clockrate:8000],
		/* 8kHz GSM mono */
		[VCAudioPayload createWithId:kRTPPayload_GSM name:@"GSM" channels:1 clockrate:8000],
		/* 8kHz G.723 ADPCM mono */
		[VCAudioPayload createWithId:kRTPPayload_G723 name:@"G723" channels:1 clockrate:8000],
		/* 8kHz Intel DVI ADPCM mono */
		[VCAudioPayload createWithId:kRTPPayload_DVI_8 name:@"DVI 8" channels:1 clockrate:8000],
		/* 16kHz Intel DVI ADPCM mono */
		[VCAudioPayload createWithId:kRTPPayload_DVI_16 name:@"DVI 16" channels:1 clockrate:16000],
		/* 8kHz LPC */
		[VCAudioPayload createWithId:kRTPPayload_LPC name:@"LPC" channels:1 clockrate:8000],
		/* 8kHz PCM a-law mono */
		[VCAudioPayload createWithId:kRTPPayload_PCMA name:@"PCMA" channels:1 clockrate:8000],
		/* 44.1kHz 16-bit linear stereo */
		[VCAudioPayload createWithId:kRTPPayload_L16_44_2 name:@"L16 44 2" channels:2 clockrate:44100],
		/* 44.1kHz 16-bit linear mono */
		[VCAudioPayload createWithId:kRTPPayload_L16_44_1 name:@"L16 44 1" channels:1 clockrate:44100],		
		/* 8kHz PureVoice mono (QCELP) */
		[VCAudioPayload createWithId:kRTPPayload_PureVoice name:@"PureVoice" channels:1 clockrate:8000],		
		/* MPEG I and II audio */
		[VCAudioPayload createWithId:kRTPPayload_MPEGAUDIO name:@"MPEGAUDIO" channels:1 clockrate:90000],		
		/* 11kHz Intel DVI ADPCM mono */
		[VCAudioPayload createWithId:kRTPPayload_DVI_11 name:@"DVI 11" channels:1 clockrate:11025],		
		/* 22kHz Intel DVI ADPCM mono */
		[VCAudioPayload createWithId:kRTPPayload_DVI_22 name:@"DVI 22" channels:1 clockrate:22050],
		
		nil];
	
	return res;
}

@end
