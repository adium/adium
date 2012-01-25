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

#import "AIContactController.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIListCell.h>
#import <Adium/AIListOutlineView.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListContact.h>
#import <Adium/AIProxyListObject.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIEventAdditions.h>
#import "AISCLViewPlugin.h"

@interface AIListOutlineView ()

- (void)AI_initListOutlineView;

@end

@implementation AIListOutlineView

+ (void)initialize
{
	if (self != [AIListOutlineView class]) {
		return;
	}

	[self exposeBinding:@"desiredHeight"];
	[self exposeBinding:@"totalHeight"];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *superSet = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"desiredHeight"]) {
		return [superSet setByAddingObject:@"totalHeight"];
	}

	return superSet;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
		[self AI_initListOutlineView];
	}

    return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self AI_initListOutlineView];
		[self registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListContact",@"AIListObject",nil]];
	}

	return self;
}

- (void)AI_initListOutlineView
{
	updateShadowsWhileDrawing = NO;
	
	backgroundImage = nil;
	backgroundFade = 1.0f;
	backgroundColor = nil;
	backgroundStyle = AINormalBackground;
		
	[self setDrawsGradientSelection:YES];
	[self sizeLastColumnToFit];	

	groupsHaveBackground = NO;
	
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_THEME];
}

- (void)dealloc
{	
	[adium.preferenceController unregisterPreferenceObserver:self];
	
	[backgroundImage release];
	[backgroundColor release];
	[_backgroundColorWithOpacity release];
	[highlightColor release];
	[rowColor release];
	[_rowColorWithOpacity release];
	 
	[self unregisterDraggedTypes];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)preferencesChangedForGroup:(NSString *)group 
							   key:(NSString *)key
							object:(AIListObject *)object 
					preferenceDict:(NSDictionary *)prefDict 
						 firstTime:(BOOL)firstTime
{
	groupsHaveBackground = [[prefDict objectForKey:KEY_LIST_THEME_GROUP_GRADIENT] boolValue];
}

// Keep our column full width
- (void)setFrameSize:(NSSize)newSize
{
	[super setFrameSize:newSize];
	[self sizeLastColumnToFit];
}

/*!
 * @brief Should we perform type select next/previous on find?
 *
 * @return YES to switch between type-select results. NO to to switch within the responder chain.
 */
- (BOOL)tabPerformsTypeSelectFind
{
	return YES;
}

- (void)cancelOperation:(id)sender
{
	[self deselectAll:nil];
}

#pragma mark Sizing

/*!
 * @brief Get the desired height for the outline view
 *
 * This includes content and desiredHeightPadding
 */
- (NSInteger)desiredHeight
{
	return ([self totalHeight] + desiredHeightPadding);
}

/*!
 * @brief Add padding to the desired height
 */
- (void)setDesiredHeightPadding:(int)inPadding
{
	desiredHeightPadding = inPadding;
}

/*!
 * @brief Get the desired width for the outline view
 *
 * This includes content; minimumDesiredWidth is respected
 */
- (NSInteger)desiredWidth
{
	NSInteger	row;
	NSInteger	numberOfRows = [self numberOfRows];
	CGFloat		widestCell = 0;
	id			theDelegate = self.delegate;
	
	// Enumerate all rows, find the widest one
	for (row = 0; row < numberOfRows; row++) {
		id		item = [self itemAtRow:row];
		NSCell	*cell = ([theDelegate outlineView:self isGroup:item] ? groupCell : contentCell);
	
		[theDelegate outlineView:self willDisplayCell:cell forTableColumn:nil item:item];
		CGFloat	width = [(AIListCell *)cell cellWidth];
		
		if (width > widestCell) {
			widestCell = width;
		}
	}

	return ((widestCell > minimumDesiredWidth) ? widestCell : minimumDesiredWidth);
}

/*!
 * @brief Set the minimum desired width reported by -[self desiredWidth]
 */
- (void)setMinimumDesiredWidth:(CGFloat)inMinimumDesiredWidth
{
	minimumDesiredWidth = inMinimumDesiredWidth;
}

#pragma mark List object access

/*!
 * @brief Return the selected object (to auto-configure the contact menu)
 */
- (AIListObject *)listObject
{
    NSInteger selectedRow = [self selectedRow];

    if (selectedRow >= 0 && selectedRow < [self numberOfRows]) {
        return ((AIProxyListObject *)[self itemAtRow:selectedRow]).listObject;
    } else {
        return nil;
    }
}

