/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

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
