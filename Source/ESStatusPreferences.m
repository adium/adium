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

#import "ESStatusPreferences.h"
#import "AIStatusController.h"
#import "ESEditStatusGroupWindowController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIEditStateWindowController.h>
#import <Adium/AIStatusMenu.h>
#import <Adium/AIStatusGroup.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <AIUtilities/AIAlternatingRowOutlineView.h>
#import <AIUtilities/AIImageDrawingAdditions.h>

#define STATE_DRAG_TYPE	@"AIState"

@interface ESStatusPreferences ()
- (void)configureOtherControls;
- (void)configureAutoAwayStatusStatePopUp;
- (void)saveTimeValues;
- (void)_selectStatusWithUniqueID:(NSNumber *)uniqueID inPopUpButton:(NSPopUpButton *)inPopUpButton;

- (void)reselectDraggedItems:(NSArray *)theDraggedItems;
- (void)changedAutoAwayStatus:(id)sender;
- (void)changedFastUserSwitchingStatus:(id)sender;
- (void)changedScreenSaverStatus:(id)sender;

- (BOOL)addItemIfNeeded:(NSMenuItem *)menuItem toPopUpButton:(NSPopUpButton *)popUpButton alreadyShowingAnItem:(BOOL)alreadyShowing;

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

- (void)newState;
- (void)deleteState;
@end

@implementation ESStatusPreferences

- (NSString *)paneIdentifier
{
	return @"Status";
}
- (NSString *)paneName
{
    return AILocalizedString(@"Status",nil);
}
- (NSImage *)paneIcon
{
	return [NSImage imageNamed:@"pref-status" forClass:[self class]];
}

/*!
 * @brief Nib name
 */
- (NSString *)nibName{
    return @"StatusPreferences";
}

/*!
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
	//Configure the controls
	[self configureStateList];

	[outlineView_stateList setDrawsBackground:NO];
	[outlineView_stateList setUsesAlternatingRowBackgroundColors:YES];
	
	[outlineView_stateList accessibilitySetOverrideValue:AILocalizedString(@"Statuses", nil)
											forAttribute:NSAccessibilityTitleAttribute];

	/* Register as an observer of state array changes so we can refresh our list
	 * in response to changes. */
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(stateArrayChanged:)
									   name:AIStatusStateArrayChangedNotification
									 object:nil];
	[self stateArrayChanged:nil];

	[self configureOtherControls];
}

/*!
 * @brief Preference view is closing
 */
- (void)viewWillClose
{
	[self saveTimeValues];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[super dealloc];
}

#pragma mark Status state list and controls
/*!
* @brief Configure the state list
 *
 * Configure the state list table view, setting up the custom table cells, padding, scroll view settings and other
 * state list interface related setup.
 */
- (void)configureStateList
{
    AIVerticallyCenteredTextCell *cell;

	//Configure the table view
	[outlineView_stateList setTarget:self];
	[outlineView_stateList setDoubleAction:@selector(editState:)];
	[outlineView_stateList setIntercellSpacing:NSMakeSize(4,4)];
    [scrollView_stateList setAutohidesScrollers:YES];
	
	//Enable dragging of states
	[outlineView_stateList registerForDraggedTypes:[NSArray arrayWithObject:STATE_DRAG_TYPE]];
	
    //Custom vertically-centered text cell for status state names
    cell = [[AIVerticallyCenteredTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:13]];
    [[outlineView_stateList tableColumnWithIdentifier:@"name"] setDataCell:cell];
	[cell release];
}

/*!
 * @brief Update table control availability
 *
 * Updates table control availability based on the current state selection.  If no states are selected this method dims the
 * edit and delete buttons since they require a selection to function.  The edit and delete buttons are also
 * dimmed if the selected state is a built-in state.
 */