- (NSArray *)arrayOfListObjects
{
	NSMutableArray *array = [NSMutableArray array];
	for (AIProxyListObject *proxyObject in self.arrayOfSelectedItems) {
		[array addObject:proxyObject.listObject];
	}
	
	return array;
}

- (NSArray *)arrayOfListObjectsWithGroups
{
	NSMutableArray *array = [NSMutableArray array];
	for (AIProxyListObject *proxyObject in self.arrayOfSelectedItems) {
		[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:proxyObject.listObject, @"ListObject",
						  proxyObject.containingObject, @"ContainingObject", nil]];
	}
	
	return array;
}

- (AIListContact *)firstVisibleListContact
{
	NSInteger numberOfRows = [self numberOfRows];
	for (unsigned i = 0; i <numberOfRows ; i++) {
		AIProxyListObject *item = [self itemAtRow:i];
		if ([item isKindOfClass:[AIListContact class]]) {
			return (AIListContact *)item.listObject;
		}
	}

	return nil;
}

- (int)indexOfFirstVisibleListContact
{
	NSInteger numberOfRows = [self numberOfRows];
	for (unsigned i = 0; i <numberOfRows ; i++) {
		if ([[self itemAtRow:i] isKindOfClass:[AIListContact class]]) {
			return i;
		}
	}
	
	return -1;
}

#pragma mark Group expanding

/*!
 * @brief Expand or collapses groups on mouse down
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint	viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSInteger row = [self rowAtPoint:viewPoint];
	id item = [self itemAtRow:row];
	
	// Let super handle it if it's not a group, or the command key is down (dealing with selection)
	// Allow clickthroughs for triangle disclosure only.
	if (![item isKindOfClass:[AIListGroup class]] || [NSEvent cmdKey] || ![[self window] isKeyWindow]) {
		[super mouseDown:theEvent];
		return;
	}
	
	// Wait for the next event
	NSEvent *nextEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)
													untilDate:[NSDate distantFuture]
													   inMode:NSEventTrackingRunLoopMode
													  dequeue:NO];
	
	// Only expand/contract if they release the mouse. Otherwise pass on the goods.
	switch ([nextEvent type]) {
		case NSLeftMouseUp:
			if ([self isItemExpanded:item]) {
				[self collapseItem:item]; 
			} else {
				[self expandItem:item]; 
			}
			
			/* If the disclosure triangle was not the click-point, select the row.
			 *
			 * We use the approximation that the height of the row is about the same widht
			 * as the disclosure triangle.
			 */
			 if (viewPoint.x >= NSHeight([self frameOfCellAtColumn:0 row:row]))
				 [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO]; 
			 break;
		case NSLeftMouseDragged:
			[super mouseDown:theEvent];
			[super mouseDragged:nextEvent];
			break;
		default:
			[super mouseDown:theEvent];
			break;
	}	
}

#pragma mark Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{	
	// From previous implementation - still needed?
	[[sender draggingDestinationWindow] makeKeyAndOrderFront:self];

	return [super draggingEntered:sender];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return (NSDragOperationCopy | NSDragOperationMove | NSDragOperationPrivate);
}

- (BOOL)shouldCollapseAutoExpandedItemsForDeposited:(BOOL)deposited
{
	return YES;
}

#pragma mark Copying selected objects via the data source

- (IBAction)copy:(id)sender
{
	id dataSource = [self dataSource];

	if (dataSource) {
		NSIndexSet *selection = [self selectedRowIndexes];

		NSMutableArray *items = [NSMutableArray arrayWithCapacity:[selection count]];
		for (NSUInteger idx = [selection firstIndex]; idx <= [selection lastIndex]; idx = [selection indexGreaterThanIndex:idx]) {
			[items addObject:[self itemAtRow:idx]];
		}

		[dataSource outlineView:self
	                 writeItems:items
	               toPasteboard:[NSPasteboard generalPasteboard]];
	}
}

#pragma mark Menu items

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if ([anItem action] == @selector(copy:))
		return [self numberOfSelectedRows] > 0;
	else
		return [super validateUserInterfaceItem:anItem];
}

#pragma mark Accessibility
#if ACCESSIBILITY_DEBUG

- (NSArray *)accessibilityAttributeNames
{
	AILogWithSignature(@"names: %@", [super accessibilityAttributeNames]);
	return [super accessibilityAttributeNames];
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	AILogWithSignature(@"%@ -> %@", attribute, [super accessibilityAttributeValue:attribute]);
	return [super accessibilityAttributeValue:attribute];
	
}

#endif

@end
