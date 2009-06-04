//
//  AIMessageHistoryPreferencesWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 4/6/07.
//

#import <Adium/AIWindowController.h>

@interface AIMessageHistoryPreferencesWindowController : AIWindowController {
	IBOutlet	NSTextField		*textField_haveTalkedDays;
	IBOutlet	NSStepper		*stepper_haveTalkedDays;

	IBOutlet	NSTextField		*textField_haveNotTalkedDays;
	IBOutlet	NSStepper		*stepper_haveNotTalkedDays;	
	
	IBOutlet	NSPopUpButton   *popUp_haveTalkedUnits;
	IBOutlet	NSPopUpButton   *popUp_haveNotTalkedUnits;	
}

+ (void)configureMessageHistoryPreferencesOnWindow:(id)parentWindow;

@end
