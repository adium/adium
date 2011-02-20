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

#import "AMPurpleSearchResultsController.h"


@implementation AMPurpleSearchResultsController

- (id)initWithPurpleConnection:(PurpleConnection*)_gc title:(NSString*)title primaryText:(NSString*)primary secondaryText:(NSString*)secondary searchResults:(PurpleNotifySearchResults*)results userData:(gpointer)_user_data {
    if((self = [super initWithWindowNibName:@"AMPurpleSearchResultsWindow"])) {
		[[self window] setTitle:title?title:AILocalizedString(@"Search Results",nil)];
		[textfield_primary setStringValue:primary?primary:@""];
		[textfield_secondary setStringValue:secondary?secondary:@""];
		
		gc = _gc;
		purpleresults = results;
		
		// add the action buttons
		CGFloat offset = [buttonview frame].size.width - 20.0f;
		searchButtons = [[NSMutableDictionary alloc] init];
		GList *but;
		for(but = results->buttons; but; but = g_list_next(but)) {
			PurpleNotifySearchButton *button = but->data;
			NSString *buttonTitle = nil;
			switch(button->type) {
				case PURPLE_NOTIFY_BUTTON_LABELED:
					if(button->label)
						buttonTitle = [NSString stringWithUTF8String:button->label];
					break;
				case PURPLE_NOTIFY_BUTTON_CONTINUE:
					buttonTitle = AILocalizedString(@"Continue",nil);
					break;
				case PURPLE_NOTIFY_BUTTON_ADD:
					buttonTitle = AILocalizedString(@"Add",nil);
					break;
				case PURPLE_NOTIFY_BUTTON_INFO:
					buttonTitle = AILocalizedString(@"Info",nil);
					break;
				case PURPLE_NOTIFY_BUTTON_IM:
					buttonTitle = AILocalizedString(@"Send Message",nil);
					break;
				case PURPLE_NOTIFY_BUTTON_JOIN:
					buttonTitle = AILocalizedString(@"Join",nil);
					break;
				case PURPLE_NOTIFY_BUTTON_INVITE:
					buttonTitle = AILocalizedString(@"Invite",nil);
					break;
			}
			NSButton *newbutton = [[NSButton alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 100.0f, 100.0f)];
			[newbutton setTitle:buttonTitle];
			[[newbutton cell] setControlSize:NSRegularControlSize];
			[newbutton setTarget:self];
			[newbutton setAction:@selector(invokeAction:)];
			[newbutton setBordered:YES];
			[newbutton setBezelStyle:NSRoundedBezelStyle];
			[newbutton setImagePosition:NSNoImage];
			[newbutton setAlignment:NSCenterTextAlignment];
			[[newbutton cell] setControlTint:NSDefaultControlTint];
			[newbutton setButtonType:NSMomentaryPushInButton];
			// determine ideal size
			NSSize minsize = [[newbutton cell] cellSize];
			
			offset -= minsize.width + 20.0f;
			
			[buttonview addSubview:newbutton];
			[newbutton setFrame:NSMakeRect(offset, 0.0f, minsize.width + 20.0f, minsize.height)];
			[newbutton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
			
			[searchButtons setObject:[NSValue valueWithPointer:button] forKey:[NSValue valueWithNonretainedObject:newbutton]];
			
			[newbutton release];
			offset -= 20.0f;
		}
		
		// remove all columns (it's not possible to create a table without any columns in IB
		while([tableview numberOfColumns] > 0)
			[tableview removeTableColumn:[[tableview tableColumns] objectAtIndex:0]];
		
		// add the ones we need
		NSUInteger idx = 0;
		GList *column;
		for(column = results->columns; column; column = g_list_next(column)) {
			PurpleNotifySearchColumn *scol = column->data;
			NSTableColumn *tcol = [[NSTableColumn alloc] initWithIdentifier:[NSNumber numberWithUnsignedInteger:idx++]];
			
			if(scol->title)
				[[tcol headerCell] setStringValue:[NSString stringWithUTF8String:scol->title]];
			[tableview addTableColumn:tcol];
			[tcol release];
		}
		
		// convert the rows
		searchResults = [[NSMutableArray alloc] init];
		
		GList *row;
		for(row = results->rows; row; row = g_list_next(row)) {
			NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
			NSUInteger col = 0;
			[searchResults addObject:dict];
			GList *cell;
			for(cell = row->data; cell; cell = g_list_next(cell)) {
				const char *text = cell->data;
				if(text)
					[dict setObject:[NSString stringWithUTF8String:text] forKey:[NSNumber numberWithUnsignedInteger:col++]];
			}
			[dict release];
		}
		
		[tableview reloadData];
		[tableview sizeToFit];
		[self showWindow:nil];
		[self tableViewSelectionDidChange:nil];
	}
	return [self retain]; // will be released in -purpleRequestClose when we're done
}

- (void)dealloc {
	[searchButtons release];
	[searchResults release];
	[super dealloc];
}

- (void)addResults:(PurpleNotifySearchResults*)results {
	GList *row;
	for(row = results->rows; row; row = g_list_next(row)) {
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		NSUInteger col = 0;
		[searchResults addObject:dict];
		GList *cell;
		for(cell = row->data; cell; cell = g_list_next(cell)) {
			const char *text = cell->data;
			if(text)
				[dict setObject:[NSString stringWithUTF8String:text] forKey:[NSNumber numberWithUnsignedInteger:col++]];
		}
		[dict release];
	}
	
	[tableview reloadData];
	[tableview sizeToFit];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [searchResults count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return [[searchResults objectAtIndex:row] objectForKey:[tableColumn identifier]];
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	BOOL enabled = [tableview numberOfSelectedRows] > 0;
	for (NSValue *buttonval in searchButtons) {
		[(NSButton *)[buttonval nonretainedObjectValue] setEnabled:enabled];
	}
}

- (BOOL)windowShouldClose:(id)sender {
	purple_notify_close(PURPLE_NOTIFY_SEARCHRESULTS, self);
	return windowIsClosing;
}

- (IBAction)invokeAction:(id)sender {
	PurpleNotifySearchButton *button = [[searchButtons objectForKey:[NSValue valueWithNonretainedObject:sender]] pointerValue];
	if(!button) {
		NSBeep();
		return;
	}
	NSInteger row = [tableview selectedRow];
	NSAssert( INT_MAX >= row,
					 @"Holy crap that's a lot of rows!  GList can't handle that.  Abort." );
	GList *rowptr = NULL;
	if(row != -1)
		rowptr = g_list_nth_data(purpleresults->rows,(guint)row);
	button->callback(gc, rowptr, user_data);
}

@end
