/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AITableViewAdditions.h"
#import "AIApplicationAdditions.h"
#import "AITigerCompatibility.h"

@implementation NSTableView (AITableViewAdditions)

//Return an array of items which are currently selected. SourceArray should be an array from which to pull the items;
//its count must be the same as the number of rows
- (NSArray *)arrayOfSelectedItemsUsingSourceArray:(NSArray *)sourceArray
{
	NSParameterAssert([sourceArray count] >= [self numberOfRows]);

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
		NSLog(@"SourceArray is %i; rows is %i",[sourceArray count],[self numberOfRows]);
	}

	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	
	NSEnumerator *enumerator = [selectedItems objectEnumerator];
	id	item;
	while ((item = [enumerator nextObject])) {
		NSUInteger i = [sourceArray indexOfObject:item];
		if (i != NSNotFound) {
			[indexes addIndex:i];
		}
	}
	
	[self selectRowIndexes:indexes byExtendingSelection:NO];
}

@end
