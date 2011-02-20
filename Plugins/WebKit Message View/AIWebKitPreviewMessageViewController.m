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

#import "AIWebKitPreviewMessageViewController.h"
#import "ESWebView.h"
#import "AIWebKitMessageViewPlugin.h"
#import <Adium/AIChat.h>

@implementation AIWebKitPreviewMessageViewController

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	return [NSArray array];
}

- (void)dealloc
{
	[preferencesChangedDelegate release]; preferencesChangedDelegate = nil;

	[super dealloc];
}

- (void)setIsGroupChat:(BOOL)groupChat
{
	chat.isGroupChat = groupChat;
	preferenceGroup = [[plugin preferenceGroupForChat:chat] retain];
}

- (void)setPreferencesChangedDelegate:(id)inDelegate
{
	if (inDelegate != preferencesChangedDelegate) {
		[preferencesChangedDelegate release];
		preferencesChangedDelegate = [inDelegate retain];
		
		[preferencesChangedDelegate preferencesChangedForGroup:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY
														   key:nil
														object:nil
												preferenceDict:[adium.preferenceController preferencesForGroup:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY]
													 firstTime:YES];
		
		[preferencesChangedDelegate preferencesChangedForGroup:PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY
														   key:nil
														object:nil
												preferenceDict:[adium.preferenceController preferencesForGroup:PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY]
													 firstTime:YES];
		
		[preferencesChangedDelegate preferencesChangedForGroup:PREF_GROUP_WEBKIT_BACKGROUND_IMAGES
														   key:nil
														object:nil
												preferenceDict:[adium.preferenceController preferencesForGroup:PREF_GROUP_WEBKIT_BACKGROUND_IMAGES]
													 firstTime:YES];
	}
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];

	if (preferencesChangedDelegate) {
		[preferencesChangedDelegate preferencesChangedForGroup:group
														   key:key
														object:object
												preferenceDict:prefDict
													 firstTime:firstTime];
	}
}

@end
