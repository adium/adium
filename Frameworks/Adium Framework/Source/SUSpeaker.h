//
//  SUSpeaker.h
//
//  Created by raf on Sun Jan 28 2001.
//  Based on SpeechUtilities framework by Raphael Sebbe.
//  Revised by Evan Schoenberg on Tue Sep 30 2003.
//  Optimized and expanded by Evan Schoenberg.

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

/*!
 * @class SUSpeaker
 * @brief Cocoa wrapper for the Carbon Speech Synthesis Manager
 */
@interface SUSpeaker : NSObject 
{
    SpeechChannel _speechChannel;
    id _delegate;
    NSPort *_port;

    BOOL _usePort;
    unsigned int _reserved1;
    unsigned int _reserved2;
}

+ (NSArray *)voiceNames;
//+(NSString*) defaultVoiceName;

//pitch is in Hertz.
- (void) setPitch:(float)pitch;
- (float) pitch;
//rate is in words per minute.
- (void) setRate:(float)rate;
- (float) rate;

-(void)setVolume:(float)vol;

//voice is an index into +voiceNames. pass -1 for the default voice.
- (void) setVoiceUsingIndex:(int)index;

- (void) speakText:(NSString*)text;
- (void) stopSpeaking;
- (BOOL) isSpeaking;

- (void) resetToDefaults;

//e.g., for Bad News: 'The light you see at the end of the tunnel is the headlamp of a fast approaching train.' (remember that Bad News is a singing voice...)
- (NSString *)demoTextForVoiceAtIndex:(int)voiceIndex;

-(void) setDelegate:(id)delegate;
-(id) delegate;

@end

@interface NSObject (SUSpeakerDelegate)
-(void) didFinishSpeaking:(SUSpeaker*)speaker;
-(void) willSpeakWord:(SUSpeaker*)speaker at:(int)where length:(int)length;
@end
