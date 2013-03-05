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

#import "AIListContactGroupChatCell.h"
#import <Adium/AIGroupChat.h>
#import <Adium/AIGroupChatStatusIcons.h>
#import <Adium/AIStatusIcons.h>

@implementation AIListContactGroupChatCell

@synthesize chat;
- (void)dealloc
{
	[chat release];
	[super dealloc];
}

- (NSString *)labelString
{
	AIListObject *listObject = [proxyObject listObject];
	NSString *label;
	
	if (chat && [chat displayNameForContact:listObject]) {
		label = [chat displayNameForContact:listObject];
	} else {
		label = [super labelString];
	}
	
	return label;
}

- (NSImage *)statusImage
{
    AIListObject    *listObject = [proxyObject listObject];
	return [[AIGroupChatStatusIcons sharedIcons] imageForFlag:[chat flagsForContact:listObject]];
}

- (NSImage *)serviceImage
{
	// We can't use [listObject statusIcon] because it will show unknown for strangers.
    AIListObject    *listObject = [proxyObject listObject];
	return [AIStatusIcons statusIconForListObject:listObject
											 type:AIStatusIconTab
										direction:AIIconFlipped];
}

- (NSColor *)textColor
{
    AIListObject    *listObject = [proxyObject listObject];
	return [[AIGroupChatStatusIcons sharedIcons] colorForFlag:[chat flagsForContact:listObject]];
}

- (float)imageOpacityForDrawing
{
	return 1.0f;
}

@end
