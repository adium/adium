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
#import <AIUtilities/AIAlternatingRowTableView.h>
#import <AIUtilities/AITableViewAdditions.h>
#import <AIUtilities/AIGenericViewCell.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>

#import <Adium/AIListObject.h>
#import <Adium/AIPreferenceControllerProtocol.h>

#define	EMOTICON_PACK_DRAG_TYPE         @"AIEmoticonPack"
#define EMOTICON_MIN_ROW_HEIGHT         17
#define EMOTICON_MAX_ROW_HEIGHT			64
#define EMOTICON_PACKS_TOOLTIP          AILocalizedString(@"Reorder emoticon packs by dragging. Packs are used in the order listed.",nil)

@interface AIEmoticonPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureEmoticonListForSelection;
- (void)moveSelectedPacksToTrash;
- (void)configurePreviewControllers;
@end

@implementation AIEmoticonPreferences

+ (void)showEmoticionCustomizationOnWindow:(NSWindow *)parentWindow
{
	AIEmoticonPreferences	*controller;
	
	controller = [[self alloc] initWithWindowNibName:@"EmoticonPrefs"];
	
	if (parentWindow) {
		[NSApp beginSheet:[controller window]
		   modalForWindow:parentWindow
			modalDelegate:controller
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	} else {
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];
		[NSApp activateIgnoringOtherApps:YES];
	}
}

