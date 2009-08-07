//
//  AIContactListImagePicker.h
//  Adium
//
//  Created by Evan Schoenberg on 12/16/05.
//  Copyright 2006 the Adium Team. All rights reserved.
//

#import <AIUtilities/AIImageViewWithImagePicker.h>

@class AIAccount;

@interface AIContactListImagePicker : AIImageViewWithImagePicker {
	BOOL				hovered;
	NSTrackingRectTag	trackingTag;
	
	NSMenu				*imageMenu;
}

@end
