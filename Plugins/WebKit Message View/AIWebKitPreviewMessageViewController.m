//
//  AIWebKitPreviewMessageViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 6/13/08.
//

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
