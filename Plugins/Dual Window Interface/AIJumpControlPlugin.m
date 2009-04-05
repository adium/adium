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

@implementation AIJumpControlPlugin
- (void)installPlugin
{
	NSMenuItem *menuItem;
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Jump to Previous Mark", "Jump to the previous mark in the message window")
										  target:self
										  action:@selector(jumpToPrevious)
								   keyEquivalent:@"["
										 keyMask:NSAlternateKeyMask | NSCommandKeyMask];
	
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Display_Jump];
	[menuItem release];

	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Jump to Next Mark", "Jump to the next mark in the message window")
										  target:self
										  action:@selector(jumpToNext)
								   keyEquivalent:@"]"
										 keyMask:NSAlternateKeyMask | NSCommandKeyMask];
	
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Display_Jump];
	[menuItem release];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Jump to Focus Mark", "Jump to the next location in the message window where the user last saw content")
										  target:self
										  action:@selector(jumpToFocus)
								   keyEquivalent:@""];
	
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Display_Jump];
	[menuItem release];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Add Mark", "Inserts a custom mark into the message window")
										  target:self
										  action:@selector(addMark)
								   keyEquivalent:@""];
	
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Display_Jump];
	[menuItem release];
}

- (void)uninstallPlugin
{
	
}

#pragma mark Jump handling
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	return (nil != adium.interfaceController.activeChat);
}

- (NSObject<AIMessageDisplayController> *)currentController
{
	return ((AIMessageTabViewItem *)adium.interfaceController.activeChat.chatContainer).messageViewController.messageDisplayController;	
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

@end
