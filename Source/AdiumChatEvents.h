//
//  AdiumChatEvents.h
//  Adium
//
//  Created by Evan Schoenberg on 9/10/05.
//

#import <Adium/AIContactAlertsControllerProtocol.h>

@class AIChat, AIListContact;

@interface AdiumChatEvents : NSObject <AIEventHandler> {

}

- (void)controllerDidLoad;
- (void)chat:(AIChat *)chat addedListContact:(AIListContact *)inContact;
- (void)chat:(AIChat *)chat removedListContact:(AIListContact *)inContact;

@end
