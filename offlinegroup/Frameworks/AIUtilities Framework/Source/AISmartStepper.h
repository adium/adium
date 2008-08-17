//
//  AISmartStepper.h
//  Adium
//
//  Created by Adam Iser on Sat Jul 26 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

/*!
 * @class AISmartStepper
 * @brief NSStepper subclass which fixes a bug related to keyboard focus
 *
 * <tt>NSStepper</tt> as of OS X 10.3 steals focus away from its target... which is very rarely the desired behavior. This subclass correctly refocuses the target when the stepper is used so the user can click the stepper and then type in a number to its field if desired.
 */

@interface AISmartStepper : NSStepper {

}

@end
