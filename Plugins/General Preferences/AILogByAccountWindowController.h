//
//  AILogByAccountWindowController.h
//  Adium
//
//  Created by Zachary West on 2011-01-14.
//  Copyright 2011  . All rights reserved.
//

@interface AILogByAccountWindowController : NSWindowController {
	NSArray *accounts;
	
	IBOutlet AILocalizationTextField *textField_description;
	
}

- (IBAction)done:(id)sender;

@end
