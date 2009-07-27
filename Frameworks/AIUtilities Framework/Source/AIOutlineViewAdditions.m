//
//  AIOutlineViewAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Jul 09 2004.
//

#import "AIOutlineViewAdditions.h"
#import "AIApplicationAdditions.h"

@implementation NSOutlineView (AIOutlineViewAdditions)

- (id)firstSelectedItem
{
    int selectedRow = [self selectedRow];
	
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
		int row = [self rowForItem:item];
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
	unsigned int bufSize = [indices count];
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
	NSEnumerator	*enumerator = [selectedItems objectEnumerator];
	id				selectedItem;
	NSUInteger 			selectedRow;

	id  indexSet = [NSMutableIndexSet indexSet];

	//Build an index set
	while ((selectedItem = [enumerator nextObject])) {
		selectedRow = [self rowForItem:selectedItem];
		if (selectedRow != NSNotFound) {
			[indexSet addIndex:selectedRow];
		}
	}

	//Select the indexes
	[self selectRowIndexes:indexSet byExtendingSelection:NO];
}

@end
