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
- (void)jumpToPrevious;
- (void)jumpToNext;
- (void)jumpToFocus;
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

@end
