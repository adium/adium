//
//  AXCArrayControllerWithDragAndDrop.h
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-11-09.
//  Copyright 2005 Adium Team. All rights reserved.
//

/*! @class AXCArrayControllerWithDragAndDrop
 *  @brief Forwards table-view data-source methods for drag-and-drop validation
 *   acceptance to another object (the drag validator).
 *  @discussion Set an object as the drag validator, and this array controller
 *   as the table view's data source, and this array controller
 *   will forward any requests from the table view for drag validation
 *   information to that object, and also carry the results back.
 */
@interface AXCArrayControllerWithDragAndDrop : NSArrayController {
	id dragValidator;
}

- (id) dragValidator;
- (void) setDragValidator:(id)newValidator;

#pragma mark -

- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation;
- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation;

@end
