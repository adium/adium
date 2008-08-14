//
//  ESEditStatusGroupWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 11/25/05.
//

#import "ESEditStatusGroupWindowController.h"
#import "AIStatusController.h"
#import <Adium/AIStatusGroup.h>
#import <Adium/AIStatusIcons.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>

@interface ESEditStatusGroupWindowController ()
- (NSMenu *)groupWithStatusMenu;
- (id)initWithWindowNibName:(NSString *)windowNibName forStatusGroup:(AIStatusGroup *)inStatusGroup notifyingTarget:(id)inTarget;
@end

@implementation ESEditStatusGroupWindowController

+ (void)editStatusGroup:(AIStatusGroup *)inStatusGroup onWindow:(id)parentWindow notifyingTarget:(id)inTarget
{
	ESEditStatusGroupWindowController *controller;

	controller = [[self alloc] initWithWindowNibName:@"EditStatusGroup"
									  forStatusGroup:inStatusGroup
									 notifyingTarget:inTarget];

	if (parentWindow) {
		[NSApp beginSheet:[controller window]
		   modalForWindow:parentWindow
			modalDelegate:controller
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	} else {
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];
	}
}

- (id)initWithWindowNibName:(NSString *)windowNibName forStatusGroup:(AIStatusGroup *)inStatusGroup notifyingTarget:(id)inTarget
{
    if ((self = [super initWithWindowNibName:windowNibName])) {
		target = inTarget;
		statusGroup = (inStatusGroup ? [inStatusGroup retain] : [[AIStatusGroup alloc] init]);
	}	
	
	return self;
}

- (void)dealloc
{
	[statusGroup release];
	
	[super dealloc];
}

- (void)windowDidLoad
{
	[popUp_groupWith setMenu:[self groupWithStatusMenu]];
	[popUp_groupWith compatibleSelectItemWithTag:[statusGroup statusType]];
	
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

	[self autorelease];
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
	[statusGroup setStatusType:[[popUp_groupWith selectedItem] tag]];

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
	NSMenu *menu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	NSMenuItem *menuItem;
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
																	target:nil
																	action:nil
															 keyEquivalent:@""];
	[menuItem setTag:AIAvailableStatusType];
	[menuItem setImage:[AIStatusIcons statusIconForStatusName:nil
												   statusType:AIAvailableStatusType
													 iconType:AIStatusIconMenu
													direction:AIIconNormal]];
	[menu addItem:menuItem];
	[menuItem release];

	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY]
																	target:nil
																	action:nil
															 keyEquivalent:@""];
	[menuItem setTag:AIAwayStatusType];
	[menuItem setImage:[AIStatusIcons statusIconForStatusName:nil
												   statusType:AIAwayStatusType
													 iconType:AIStatusIconMenu
													direction:AIIconNormal]];	
	[menu addItem:menuItem];
	[menuItem release];
	
	return [menu autorelease];
}

@end
