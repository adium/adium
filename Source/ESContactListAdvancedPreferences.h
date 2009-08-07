//
//  ESContactListAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 2/20/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIAdvancedPreferencePane.h>

@interface ESContactListAdvancedPreferences : AIAdvancedPreferencePane {
	IBOutlet	NSPopUpButton   *popUp_windowPosition;
	
	IBOutlet	NSMatrix		*matrix_hiding;
    IBOutlet	NSButton		*checkBox_hideOnScreenEdgesOnlyInBackground;
	
	IBOutlet	NSButton		*checkBox_flash;
	IBOutlet	NSButton		*checkBox_animateChanges;
	IBOutlet	NSButton		*checkBox_showTooltips;
	IBOutlet	NSButton		*checkBox_showTooltipsInBackground;
	IBOutlet	NSButton		*checkBox_windowHasShadow;
	IBOutlet	NSButton		*checkBox_showOnAllSpaces;

	IBOutlet	NSTextField		*label_appearance;
	IBOutlet	NSTextField		*label_tooltips;
	IBOutlet	NSTextField		*label_windowHandling;
	IBOutlet	NSTextField		*label_hide;
	IBOutlet	NSTextField		*label_orderTheContactList;	
}

@end
