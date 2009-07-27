/*
 *  AISoundControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

#define PREF_GROUP_SOUNDS					@"Sounds"
#define KEY_SOUND_CUSTOM_VOLUME_LEVEL		@"Custom Volume Level"

@protocol AISoundController <AIController>
//Sound
- (void)playSoundAtPath:(NSString *)inPath;
- (void)stopPlayingSoundAtPath:(NSString *)inPath;

//Speech
- (void)speakDemoTextForVoice:(NSString *)voiceString withPitch:(float)pitch andRate:(float)rate;
@property (nonatomic, readonly) float defaultRate;
@property (nonatomic, readonly) float defaultPitch;
- (void)speakText:(NSString *)text;
- (void)speakText:(NSString *)text withVoice:(NSString *)voiceString pitch:(float)pitch rate:(float)rate;

//Soundsets
@property (nonatomic, readonly) NSArray *soundSets;

- (void)setSoundsAreMuted:(BOOL)muted;
@end
