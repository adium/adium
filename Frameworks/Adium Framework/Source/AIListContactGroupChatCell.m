
#import "AIListContactGroupChatCell.h"
#import <Adium/AIChat.h>

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

- (NSColor *)textColor
{
	if (([chat flagsForContact:listObject] & AIGroupChatFounder) == AIGroupChatFounder) {
		return [NSColor redColor];
	}
		
	if (([chat flagsForContact:listObject] & AIGroupChatOp) == AIGroupChatOp) {
		return [NSColor purpleColor];
	}
	
	if (([chat flagsForContact:listObject] & AIGroupChatHalfOp) == AIGroupChatHalfOp) {
		return [NSColor blueColor];
	}
	
	if (([chat flagsForContact:listObject] & AIGroupChatVoice) == AIGroupChatVoice) {
		return [NSColor brownColor];
	}
	
	return [NSColor blackColor];
}

@end
