//
//  SUSpeaker.m
//
//  Created by raf on Sun Jan 28 2001.
//  Based on SpeechUtilities framework by Raphael Sebbe.
//  Optimized and expanded by Evan Schoenberg.

#import <Adium/SUSpeaker.h>
#include <unistd.h>
#include <pthread.h>

void MySpeechDoneCallback(SpeechChannel chan,SInt32 refCon);
void MySpeechWordCallback (SpeechChannel chan, SInt32 refCon, UInt32 wordPos, 
    UInt16 wordLen);

@interface SUSpeaker (Private)
-(void)createNewSpeechChannelForVoice:(VoiceSpec *)voice;
-(NSPort*) port;
-(void)setReserved1:(unsigned int)r;
-(void)setReserved2:(unsigned int)r;
-(BOOL) usesPort;
-(void)handleMessage:(unsigned)msgid;
@end

@implementation SUSpeaker

-init
{
	if ((self = [super init])) {
		// we have 2 options here : we use a port or we don't.
		// using a port means delegate message are invoked from the main 
		// thread (runloop in which this object is created), otherwise, those message 
		// are asynchronous.
		NSRunLoop *loop = [NSRunLoop currentRunLoop];
		if (loop != nil) {
			_port = [[NSPort port] retain];
			// we use a port so that the speech manager callbacks can talk to the main thread.
			// That way, we can safely access interface elements from the delegate methods
			
			[_port setDelegate:self];
			[loop addPort:_port forMode:NSDefaultRunLoopMode];
			_usePort = YES;
		} else {
			_usePort = NO;
		}

		_speechChannel = NULL;
		
		// NULL voice is default voice
		[self createNewSpeechChannelForVoice:NULL];
	}

	return self;
}

-(void)dealloc
{
    [_port release];
    if (_speechChannel != NULL) {
		[self stopSpeaking];
        DisposeSpeechChannel(_speechChannel);
    }

    [super dealloc];
}

-(void)resetToDefaults
{
    if (_speechChannel != NULL) {
        StopSpeech(_speechChannel);
        SetSpeechInfo(_speechChannel, soReset, NULL);
    }
}

//---Pitch
/* "Sets the pitch. Pitch is given in Hertz and should be comprised between 80 and 500, depending on the voice.
Note that extreme value can make your app crash..."  */
-(void)setPitch:(float)pitch
{
    pitch = (pitch-90.0)/(300.0-90.0)*(65.0 - 30.0) + 30.0;  //conversion from hertz
    /* I don't know what Apple means with pitch between 30 and 65, so I convert that range to [90, 300].
		I did not test frequencies correspond, though. */

	if (_speechChannel) SetSpeechPitch (_speechChannel, FloatToFixed(pitch));
}
-(float)pitch
{
	Fixed fixedPitch = 0;
	if (_speechChannel) GetSpeechInfo(_speechChannel, soPitchBase, &fixedPitch);

	//perform needed conversion to reasonable numbers
	return (FixedToFloat(fixedPitch) - 30.0)*(210.0/35.0) + 90.0;
}

//---Rate
//normal is 150 to 220
-(void)setRate:(float)rate
{
	if (_speechChannel) SetSpeechRate(_speechChannel, FloatToFixed(rate));
}
-(float)rate
{
	Fixed fixedRate = 0;
	if (_speechChannel) GetSpeechInfo(_speechChannel, soRate, &fixedRate);

	return FixedToFloat(fixedRate);
}

//---Volume
-(void)setVolume:(float)vol
{
	Fixed	fixedVolume = FloatToFixed(vol);
    if(_speechChannel != NULL)
        SetSpeechInfo(_speechChannel, soVolume, &fixedVolume);
}

//---Voice
//set index=-1 for default voice
-(void)setVoiceUsingIndex:(int)index
{
	VoiceSpec voice;
	OSErr error = noErr;

	if (index >= 0) {
		error = GetIndVoice(index+1, &voice);
		if (error == noErr) {
			if (_speechChannel) {
				if ([self isSpeaking]) {
					[self stopSpeaking];
				}

				error = SetSpeechInfo(_speechChannel, soCurrentVoice, &voice);
				/* If SetSpeechInfo() returns incompatibleVoice, we need to use a new speech channel, as the
				 * synthesizer must have changed
				 */
				if (error == incompatibleVoice) {
					[self createNewSpeechChannelForVoice:&voice];
				}

			} else {
				[self createNewSpeechChannelForVoice:&voice];
			}
		}
	}
}

/*"Returns the voice names in the same order as expected by setVoice:."*/
+(NSArray*)voiceNames
{
	NSMutableArray *voices = nil;
	short voiceCount;
	OSErr error = noErr;
	int voiceIndex;

	error = CountVoices(&voiceCount);
	if (error != noErr) return voices;

	voices = [NSMutableArray arrayWithCapacity:voiceCount];
	for (voiceIndex=0; voiceIndex<voiceCount; voiceIndex++) {
		VoiceSpec	voiceSpec;
		VoiceDescription voiceDescription;

		error = GetIndVoice(voiceIndex+1, &voiceSpec);
		if (error != noErr) return voices;
		error = GetVoiceDescription( &voiceSpec, &voiceDescription, sizeof(voiceDescription));
		if (error == noErr) {
			NSString *voiceName = [[NSString alloc] initWithBytes:(const char *)&(voiceDescription.name[1]) length:voiceDescription.name[0] encoding:NSMacOSRomanStringEncoding];
			[voices addObject:voiceName];
			[voiceName release];
		} else {
			return voices;
		}
	}
	return voices;
}
/*
+(NSString*)defaultVoiceName
{
    VoiceSpec	voiceSpec;
    VoiceDescription voiceDescription;
    
    GetIndVoice(0, &voiceSpec);
    GetVoiceDescription( &voiceSpec, &voiceDescription, sizeof(voiceDescription));
    return [[[NSString alloc] initWithBytes:(const char *)&(voiceDescription.name[1]) length:voiceDescription.name[0] encoding:NSMacOSRomanStringEncoding] autorelease];
}*/


