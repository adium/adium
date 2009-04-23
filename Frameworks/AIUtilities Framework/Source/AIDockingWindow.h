//
//  AIDockingWindow.h
//  Adium
//
//  Created by Adam Iser on Sun May 02 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

/*!
 * @class AIDockingWindow
 * @brief An NSWindow subclass which docks to screen edges
 *
 * An NSWindow subclass which docks to screen edges. It also posts AIWindowToolbarDidToggleVisibility to the default notification center
 * when its toolbar visibility is toggled with an object of the window.
 *
 * Docking is temporarily disabled if the shift key is held.
 */

#define AIWindowToolbarDidToggleVisibility @"AIWindowToolbarDidToggleVisibility"

@interface AIDockingWindow : NSWindow {
	NSRect			oldWindowFrame;
	unsigned int	resisted_XMotion;
	unsigned int	resisted_YMotion;
	BOOL 			alreadyMoving;
	
	BOOL			dockingEnabled;
}

- (void)setDockingEnabled:(BOOL)inEnabled;

@end
