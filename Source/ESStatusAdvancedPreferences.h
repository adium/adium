//
//  ESStatusAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 1/6/06.
//

#import <Adium/AIAdvancedPreferencePane.h>

@interface ESStatusAdvancedPreferences : AIAdvancedPreferencePane {
	IBOutlet	NSTextField	*label_dockMenuBarIconCounts;
	IBOutlet	NSButton	*checkBox_unreadConversations;
	IBOutlet	NSButton	*checkBox_unreadContentMention;
	
	IBOutlet	NSTextField	*label_statusWindow;
	IBOutlet	NSButton	*checkBox_statusWindowHideInBackground;
	IBOutlet	NSButton	*checkBox_statusWindowAlwaysOnTop;	
	
	IBOutlet	NSTextField *label_statusMenuItem;
	IBOutlet	NSButton	*checkBox_statusMenuItemBadge;
	IBOutlet	NSButton	*checkBox_statusMenuItemFlash;
	IBOutlet	NSButton	*checkBox_statusMenuItemCount;
	
	IBOutlet	NSTextField	*label_quitConfirmation;

	IBOutlet	NSButton	*checkBox_quitConfirmEnabled;
	IBOutlet	NSMatrix	*matrix_quitConfirmation;
	IBOutlet	NSButton	*checkBox_quitConfirmFT;
	IBOutlet	NSButton	*checkBox_quitConfirmUnread;
	IBOutlet	NSButton	*checkBox_quitConfirmOpenChats;
}

@end
