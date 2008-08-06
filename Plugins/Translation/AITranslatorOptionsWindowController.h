//
//  AITranslatorOptionsWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/13/06.
//

#import <Adium/AIWindowController.h>

@class AIListObject;

@interface AITranslatorOptionsWindowController : AIWindowController {
	IBOutlet	NSPopUpButton	*popUp_sourceLanguage;
	IBOutlet	NSPopUpButton	*popUp_destinationLanguage;
	
	IBOutlet	NSTextField		*textField_header;
	IBOutlet	NSTextField		*textField_sourceLanguage;
	IBOutlet	NSTextField		*textField_destinationLanguage;
	
	AIListObject	*currentListObject;
}

+ (void)showOptionsForListObject:(AIListObject *)listObject;
- (IBAction)selectLanguage:(id)sender;

@end
