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

#import "AILocalVideoWindowController.h"
#import "AIVideoChatInterfacePlugin.h"

@implementation AIVideoChatInterfacePlugin

- (void)installPlugin
{
//	NSMenuItem	*menuItem;
//	
//	//View my webcam menu
//	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"My Webcam",nil)
//										  target:self 
//										  action:@selector(openSelfVideo:)
//								   keyEquivalent:@""];
//	[adium.menuController addMenuItem:menuItem toLocation:LOC_Window_Auxiliary];
//	
	
	
	//Observe video chat creation and destruction
//	[[NSNotificationCenter defaultCenter] addObserver:self
//								   selector:@selector(videoChatDidOpen:)
//									   name:AIVideoChatDidOpenNotification
//									 object:nil];
//	[[NSNotificationCenter defaultCenter] addObserver:self
//								   selector:@selector(videoChatWillClose:)
//									   name:AIVideoChatWillCloseNotification
//									 object:nil];
}

- (void)openSelfVideo:(id)sender
{
	[AILocalVideoWindowController showLocalVideoWindow];
}

//- (void)videoChatDidOpen:(NSNotification *)notification
//{
//	AIVideoChatWindowController	*window;
//	NSLog(@"Video chat open");
//	
//	//
//	window = [[AIVideoChatWindowController windowForVideoChat:[notification object]] retain];
//	[window showWindow:nil];
//}
//
//- (void)videoChatDidClose:(NSNotification *)notification
//{
//	NSLog(@"Video chat close");
//}

@end
