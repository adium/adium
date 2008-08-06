//
//  AIOutlineViewAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Jul 09 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface NSOutlineView (AIOutlineViewAdditions)

- (id)firstSelectedItem;
- (NSArray *)arrayOfSelectedItems;
- (void)selectItemsInArray:(NSArray *)selectedItems;
- (void)redisplayItem:(id)item;

@end

