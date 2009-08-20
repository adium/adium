//
//  AIJumpControlPlugin.m
//  Adium
//
//  Created by Zachary West on 2009-04-04.
//

#import "AIJumpControlPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/JVMarkedScroller.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIChat.h>
#import "AIMessageViewController.h"
#import "AIMessageTabViewItem.h"

#define PREF_KEY_FOCUS_LINE	@"Draw Focus Lines"

@interface AIJumpControlPlugin()
- (NSObject<AIMessageDisplayController> *)currentController;
@end

@implementation AIJumpControlPlugin
- (void)installPlugin
{
	menuItem_previous = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Jump to Previous Mark", "Jump to the previous mark in the message window")
															   target:self
															   action:@selector(jumpToPrevious)
														keyEquivalent:@"["
															  keyMask:NSAlternateKeyMask | NSCommandKeyMask];
	
	[adium.menuController addMenuItem:menuItem_previous toLocation:LOC_Display_Jump];
	
	menuItem_next = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Jump to Next Mark", "Jump to the next mark in the message window")
														   target:self
														   action:@selector(jumpToNext)
													keyEquivalent:@"]"
														  keyMask:NSAlternateKeyMask | NSCommandKeyMask];
	
	[adium.menuController addMenuItem:menuItem_next toLocation:LOC_Display_Jump];
	
	menuItem_focus = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Jump to Focus Mark", "Jump to the next location in the message window where the user last saw content")
															target:self
															action:@selector(jumpToFocus)
													 keyEquivalent:@""];
	
	[adium.menuController addMenuItem:menuItem_focus toLocation:LOC_Display_Jump];
	
	menuItem_add = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Add Mark", "Inserts a custom mark into the message window")
														  target:self
														  action:@selector(addMark)
												   keyEquivalent:@""];
	
	[adium.menuController addMenuItem:menuItem_add toLocation:LOC_Display_Jump];
	
	menuItem_focusLine = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Show Focus Lines", "Shows the focus lines inside the chats")
													target:self
													action:@selector(showFocusLines:)
											 keyEquivalent:@""];
	
	[adium.menuController addMenuItem:menuItem_focusLine toLocation:LOC_Display_MessageControl];
}

- (void)uninstallPlugin
{
	[adium.menuController removeMenuItem:menuItem_previous];
	[adium.menuController removeMenuItem:menuItem_next];
	[adium.menuController removeMenuItem:menuItem_focus];
	[adium.menuController removeMenuItem:menuItem_add];
}

#pragma mark Jump handling
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem == menuItem_previous) {
		return [self.currentController previousMarkExists];
	} else if (menuItem == menuItem_next) {
		return [self.currentController nextMarkExists];
	} else if (menuItem == menuItem_focus) {
		return [self.currentController focusMarkExists];
	} else if (menuItem == menuItem_focusLine) {
		[menuItem setState:[[adium.preferenceController preferenceForKey:PREF_KEY_FOCUS_LINE group:PREF_GROUP_GENERAL] boolValue]];
	}
	
	return (nil != adium.interfaceController.activeChat);
}

- (NSObject<AIMessageDisplayController> *)currentController
{
	return adium.interfaceController.activeChat.chatContainer.messageViewController.messageDisplayController;
}

- (void)jumpToPrevious
{
	[self.currentController jumpToPreviousMark];
}

- (void)jumpToNext
{
	[self.currentController jumpToNextMark];
}

- (void)jumpToFocus
{
	[self.currentController jumpToFocusMark];
}

- (void)addMark
{
	[self.currentController addMark];
}

- (void)showFocusLines:(id)sender
{
	[adium.preferenceController setPreference:[NSNumber numberWithBool:![sender state]]
									   forKey:PREF_KEY_FOCUS_LINE 
									    group:PREF_GROUP_GENERAL];
}

@end
