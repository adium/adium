
#import "AIListContactGroupChatCell.h"
#import <Adium/AIChat.h>
#import <Adium/AIGroupChatStatusIcons.h>

@implementation AIListContactGroupChatCell

@synthesize chat;
- (void)dealloc
{
	[chat release];
	[super dealloc];
}

- (NSString *)labelString
{
	NSString *label;
	
	if (chat && [chat displayNameForContact:listObject]) {
		label = [chat displayNameForContact:listObject];
	} else {
		label = [super labelString];
	}
	
	return label;
}

- (NSImage *)statusImage
{
	return [[AIGroupChatStatusIcons sharedIcons] imageForFlag:[chat flagsForContact:listObject]];
}

- (NSColor *)textColor
{
	return [[AIGroupChatStatusIcons sharedIcons] colorForFlag:[chat flagsForContact:listObject]];
}

@end
