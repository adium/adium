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

#import "AIAnimatingListOutlineView.h"
#import "AIOutlineViewAnimation.h"

#define DISABLE_ALL_ANIMATION				FALSE
#define DISABLE_ANIMATE_EXPAND_AND_COLLAPSE	TRUE

@interface AIAnimatingListOutlineView ()
- (NSRect)unanimatedRectOfRow:(NSInteger)rowIndex;
@end

/*!
 * @class AIAnimatingListOutlineView
 * @brief An outline view which animates changes to its order
 *
 * Implementation inspired by Dan Wood's AnimatingTableView in TableTester, http://gigliwood.com/tabletester/
 * Used with permission.  AIAnimatingListOutlineView is licensed under the GPL, like Adium itself; Dan's tabletester code
 * is BSD, with explicit double-licensing as GPL the parts used in this class.
 */
@implementation AIAnimatingListOutlineView

#if !DISABLE_ALL_ANIMATION

- (void)_initAnimatingListOutlineView
{
	allAnimatingItemsDict  = [[NSMutableDictionary alloc] init];
	animationsCount = 0;
	animations = [[NSMutableSet alloc] init];
	animationHedgeFactor = NSZeroSize;
	enableAnimation = YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
		[self _initAnimatingListOutlineView];
	}

    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		[self _initAnimatingListOutlineView];
	}
	
	return self;
}

- (void)dealloc
{
	[animations makeObjectsPerformSelector:@selector(stopAnimation)];
	[animations release];

	[allAnimatingItemsDict release];
	[super dealloc];
}

#pragma mark Enabling
- (void)setEnableAnimation:(BOOL)shouldEnable
{
	enableAnimation = shouldEnable;
}

- (BOOL)enableAnimation
{
	return enableAnimation;
}

#pragma mark Rect determination
/*!
 * @brief Return the current rect for an item at a given row
 *
 * This is the same as rectOfRow but is slightly faster if an NSValue pointer for the item is already known.
 *
 * @result The rect in which the row is currently displayed
 */
- (NSRect)currentDisplayRectForItemPointer:(NSValue *)itemPointer atRow:(NSInteger)rowIndex
{
	NSDictionary *animDict = [allAnimatingItemsDict objectForKey:itemPointer];
	NSRect rect;

	if (animDict) {
		CGFloat progress = (CGFloat)[[animDict objectForKey:@"progress"] doubleValue];
		NSRect oldR = [[animDict objectForKey:@"old rect"] rectValue];
		NSRect newR = [self unanimatedRectOfRow:rowIndex];

		//Calculate a rectangle between the original and the final rectangles.
		rect = NSMakeRect(NSMinX(oldR) + (progress * (NSMinX(newR) - NSMinX(oldR))),
						  NSMinY(oldR) + (progress * (NSMinY(newR) - NSMinY(oldR))),
						  NSWidth(newR), NSHeight(newR) );
	} else {
		rect = [self unanimatedRectOfRow:rowIndex];
	}
	
	return rect;	
}

/*
 * @brief Return the current rect for a row
 *
 * If we're animating, this is somewhere between (progress % between) the old and new rects.
 * If we're not, pass it to super.
 *
 * @result The rect in which the row is currently displayed
 */
- (NSRect)rectOfRow:(NSInteger)rowIndex
{
	if (animationsCount > 0) {
		return [self currentDisplayRectForItemPointer:[NSValue valueWithPointer:[self itemAtRow:rowIndex]] atRow:rowIndex];

	} else {
		return [super rectOfRow:rowIndex];
	}
}

/*!
 * @brief What rows are in a given rect?
 *
 * When animating, the range has to be expanded to include rows which NSTableView would not expect to be in the rect
 */