- (void)updateTableControlAvailability
{
//	NSArray *selectedItems = [outlineView_stateList arrayOfSelectedItems];
	NSIndexSet *selectedIndexes = [outlineView_stateList selectedRowIndexes];
	NSInteger			count = [selectedIndexes count];

	[button_editState setEnabled:(count && 
								  ([[outlineView_stateList itemAtRow:[selectedIndexes firstIndex]] mutabilityType] == AIEditableStatusState))];
	[button_addOrRemoveState setEnabled:count forSegment:1];
}

/*!
 * @brief Invoked when the state array changes
 *
 * This method is invoked when the state array changes.  In response, we hold onto the new array and refresh our state
 * list.
 */
- (void)stateArrayChanged:(NSNotification *)notification
{
	[outlineView_stateList reloadData];
	[self updateTableControlAvailability];
	
	//Update the auto away status pop up as necessary
	[self configureAutoAwayStatusStatePopUp];
}

//State Editing --------------------------------------------------------------------------------------------------------
#pragma mark State Editing
/*!
* @brief Edit the selected state
 *
 * Opens an edit state sheet for the selected state.  If the sheet is closed with success our
 * customStatusState:changedTo: method will be invoked and we can save the changes
 */
- (IBAction)editState:(id)sender
{
	NSInteger				selectedRow = [outlineView_stateList selectedRow];
	AIStatusItem	*statusState = [outlineView_stateList itemAtRow:selectedRow];
	
	if (statusState) {
		if ([statusState isKindOfClass:[AIStatus class]]) {
			[AIEditStateWindowController editCustomState:(AIStatus *)statusState
												 forType:statusState.statusType
											  andAccount:nil
										  withSaveOption:NO
												onWindow:[[self view] window]
										 notifyingTarget:self];
			
		} else if ([statusState isKindOfClass:[AIStatusGroup class]]) {
			ESEditStatusGroupWindowController *editStatusGroupWindowController = [[ESEditStatusGroupWindowController alloc] initWithStatusGroup:(AIStatusGroup *)statusState
																																notifyingTarget:self];
			[editStatusGroupWindowController showOnWindow:[[self view] window]];
		}
	}
}

/*!
* @brief State edited callback
 *
 * Invoked when the user successfully edits a state.  This method adds the new or updated state to Adium's state array.
 */
- (void)customStatusState:(AIStatus *)originalState changedTo:(AIStatus *)newState forAccount:(AIAccount *)account
{
	if (originalState) {
		/* As far the user was concerned, this was an edit.  The unique status ID should remain the same so that anything
		 * depending upon this status will update to using it.  Furthermore, since this may be a copy of originalState
		 * rather than the exact same object, we should update all accounts which are using this state to use the new copy
		 */
		[newState setUniqueStatusID:[originalState uniqueStatusID]];
		
		for (AIAccount *loopAccount in adium.accountController.accounts) {
			if (loopAccount.statusState == originalState) {
				[loopAccount setStatusStateAndRemainOffline:newState];
				
				[loopAccount notifyOfChangedPropertiesSilently:YES];
			}
		}

		[[originalState containingStatusGroup] replaceExistingStatusState:originalState withStatusState:newState];

		[originalState setUniqueStatusID:nil];

	} else {
		[adium.statusController addStatusState:newState];
	}
	
	[outlineView_stateList selectItemsInArray:[NSArray arrayWithObject:newState]];
	[outlineView_stateList scrollRowToVisible:[outlineView_stateList rowForItem:newState]];
}

- (void)finishedStatusGroupEdit:(AIStatusGroup *)inStatusGroup
{
	if (![inStatusGroup containingStatusGroup]) {
		//Add it if it's not already in a group
		[[adium.statusController rootStateGroup] addStatusItem:inStatusGroup atIndex:-1];

	} else {
		//Otherwise just save
		[adium.statusController savedStatusesChanged];
	}

	[outlineView_stateList selectItemsInArray:[NSArray arrayWithObject:inStatusGroup]];
	[outlineView_stateList scrollRowToVisible:[outlineView_stateList rowForItem:inStatusGroup]];
}

/*!
 * @brief Delete the selected state
 *
 * Deletes the selected state from Adium's state array.
 */
