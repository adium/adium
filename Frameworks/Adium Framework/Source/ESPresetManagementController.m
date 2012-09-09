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

#import <Adium/ESPresetManagementController.h>

#define	PRESET_DRAG_TYPE @"Adium:PresetDrag"

@interface ESPresetManagementController ()
- (void)configureControlDimming;
- (void)tableViewSelectionDidChange:(NSNotification *)notification;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

/*!
 * @class ESPresetManagementController
 * @brief Generic controller for managing presets
 */
@implementation ESPresetManagementController

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
		[NSApp activateIgnoringOtherApps:YES];
	}
}


/*!
 * @brief Begin managing presets
 *
 * @param inPresets An array of either NSString or NSDictionary objects.
 * @param inNameKey If inPresets contains NSDictionary objects, the key used to look up the name ot present to the user.
 * @param inDelegate The delegate for preset management.  It must implement all methods in the ESPresetManagementControllerDelegate informal protocol.
 */
- (id)initWithPresets:(NSArray *)inPresets namedByKey:(NSString *)inNameKey withDelegate:(id)inDelegate
{
	
	NSParameterAssert([inDelegate respondsToSelector:@selector(renamePreset:toName:inPresets:renamedPreset:)]);
	NSParameterAssert([inDelegate respondsToSelector:@selector(duplicatePreset:inPresets:createdDuplicate:)]);
	NSParameterAssert([inDelegate respondsToSelector:@selector(deletePreset:inPresets:)]);
	
    if ((self = [super initWithWindowNibName:@"PresetManagement"])) {
		presets = inPresets;
		nameKey = inNameKey;
		delegate = inDelegate;
	}
	
	return self;	
}

/*!
 * @brief Window did load
 */
- (void)windowDidLoad
{
	//Enable dragging of presets
	[tableView_presets registerForDraggedTypes:[NSArray arrayWithObject:PRESET_DRAG_TYPE]];

	[label_editPresets setLocalizedString:AILocalizedString(@"Edit presets:", nil)];
	
	[button_duplicate setAlignment:NSLeftTextAlignment];
	[button_duplicate setLocalizedString:AILocalizedString(@"Duplicate", "Button which duplicates the selection")];
	[button_duplicate setAlignment:NSCenterTextAlignment];

	[button_delete setAlignment:NSLeftTextAlignment];
	[button_delete setLocalizedString:AILocalizedString(@"Delete", "Button which deletes the selection")];
	[button_delete setAlignment:NSCenterTextAlignment];
	
	[button_rename setAlignment:NSLeftTextAlignment];
	[button_rename setLocalizedString:AILocalizedString(@"Rename", "Button which renames the selection")];
	[button_rename setAlignment:NSCenterTextAlignment];

	[button_done setAlignment:NSLeftTextAlignment];
	[button_done setLocalizedString:AILocalizedString(@"Done", "Button which indicates that the editing sheet is done")];
	[button_done setAlignment:NSCenterTextAlignment];
	
	[self configureControlDimming];
}

/*!
 * @brief Okay
 *
 * Close the window
 */
- (IBAction)okay:(id)sender
{
	
	[self closeWindow:nil];
}

/*!
 * Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
    [sheet orderOut:nil];
}

/*!
 * @brief As the window closes, release this controller instance
 *
 * The instance retained itself (rather, was not autoreleased when created) so it could function independently.
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
}

/*!
 * @brief Duplicate the selected preset
 */
- (IBAction)duplicatePreset:(id)sender
{
	NSInteger selectedRow = [tableView_presets selectedRow];
	if (selectedRow != -1) {
		id duplicatePreset, selectedPreset;
		NSInteger duplicatePresetIndex;
		
		//Finish any editing before continuing		
		//[tableView_presets validateEditing] doesn't work?
		[tableView_presets validateEditing];
		[tableView_presets abortEditing];

		selectedPreset = [presets objectAtIndex:selectedRow];
		
		//Inform the delegate of the duplicate request
		NSArray	*newPresets;
		newPresets = [delegate duplicatePreset:selectedPreset 
									 inPresets:presets
							  createdDuplicate:&duplicatePreset];
		
		presets = newPresets;
		
		//The delegate returned a potentially changed presets array; reload table data
		[tableView_presets reloadData];

		//Set up for a rename of the new duplicate if possible
		if (duplicatePreset) {
			duplicatePresetIndex = [presets indexOfObject:duplicatePreset];
			if (duplicatePresetIndex != NSNotFound) {
				[tableView_presets selectRowIndexes:[NSIndexSet indexSetWithIndex:duplicatePresetIndex] byExtendingSelection:NO];
				[tableView_presets editColumn:0
										  row:duplicatePresetIndex
									withEvent:nil
									   select:YES];
			}
		} else {
			NSLog(@"Failed to retrieve duplicate preset while duplicating %@ in %@",selectedPreset,presets);
		}
	}	
}

/*!
 * @brief Delete the selected preset
 */
