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

#import "AIEmoticon.h"
#import "AIEmoticonPack.h"
#import "AIEmoticonPackPreviewController.h"
#import "AIEmoticonPackPreviewView.h"
#import "AIEmoticonPreferences.h"
#import "AIEmoticonController.h"
#import <AIUtilities/AITableViewAdditions.h>
#import <AIUtilities/AIGenericViewCell.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>

#import <Adium/AIListObject.h>

#define	EMOTICON_PACK_DRAG_TYPE         @"AIEmoticonPack"
#define EMOTICON_MIN_ROW_HEIGHT         17
#define EMOTICON_MAX_ROW_HEIGHT			64
#define EMOTICON_PACKS_TOOLTIP          AILocalizedString(@"Reorder emoticon packs by dragging. Packs are used in the order listed.",nil)

@interface AIEmoticonPreferences ()
- (void)_configureEmoticonListForSelection;
- (void)moveSelectedPacksToTrash;
- (void)configurePreviewControllers;

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)trashConfirmSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end

@implementation AIEmoticonPreferences

- (id)init
{
	if ((self = [super initWithWindowNibName:@"EmoticonPrefs"])) {
		
	}
	
	return self;
}

- (void)showOnWindow:(id)parentWindow
{
	[super showOnWindow:parentWindow];
	
	if (!parentWindow) {
		[self.window makeKeyAndOrderFront:nil];
		[NSApp activateIgnoringOtherApps:YES];
	}
}