/*!
* Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//Configure the preference view
//- (void)viewDidLoad
- (void)windowDidLoad
{
    //Pack table
    [table_emoticonPacks registerForDraggedTypes:[NSArray arrayWithObject:EMOTICON_PACK_DRAG_TYPE]];
	
	//Configure the outline view
	[table_emoticonPacks setDrawsGradientSelection:YES];
	[[table_emoticonPacks tableColumnWithIdentifier:@"Emoticons"] setDataCell:[[[AIGenericViewCell alloc] init] autorelease]];
	[table_emoticonPacks selectRow:0 byExtendingSelection:NO];
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
	[checkCell release];

	NSImageCell *imageCell = [[NSImageCell alloc] initImageCell:nil];
	if ([imageCell respondsToSelector:@selector(_setAnimates:)]) [imageCell _setAnimates:NO];
	[[table_emoticons tableColumnWithIdentifier:@"Image"] setDataCell:imageCell];
	[imageCell release];

	AIVerticallyCenteredTextCell *textCell = [[AIVerticallyCenteredTextCell alloc] init];
	[textCell setLineBreakMode:NSLineBreakByTruncatingTail];
	[[table_emoticons tableColumnWithIdentifier:@"Name"] setDataCell:textCell];
	[textCell release];
	
	textCell = [[AIVerticallyCenteredTextCell alloc] init];
	[textCell setLineBreakMode:NSLineBreakByTruncatingTail];
	[[table_emoticons tableColumnWithIdentifier:@"String"] setDataCell:textCell];
	[textCell release];

    [table_emoticons setUsesAlternatingRowBackgroundColors:YES];
        
    //Observe prefs    
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_EMOTICONS];
    
    //Configure the right pane to display the emoticons for the current selection
    [self _configureEmoticonListForSelection];

	[button_OK setLocalizedString:AILocalizedStringFromTable(@"Close", @"Buttons", nil)];
	
	//Redisplay the emoticons after an small delay so the sample emoticons line up properly
	//since the desired width isn't known by AIEmoticonPackCell until once through the list of packs
	[table_emoticonPacks performSelector:@selector(display) withObject:nil afterDelay:0.0001];
	
	viewIsOpen = YES;
}

- (void)windowWillClose:(id)sender
{
	viewIsOpen = NO;

	[checkCell release]; checkCell = nil;
	[selectedEmoticonPack release]; selectedEmoticonPack = nil;
	[emoticonPackPreviewControllers release]; emoticonPackPreviewControllers = nil;
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[emoticonImageCache release]; emoticonImageCache = nil;

    //Flush all the images we loaded
    [[adium emoticonController] flushEmoticonImageCache];
}

- (void)configurePreviewControllers
{
	NSEnumerator	*enumerator;
	AIEmoticonPack	*pack;
	NSView			*view;
	
	//First, remove any AIEmoticonPackPreviewView instances from the table
	enumerator = [[[[table_emoticonPacks subviews] copy] autorelease] objectEnumerator];
	while ((view = [enumerator nextObject])) {
		if ([view isKindOfClass:[AIEmoticonPackPreviewView class]]) {
			[view removeFromSuperviewWithoutNeedingDisplay];
		}
	}
	
	//Now [re]create the array of emoticon pack preview controlls
	[emoticonPackPreviewControllers release];
	emoticonPackPreviewControllers = [[NSMutableArray alloc] init];
	
	enumerator = [[[adium emoticonController] availableEmoticonPacks] objectEnumerator];
	while ((pack = [enumerator nextObject])) {
		[emoticonPackPreviewControllers addObject:[AIEmoticonPackPreviewController previewControllerForPack:pack
																								preferences:self]];
	}

	//Finally, reload
	[table_emoticonPacks reloadData];
}

//Configure the emoticon table view for the currently selected pack
- (void)_configureEmoticonListForSelection
{
    int         rowHeight = EMOTICON_MIN_ROW_HEIGHT;
	int			selectedRow = [table_emoticonPacks selectedRow];
	NSArray		*availableEmoticonPacks = [[adium emoticonController] availableEmoticonPacks];
	
    //Remember the selected pack
    if ([table_emoticonPacks numberOfSelectedRows] == 1 &&
	   ((selectedRow != -1) && (selectedRow < [availableEmoticonPacks count]))) {
		[selectedEmoticonPack release];
        selectedEmoticonPack = [[availableEmoticonPacks objectAtIndex:selectedRow] retain];
    } else {
        selectedEmoticonPack = nil;
    }

    //Set the row height to the average height of the emoticons
    if (selectedEmoticonPack) {
        NSEnumerator    *enumerator;
        AIEmoticon      *emoticon;
        int             totalHeight = 0;
        
        enumerator = [[selectedEmoticonPack emoticons] objectEnumerator];
        while ((emoticon = [enumerator nextObject])) {
            totalHeight += [[emoticon image] size].height;
        }

        rowHeight = totalHeight / [[selectedEmoticonPack emoticons] count];
        if (rowHeight < EMOTICON_MIN_ROW_HEIGHT) rowHeight = EMOTICON_MIN_ROW_HEIGHT;
		if (rowHeight > EMOTICON_MAX_ROW_HEIGHT) rowHeight = EMOTICON_MAX_ROW_HEIGHT;
    }
    
	[emoticonImageCache release];
	emoticonImageCache = [[NSMutableDictionary alloc] init];
	
    //Update the table
    [table_emoticons reloadData];
    [table_emoticons setRowHeight:rowHeight];

    //Update header
    if (selectedEmoticonPack) {
		//Enable the individual emoticon checks only if the selectedEmoticonPack is enabled
		[checkCell setEnabled:[selectedEmoticonPack isEnabled]];
		
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

    return [[[NSAttributedString alloc] initWithString:inString attributes:attributes] autorelease];
}

#pragma mark Table view data source
//Emoticon table view
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == table_emoticonPacks) {
        return [emoticonPackPreviewControllers count];
    } else {
        return [[selectedEmoticonPack emoticons] count];
    }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if (tableView == table_emoticonPacks) {
		[cell setEmbeddedView:[[emoticonPackPreviewControllers objectAtIndex:row] view]];
	}
}

//Emoticon table view delegates
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if (tableView == table_emoticonPacks) {
		
		return @"";
			
    } else {
		NSString    *identifier = [tableColumn identifier];
        AIEmoticon  *emoticon = [[selectedEmoticonPack emoticons] objectAtIndex:row];
        
        if ([identifier isEqualToString:@"Enabled"]) {
            return [NSNumber numberWithBool:[emoticon isEnabled]];
            
        } else if ([identifier isEqualToString:@"Image"]) {
			NSNumber *key = [NSNumber numberWithUnsignedInt:[emoticon hash]];
			NSImage	*image = [emoticonImageCache objectForKey:key];
			if (!image) {
				image = [emoticon image];
				if (image) {
					[emoticonImageCache setObject:image
										   forKey:key];
				}
			}
			
			return image;
	
		} else if ([identifier isEqualToString:@"Name"]) {
            if ([selectedEmoticonPack isEnabled] && [emoticon isEnabled]) {
				return [emoticon name];
            } else {
				return [self _dimString:[emoticon name] center:NO];
			}
            
        } else {// if ([identifier compare:@"String"] == NSOrderedSame) {
			NSArray *textEquivalents = [emoticon textEquivalents];
			if ([textEquivalents count]) {
				if ([selectedEmoticonPack isEnabled] && [emoticon isEnabled]) {
					return [textEquivalents objectAtIndex:0];
				} else {
					return [self _dimString:[textEquivalents objectAtIndex:0] center:YES];
				}
			} else {
				return @"";
			}
        }

    }
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (tableView == table_emoticons && [@"Enabled" isEqualToString:[tableColumn identifier]]) {
		AIEmoticon  *emoticon = [[selectedEmoticonPack emoticons] objectAtIndex:row];
		
		[[adium emoticonController] setEmoticon:emoticon inPack:selectedEmoticonPack enabled:[object intValue]];
	}
}

#pragma mark Drag and Drop


- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    if (tableView == table_emoticonPacks) {
        dragRows = rows;        
        [pboard declareTypes:[NSArray arrayWithObject:EMOTICON_PACK_DRAG_TYPE] owner:self];
        [pboard setString:@"dragPack" forType:EMOTICON_PACK_DRAG_TYPE];
        
        return YES;
    } else {
        return NO;
    }
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
{
    if (tableView == table_emoticonPacks) {
        if (op == NSTableViewDropAbove && row != -1) {
            return NSDragOperationMove;
        } else {
            return NSDragOperationNone;
        }
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;
{
    if (tableView == table_emoticonPacks) {
        NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:EMOTICON_PACK_DRAG_TYPE]];
        
        if ([avaliableType isEqualToString:EMOTICON_PACK_DRAG_TYPE]) {
            NSMutableArray  *movedPacks = [NSMutableArray array]; //Keep track of the packs we've moved
            NSEnumerator    *enumerator;
            NSNumber        *dragRow;
			
            AIEmoticonPackPreviewController  *previewController;
            
            //Move
            enumerator = [dragRows objectEnumerator];
            while ((dragRow = [enumerator nextObject])) {
                [movedPacks addObject:[[emoticonPackPreviewControllers objectAtIndex:[dragRow intValue]] emoticonPack]];
            }
            [[adium emoticonController] moveEmoticonPacks:movedPacks toIndex:row];
            
			[self configurePreviewControllers];
			
            //Select the moved packs
            [tableView deselectAll:nil];
            enumerator = [emoticonPackPreviewControllers objectEnumerator];
            while ((previewController = [enumerator nextObject])) {
				//If the moved packs contains this preview controller's pack, select it, wherever it may be
				AIEmoticonPack	*emoticonPack = [previewController emoticonPack];
				if ([movedPacks indexOfObjectIdenticalTo:emoticonPack] != NSNotFound) {
					[tableView selectRow:[emoticonPackPreviewControllers indexOfObject:previewController] byExtendingSelection:NO];					
				}
            }
            
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
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
	NSRange range = [[selectedEmoticonPack path] rangeOfString:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Emoticons"]];
	if (range.length > 0)
		NSBeep();
	else{
		[self moveSelectedPacksToTrash];
	}
}

-(void)moveSelectedPacksToTrash
{
	NSString	*name = [[[selectedEmoticonPack name] copy] autorelease];
    NSBeginAlertSheet(AILocalizedString(@"Delete Emoticon Pack",nil),
					  AILocalizedString(@"Delete",nil),
					  AILocalizedString(@"Cancel",nil),
					  @"",
					  [self window],
					  self, 
                      @selector(trashConfirmSheetDidEnd:returnCode:contextInfo:), nil, nil, 
                      AILocalizedString(@"Are you sure you want to delete the %@ Emoticon Pack? It will be moved to the Trash.",nil), name);
}

- (void)trashConfirmSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton) {
        NSEnumerator *enumerator = [[table_emoticonPacks arrayOfSelectedItemsUsingSourceArray:emoticonPackPreviewControllers] objectEnumerator];
        
		AIEmoticonPackPreviewController		*previewController;
        while ((previewController = [enumerator nextObject])) {

            NSString *currentEPPath = [[previewController emoticonPack] path];

			//trash it
            [[NSFileManager defaultManager] trashFileAtPath:currentEPPath];
		}

		[table_emoticonPacks deselectAll:nil];
		//Note the changed packs
        [[adium emoticonController] xtrasChanged:nil];
    }
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
	[table_emoticonPacks selectRow:[emoticonPackPreviewControllers indexOfObject:packController] byExtendingSelection:NO];					
}

- (void)emoticonXtrasDidChange
{
	if (viewIsOpen) {
		[self configurePreviewControllers];
	}
}

@end
