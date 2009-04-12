//
//  AIJumpControlPlugin.h
//  Adium
//
//  Created by Zachary West on 2009-04-04.
//

#import <Adium/AIPlugin.h>

@interface AIJumpControlPlugin : NSObject {
	NSMenuItem		*menuItem_previous;
	NSMenuItem		*menuItem_next;
	NSMenuItem		*menuItem_focus;
	NSMenuItem		*menuItem_add;
	
	NSMenuItem		*menuItem_focusLine;
}

@end
