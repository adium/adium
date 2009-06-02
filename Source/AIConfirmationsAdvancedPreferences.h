//
//  AIConfirmationsAdvancedPreferences.h
//  Adium
//
//  Created by Zachary West on 2009-06-02.
//  Copyright 2009 Adium. All rights reserved.
//

#import <Adium/AIAdvancedPreferencePane.h>

@interface AIConfirmationsAdvancedPreferences : AIAdvancedPreferencePane {	
	// Quit confirmation
	IBOutlet	NSTextField		*label_quitConfirmation;
	IBOutlet	NSButton		*checkBox_confirmBeforeQuitting;
	IBOutlet	NSMatrix		*matrix_quitConfirmType;

	IBOutlet	NSButton		*checkBox_quitConfirmFT;
	IBOutlet	NSButton		*checkBox_quitConfirmUnread;
	IBOutlet	NSButton		*checkBox_quitConfirmOpenChats;
	
	// Message window close confirmation
	IBOutlet	NSTextField		*label_messageCloseConfirmation;
	IBOutlet	NSButton		*checkBox_confirmBeforeClosing;
	IBOutlet	NSMatrix		*matrix_closeConfirmType;
}

- (IBAction)changePreference:(id)sender;

@end
