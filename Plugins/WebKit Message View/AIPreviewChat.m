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

#import "AIPreviewChat.h"

@implementation AIPreviewChat

+ (AIPreviewChat *)previewChat
{
	return [self chatForAccount:nil];
}

- (void)setDateOpened:(NSDate *)inDate
{
	if (dateOpened != inDate) {
		[dateOpened release]; 
		dateOpened = [inDate retain];
    }
}

- (BOOL)supportsTopic
{
	return isGroupChat;
}

- (NSString *)topic
{
	return AILocalizedString(@"This is a sample topic for this chat. Enjoy!",nil);
}

- (void)setTopic:(NSString *)inTopic
{
	return;
}

- (NSString *)aliasForContact:(AIListObject *)contact
{
	return nil;
}

@end
