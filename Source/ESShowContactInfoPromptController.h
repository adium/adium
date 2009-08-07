//
//  ESShowContactInfoPromptController.h
//  Adium
//
//  Created by Evan Schoenberg on 1/8/06.

#import "AIAccountPlusFieldPromptController.h"

@interface ESShowContactInfoPromptController : AIAccountPlusFieldPromptController {
	IBOutlet	NSTextField	*label_using;
	IBOutlet	NSTextField	*label_contact;
}

@end
