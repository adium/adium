//
//  ESPersonalPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 12/18/05.
//

#import <Adium/AIPreferencePane.h>
#import <AIUtilities/AILeopardCompatibility.h>

@class AIImageViewWithImagePicker, AIDelayedTextField;

@interface ESPersonalPreferences : AIPreferencePane {
	IBOutlet	NSMatrix					*matrix_userIcon;
	IBOutlet	NSButton					*button_chooseIcon;
	IBOutlet	AIImageViewWithImagePicker  *imageView_userIcon;
	
	IBOutlet	AIDelayedTextField			*textField_alias;
	IBOutlet	AIDelayedTextField			*textField_displayName;
	IBOutlet	NSTextView <NSWindowDelegate>	*textView_profile;
	
	IBOutlet	NSTextField					*label_localAlias;
	IBOutlet	NSTextField					*label_remoteAlias;
	IBOutlet	NSTextField					*label_profile;
	
	IBOutlet	NSButton					*button_enableMusicProfile;
}

@end
