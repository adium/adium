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

#import "AIBorderlessListWindowController.h"
#import "AIBorderlessListController.h"

#import <Adium/AIListOutlineView.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIPreferenceControllerProtocol.h>

#define PREF_GROUP_APPEARANCE		@"Appearance"

@implementation AIBorderlessListWindowController

//Borderless nib
+ (NSString *)nibName
{
    return @"ContactListWindowBorderless";
}

- (Class)listControllerClass
{
	return [AIBorderlessListController class];
}

- (void)windowDidLoad
{
	//Clear the minimum size before our window restores its position and size; a borderless window can be any size it wants
	[[self window] setMinSize:NSZeroSize];
	
	AIContactListWindowStyle style = [[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE
																			 group:PREF_GROUP_APPEARANCE] integerValue];
	
	filterBarView.drawBackground = YES;
	filterBarView.backgroundColor = [NSColor whiteColor];
	filterBarView.backgroundIsRounded = (style == AIContactListWindowStyleContactBubbles ||
										 style == AIContactListWindowStyleContactBubbles_Fitted ||
										 style == AIContactListWindowStyleGroupBubbles);
	
	[super windowDidLoad];
}

/*!
 * @brief Used by the interface controller to know that despite having no NSWindowCloseButton, our window can be closed
 */
- (BOOL)windowPermitsClose
{
	return YES;
}


@end