- (void)deleteState
{
	NSArray		 *selectedItems = [outlineView_stateList arrayOfSelectedItems];
	
	if ([selectedItems count]) {
		//Confirm deletion of a status group with contents
		NSUInteger			 numberOfItems = 0;

		for (AIStatusItem *statusItem in selectedItems) {
			if ([statusItem isKindOfClass:[AIStatusGroup class]] &&
				[[(AIStatusGroup *)statusItem flatStatusSet] count]) {
				numberOfItems += [[(AIStatusGroup *)statusItem flatStatusSet] count];
			} else {
				numberOfItems++;
			}
		}

		NSString *message = [NSString stringWithFormat:AILocalizedString(@"Are you sure you want to delete %lu saved status items?",nil),
							 numberOfItems];
		
		//Warn if deleting a group containing status items
		NSBeginAlertSheet(AILocalizedString(@"Status Deletion Confirmation",nil),
						  AILocalizedString(@"Delete", nil),
						  AILocalizedString(@"Cancel", nil), nil,
						  [[self view] window], self,
						  @selector(sheetDidEnd:returnCode:contextInfo:), NULL,
						  [selectedItems retain],
						  message);
	}
}

/*!
 * @brief Confirmed a status item deletion operation
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSArray *selectedItems = (NSArray *)contextInfo;
	if (returnCode == NSAlertDefaultReturn) {
		AIStatusItem *statusItem;

		for (statusItem in selectedItems) {
			[[statusItem containingStatusGroup] removeStatusItem:statusItem];
		}
	}	
	
	[selectedItems release];
}

/*!
* @brief Add a new state
 *
 * Creates a new state.  This is done by invoking an edit window without passing it a base state.  When the edit window
 * returns successfully, it will invoke our customStatusState:changedTo: which adds the new state to Adium's state
 * array.
 */
- (void)newState
{
	[AIEditStateWindowController editCustomState:nil
										 forType:AIAwayStatusType
									  andAccount:nil
								  withSaveOption:NO
										onWindow:[[self view] window]
								 notifyingTarget:self];
}

- (IBAction)addGroup:(id)sender
{
	ESEditStatusGroupWindowController *editStatusGroupWindowController = [[ESEditStatusGroupWindowController alloc] initWithStatusGroup:nil
																														notifyingTarget:self];
	[editStatusGroupWindowController showOnWindow:[[self view] window]];
}

- (IBAction)addOrRemoveState:(id)sender
{
	NSInteger selectedSegment = [sender selectedSegment];
	
	switch (selectedSegment) {
		case 0:
			[self newState];
			break;
		case 1:
			[self deleteState];
			break;
	}
}

//State List OutlinView Delegate --------------------------------------------------------------------------------------------
#pragma mark State List (OutlineView Delegate)
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)idx ofItem:(id)item
{
	AIStatusGroup *statusGroup = (item ? item : [adium.statusController rootStateGroup]);
	
	return [[statusGroup containedStatusItems] objectAtIndex:idx];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	AIStatusGroup *statusGroup = (item ? item : [adium.statusController rootStateGroup]);
	
	return [[statusGroup containedStatusItems] count];	
}

- (NSString *)outlineView:(NSOutlineView *)outlineView typeSelectStringForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if([[tableColumn identifier] isEqualToString:@"name"])
		return [item title] ? [item title] : @"";
	return @"";
}
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{

}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	NSString 		*identifier = [tableColumn identifier];
	
	if ([identifier isEqualToString:@"icon"]) {
		return ([item respondsToSelector:@selector(icon)] ? [item icon] : nil);
		
	} else if ([identifier isEqualToString:@"name"]) {
		NSImage *icon = ([item respondsToSelector:@selector(icon)] ? [item icon] : nil);
		
		if (icon) {
			NSMutableAttributedString *name;

			NSTextAttachment		*attachment;
			NSTextAttachmentCell	*cell;
			
			NSSize					iconSize = [icon size];
			
			if ((iconSize.width > 13) || (iconSize.height > 13)) {
				icon = [icon imageByScalingToSize:NSMakeSize(13, 13)];
			}

			cell = [[[NSTextAttachmentCell alloc] init] autorelease];
			[cell setImage:icon];
			
			attachment = [[[NSTextAttachment alloc] init] autorelease];
			[attachment setAttachmentCell:cell];
			
			name = [[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy];
			[name appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@",([item title] ? [item title] : @"")]
																		  attributes:nil] autorelease]];
			return [name autorelease];
		} else {
			return [item title]; 
		}
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [item isKindOfClass:[AIStatusGroup class]];
}

