//
//  AIChatController.h
//  Adium
//
//  Created by Evan Schoenberg on 6/10/05.
//

#import <Adium/AIChatControllerProtocol.h>

@class AIChat, AdiumChatEvents;

@interface AIChatController : NSObject <AIChatController> {
@private
    NSMutableSet			*openChats;
	NSMutableArray			*chatObserverArray;
	
    AIChat					*mostRecentChat;	
	
	NSMenuItem				*menuItem_ignore;
	NSMenuItem				*menuItem_joinLeave;
	
	AdiumChatEvents			*adiumChatEvents;
}

@end
