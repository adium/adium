
#import "AIListContactGroupChatCell.h"
#import <Adium/AIChat.h>
#import <Adium/AIGroupChatStatusIcons.h>
#import <Adium/AIStatusIcons.h>

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

- (NSImage *)serviceImage
{
	// We can't use [listObject statusIcon] because it will show unknown for strangers.
	return [AIStatusIcons statusIconForListObject:listObject
											 type:AIStatusIconList
										direction:AIIconFlipped];
}

- (NSColor *)textColor
{
	return [[AIGroupChatStatusIcons sharedIcons] colorForFlag:[chat flagsForContact:listObject]];
}

- (float)imageOpacityForDrawing
{
	return 1.0;
}

@end