//setVolume: SetSpeechInfo(_speechChannel, soCurrentVoice, ????);

//---Speech
-(void)speakText:(NSString*)text
{
    if (_speechChannel && text) {
		if ([self isSpeaking]) {
			[self stopSpeaking];
		}

		NSData *data = [text dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:YES];
		SpeakText(_speechChannel, [data bytes], [data length]);
    }
}
-(void)stopSpeaking
{
    if (_speechChannel) {
        StopSpeech(_speechChannel);
        if ([_delegate respondsToSelector:@selector(didFinishSpeaking:)]) {
            [_delegate didFinishSpeaking:self];
        }
    }
}
-(BOOL)isSpeaking {
	if (!_speechChannel) return NO;

	struct SpeechStatusInfo status;
	OSStatus err = GetSpeechInfo(_speechChannel, soStatus, &status);
	if (err != noErr) {
		NSLog(@"in -isSpeaking, GetSpeechInfo returned %li", (long)err);
		return NO;
	} else {
		return status.outputBusy;
	}
}

-(NSString *)demoTextForVoiceAtIndex:(int)voiceIndex
{
	NSString *demoText = nil;
	OSErr error = noErr;
	
	VoiceSpec	voiceSpec;
	VoiceDescription voiceDescription;
	
	if (voiceIndex >= 0) {
		error = GetIndVoice(voiceIndex+1, &voiceSpec);
		if (error == noErr) {
			error = GetVoiceDescription( &voiceSpec, &voiceDescription, sizeof(voiceDescription));
		}
	} else {
		error = GetVoiceDescription( NULL, &voiceDescription, sizeof(voiceDescription));		
	}

	
	if (error == noErr) {
		demoText = [[[NSString alloc] initWithBytes:(const char *)&(voiceDescription.comment[1]) 
											 length:voiceDescription.comment[0]
										   encoding:NSMacOSRomanStringEncoding] autorelease];
	}
	
	return demoText;
}

//---Delegate
-(void)setDelegate:(id)delegate
{
    _delegate = delegate;
}
-(id) delegate
{
    return _delegate;
}


//--- Private ---
-(void)createNewSpeechChannelForVoice:(VoiceSpec *)voice
{
	OSErr error;

	if (_speechChannel) {
		if ([self isSpeaking]) {
			[self stopSpeaking];
		}
		DisposeSpeechChannel(_speechChannel);
		_speechChannel = NULL;
	}

	error = NewSpeechChannel(voice, &_speechChannel);

	if (error == noErr) {
		SetSpeechInfo(_speechChannel, soSpeechDoneCallBack, &MySpeechDoneCallback);
		SetSpeechInfo(_speechChannel, soWordCallBack, &MySpeechWordCallback);
		SetSpeechInfo(_speechChannel, soRefCon, (const void*)self);
	}
}

-(void)setReserved1:(unsigned int)r
{
    _reserved1 = r;
}
-(void)setReserved2:(unsigned int)r
{
    _reserved2 = r;
}
-(NSPort*) port
{
    return _port;
}
-(BOOL) usesPort
{
    return _usePort;
}
-(void)handleMessage:(unsigned)msgid
{
    if (msgid == 5) {
        if ([_delegate respondsToSelector:@selector(willSpeakWord:at:length:)]) {
            if (_reserved1 >= 0 && _reserved2 >= 0)
                [_delegate willSpeakWord:self at:_reserved1 length:_reserved2];
            else
                [_delegate willSpeakWord:self at:0 length:0];
        }
    } else if (msgid == 8) {
		//Notify our delegate that we finished
        if ([_delegate respondsToSelector:@selector(didFinishSpeaking:)]) {
            [_delegate didFinishSpeaking:self];
        }
    }
}
//--- NSPort delegate ---
- (void)handlePortMessage:(NSPortMessage *)portMessage
{
    int msg = [portMessage msgid];
    
    [self handleMessage:msg];
}

@end

void MySpeechDoneCallback(SpeechChannel chan,SInt32 refCon)
{
    SUSpeaker *speaker = (SUSpeaker*)refCon;
    unsigned msg = 8;
    
    if ([speaker isKindOfClass:[SUSpeaker class]]) {
        if ([speaker usesPort]) {
            NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort:[speaker port]
                receivePort:[speaker port] components:nil];
        
            [message setMsgid:msg];
            [message sendBeforeDate:nil];
            [message release];
        } else {
            // short-circuit port
            [speaker handleMessage:msg];
        }
    } 
}
void MySpeechWordCallback(SpeechChannel chan, SInt32 refCon, UInt32 wordPos,UInt16 wordLen)
{
    SUSpeaker *speaker = (SUSpeaker*)refCon;
    unsigned msg = 5;

    if ([speaker isKindOfClass:[SUSpeaker class]]) {
        [speaker setReserved1:wordPos];
        [speaker setReserved2:wordLen];
        
        if ([speaker usesPort]) {
            NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort:[speaker port]
                receivePort:[speaker port] components:nil];
        
            [message setMsgid:msg];
            [message sendBeforeDate:nil];
            [message release];
        } else {
            // short-circuit port
            [speaker handleMessage:msg];
        }
    } 
}