- (NSRange)rowsInRect:(NSRect)inRect
{
	if (animationsCount > 0) {
		//The rows in a given rect aren't necessarily sequential while we're animating. Too bad this doesn't return an NSIndexSet.
		NSInteger count = [self numberOfRows];
		NSRange range = NSMakeRange(0, count);
		BOOL foundLowest = NO;
		
		for (NSInteger i = 0; i < count; i++) {
			NSRect rowRect = [self rectOfRow:i];

			if (!foundLowest) {
				if (NSIntersectsRect(rowRect, inRect)) {
					foundLowest = YES;	
				} else {
					range.location += 1;
					range.length -= 1;
				}
			} else {
				//Looking for the highest
				if (NSIntersectsRect(rowRect, inRect)) {
					//We need to reach here
					if ((range.location + range.length) < i) {
						range.length = i - range.location;
					}
				}
			}
		}
		
		return range;

	} else {
		return [super rowsInRect:inRect];
	}
}

/*!
 * @brief Rect of the row if we weren't animating
 *
 * @result The rect in which the row would be displayed were all animations complete.
 */
- (NSRect)unanimatedRectOfRow:(NSInteger)rowIndex
{
	return [super rectOfRow:rowIndex];
}

#pragma mark Indexes, before and after

/*
 * @brief Return a dictionary of indexes keyed by pointers to items for item and all children
 *
 * This function uses itself recursively; when calling from outside, dict should be nil.
 *
 * @result The dictionary
 */
- (NSMutableDictionary *)indexesForItemAndChildren:(id)item dict:(NSMutableDictionary *)dict
{
	if (!dict) dict = [NSMutableDictionary dictionary];

	NSInteger idx = (item ? [self rowForItem:item] : -1);

	if ((idx != -1) || !item) {
		if (!item || ([self isExpandable:item] &&
					  [self isItemExpanded:item])) {
			NSInteger numChildren = [[self dataSource] outlineView:self numberOfChildrenOfItem:item];
			//Add each child
			for (NSInteger i = 0; i < numChildren; i++) {
				id thisChild = [[self dataSource] outlineView:self child:i ofItem:item];
				dict = [self indexesForItemAndChildren:thisChild dict:dict];
			}
		}
		
		if (item) [dict setObject:[NSNumber numberWithInteger:idx] forKey:[NSValue valueWithPointer:item]];
	}

	return dict;
}

/*!
 * @brief Create a dictionary of the current indexes, keyed by items, and configure before an animation starts
 *
 * Every row, regardles of whether it has changed (which we don't know yet), starts off at its current index ("old index")
 * with a progress of 0% towards its new index.
 *
 * This is called before allowing super to perform an update.
 * 
 * @result A dictionary of indexes keyed by pointers to items
 */
- (NSDictionary *)saveCurrentIndexesForItem:(id)item
{
	NSDictionary *oldDict = [self indexesForItemAndChildren:item dict:nil];
	for (id oldItem in oldDict) {
		NSNumber *oldIndex = [oldDict objectForKey:oldItem];
		[allAnimatingItemsDict setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
			oldIndex, @"old index",
			oldIndex, @"new index", /* unchanged */
			[NSValue valueWithRect:[self unanimatedRectOfRow:[oldIndex integerValue]]], @"old rect",
			[NSNumber numberWithDouble:0.0f], @"progress", nil]
								  forKey:oldItem];			
	}
	
	animationsCount++;

	return oldDict;
}

/*!
 * @brief Given old indexes, after an update has occurred, determine what needs to be animated
 *
 * Any item which is not at the same row as it was in oldDict has changed. 
 * allAnimatingItemsDict already has this item at 0% from the old row towards its new row.
 *
 * If the item has not changed, immediately set it to 100% progress.
 *
 * Finally, create and start an AIOutlineViewAnimation which will notify us as the animation progresses.
 */
