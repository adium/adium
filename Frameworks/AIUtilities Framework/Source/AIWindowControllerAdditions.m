//
//  AIWindowControllerAdditions.m
//  AIUtilities.framework
//
//  Created by David Smith on 9/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIWindowControllerAdditions.h"


@implementation NSWindowController (AIWindowControllerAdditions)

- (BOOL) canCustomizeToolbar
{
	return YES; //default implementation, should be overridden.
}

/*!
 * @brief Returns NO if another window should avoid taking over 
 * the key window from this controller without direct user interaction.
 *
 * Defaults to YES, allowing other windows to become the key window.
 * @see AIWindowController::showWindowInFrontIfAllowed:
 */
- (BOOL) shouldResignKeyWindowWithoutUserInput
{
	return YES;
}

@end
