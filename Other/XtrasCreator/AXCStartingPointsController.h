//
//  AXCStartingPointsController.h
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-31.
//  Copyright 2005 Adium Team. All rights reserved.
//

@interface AXCStartingPointsController : NSObject {
	NSArray *documentTypes;
	NSMutableSet *usableDocTypes; //document types with a class name that exists

	IBOutlet NSPanel *startingPointsWindow;
	IBOutlet NSTableView *startingPointsTableView;
}

- (NSArray *) documentTypes;

- (void) setStartingPointsVisible:(BOOL)flag;
- (BOOL) isStartingPointsVisible;

- (IBAction) displayStartingPoints:(id)sender;
- (IBAction) makeNewDocumentOfSelectedType:(id)sender;

@end