/*!
* @brief Delete the selected row
 */
- (void)outlineViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteState];
}

/*!
* @brief Selection change
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	[self updateTableControlAvailability];
}

/*!
* @brief Drag start
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
    draggingItems = [items retain];
	
    [pboard declareTypes:[NSArray arrayWithObject:STATE_DRAG_TYPE] owner:self];
    [pboard setString:@"State" forType:STATE_DRAG_TYPE]; //Arbitrary state

    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)idx
{
    if (idx == NSOutlineViewDropOnItemIndex && ![item isKindOfClass:[AIStatusGroup class]]) {
		AIStatusGroup *dropItem = [item containingStatusGroup];
		if (dropItem == [adium.statusController rootStateGroup])
			dropItem = nil;

		[outlineView setDropItem:dropItem
				  dropChildIndex:[[[item containingStatusGroup] containedStatusItems] indexOfObjectIdenticalTo:item]];
	}
     
	return NSDragOperationPrivate;
}

/*!
* @brief Drag complete
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)idx
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:STATE_DRAG_TYPE]];
    if ([avaliableType isEqualToString:STATE_DRAG_TYPE]) {		
		[adium.statusController setDelayStatusMenuRebuilding:YES];

		if (!item) item = [adium.statusController rootStateGroup];

		AIStatusItem *statusItem;
		

		for (statusItem in draggingItems) {
			if ([statusItem containingStatusGroup] == item) {
				BOOL shouldIncrement = NO;
				if ([[[statusItem containingStatusGroup] containedStatusItems] indexOfObject:statusItem] > idx) {
					shouldIncrement = YES;
				}
				
				//Move the state and select it in the new location
				[item moveStatusItem:statusItem toIndex:idx];
				
				if (shouldIncrement) idx++;
			} else {
				//Don't let an object be moved into itself...
				if (item != statusItem) {
					[statusItem retain];
					[[statusItem containingStatusGroup] removeStatusItem:statusItem];
					[item addStatusItem:statusItem atIndex:idx];
					[statusItem release];
					
					idx++;
				}
			}
		}

		//Notify and reselect outside of the NSOutlineView callback
		[self performSelector:@selector(reselectDraggedItems:)
				   withObject:draggingItems
				   afterDelay:0];

		[draggingItems release]; draggingItems = nil;

        return YES;
    } else {
        return NO;
    }
}

- (void)reselectDraggedItems:(NSArray *)theDraggedItems
{
	[adium.statusController setDelayStatusMenuRebuilding:NO];

	[outlineView_stateList selectItemsInArray:theDraggedItems];
	[outlineView_stateList scrollRowToVisible:[outlineView_stateList rowForItem:[theDraggedItems objectAtIndex:0]]];
}

#pragma mark Other status-related controls

/*!
 * @brief Configure initial values for idle, auto-away, etc., preferences.
 */