- (void)updateForNewIndexesFromOldIndexes:(NSDictionary *)oldDict forItem:(id)item recalculateHedge:(BOOL)recalculateHedge duration:(NSTimeInterval)duration
{
	NSDictionary *newDict = [self indexesForItemAndChildren:item dict:nil];
	NSMutableDictionary *animatingRowsDict = [NSMutableDictionary dictionary];
	
	if (recalculateHedge) {
		[self willChangeValueForKey:@"totalHeight"];
		animationHedgeFactor = NSZeroSize;
	}

	//Compare differences
	for (id oldItem in oldDict) {
		NSNumber *oldIndex = [oldDict objectForKey:oldItem];
		NSNumber *newIndex = [newDict objectForKey:oldItem];
		if (newIndex) {
			NSInteger oldIndexInt = [oldIndex integerValue];
			NSInteger newIndexInt = [newIndex integerValue];
			if (oldIndexInt != newIndexInt) {
				[animatingRowsDict setObject:oldIndex
									  forKey:oldItem];
				
				[[allAnimatingItemsDict objectForKey:oldItem] setObject:newIndex
																 forKey:@"new index"];

				if (recalculateHedge) {
					//If we're animating a row which will be starting off outside our bounds, set the hedge factor
					if (oldIndexInt >= [self numberOfRows]) {
						animationHedgeFactor.height += ([self currentDisplayRectForItemPointer:oldItem atRow:newIndexInt].size.height +
														[self intercellSpacing].height);
					}
				}
			} else {
				[[allAnimatingItemsDict objectForKey:oldItem] setObject:[NSNumber numberWithDouble:1.0f]
																 forKey:@"progress"];
			}

		} else {
			//The item is no longer in the outline view
			[allAnimatingItemsDict removeObjectForKey:oldItem];
		}
	}

	if ([animatingRowsDict count]) {
		AIOutlineViewAnimation *animation = [AIOutlineViewAnimation listObjectAnimationWithDictionary:animatingRowsDict
																							 delegate:self];
		[animation setDuration:duration];
		[animation startAnimation];
		[animations addObject:animation];

	} else {
		//This was incremented in saveCurrentIndexesForItem:, but we didn't end up actually creating an animation for it
		animationsCount--;
	}
	
	if (recalculateHedge)
		[self didChangeValueForKey:@"totalHeight"];
}

#pragma mark AIOutlineViewAnimation callbacks

/*!
 * @brief The animation for some rows (animatingRowsDict) has progressed
 *
 * Update the progress for those rows as tracked in allAnimatingItemsDict, then display.
 */
- (void)animation:(AIOutlineViewAnimation *)animation didSetCurrentValue:(float)currentValue forDict:(NSDictionary *)animatingRowsDict
{
	CGFloat maxRequiredY = 0;

	[self willChangeValueForKey:@"totalHeight"];

	//Update progress for each item in animatingRowsDict
	for (NSValue *itemPointer in animatingRowsDict) {
		NSMutableDictionary *animDict = [allAnimatingItemsDict objectForKey:itemPointer];
		NSInteger newIndex = [[animDict objectForKey:@"new index"] integerValue];
		NSRect oldFrame, newFrame;

		//We'll need to redisplay the space we were in previously
		oldFrame = [self currentDisplayRectForItemPointer:itemPointer
													atRow:newIndex];
		[self setNeedsDisplayInRect:oldFrame];

		//Update the actual progress
		[animDict setObject:[NSNumber numberWithDouble:currentValue]
					 forKey:@"progress"];

		//We'll need to redisplay after updating to the new location
		newFrame = [self currentDisplayRectForItemPointer:itemPointer
													atRow:newIndex];
		[self setNeedsDisplayInRect:[self currentDisplayRectForItemPointer:itemPointer
																	 atRow:newIndex]];

		//Track how much Y-space we're requiring at this point
		if (NSMaxY(newFrame) > maxRequiredY) {
			maxRequiredY = NSMaxY(newFrame);
		}
	}
	
	//The hedge factor can now be updated to be minimal for the animation
	if (maxRequiredY > [self totalHeight]) {
		animationHedgeFactor.height = maxRequiredY - [self totalHeight];
	} else if (maxRequiredY > [super totalHeight]) {
		animationHedgeFactor.height = maxRequiredY - [super totalHeight];
	} else {
		animationHedgeFactor.height = 0;
	}

	[self didChangeValueForKey:@"totalHeight"];
}

/*!
 * @brief Animation ended
 */
- (void)animationDidEnd:(NSAnimation *)animation
{
	animationsCount--;
	if (animationsCount == 0) {
		[self willChangeValueForKey:@"totalHeight"];
		animationHedgeFactor = NSZeroSize;
		[allAnimatingItemsDict removeAllObjects];
		[self didChangeValueForKey:@"totalHeight"];
	}

	[animation stopAnimation];
	[animations removeObject:animation];
}

