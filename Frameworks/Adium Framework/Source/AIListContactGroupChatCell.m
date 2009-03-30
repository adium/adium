
#import "AIListContactGroupChatCell.h"
#import <Adium/AIChat.h>

@interface AIListContactGroupChatCell()
- (NSString *)stringForFlags:(AIGroupChatFlags)flags;
@end

@implementation AIListContactGroupChatCell

@synthesize chat;
- (void)dealloc
{
	[chat release];
	[super dealloc];
}

/*! 
 * @brief A string value for the given flags. 
 * 
 * @param flags The AIGroupChatFlags to evaluate; only the highest is returned. 
 * 
 * @returns . for founder, @ for ops, % for halfop, + for voice. 
 */ 
- (NSString *)stringForFlags:(AIGroupChatFlags)flags 
{ 
	if ((flags & AIGroupChatFounder) == AIGroupChatFounder) { 
		return @"."; 
	} else if ((flags & AIGroupChatOp) == AIGroupChatOp) { 
		return @"@"; 
	} else if ((flags & AIGroupChatHalfOp) == AIGroupChatHalfOp) { 
		return @"%"; 
	} else if ((flags & AIGroupChatVoice) == AIGroupChatVoice) { 
		return @"+"; 
	} 
	
	return @""; 
}

- (NSString *)labelString
{
	NSString *label;
	
	if (chat && [chat displayNameForContact:listObject]) {
		label = [NSString stringWithFormat:@"%@%@", [self stringForFlags:[chat flagsForContact:listObject]], [chat displayNameForContact:listObject]];
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
		return [NSColor blueColor];
	}
	
	if (([chat flagsForContact:listObject] & AIGroupChatHalfOp) == AIGroupChatHalfOp) {
		return [NSColor magentaColor];
	}
	
	if (([chat flagsForContact:listObject] & AIGroupChatVoice) == AIGroupChatVoice) {
		return [NSColor purpleColor];
	}
	
	return [NSColor blackColor];
}

@end
