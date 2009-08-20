//
//  AMPurpleSearchResultsController.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-06-25.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import "ESPurpleRequestAbstractWindowController.h"
#import <AdiumLibpurple/PurpleCommon.h>

@interface AMPurpleSearchResultsController : ESPurpleRequestAbstractWindowController {
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
