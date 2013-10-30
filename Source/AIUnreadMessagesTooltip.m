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

#import "AIUnreadMessagesTooltip.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIGroupChatStatusIcons.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIListBookmark.h>

@implementation AIUnreadMessagesTooltip

- (void)installPlugin
{
	[adium.interfaceController registerContactListTooltipEntry:self secondaryEntry:YES];
}

- (void)uninstallPlugin
{
	[adium.interfaceController unregisterContactListTooltipEntry:self secondaryEntry:YES];
}

- (NSString *)labelForObject:(AIListObject *)inObject
{
	NSString *label = nil;
	
	if ([inObject isKindOfClass:[AIListBookmark class]] && [inObject valueForProperty:KEY_UNREAD_STATUS]) {
		label = AILocalizedString(@"Unread messages", nil);
	}
	
	return label;
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
	NSAttributedString *entry = nil;
	
	if ([inObject isKindOfClass:[AIListBookmark class]] && [inObject valueForProperty:KEY_UNREAD_STATUS]) {
		entry = [NSAttributedString stringWithString:[inObject valueForProperty:KEY_UNREAD_STATUS]];
	}
	
	return entry;
}

- (BOOL)shouldDisplayInContactInspector
{
	return NO;
}

@end
