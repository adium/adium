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
@property (nonatomic, readonly) NSArray *voices;
- (void)speakDemoTextForVoice:(NSString *)voiceString withPitch:(CGFloat)pitch andRate:(CGFloat)rate;
@property (nonatomic, readonly) CGFloat defaultRate;
@property (nonatomic, readonly) CGFloat defaultPitch;
- (void)speakText:(NSString *)text;
- (void)speakText:(NSString *)text withVoice:(NSString *)voiceString pitch:(CGFloat)pitch rate:(CGFloat)rate;

//Soundsets
@property (nonatomic, readonly) NSArray *soundSets;

- (void)setSoundsAreMuted:(BOOL)muted;
@end
