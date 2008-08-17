//
//  AXCArrayControllerWithDragAndDrop.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-11-09.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCArrayControllerWithDragAndDrop.h"

@implementation AXCArrayControllerWithDragAndDrop

- (id) dragValidator
{
	return dragValidator;
}
- (void) setDragValidator:(id)newValidator
{
	dragValidator = newValidator;
}

#pragma mark -

- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	return [dragValidator tableView:tableView validateDrop:info proposedRow:row proposedDropOperation:operation];
}
- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	return [dragValidator tableView:tableView acceptDrop:info row:row dropOperation:operation];
}
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndices toPasteboard:(NSPasteboard*)pboard
{
	if([dragValidator respondsToSelector:@selector(tableView:writeRowsWithIndexes:toPasteboard:)])
		return [dragValidator tableView:aTableView writeRowsWithIndexes:rowIndices toPasteboard:pboard];
	else
		return NO;
}

@end