- (IBAction)deletePreset:(id)sender
{
	NSInteger selectedRow = [tableView_presets selectedRow];
	if (selectedRow != -1) {
		//Abort any editing before continuing
		[tableView_presets abortEditing];

		id selectedPreset = [presets objectAtIndex:selectedRow];

		//Inform the delegate of the deletion
		NSArray	*newPresets;
		newPresets = [delegate deletePreset:selectedPreset inPresets:presets];
		presets = newPresets;
		
		//The delegate returned a potentially changed presets array; reload table data
		[tableView_presets reloadData];
		
		//Reloading after the deletion changed our selection
		[self tableViewSelectionDidChange:nil];
	}
}

/*!
 * @brief Rename the selected preset
 */
- (IBAction)renamePreset:(id)sender
{
	NSInteger selectedRow = [tableView_presets selectedRow];
	if (selectedRow != -1) {
		[tableView_presets editColumn:0 row:selectedRow withEvent:nil select:YES];
	}
}

/*!
 * @brief Configure control dimming
 */
- (void)configureControlDimming
{
	NSInteger selectedRow = [tableView_presets selectedRow];
	
	if (selectedRow != -1) {
		id	preset = [presets objectAtIndex:selectedRow];
		BOOL	allowDelete = (![delegate respondsToSelector:@selector(allowDeleteOfPreset:)] ||
							   [delegate allowDeleteOfPreset:preset]);
		BOOL	allowRename = (![delegate respondsToSelector:@selector(allowRenameOfPreset:)] ||
							   [delegate allowRenameOfPreset:preset]);

		[button_delete setEnabled:allowDelete];
		[button_rename setEnabled:allowRename];
		
		//Always allow duplication
		[button_duplicate setEnabled:YES];
		
	} else {
		[button_duplicate setEnabled:NO];
		[button_delete setEnabled:NO];
		[button_rename setEnabled:NO];
	}
}

#pragma mark Table view data source and delegate

//State List Table Delegate --------------------------------------------------------------------------------------------
#pragma mark State List (Table Delegate)
/*!
 * @brief Number of rows
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [presets count];
}

/*!
 * @brief Table values
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id	preset = [presets objectAtIndex:row];

	if ([preset isKindOfClass:[NSDictionary class]]) {
		return [preset objectForKey:(nameKey ? nameKey : @"Name")];
		
	} else if ([preset isKindOfClass:[NSString class]]) {
		return preset;
	}
	
	return @"";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row
{
	if ([anObject isKindOfClass:[NSString class]]) {
		id			preset = [presets objectAtIndex:row];
		NSString	*oldName = nil;

		if ([preset isKindOfClass:[NSDictionary class]]) {
			oldName = [preset objectForKey:(nameKey ? nameKey : @"Name")];

		} else if ([preset isKindOfClass:[NSString class]]) {
			oldName = preset;
		}

		if (![(NSString *)anObject isEqualToString:oldName]) {
			//Inform the delegate of the rename
			NSArray	*newPresets;
			id			renamedPreset;
			
			newPresets = [delegate renamePreset:preset toName:(NSString *)anObject inPresets:presets renamedPreset:&renamedPreset];
			presets = newPresets;
			
			//The delegate returned a potentially changed presets array; reload table data
			[tableView_presets reloadData];
						
			//Select the new row
			[tableView_presets selectRowIndexes:[NSIndexSet indexSetWithIndex:[presets indexOfObjectIdenticalTo:renamedPreset]] byExtendingSelection:NO];
		}
	}		
}

/*!
 * @brief Delete the selected row
 */
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deletePreset:nil];
}

/*!
 * @brief Selection change
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self configureControlDimming];
}

/*!
 * @brief Drag start
 *
 * Only allow the drag to start if the delegate responds to @selector(movePreset:toIndex:inPresets:)
 */
- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	if ([delegate respondsToSelector:@selector(movePreset:toIndex:inPresets:presetAfterMove:)]) {
		tempDragPreset = [presets objectAtIndex:[rowIndexes firstIndex]];
		
		[pboard declareTypes:[NSArray arrayWithObject:PRESET_DRAG_TYPE] owner:self];
		[pboard setString:@"Preset" forType:PRESET_DRAG_TYPE]; //Arbitrary state
		
		return YES;
	} else {
		return NO;
	}
}

/*!
 * @brief Drag validate
 */
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if (op == NSTableViewDropAbove && row != -1) {
        return NSDragOperationPrivate;
    } else {
        return NSDragOperationNone;
    }
}

/*!
 * @brief Drag complete
 */
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
    NSString	*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:PRESET_DRAG_TYPE]];
	BOOL		success = NO;
    if ([availableType isEqualToString:PRESET_DRAG_TYPE]) {		
		NSDictionary	*presetAfterMove = tempDragPreset;
		
		//Inform the delegate of the move; it may pass back a changed preset by reference
		NSArray	*newPresets;
		newPresets = [delegate movePreset:tempDragPreset toIndex:row inPresets:presets presetAfterMove:&presetAfterMove];
		presets = newPresets;

		//Reload with the new data
		[tableView_presets reloadData];
		
		//Reselect the moved preset if possible
		NSInteger movedPresetIndex = [presets indexOfObject:presetAfterMove];
		if (movedPresetIndex != NSNotFound) {
			[tableView_presets selectRowIndexes:[NSIndexSet indexSetWithIndex:movedPresetIndex] byExtendingSelection:NO];
		}

        success = YES;
    }
	
	tempDragPreset = nil;
	
	return success;
}

@end
