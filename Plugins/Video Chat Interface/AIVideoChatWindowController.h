//
//  AIVideoChatWindowController.h
//  Adium
//
//  Created by Adam Iser on 12/4/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIWindowController.h>

@class AIVideoCapture;

@interface AIVideoChatWindowController : AIWindowController <AIVideoChatObserver> {
	IBOutlet	NSImageView		*videoImageView;
	AIVideoChat					*videoChat;
}

@end
