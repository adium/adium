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

#import "AIMessageAlertsAdvancedPreferences.h"
#import <AIUtilities/AIImageAdditions.h>

@implementation AIMessageAlertsAdvancedPreferences
@synthesize label_unreadMessages, label_actions, label_counts, label_statusMenu, label_tabCounts;
@synthesize checkbox_statusMenuItemFlash, checkbox_statusMenuItemCount, checkbox_statusMenuItemBadge;
@synthesize checkbox_animateDockIcon, checkbox_badgeDockIcon;
@synthesize checkbox_unreadConversations, checkbox_unreadContentMention, checkbox_unreadMentionCount;
@synthesize checkbox_showTabCountSingle, checkbox_showTabCountGroup;

#pragma mark Preference Pane
- (AIPreferenceCategory)category
{
    return AIPref_Events;
}
- (NSString *)paneIdentifier{
	return @"MessageAlertsAdvanced";
}
- (NSString *)paneName{
    return AILocalizedString(@"Message Alerts",nil);
}
- (NSString *)nibName{
    return @"Preferences-MessageAlerts";
}
- (NSImage *)paneIcon{
	return [NSImage imageNamed:@"pref-message-alerts" forClass:[self class]];
}

#pragma mark Display

- (void)localizePane
{
	[label_actions setLocalizedString:AILocalizedString(@"Actions:", nil)];
	[label_unreadMessages setLocalizedString:AILocalizedString(@"Unread Messages", nil)];
	[label_counts setLocalizedString:AILocalizedString(@"Counts:", nil)];
	[label_statusMenu setLocalizedString:AILocalizedString(@"Status Menu Item:", nil)];
	[label_tabCounts setLocalizedString:AILocalizedString(@"Tabs:", nil)];
	
	[checkbox_statusMenuItemBadge setLocalizedString:AILocalizedString(@"Badge the menu item with current status", nil)];
	[checkbox_statusMenuItemFlash setLocalizedString:AILocalizedString(@"Flash status menu item", nil)];
	[checkbox_statusMenuItemCount setLocalizedString:AILocalizedString(@"Show count in the menu bar", nil)];
	
	[checkbox_animateDockIcon setLocalizedString:AILocalizedString(@"Animate the dock icon", nil)];
	[checkbox_badgeDockIcon setLocalizedString:AILocalizedString(@"Display a count badge on the dock icon", nil)];
	
	[checkbox_unreadConversations setLocalizedString:AILocalizedString(@"Count unread conversations instead of unread messages", nil)];
	[checkbox_unreadContentMention setLocalizedString:AILocalizedString(@"For group chats, only count number of highlights and mentions", nil)];
	[checkbox_unreadMentionCount setLocalizedString:AILocalizedString(@"For tabs, only count number of unread mentions", nil)];
	
	[checkbox_showTabCountSingle setLocalizedString:AILocalizedString(@"Show count in tabs (single chat)", nil)];
	[checkbox_showTabCountGroup setLocalizedString:AILocalizedString(@"Show count in tabs (group chat)", nil)];
}


@end
