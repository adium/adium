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

#import <Adium/AIPreferencePane.h>

@interface AIMessageAlertsAdvancedPreferences : AIPreferencePane {
	NSTextField *label_unreadMessages;
	NSTextField *label_actions;
	NSTextField *label_counts;
	NSTextField *label_statusMenu;
	NSTextField *label_tabCounts;
	AILocalizationButton *checkbox_statusMenuItemFlash;
	AILocalizationButton *checkbox_statusMenuItemCount;
	AILocalizationButton *checkbox_statusMenuItemBadge;
	AILocalizationButton *checkbox_animateDockIcon;
	AILocalizationButton *checkbox_badgeDockIcon;
	AILocalizationButton *checkbox_unreadConversations;
	AILocalizationButton *checkbox_unreadContentMention;
	AILocalizationButton *checkbox_unreadMentionCount;
	AILocalizationButton *checkbox_showTabCountSingle;
	AILocalizationButton *checkbox_showTabCountGroup;
}

@property (assign) IBOutlet NSTextField *label_unreadMessages;
@property (assign) IBOutlet NSTextField *label_actions;
@property (assign) IBOutlet NSTextField *label_counts;
@property (assign) IBOutlet NSTextField *label_statusMenu;
@property (assign) IBOutlet NSTextField *label_tabCounts;

@property (assign) IBOutlet AILocalizationButton *checkbox_statusMenuItemFlash;
@property (assign) IBOutlet AILocalizationButton *checkbox_statusMenuItemCount;
@property (assign) IBOutlet AILocalizationButton *checkbox_statusMenuItemBadge;
@property (assign) IBOutlet AILocalizationButton *checkbox_animateDockIcon;
@property (assign) IBOutlet AILocalizationButton *checkbox_badgeDockIcon;
@property (assign) IBOutlet AILocalizationButton *checkbox_unreadConversations;
@property (assign) IBOutlet AILocalizationButton *checkbox_unreadContentMention;
@property (assign) IBOutlet AILocalizationButton *checkbox_unreadMentionCount;
@property (assign) IBOutlet AILocalizationButton *checkbox_showTabCountSingle;
@property (assign) IBOutlet AILocalizationButton *checkbox_showTabCountGroup;

@end