/*!
* Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	viewIsOpen = NO;
	
	[adium.preferenceController unregisterPreferenceObserver:self];
    [adium.emoticonController flushEmoticonImageCache];
	
	[super sheetDidEnd:sheet returnCode:returnCode contextInfo:contextInfo];
}

//Configure the preference view
//- (void)viewDidLoad
- (void)windowDidLoad
{
	//Pack table
	[table_emoticonPacks registerForDraggedTypes:[NSArray arrayWithObject:EMOTICON_PACK_DRAG_TYPE]];
	
	//Configure the outline view
	[[table_emoticonPacks tableColumnWithIdentifier:@"Emoticons"] setDataCell:[[AIGenericViewCell alloc] init]];
	[table_emoticonPacks selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[table_emoticonPacks setToolTip:EMOTICON_PACKS_TOOLTIP];
	[table_emoticonPacks setDelegate:self];
	[table_emoticonPacks setDataSource:self];
	[self configurePreviewControllers];

    //Emoticons table
	selectedEmoticonPack = nil;
	checkCell = [[NSButtonCell alloc] init];
	[checkCell setButtonType:NSSwitchButton];
	[checkCell setControlSize:NSSmallControlSize];
	[checkCell setTitle:@""];
	[checkCell setRefusesFirstResponder:YES];
	[[table_emoticons tableColumnWithIdentifier:@"Enabled"] setDataCell:checkCell];

	NSImageCell *imageCell = [[NSImageCell alloc] initImageCell:nil];
	if ([imageCell respondsToSelector:@selector(_setAnimates:)]) [imageCell _setAnimates:NO];
	[[table_emoticons tableColumnWithIdentifier:@"Image"] setDataCell:imageCell];

	AIVerticallyCenteredTextCell *textCell = [[AIVerticallyCenteredTextCell alloc] init];
	[textCell setLineBreakMode:NSLineBreakByTruncatingTail];
	[[table_emoticons tableColumnWithIdentifier:@"Name"] setDataCell:textCell];
	
	textCell = [[AIVerticallyCenteredTextCell alloc] init];
	[textCell setLineBreakMode:NSLineBreakByTruncatingTail];
	[[table_emoticons tableColumnWithIdentifier:@"String"] setDataCell:textCell];

    [table_emoticons setUsesAlternatingRowBackgroundColors:YES];
        
    //Observe prefs    
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_EMOTICONS];
    
    //Configure the right pane to display the emoticons for the current selection
    [self _configureEmoticonListForSelection];

	[button_OK setLocalizedString:AILocalizedStringFromTable(@"Close", @"Buttons", nil)];
	[checkbox_emoticonMenu setTitle:AILocalizedString(@"Show the emoticon menu in the message entry bar", nil)];
	
	//Redisplay the emoticons after an small delay so the sample emoticons line up properly
	//since the desired width isn't known by AIEmoticonPackCell until once through the list of packs
	[table_emoticonPacks performSelector:@selector(display) withObject:nil afterDelay:0];
	
	viewIsOpen = YES;
}

- (void)windowWillClose:(id)sender
{
	viewIsOpen = NO;
	
	[adium.preferenceController unregisterPreferenceObserver:self];
    [adium.emoticonController flushEmoticonImageCache];
	
	[super windowWillClose:sender];
}

- (void)dealloc
{
	checkCell = nil;
	selectedEmoticonPack = nil;
	emoticonPackPreviewControllers = nil;
	[adium.preferenceController unregisterPreferenceObserver:self];
	emoticonImageCache = nil;

    //Flush all the images we loaded
    [adium.emoticonController flushEmoticonImageCache];
}

- (void)configurePreviewControllers
{
	//First, remove any AIEmoticonPackPreviewView instances from the table
	for (NSView *view in [[table_emoticonPacks subviews] copy]) {
		if ([view isKindOfClass:[AIEmoticonPackPreviewView class]]) {
			[view removeFromSuperviewWithoutNeedingDisplay];
		}
	}
	
	//Now [re]create the array of emoticon pack preview controlls
	emoticonPackPreviewControllers = [[NSMutableArray alloc] init];
	
	for (AIEmoticonPack *pack in [adium.emoticonController availableEmoticonPacks]) {
		[emoticonPackPreviewControllers addObject:[AIEmoticonPackPreviewController previewControllerForPack:pack
																								preferences:self]];
	}

	//Finally, reload
	[table_emoticonPacks reloadData];
}

//Configure the emoticon table view for the currently selected pack
- (void)_configureEmoticonListForSelection
{
    NSInteger         rowHeight = EMOTICON_MIN_ROW_HEIGHT;
	NSInteger			selectedRow = [table_emoticonPacks selectedRow];
	NSArray		*availableEmoticonPacks = [adium.emoticonController availableEmoticonPacks];
	
    //Remember the selected pack
    if ([table_emoticonPacks numberOfSelectedRows] == 1 &&
	   ((selectedRow != -1) && (selectedRow < [availableEmoticonPacks count]))) {
        selectedEmoticonPack = [availableEmoticonPacks objectAtIndex:selectedRow];
    } else {
        selectedEmoticonPack = nil;
    }

    //Set the row height to the average height of the emoticons
    if (selectedEmoticonPack) {
        NSInteger             totalHeight = 0;
        
        for (AIEmoticon *emoticon in [selectedEmoticonPack emoticons]) {
            totalHeight += [[emoticon image] size].height;
        }

        rowHeight = totalHeight / [[selectedEmoticonPack emoticons] count];
        if (rowHeight < EMOTICON_MIN_ROW_HEIGHT) rowHeight = EMOTICON_MIN_ROW_HEIGHT;
		if (rowHeight > EMOTICON_MAX_ROW_HEIGHT) rowHeight = EMOTICON_MAX_ROW_HEIGHT;
    }
    
	emoticonImageCache = [[NSMutableDictionary alloc] init];
	
    //Update the table
    [table_emoticons reloadData];
    [table_emoticons setRowHeight:rowHeight];

    //Update header
    if (selectedEmoticonPack) {
		//Enable the individual emoticon checks only if the selectedEmoticonPack is enabled
		[checkCell setEnabled:selectedEmoticonPack.isEnabled];
		
        [textField_packTitle setStringValue:[NSString stringWithFormat:AILocalizedString(@"Emoticons in %@","Emoticons in <an emoticon pack name>"),[selectedEmoticonPack name]]];
    } else {
        [textField_packTitle setStringValue:@""];
    }
}

//Reflect new preferences in view
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Refresh our emoticon tables
	[table_emoticonPacks reloadData];
	[self _configureEmoticonListForSelection];
}


//Returns a dimmed, attributed version of the passed string
- (NSAttributedString *)_dimString:(NSString *)inString center:(BOOL)center
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
    
    if (center) {
        [attributes setObject:[NSParagraphStyle styleWithAlignment:NSCenterTextAlignment]
		       forKey:NSParagraphStyleAttributeName];
    }

    return [[NSAttributedString alloc] initWithString:inString attributes:attributes];
}

#pragma mark Table view data source
//Emoticon table view
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == table_emoticonPacks) {
        return [emoticonPackPreviewControllers count];
    } else {
        return [[selectedEmoticonPack emoticons] count];
    }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == table_emoticonPacks) {
		[cell setEmbeddedView:[[emoticonPackPreviewControllers objectAtIndex:row] view]];
	}
}

//Emoticon table view delegates
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == table_emoticonPacks)
		return @"";

	NSString    *identifier = [tableColumn identifier];
	AIEmoticon  *emoticon = [[selectedEmoticonPack emoticons] objectAtIndex:row];
	
	if ([identifier isEqualToString:@"Enabled"])
		return [NSNumber numberWithBool:emoticon.isEnabled]; 
		
	if ([identifier isEqualToString:@"Image"]) {
		NSNumber *key = [NSNumber numberWithUnsignedInteger:[emoticon hash]];
		NSImage	*image = [emoticonImageCache objectForKey:key];
		if (!image) {
			image = [emoticon image];
			if (image)
				[emoticonImageCache setObject:image forKey:key];
		}
		
		return image;
	}
	
	if ([identifier isEqualToString:@"Name"]) {
		if (selectedEmoticonPack.isEnabled && emoticon.isEnabled)
			return emoticon.name;
		
		return [self _dimString:emoticon.name center:NO];
	} 
	
	// if ([identifier compare:@"String"] == NSOrderedSame) {
	NSArray *textEquivalents = [emoticon textEquivalents];
	if ([textEquivalents count]) {
		if (selectedEmoticonPack.isEnabled && emoticon.isEnabled)
			return [textEquivalents objectAtIndex:0];
		
		return [self _dimString:[textEquivalents objectAtIndex:0] center:YES];
	}
	
	return @"";
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == table_emoticons && [@"Enabled" isEqualToString:[tableColumn identifier]])		
		[adium.emoticonController setEmoticon:[[selectedEmoticonPack emoticons] objectAtIndex:row] inPack:selectedEmoticonPack enabled:[object integerValue]];
}

#pragma mark Drag and Drop


- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	if (tableView != table_emoticonPacks)
		return NO;
	
	dragRows = rowIndexes;
	[pboard declareTypes:[NSArray arrayWithObject:EMOTICON_PACK_DRAG_TYPE] owner:self];
	[pboard setString:@"dragPack" forType:EMOTICON_PACK_DRAG_TYPE];

	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op;
{
	if (tableView == table_emoticonPacks && op == NSTableViewDropAbove && row != -1)
		return NSDragOperationMove;
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op;
{
	if (tableView != table_emoticonPacks)
		return NO;
	
	NSString	*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:EMOTICON_PACK_DRAG_TYPE]];

	if (![availableType isEqualToString:EMOTICON_PACK_DRAG_TYPE])
		return NO;

	//Move
	NSMutableArray  *movedPacks = [NSMutableArray array]; //Keep track of the packs we've moved
	[dragRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[movedPacks addObject:[[emoticonPackPreviewControllers objectAtIndex:idx] emoticonPack]];
	}];
	[adium.emoticonController moveEmoticonPacks:movedPacks toIndex:row];
	
	[self configurePreviewControllers];

	//Select the moved packs
	[tableView deselectAll:nil];
	for (AIEmoticonPackPreviewController *previewController in emoticonPackPreviewControllers) {
		//If the moved packs contains this preview controller's pack, select it, wherever it may be
		AIEmoticonPack	*emoticonPack = [previewController emoticonPack];
		if ([movedPacks containsObjectIdenticalTo:emoticonPack]) {
			[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[emoticonPackPreviewControllers indexOfObject:previewController]] byExtendingSelection:NO];					
		}
	}

	return YES;
}

/*
- (void)tableViewSelectionIsChanging:(NSNotification *)notification
{
    if ([notification object] == table_emoticonPacks) {
        [self _configureEmoticonListForSelection];
    } else {
        //I don't want the emoticon table to display its selection.
        //Returning NO from 'shouldSelectRow' would work, but if we do that
        //the checkbox cells stop working.  The best solution I've come up with
        //so far is to just force a deselect here :( .
        [table_emoticons deselectAll:nil];
    }
}
*/