- (void)configureOtherControls
{
	NSDictionary	*prefDict = [adium.preferenceController preferencesForGroup:PREF_GROUP_STATUS_PREFERENCES];
	
	[checkBox_idle setState:[[prefDict objectForKey:KEY_STATUS_REPORT_IDLE] boolValue]];
	[textField_idleMinutes setDoubleValue:([[prefDict objectForKey:KEY_STATUS_REPORT_IDLE_INTERVAL] doubleValue] / 60.0)];
	[stepper_idleMinutes setDoubleValue:([[prefDict objectForKey:KEY_STATUS_REPORT_IDLE_INTERVAL] doubleValue] / 60.0)];

	[checkBox_autoAway setState:[[prefDict objectForKey:KEY_STATUS_AUTO_AWAY] boolValue]];
	[textField_autoAwayMinutes setDoubleValue:([[prefDict objectForKey:KEY_STATUS_AUTO_AWAY_INTERVAL] doubleValue] / 60.0)];
	[stepper_autoAwayMinutes setDoubleValue:([[prefDict objectForKey:KEY_STATUS_AUTO_AWAY_INTERVAL] doubleValue] / 60.0)];

	[checkBox_fastUserSwitching setState:[[prefDict objectForKey:KEY_STATUS_FUS] boolValue]];
	[checkBox_screenSaver setState:[[prefDict objectForKey:KEY_STATUS_SS] boolValue]];

	[checkBox_showStatusWindow setState:[[prefDict objectForKey:KEY_STATUS_SHOW_STATUS_WINDOW] boolValue]];
	
	[self configureControlDimming];
}

/*!
 * @brief Configure the pop up of states for autoAway.
 *
 * Should be called by stateArrayChanged: both for initial set up and for updating when the states change.
 */
- (void)configureAutoAwayStatusStatePopUp
{
	NSMenu		*statusStatesMenu;
	NSNumber	*targetUniqueStatusIDNumber;

	statusStatesMenu = [AIStatusMenu staticStatusStatesMenuNotifyingTarget:self selector:@selector(changedAutoAwayStatus:)];
	[popUp_autoAwayStatusState setMenu:statusStatesMenu];
	
	statusStatesMenu = [AIStatusMenu staticStatusStatesMenuNotifyingTarget:self selector:@selector(changedFastUserSwitchingStatus:)];	
	[popUp_fastUserSwitchingStatusState setMenu:[[statusStatesMenu copy] autorelease]];
	
	statusStatesMenu = [AIStatusMenu staticStatusStatesMenuNotifyingTarget:self selector:@selector(changedScreenSaverStatus:)];	
	[popUp_screenSaverStatusState setMenu:[[statusStatesMenu copy] autorelease]];

	//Now select the proper state, or deselect all items if there is no chosen state or the chosen state doesn't exist
	targetUniqueStatusIDNumber = [adium.preferenceController preferenceForKey:KEY_STATUS_AUTO_AWAY_STATUS_STATE_ID
																		  group:PREF_GROUP_STATUS_PREFERENCES];
	[self _selectStatusWithUniqueID:targetUniqueStatusIDNumber inPopUpButton:popUp_autoAwayStatusState];
	
	targetUniqueStatusIDNumber = [adium.preferenceController preferenceForKey:KEY_STATUS_FUS_STATUS_STATE_ID
																		  group:PREF_GROUP_STATUS_PREFERENCES];
	[self _selectStatusWithUniqueID:targetUniqueStatusIDNumber inPopUpButton:popUp_fastUserSwitchingStatusState];	
	
	targetUniqueStatusIDNumber = [adium.preferenceController preferenceForKey:KEY_STATUS_SS_STATUS_STATE_ID
																		  group:PREF_GROUP_STATUS_PREFERENCES];
	[self _selectStatusWithUniqueID:targetUniqueStatusIDNumber inPopUpButton:popUp_screenSaverStatusState];	
}

/*!
 * @brief Add all items in inMenu to an array, returning the resulting array
 *
 * This method adds items deeply; that is, submenus and their contents are recursively included
 *
 * @param inMenu The menu to start from
 * @param recursiveArray The array thus far; if nil an array will be created
 *
 * @result All the menu items in inMenu
 */
- (NSMutableArray *)addItemsFromMenu:(NSMenu *)inMenu toArray:(NSMutableArray *)recursiveArray
{
	NSArray			*itemArray = [inMenu itemArray];
	NSMenuItem		*menuItem;

	if (!recursiveArray) recursiveArray = [NSMutableArray array];

	for (menuItem in itemArray) {
		[recursiveArray addObject:menuItem];

		if ([menuItem submenu]) {
			[self addItemsFromMenu:[menuItem submenu] toArray:recursiveArray];
		}
	}

	return recursiveArray;
}

