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

#import "AIOutlineViewAdditions.h"

@implementation NSOutlineView (AIOutlineViewAdditions)

- (id)firstSelectedItem
{
    NSInteger selectedRow = [self selectedRow];
	
    if (selectedRow >= 0 && selectedRow < [self numberOfRows]) {
        return [self itemAtRow:selectedRow];
    } else {
        return nil;
    }
}

//Redisplay an item (passing nil is the same as requesting a redisplay of the entire list)
- (void)redisplayItem:(id)item
{
	if (item) {
		NSInteger row = [self rowForItem:item];
		if (row >= 0 && row < [self numberOfRows]) {
			[self setNeedsDisplayInRect:[self rectOfRow:row]];
		}
	} else {
		[self setNeedsDisplay:YES];
	}
}

- (NSArray *)arrayOfSelectedItems
{
	NSMutableArray 	*itemArray = [NSMutableArray array];
	id 				item;
	
	//Apple wants us to do some pretty crazy stuff for selections in 10.3
	NSIndexSet *indices = [self selectedRowIndexes];
	NSUInteger bufSize = [indices count];
	NSUInteger *buf = malloc(bufSize * sizeof(NSUInteger));
	unsigned int i;

	NSRange range = NSMakeRange([indices firstIndex], ([indices lastIndex]-[indices firstIndex]) + 1);
	[indices getIndexes:buf maxCount:bufSize inIndexRange:&range];

	for (i = 0; i != bufSize; i++) {
		if ((item = [self itemAtRow:buf[i]])) {
			[itemArray addObject:item];
		}
	}

	free(buf);

	return itemArray;
}

- (void)selectItemsInArray:(NSArray *)selectedItems
{
	id  indexSet = [NSMutableIndexSet indexSet];

	//Build an index set
	[selectedItems enumerateObjectsUsingBlock:^(id selectedItem, NSUInteger idx, BOOL *stop) {
		NSUInteger selectedRow = [self rowForItem:selectedItem];
		if (selectedRow != NSNotFound) {
			[indexSet addIndex:selectedRow];
		}
	}];

	//Select the indexes
	[self selectRowIndexes:indexSet byExtendingSelection:NO];
}

@end
