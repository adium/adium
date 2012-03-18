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
}

@property (weak) IBOutlet NSTextField *label_unreadMessages;
@property (weak) IBOutlet NSTextField *label_actions;
@property (weak) IBOutlet NSTextField *label_counts;
@property (weak) IBOutlet NSTextField *label_statusMenu;
@property (weak) IBOutlet NSTextField *label_tabCounts;

@property (weak) IBOutlet AILocalizationButton *checkbox_statusMenuItemFlash;
@property (weak) IBOutlet AILocalizationButton *checkbox_statusMenuItemCount;
@property (weak) IBOutlet AILocalizationButton *checkbox_statusMenuItemBadge;
@property (weak) IBOutlet AILocalizationButton *checkbox_animateDockIcon;
@property (weak) IBOutlet AILocalizationButton *checkbox_badgeDockIcon;
@property (weak) IBOutlet AILocalizationButton *checkbox_unreadConversations;
@property (weak) IBOutlet AILocalizationButton *checkbox_unreadContentMention;
@property (weak) IBOutlet AILocalizationButton *checkbox_unreadMentionCount;
@property (weak) IBOutlet AILocalizationButton *checkbox_showTabCountSingle;
@property (weak) IBOutlet AILocalizationButton *checkbox_showTabCountGroup;

@end
