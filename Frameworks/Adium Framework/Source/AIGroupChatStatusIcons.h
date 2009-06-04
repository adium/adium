//
//  AIGroupChatStatusIcons.h
//  Adium
//
//  Created by Zachary West on 2009-03-31.
//

#define PREF_GROUP_APPEARANCE				@"Appearance"
#define	KEY_GROUP_CHAT_STATUS_ICONS			@"Group Chat Status Icons"
#define EXTENSION_GROUP_CHAT_STATUS_ICONS	@"AdiumGroupChatStatusIcons"
#define	RESOURCE_GROUP_CHAT_STATUS_ICONS	@"Group Chat Status Icons"

#define KEY_COLORS_DICT	@"Colors"
#define KEY_ICONS_DICT	@"Icons"

#define FOUNDER		@"Founder"
#define OP			@"Op"
#define HOP			@"Half-op"
#define VOICE		@"Voice"
#define NONE		@"None"

#import <Adium/AIListObject.h>
#import <Adium/AIXtraInfo.h>

@interface AIGroupChatStatusIcons : AIXtraInfo {
	NSMutableDictionary		*icons;
	NSMutableDictionary		*colors;
	NSDictionary			*iconInfo;
	NSDictionary			*colorInfo;
}

+ (AIGroupChatStatusIcons *)sharedIcons;
- (NSImage *)imageForFlag:(AIGroupChatFlags)flag;
- (NSColor *)colorForFlag:(AIGroupChatFlags)flags;

@end
