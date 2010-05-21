#import <Adium/AIListContactCell.h>

@class AIChat;

@interface AIListContactGroupChatCell : AIListContactCell {
	AIChat	*chat;
}

@property (readwrite, retain, nonatomic) AIChat *chat;

@end
