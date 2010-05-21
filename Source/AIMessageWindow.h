//
//  AIMessageWindow.h
//  Adium
//
//  Created by Evan Schoenberg on 12/26/05.
//

#import <AIUtilities/AIDockingWindow.h>

@interface AIMessageWindow : AIDockingWindow {
	NSArray *chats;
	id rememberedScriptCommand;
}

@end
