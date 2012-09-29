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

#import "ESPurpleRequestAbstractWindowController.h"
#import <AdiumLibpurple/PurpleCommon.h>

@interface AMPurpleSearchResultsController : ESPurpleRequestAbstractWindowController <NSTableViewDelegate>{
	IBOutlet NSTextField *textfield_primary;
	IBOutlet NSTextField *textfield_secondary;
	IBOutlet NSTableView *tableview;
	IBOutlet NSView *buttonview;
	
	NSMutableDictionary *searchButtons;
	
	PurpleNotifySearchResults *purpleresults;
	NSMutableArray *searchResults;

	PurpleConnection *gc;
	gpointer user_data;
}

- (id)initWithPurpleConnection:(PurpleConnection*)_gc title:(NSString*)title primaryText:(NSString*)primary secondaryText:(NSString*)secondary searchResults:(PurpleNotifySearchResults*)results userData:(gpointer)_user_data;

- (void)addResults:(PurpleNotifySearchResults*)results;

- (IBAction)invokeAction:(id)sender;

@end
