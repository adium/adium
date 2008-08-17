//
//  AIFacebookOutgoingMessageManager.h
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//


@class AIContentMessage, AIContentTyping;

@interface AIFacebookOutgoingMessageManager : NSObject {

}

+ (void)sendMessageObject:(AIContentMessage *)inContentMessage;
+ (void)sendTypingObject:(AIContentTyping *)inContentTyping;

@end