/*!
 * @brief Select a status with uniqueID in inPopUpButton
 */
- (void)_selectStatusWithUniqueID:(NSNumber *)uniqueID inPopUpButton:(NSPopUpButton *)inPopUpButton
{
	NSMenuItem	*menuItem = nil;
	
	if (uniqueID) {
		NSInteger			 targetUniqueStatusID= [uniqueID integerValue];

		for (menuItem in [self addItemsFromMenu:[inPopUpButton menu] toArray:nil]) {
			AIStatusItem	*statusState;
			
			statusState = [[menuItem representedObject] objectForKey:@"AIStatus"];

			//Found the right status by matching its status ID to our preferred one
			if ([statusState preexistingUniqueStatusID] == targetUniqueStatusID) {
				break;
			}
		}
	}

	if (menuItem) {
		[inPopUpButton selectItem:menuItem];

		//Add it if we weren't able to select it initially
		if (![inPopUpButton selectedItem]) {
			[self addItemIfNeeded:menuItem toPopUpButton:inPopUpButton alreadyShowingAnItem:NO];
			
			if (inPopUpButton == popUp_autoAwayStatusState) {
				showingSubmenuItemInAutoAway = YES;
				
			} else if (inPopUpButton == popUp_fastUserSwitchingStatusState) {
				showingSubmenuItemInFastUserSwitching = YES;
				
			} else if (inPopUpButton == popUp_screenSaverStatusState) {
				showingSubmenuItemInScreenSaver = YES;
				
			}
		}
	}
}

/*!
 * @brief Configure control dimming for idle, auto-away, etc., preferences.
 */
- (void)configureControlDimming
{
	BOOL	idleControlsEnabled, autoAwayControlsEnabled;

	idleControlsEnabled = ([checkBox_idle state] == NSOnState);
	[textField_idleMinutes setEnabled:idleControlsEnabled];
	[stepper_idleMinutes setEnabled:idleControlsEnabled];
	
	autoAwayControlsEnabled = ([checkBox_autoAway state] == NSOnState);
	[popUp_autoAwayStatusState setEnabled:autoAwayControlsEnabled];
	[textField_autoAwayMinutes setEnabled:autoAwayControlsEnabled];
	[stepper_autoAwayMinutes setEnabled:autoAwayControlsEnabled];
	
	[popUp_fastUserSwitchingStatusState setEnabled:([checkBox_fastUserSwitching state] == NSOnState)];
	[popUp_screenSaverStatusState setEnabled:([checkBox_screenSaver state] == NSOnState)];
}

/*!
 * @brief Change preference
 *
 * Sent when controls are clicked
 */
- (void)changePreference:(id)sender
{
	if (sender == checkBox_idle) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_STATUS_REPORT_IDLE
											  group:PREF_GROUP_STATUS_PREFERENCES];
		[self configureControlDimming];
		
	} else if (sender == checkBox_autoAway) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_STATUS_AUTO_AWAY
											  group:PREF_GROUP_STATUS_PREFERENCES];
		[self configureControlDimming];
		
	} else if (sender == checkBox_showStatusWindow) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_STATUS_SHOW_STATUS_WINDOW
											  group:PREF_GROUP_STATUS_PREFERENCES];		
		
	} else if (sender == checkBox_fastUserSwitching) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_STATUS_FUS
											  group:PREF_GROUP_STATUS_PREFERENCES];
		[self configureControlDimming];
		
	} else if (sender == checkBox_screenSaver) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_STATUS_SS
											  group:PREF_GROUP_STATUS_PREFERENCES];
		[self configureControlDimming];
		
	}
}