#pragma mark Deletion


- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	//Prevent deleting included packs
	NSRange range = [selectedEmoticonPack.path rangeOfString:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Emoticons"]];
	if (range.length > 0)
		NSBeep();
	else
		[self moveSelectedPacksToTrash];
}

-(void)moveSelectedPacksToTrash
{
	NSString	*name = [selectedEmoticonPack.name copy];
    NSBeginAlertSheet(AILocalizedString(@"Delete Emoticon Pack",nil),
					  AILocalizedString(@"Delete",nil),
					  AILocalizedString(@"Cancel",nil),
					  @"",
					  [self window],
					  self, 
                      @selector(trashConfirmSheetDidEnd:returnCode:contextInfo:), nil, nil, 
                      AILocalizedString(@"Are you sure you want to delete the %@ Emoticon Pack? It will be moved to the Trash.",nil), name);
}

- (void)trashConfirmSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode != NSOKButton)
		return;
	
	for (AIEmoticonPackPreviewController *previewController in [table_emoticonPacks selectedItemsFromArray:emoticonPackPreviewControllers]) {
		[[NSFileManager defaultManager] trashFileAtPath:previewController.emoticonPack.path];
	}

	[table_emoticonPacks deselectAll:nil];
	//Note the changed packs
	[adium.emoticonController xtrasChanged:nil];
}

#pragma mark Selection changes
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if ([notification object] == table_emoticonPacks) {
        [self _configureEmoticonListForSelection];
    } else {
        //I don't want the emoticon table to display its selection.
        //Returning NO from 'shouldSelectRow' would work, but if we do that
        //the checkbox cells stop working.  The best solution I've come up with
        //so far is to just force a deselect here :( .
        [table_emoticons deselectAll:nil];
    }
}

- (void)toggledPackController:(id)packController
{
	[table_emoticonPacks selectRowIndexes:[NSIndexSet indexSetWithIndex:[emoticonPackPreviewControllers indexOfObject:packController]] byExtendingSelection:NO];					
}

- (void)emoticonXtrasDidChange
{
	if (viewIsOpen)
		[self configurePreviewControllers];
}

@end
