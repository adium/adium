//
//  AIMessageAlertsAdvancedPreferences.h
//  Adium
//
//  Created by Zachary West on 2009-05-23.
//  Copyright 2009 Adium. All rights reserved.
//

#import <Adium/AIAdvancedPreferencePane.h>

#define PREF_GROUP_STATUS_MENU_ITEM     @"Status Menu Item"
#define KEY_STATUS_MENU_ITEM_ENABLED    @"Status Menu Item Enabled"
#define	KEY_STATUS_MENU_ITEM_COUNT		@"Status Menu Item Unread Count"
#define	KEY_STATUS_MENU_ITEM_BADGE		@"Status Menu Item Badge"
#define KEY_STATUS_MENU_ITEM_FLASH		@"Status Menu Item Flash Unviewed"

@interface AIMessageAlertsAdvancedPreferences : AIAdvancedPreferencePane {
	IBOutlet	NSTextField	*label_dockMenuBarIconCounts;
	IBOutlet	NSButton	*checkBox_unreadConversations;
	IBOutlet	NSButton	*checkBox_unreadContentMention;
	
	IBOutlet	NSTextField *label_statusMenuItem;
	IBOutlet	NSButton	*checkBox_statusMenuItemBadge;
	IBOutlet	NSButton	*checkBox_statusMenuItemFlash;
	IBOutlet	NSButton	*checkBox_statusMenuItemCount;
	
	IBOutlet	NSTextField	*label_dockIcon;
	IBOutlet	NSTextField	*label_dockIconWhenUnread;
    IBOutlet	NSButton	*checkBox_animateDockIcon;
    IBOutlet    NSButton	*checkBox_badgeDockIcon;
}

@end
