/*
 *  AIEmoticonControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

#define PREF_GROUP_EMOTICONS				@"Emoticons"
#define KEY_EMOTICON_ACTIVE_PACKS			@"Active Emoticon Packs"
#define KEY_EMOTICON_DISABLED				@"Disabled Emoticons"
#define KEY_EMOTICON_PACK_ORDERING			@"Emoticon Pack Ordering"
#define KEY_EMOTICON_SERVICE_APPROPRIATE	@"Service Appropriate Emoticons"

@class AIEmoticonPack, AIEmoticon;

@protocol AIEmoticonController <AIController>
- (NSArray *)availableEmoticonPacks;
- (AIEmoticonPack *)emoticonPackWithName:(NSString *)inName;
- (NSArray *)activeEmoticons;
- (NSArray *)activeEmoticonPacks;
- (void)moveEmoticonPacks:(NSArray *)inPacks toIndex:(NSUInteger)index;
- (void)setEmoticonPack:(AIEmoticonPack *)inPack enabled:(BOOL)enabled;
- (void)setEmoticon:(AIEmoticon *)inEmoticon inPack:(AIEmoticonPack *)inPack enabled:(BOOL)enabled;
- (void)flushEmoticonImageCache;
- (void)xtrasChanged:(NSNotification *)notification;
@end
