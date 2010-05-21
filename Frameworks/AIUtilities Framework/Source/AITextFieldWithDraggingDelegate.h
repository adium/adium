//
//  AITextFieldWithDraggingDelegate.h
//  AIUtilities.framework
//
//  Created by David Clark on 2/4/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

//@class AITextFieldWithDraggingDelegate;

@interface AITextFieldWithDraggingDelegate : NSTextField {
	id				dragDelegate;		// the delegate for dragging purposes
	
	NSDragOperation	lastEnteredOp;		// Last operation we returned from dragEntered
}

- (void)setDragDelegate:(id)drag;

@end