#pragma mark Intercepting changes so we can animate

- (void)reloadData
{
	if (enableAnimation) {
		NSDictionary *oldDict = [self saveCurrentIndexesForItem:nil];
		
		//If items are expanded or collapsed during reload, we don't want to animate that
		disableExpansionAnimation = YES;
		[super reloadData];
		disableExpansionAnimation = NO;
		
		[self updateForNewIndexesFromOldIndexes:oldDict forItem:nil recalculateHedge:YES duration:LIST_OBJECT_ANIMATION_DURATION];

	} else {
		[super reloadData];		
	}
}

- (void)reloadItem:(id)item reloadChildren:(BOOL)reloadChildren
{
	if (enableAnimation) {
		NSDictionary *oldDict = [self saveCurrentIndexesForItem:item];
		[super reloadItem:item reloadChildren:reloadChildren];
		[self updateForNewIndexesFromOldIndexes:oldDict forItem:item recalculateHedge:YES duration:LIST_OBJECT_ANIMATION_DURATION];

	} else {
		[super reloadItem:item reloadChildren:reloadChildren];
	}
}

- (void)reloadItem:(id)item
{
	if (enableAnimation) {
		NSDictionary *oldDict = [self saveCurrentIndexesForItem:item];
		[super reloadItem:item];
		[self updateForNewIndexesFromOldIndexes:oldDict forItem:item recalculateHedge:YES duration:LIST_OBJECT_ANIMATION_DURATION];

	} else {
		[super reloadItem:item];		
	}
}

#if !DISABLE_ANIMATE_EXPAND_AND_COLLAPSE

- (void)expandItem:(id)item
{
	if (enableAnimation) {
		if (!disableExpansionAnimation) {
			NSDictionary *oldDict = [self saveCurrentIndexesForItem:nil];
			[super expandItem:item];
			
			[self updateForNewIndexesFromOldIndexes:oldDict forItem:nil recalculateHedge:YES duration:EXPANSION_DURATION];
		} else {
			[super expandItem:item];		
		}

	} else {
		[super expandItem:item];
	}
}

/*!
 * @brief Collapse an item
 *
 * This one is a bit tricker. If the window or view will resize (using -[self totalHeight] as a guide) when the item is collapsed,
 * it will cut off our animating-upward items in rows beneath it unless we set animationHedgeFactor to include
 * the height of each row within item.
 *
 * As we animate, animationHedgeFactor will be decreased back toward 0.
 */
- (void)collapseItem:(id)item
{
	if (enableAnimation) {
		if (!disableExpansionAnimation) {
			NSDictionary *oldDict = [self saveCurrentIndexesForItem:nil];
			
			[self willChangeValueForKey:@"totalHeight"];
			
			//Maintain space for the animation to display
			NSInteger numChildren = [[self dataSource] outlineView:self numberOfChildrenOfItem:item];
			
			for (NSInteger i = 0; i < numChildren; i++) {
				id thisChild = [[self dataSource] outlineView:self child:i ofItem:item];
				animationHedgeFactor.height += [self currentDisplayRectForItemPointer:[NSValue valueWithPointer:thisChild]
																				atRow:[self rowForItem:thisChild]].size.height + [self intercellSpacing].height;
			}
			
			//Actually collapse the item
			[super collapseItem:item];
			
			[self didChangeValueForKey:@"totalHeight"];
			
			//Now animate the movement
			[self updateForNewIndexesFromOldIndexes:oldDict forItem:nil recalculateHedge:NO duration:EXPANSION_DURATION];
		} else {
			[super collapseItem:item];
		}

	} else {
		[super collapseItem:item];
	}
}

#endif

#pragma mark Total height

/*
 * @brief Total height required by this view
 *
 * This is the only point of overlap with AIListOutlineView; otherwise, we are just an NSOutlineView subclass.
 * Add the current animationHedgeFactor's height to whatever super says.
 */
- (NSInteger)totalHeight
{
	return [super totalHeight] + animationHedgeFactor.height;
}

#endif

@end
