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

#import "AITableViewAdditions.h"
#import <objc/objc-class.h>

@implementation NSTableView (AITableViewAdditions)

//Return an array of items which are currently selected. SourceArray should be an array from which to pull the items;
//its count must be the same as the number of rows
- (NSArray *)selectedItemsFromArray:(NSArray *)sourceArray
{
	NSParameterAssert([sourceArray count] >= [self numberOfRows]);

	NSMutableArray 	*itemArray = [NSMutableArray array];
	id 				item;

	//Apple wants us to do some pretty crazy stuff for selections in 10.3
	NSIndexSet *indices = [self selectedRowIndexes];
	NSUInteger bufSize = [indices count];
	NSUInteger *buf = malloc(bufSize * sizeof(NSUInteger));
	NSUInteger i;

	NSRange range = NSMakeRange([indices firstIndex], ([indices lastIndex]-[indices firstIndex]) + 1);
	[indices getIndexes:buf maxCount:bufSize inIndexRange:&range];
		
	for (i = 0; i != bufSize; i++) {
		if ((item = [sourceArray objectAtIndex:buf[i]])) {
			[itemArray addObject:item];
		}
	}

	free(buf);

	return itemArray;
}

- (void)selectItemsInArray:(NSArray *)selectedItems usingSourceArray:(NSArray *)sourceArray
{
	if ([sourceArray count] != [self numberOfRows]) {
		NSLog(@"SourceArray is %lu; rows is %ld",(unsigned long)[sourceArray count], (long)[self numberOfRows]);
	}

	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	
	for (id item in selectedItems) {
		NSUInteger i = [sourceArray indexOfObject:item];
		if (i != NSNotFound) {
			[indexes addIndex:i];
		}
	}
	
	[self selectRowIndexes:indexes byExtendingSelection:NO];
}

@end

@interface AITableView : NSTableView {}
@end

@implementation AITableView

/* 
 * @brief Load
 *
 * Install ourself to intercept keyDown: calls so we can stick our delete handling in, and menuForEvent: calls so we can ask our delegate
 */
+ (void)load
{
	//Anything you can do, I can do better...
	method_exchangeImplementations(class_getInstanceMethod([NSTableView class], @selector(keyDown:)), class_getInstanceMethod(self, @selector(keyDown:)));
	
	method_exchangeImplementations(class_getInstanceMethod([NSTableView class], @selector(menuForEvent:)), class_getInstanceMethod(self, @selector(menuForEvent:)));
}

//Filter keydowns looking for the delete key (to delete the current selection)
- (void)keyDown:(NSEvent *)theEvent
{
	NSString	*charString = [theEvent charactersIgnoringModifiers];
	unichar		pressedChar = 0;

	//Get the pressed character
	if ([charString length] == 1) pressedChar = [charString characterAtIndex:0];

	//Check if 'delete' was pressed
	if (pressedChar == NSDeleteFunctionKey || pressedChar == NSBackspaceCharacter || pressedChar == NSDeleteCharacter) { //Delete
		if ([[self delegate] respondsToSelector:@selector(tableViewDeleteSelectedRows:)])
			[(id <AITableViewDelegate>)[self delegate] tableViewDeleteSelectedRows:self]; //Delete the selection
	} else {
		//Pass the key event on to the unswizzled impl
		method_invoke(self, class_getInstanceMethod([AITableView class], @selector(keyDown:)), theEvent);
	}
}

//Allow our delegate to specify context menus
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	if ([[self delegate] respondsToSelector:@selector(tableView:menuForEvent:)])
		return [(id<AITableViewDelegate>)[self delegate] tableView:self menuForEvent:theEvent];
        
	return method_invoke(self, class_getInstanceMethod([AITableView class], @selector(menuForEvent:)), theEvent);
}

@end
