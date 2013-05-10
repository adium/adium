//
//  NSMenu+ImmediatePopulation.h
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-11-08.
//  Copyright 2005 Adium Team. All rights reserved.
//

/*! @header NSMenu+ImmediatePopulation.h
 *  @discussion NSMenu supports population by delegate methods. This is used
 *   to support lazy loading; the menu will be populated when it is tracked
 *  (i.e. when the user clicks on it). But in a pop-up button, the menu will
 *   be blank, and unable to hold a selection, until that time. This is a work-
 *   around: call -populateFromDelegate as soon as appropriate (e.g. in
 *   -awakeFromNib), and the menu will be ready when the user expects it to be.
 */

@interface NSMenu (ImmediatePopulation)

- (void) populateFromDelegate;

@end