/*!
 * @brief If menuItem is not selectable in popUpButton, add it and select it
 *
 * Menu items located within submenus can't be directly selected. This method will add a spearator item and then the item itself
 * to the bottom of popUpButton if needed.  alreadyShowing should be YES if a similarly set separate + item exists; it will be removed
 * first.
 *
 * @result YES if the item was added to popUpButton.
 */
- (BOOL)addItemIfNeeded:(NSMenuItem *)menuItem toPopUpButton:(NSPopUpButton *)popUpButton alreadyShowingAnItem:(BOOL)alreadyShowing
{
	BOOL	nowShowing = NO;
	NSMenu	*menu = [popUpButton menu];

	[menuItem retain];
	if (alreadyShowing) {
		NSInteger count = [menu numberOfItems];
		[menu removeItemAtIndex:--count];
		[menu removeItemAtIndex:--count];			
	}
	
	if ([popUpButton selectedItem] != menuItem) {
		NSMenuItem  *imitationMenuItem = [menuItem copy];
		
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItem:imitationMenuItem];
		
		[popUpButton selectItem:imitationMenuItem];
		[imitationMenuItem release];
		
		nowShowing = YES;
	}	
	[menuItem release];
	
	return nowShowing;
}
- (void)changedAutoAwayStatus:(id)sender
{
	AIStatus	*statusState = [[sender representedObject] objectForKey:@"AIStatus"];

	[adium.preferenceController setPreference:[statusState uniqueStatusID]
										 forKey:KEY_STATUS_AUTO_AWAY_STATUS_STATE_ID
										  group:PREF_GROUP_STATUS_PREFERENCES];

	showingSubmenuItemInAutoAway = [self addItemIfNeeded:sender
										   toPopUpButton:popUp_autoAwayStatusState
									alreadyShowingAnItem:showingSubmenuItemInAutoAway];
}

- (void)changedFastUserSwitchingStatus:(id)sender
{
	AIStatus	*statusState = [[sender representedObject] objectForKey:@"AIStatus"];

	[adium.preferenceController setPreference:[statusState uniqueStatusID]
										 forKey:KEY_STATUS_FUS_STATUS_STATE_ID
										  group:PREF_GROUP_STATUS_PREFERENCES];
	
	showingSubmenuItemInFastUserSwitching = [self addItemIfNeeded:sender
													toPopUpButton:popUp_fastUserSwitchingStatusState
											 alreadyShowingAnItem:showingSubmenuItemInFastUserSwitching];
}

- (void)changedScreenSaverStatus:(id)sender
{
	AIStatus	*statusState = [[sender representedObject] objectForKey:@"AIStatus"];
	
	[adium.preferenceController setPreference:[statusState uniqueStatusID]
										 forKey:KEY_STATUS_SS_STATUS_STATE_ID
										  group:PREF_GROUP_STATUS_PREFERENCES];
	
	showingSubmenuItemInScreenSaver = [self addItemIfNeeded:sender
													toPopUpButton:popUp_screenSaverStatusState
											 alreadyShowingAnItem:showingSubmenuItemInScreenSaver];
}

/*!
 * @brief Control text did end editing
 *
 * In an attempt to get closer to a live-apply of preferences, save the preference when the
 * text field loses focus.  See saveTimeValues for more information.
 */
- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	[self saveTimeValues];
}

/*!
 * @brief Save time text field values
 *
 * We can't get notified when the associated NSStepper is clicked, so we just save as requested.
 * This method should be called before the view closes.
 */
- (void)saveTimeValues
{
	[adium.preferenceController setPreference:[NSNumber numberWithDouble:([textField_idleMinutes doubleValue]*60.0)]
										 forKey:KEY_STATUS_REPORT_IDLE_INTERVAL
										  group:PREF_GROUP_STATUS_PREFERENCES];

	[adium.preferenceController setPreference:[NSNumber numberWithDouble:([textField_autoAwayMinutes doubleValue]*60.0)]
										 forKey:KEY_STATUS_AUTO_AWAY_INTERVAL
										  group:PREF_GROUP_STATUS_PREFERENCES];
}

@end
