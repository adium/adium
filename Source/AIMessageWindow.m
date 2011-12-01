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

#import "AIMessageWindow.h"
#import "AIClickThroughThemeDocumentButton.h"
#import "AIMessageWindowController.h"
#import "AIInterfaceControllerProtocol.h"

/*!
 * @class AIMessageWindow
 * @brief This AIDockingWindow subclass serves message windows.
 */
@implementation AIMessageWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	if (!(self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:deferCreation]))
		return nil;

	return self;
}

- (NSScriptObjectSpecifier *)objectSpecifier
{
	NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];
	return [[[NSUniqueIDSpecifier alloc]
			initWithContainerClassDescription:containerClassDesc
			containerSpecifier:nil key:@"chatWindows"
			uniqueID:[NSNumber numberWithInteger:[self windowNumber]]] autorelease];
}

- (void)dealloc
{
	AILogWithSignature(@"");

	[super dealloc];
}

- (NSArray *)chats
{
	return [(AIMessageWindowController *)[self windowController] containedChats];
}

- (id)handleCloseScriptCommand:(NSCloseCommand *)command
{
	[self performClose:nil];

	return nil;
}

@end
