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

#import "ESEditStatusGroupWindowController.h"
#import "AIStatusController.h"
#import <Adium/AIStatusGroup.h>
#import <Adium/AIStatusIcons.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>

@interface ESEditStatusGroupWindowController ()
- (NSMenu *)groupWithStatusMenu;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end

@implementation ESEditStatusGroupWindowController

- (void)showOnWindow:(NSWindow *)parentWindow
{
	if (parentWindow) {
		[NSApp beginSheet:self.window
		   modalForWindow:parentWindow
			modalDelegate:self
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	} else {
		[self showWindow:nil];
		[self.window makeKeyAndOrderFront:nil];
	}
}

- (id)initWithStatusGroup:(AIStatusGroup *)inStatusGroup notifyingTarget:(id)inTarget
{
    if ((self = [super initWithWindowNibName:@"EditStatusGroup"])) {
		target = inTarget;
		statusGroup = (inStatusGroup ? inStatusGroup : [[AIStatusGroup alloc] init]);
	}	
	
	return self;
}

- (void)windowDidLoad
{
	[popUp_groupWith setMenu:[self groupWithStatusMenu]];
	[popUp_groupWith selectItemWithTag:statusGroup.statusType];
	
	NSString *title = [statusGroup title];
	[textField_title setStringValue:(title ? title : @"")];

	[label_groupWith setAutoresizingMask:NSViewMinXMargin];	
	[label_title setLocalizedString:AILocalizedString(@"Title:", nil)];
	[label_groupWith setAutoresizingMask:NSViewMaxXMargin];

	[label_title setAutoresizingMask:NSViewMinXMargin];	
	[label_groupWith setLocalizedString:AILocalizedString(@"Group with:", "The popup button after this lists status types; it will determine the status type with which a status group will be listed in status menus")];
	[label_title setAutoresizingMask:NSViewMaxXMargin];

	[button_OK setLocalizedString:AILocalizedString(@"OK", nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel", nil)];

	[super windowDidLoad];
}

/*!
 * @brief Called before the window is closed
 *
 * As our window is closing, we auto-release this window controller instance.  This allows our editor to function
 * independently without needing a separate object to retain and release it.
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
}

/*!
 * Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}


/*!
 * @brief Okay
 *
 * Save changes, notify our target of the new configuration, and close the editor.
 */
- (IBAction)okay:(id)sender
{
	[statusGroup setTitle:[textField_title stringValue]];
	[statusGroup setStatusType:(AIStatusType)[[popUp_groupWith selectedItem] tag]];

	if (target && [target respondsToSelector:@selector(finishedStatusGroupEdit:)]) {
		//Perform on a delay so the sheet can begin closing immediately.
		[target performSelector:@selector(finishedStatusGroupEdit:)
				   withObject:statusGroup
				   afterDelay:0];
	}
	
	[self closeWindow:nil];
}

/*!
 * @brief Cancel
 *
 * Close the editor without saving changes.
 */
- (IBAction)cancel:(id)sender
{
	[self closeWindow:nil];
}

- (NSMenu *)groupWithStatusMenu
{
	NSMenu *menu = [[NSMenu alloc] init];
	NSMenuItem *menuItem;
	
	menuItem = [[NSMenuItem alloc] initWithTitle:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
																	target:nil
																	action:nil
															 keyEquivalent:@""];
	[menuItem setTag:AIAvailableStatusType];
	[menuItem setImage:[AIStatusIcons statusIconForStatusName:nil
												   statusType:AIAvailableStatusType
													 iconType:AIStatusIconMenu
													direction:AIIconNormal]];
	[menu addItem:menuItem];

	menuItem = [[NSMenuItem alloc] initWithTitle:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY]
																	target:nil
																	action:nil
															 keyEquivalent:@""];
	[menuItem setTag:AIAwayStatusType];
	[menuItem setImage:[AIStatusIcons statusIconForStatusName:nil
												   statusType:AIAwayStatusType
													 iconType:AIStatusIconMenu
													direction:AIIconNormal]];	
	[menu addItem:menuItem];
	
	return menu;
}

@end
