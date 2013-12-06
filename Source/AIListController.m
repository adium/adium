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

#import "AIListController.h"
#import "AIAnimatingListOutlineView.h"
#import "AIListWindowController.h"
#import "AIMessageViewController.h"
#import <Adium/AIChat.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AISortController.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIContactList.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIProxyListObject.h>
#import <Adium/AITextAttachmentExtension.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIPasteboardAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>

#import <AIUtilities/AIEventAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIOSCompatibility.h>
#import <AIUtilities/AIApplicationAdditions.h>

#define EDGE_CATCH_X						40.0f
#define EDGE_CATCH_Y						40.0f

#define	MENU_BAR_HEIGHT				22

#define KEY_CONTACT_LIST_DOCKED_TO_BOTTOM_OF_SCREEN	[NSString stringWithFormat:@"Contact List Docked To Bottom:%@", [[self contactList] contentsBasedIdentifier]]

#define PREF_GROUP_APPEARANCE		@"Appearance"

@interface AIListController ()
- (void)promptToCombineItems:(NSArray *)items withContact:(AIListContact *)inContact;
- (void)mergeContactSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end

@implementation AIListController


- (id)initWithContactList:(id<AIContainingObject>)aContactList
			inOutlineView:(AIListOutlineView *)inContactListView
			 inScrollView:(AIAutoScrollView *)inScrollView_contactList
				 delegate:(id<AIListControllerDelegate>)inDelegate
{
	NSParameterAssert(aContactList != nil);
	if ((self = [self initWithContactListView:inContactListView inScrollView:inScrollView_contactList delegate:inDelegate])) {
		[contactListView setDrawHighlightOnlyWhenMain:YES];
		
		self.autoResizeVertically = NO;
		self.autoResizeHorizontally = NO;
		maxWindowWidth = 10000;
		forcedWindowWidth = -1;
		
		//Observe contact list content and display changes
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadListObject:) 
										   name:Contact_ListChanged
										 object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadListObject:)
										   name:Contact_OrderChanged 
										 object:nil];
		
		[contactListView addObserver:self
						  forKeyPath:@"desiredHeight" 
							 options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) 
							 context:NULL];
		
		[self setContactListRoot:aContactList];

		//Recall how the contact list was docked last time Adium was open
		dockToBottomOfScreen = [[adium.preferenceController preferenceForKey:KEY_CONTACT_LIST_DOCKED_TO_BOTTOM_OF_SCREEN
																		 group:PREF_GROUP_WINDOW_POSITIONS] intValue];
		
		//Observe preference changes
		[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST];
	}

	return self;
}

//Setup the window after it has loaded
- (void)configureViewsAndTooltips
{
	[super configureViewsAndTooltips];
	
	//Listen to when the list window moves (so we can remember which edge we're docked to)
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidMove:)
												 name:NSWindowDidMoveNotification
											   object:[contactListView window]];
}

- (void)close
{	
	//Stop observing
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
}

- (void)dealloc
{
	[contactListView removeObserver:self forKeyPath:@"desiredHeight"];
}


- (void)preferencesChangedForGroup:(NSString *)group 
							   key:(NSString *)key
							object:(AIListObject *)object 
					preferenceDict:(NSDictionary *)prefDict 
						 firstTime:(BOOL)firstTime
{
	if (!object)
		[(AIAnimatingListOutlineView *)contactListView setEnableAnimation:[[prefDict objectForKey:KEY_CL_ANIMATE_CHANGES] boolValue]];
}

//Resizing And Positioning ---------------------------------------------------------------------------------------------
#pragma mark Resizing And Positioning
//Dynamically resize the contact list
- (void)contactListDesiredSizeChanged
{
	NSWindow	*theWindow;

    if ((self.autoResizeVertically || self.autoResizeHorizontally) &&
		(theWindow = [contactListView window]) &&
		[(AIListWindowController *)[theWindow windowController] windowSlidOffScreenEdgeMask] == AINoEdges) {
		
		NSRect  currentFrame = [theWindow frame];
        NSRect	desiredFrame = [self _desiredWindowFrameUsingDesiredWidth:(self.autoResizeHorizontally || (forcedWindowWidth != -1))
															desiredHeight:self.autoResizeVertically];

		if (!NSEqualRects(currentFrame, desiredFrame)) {
			//We must set the min/max first, otherwise our setFrame will be restricted by them and not produce the
			//expected results
			CGFloat toolbarHeight = (self.autoResizeVertically ? [theWindow toolbarHeight] : 0);
			
			[theWindow setMinSize:NSMakeSize((self.autoResizeHorizontally ? desiredFrame.size.width : minWindowSize.width),
											 (self.autoResizeVertically ? (desiredFrame.size.height - toolbarHeight) : minWindowSize.height))];
			[theWindow setMaxSize:NSMakeSize((self.autoResizeHorizontally ? desiredFrame.size.width : 10000),
											 (self.autoResizeVertically ? (desiredFrame.size.height - toolbarHeight) : 10000))];

			[theWindow setFrame:desiredFrame display:YES animate:NO];
		}
    }
}

/*!
 * @brief The window will be sliding on screen momentarily
 *
 * This is sent by the AIListWindowController. We take this opportunity to perform autosizing as appropriate.
 * The window is actually off-screen and should remain as such; we therefore perform sizing but maintain an appropriate origin such that
 * the window won't be seen.
 */
- (void)contactListWillSlideOnScreen
{
	NSWindow	*theWindow;
	
    if ((self.autoResizeVertically || self.autoResizeHorizontally) &&
		(theWindow = [contactListView window])) {
		NSRect currentFrame, savedFrame, desiredFrame;
		
		
		currentFrame = [theWindow frame];
		/* Pretend, for autosizing purposes, we're where we'll be once we're done sliding on screen. This allows sizing relative to screen edges and the dock
		 * to work properly. We'll return to our previous origin after performing size checking.
		 */
		savedFrame = [(AIListWindowController *)[theWindow windowController] savedFrame];
		[theWindow setFrame:savedFrame display:NO animate:NO];
        
		desiredFrame = [self _desiredWindowFrameUsingDesiredWidth:(self.autoResizeHorizontally || (forcedWindowWidth != -1))
													desiredHeight:self.autoResizeVertically];

		if (!NSEqualRects(savedFrame, desiredFrame)) {
			/* We must set the min/max first, otherwise our setFrame will be restricted by them and not produce the
			 * expected results
			 */
			CGFloat toolbarHeight = (self.autoResizeVertically ? [theWindow toolbarHeight] : 0);
			NSRect offscreenFrame = desiredFrame;
			[theWindow setMinSize:NSMakeSize((self.autoResizeHorizontally ? desiredFrame.size.width : minWindowSize.width),
											 (self.autoResizeVertically ? (desiredFrame.size.height - toolbarHeight) : minWindowSize.height))];
			[theWindow setMaxSize:NSMakeSize((self.autoResizeHorizontally ? desiredFrame.size.width : 10000),
											 (self.autoResizeVertically ? (desiredFrame.size.height - toolbarHeight) : 10000))];

			//Adjust the origin to remain offscreen
			offscreenFrame.origin.x = NSMinX(currentFrame);

			if ([(AIListWindowController *)[theWindow windowController] windowSlidOffScreenEdgeMask] & AIMinXEdgeMask) {
				offscreenFrame.origin.x -= NSWidth(desiredFrame) - NSWidth(currentFrame);
			}

			[theWindow setFrame:offscreenFrame display:NO animate:NO];

			//Note the new desired frame so that we'll slide to that position
			[(AIListWindowController *)[theWindow windowController] setSavedFrame:desiredFrame];

		} else {
			//Nothing to do. Return to our actual current frame, unchanged.
			[theWindow setFrame:currentFrame display:NO animate:NO];
		}
    }
}

//Size for window zoom
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    return [self _desiredWindowFrameUsingDesiredWidth:YES desiredHeight:YES];
}

//Window moved, remember which side the user has docked it to
- (void)windowDidMove:(NSNotification *)notification
{
	NSWindow	*theWindow = [contactListView window];
	NSRect		windowFrame = [theWindow frame];
	NSScreen	*theWindowScreen = [theWindow screen];

	NSRect		boundingFrame = [theWindowScreen frame];
	NSRect		visibleBoundingFrame = [theWindowScreen visibleFrame];
	
	AIDockToBottomType oldDockToBottom = dockToBottomOfScreen;

	//First, see if they are now within EDGE_CATCH_Y of the total boundingFrame
	if ((windowFrame.origin.y < boundingFrame.origin.y + EDGE_CATCH_Y) &&
	   ((windowFrame.origin.y + windowFrame.size.height) < (boundingFrame.origin.y + boundingFrame.size.height - EDGE_CATCH_Y))) {
		dockToBottomOfScreen = AIDockToBottom_TotalFrame;
			} else {
		//Then, check for the (possibly smaller) visibleBoundingFrame
		if ((windowFrame.origin.y < visibleBoundingFrame.origin.y + EDGE_CATCH_Y) &&
		   ((windowFrame.origin.y + windowFrame.size.height) < (visibleBoundingFrame.origin.y + visibleBoundingFrame.size.height - EDGE_CATCH_Y))) {
			dockToBottomOfScreen = AIDockToBottom_VisibleFrame;
		} else {
			dockToBottomOfScreen = AIDockToBottom_No;
		}
	}

	//Remember how the contact list is currently docked for next time
	if (oldDockToBottom != dockToBottomOfScreen) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:dockToBottomOfScreen]
											 forKey:KEY_CONTACT_LIST_DOCKED_TO_BOTTOM_OF_SCREEN
											  group:PREF_GROUP_WINDOW_POSITIONS];
	}
}

//Desired frame of our window - if one of the BOOL values is NO, don't modify that value from the current frame
- (NSRect)_desiredWindowFrameUsingDesiredWidth:(BOOL)useDesiredWidth desiredHeight:(BOOL)useDesiredHeight
{
	NSRect      windowFrame, viewFrame, newWindowFrame, screenFrame, visibleScreenFrame, boundingFrame;
	NSWindow	*theWindow = [contactListView window];
	NSScreen	*currentScreen = [theWindow screen];
	NSInteger			desiredHeight = [contactListView desiredHeight];
	BOOL		anchorToRightEdge = NO;
	
	windowFrame = [theWindow frame];
	newWindowFrame = windowFrame;
	viewFrame = [scrollView_contactList frame];
	
	if (!currentScreen) currentScreen = [(AIListWindowController *)[theWindow windowController] windowLastScreen];
	if (!currentScreen) currentScreen = [NSScreen mainScreen];

	screenFrame = [currentScreen frame]; 
	visibleScreenFrame = [currentScreen visibleFrame];
	
	//Store the window's rect for when we unresize vertically
	if (NSEqualRects(previousWindowRect, NSZeroRect) || previousWindowRect.origin.x != windowFrame.origin.x)
		previousWindowRect = windowFrame;
	
    //Width
	if (useDesiredWidth) {
		if (forcedWindowWidth != -1) {
			//If auto-sizing is disabled, use the specified width
			newWindowFrame.size.width = forcedWindowWidth;
		} else {
			/* Using horizontal auto-sizing, so find and determine our new width
			 *
			 * First, subtract the current size of the view from our frame
			 */
			newWindowFrame.size.width -= viewFrame.size.width;
			
			//Now, figure out how big the view wants to be and add that to our frame
			newWindowFrame.size.width += [contactListView desiredWidth];
			
			//Don't get bigger than our maxWindowWidth
			if (newWindowFrame.size.width > maxWindowWidth) {
				newWindowFrame.size.width = maxWindowWidth;
			} else if (newWindowFrame.size.width < 0) {
				newWindowFrame.size.width = 0;	
			}
		}

		//Anchor to the appropriate screen edge
		anchorToRightEdge = ((currentScreen && ((NSMaxX(windowFrame) + EDGE_CATCH_X) >= NSMaxX(visibleScreenFrame))) ||
							 [(AIListWindowController *)[theWindow windowController] windowSlidOffScreenEdgeMask] == AIMaxXEdgeMask);
		if (anchorToRightEdge) {
			newWindowFrame.origin.x = NSMaxX(windowFrame) - NSWidth(newWindowFrame);
		} else {
			newWindowFrame.origin.x = NSMinX(windowFrame);
		}
	}

	/*
	 * Compute boundingFrame for window
	 *
	 * If the window is against the left or right edges of the screen AND the user did not dock to the visibleFrame last,
	 * we use the full screenFrame as our bound.
	 * The edge check is used since most users' docks will not extend to the edges of the screen.
	 * Alternately, if the user docked to the total frame last, we can safely use the full screen even if we aren't
	 * on the edge.
	 */
	BOOL windowOnEdge = ((NSMinX(newWindowFrame) < NSMinX(screenFrame) + EDGE_CATCH_X) ||
						 (NSMaxX(newWindowFrame) > (NSMaxX(screenFrame) - EDGE_CATCH_X)));

	if ((windowOnEdge && (dockToBottomOfScreen != AIDockToBottom_VisibleFrame)) ||
	   (dockToBottomOfScreen == AIDockToBottom_TotalFrame)) {
		NSArray *screens;

		boundingFrame = screenFrame;

		//We still should not violate the menuBar, so account for it here if we are on the menuBar screen.
		if (([NSApp isOnMavericksOrNewer] && [NSScreen screensHaveSeparateSpaces]) ||
			((screens = [NSScreen screens]) &&
			([screens count]) &&
			(currentScreen == [screens objectAtIndex:0]))) {
			boundingFrame.size.height -= MENU_BAR_HEIGHT;
		}

	} else {
		boundingFrame = visibleScreenFrame;
	}

	//Height
	if (useDesiredHeight) {
		if (forcedWindowHeight != -1) {
			//If auto-sizing is disabled, use the specified height
			newWindowFrame.size.height = forcedWindowHeight;
		} else {
			/* Using vertical auto-sizing, so find and determine our new height
			 *
			 * First, subtract the current size of the view from our frame
			 */
			newWindowFrame.size.height -= viewFrame.size.height;
			
			//Now, figure out how big the view wants to be and add that to our frame
			newWindowFrame.size.height += desiredHeight;
			
			//Don't get bigger than our maxWindowHeight
			if (newWindowFrame.size.height > maxWindowHeight) {
				newWindowFrame.size.height = maxWindowHeight;
			} else if (newWindowFrame.size.height < 0) {
				newWindowFrame.size.height = 0;
			}
		}
		
		//Don't set a height smaller than the toolbar
		CGFloat windowHeight = NSHeight(windowFrame);
		CGFloat contentHeight = NSHeight([theWindow.contentView frame]);
		newWindowFrame.size.height = MAX(windowHeight - contentHeight, NSHeight(newWindowFrame));

		//Vertical positioning and size if we are placed on a screen
		if (NSHeight(newWindowFrame) >= NSHeight(boundingFrame)) {
			//If the window is bigger than the screen, keep it on the screen
			newWindowFrame.size.height = NSHeight(boundingFrame);
			newWindowFrame.origin.y = NSMinY(boundingFrame);
		} else {
			//A non-full height window is anchored to the appropriate screen edge
			if (dockToBottomOfScreen == AIDockToBottom_No) {
				//If the user did not dock to the bottom in any way last, the origin should move towards the saved origin
				if (NSMinX(previousWindowRect) == NSMinX(windowFrame) && NSMaxY(previousWindowRect) < NSMaxY(windowFrame))
					newWindowFrame.origin.y = NSMaxY(previousWindowRect) - NSHeight(newWindowFrame);
				else
					newWindowFrame.origin.y = NSMaxY(windowFrame) - NSHeight(newWindowFrame);
			} else {
				//If the user did dock (either to the full screen or the visible screen), the origin should remain in place.
				newWindowFrame.origin.y = NSMinY(windowFrame);	
			}
		}

		//We must never request a height of 0 or OS X will completely move us off the screen
		if (newWindowFrame.size.height == 0) newWindowFrame.size.height = 1;

		//Keep the window from hanging off any Y screen edge (This is optional and could be removed if this annoys people)
		if (NSMaxY(newWindowFrame) > NSMaxY(boundingFrame)) newWindowFrame.origin.y = NSMaxY(boundingFrame) - newWindowFrame.size.height;
		if (NSMinY(newWindowFrame) < NSMinY(boundingFrame)) newWindowFrame.origin.y = NSMinY(boundingFrame);		
	}

	if (useDesiredWidth) {
		/* If the desired height plus any toolbar height exceeds the height we determined, we will be showing a scroller; 
		 * expand horizontally to take that into account.
		 */
		if (desiredHeight + (NSHeight(windowFrame) - NSHeight(viewFrame)) > NSHeight(newWindowFrame)) {
			CGFloat scrollerWidth = [NSScroller scrollerWidthForControlSize:[[scrollView_contactList verticalScroller] controlSize]];
			newWindowFrame.size.width += scrollerWidth;
			
			if (anchorToRightEdge) {
				newWindowFrame.origin.x -= scrollerWidth;
			}
		}
		
		//We must never request a width of 0 or OS X will completely move us off the screen
		if (newWindowFrame.size.width == 0) newWindowFrame.size.width = 1;

		//Keep the window from hanging off any X screen edge (This is optional and could be removed if this annoys people)
		if (NSMaxX(newWindowFrame) > NSMaxX(boundingFrame)) newWindowFrame.origin.x = NSMaxX(boundingFrame) - NSWidth(newWindowFrame);
		if (NSMinX(newWindowFrame) < NSMinX(boundingFrame)) newWindowFrame.origin.x = NSMinX(boundingFrame);
	}
	
	return newWindowFrame;
}

@synthesize autoResizeHorizontally, autoResizeVertically, autoResizeHorizontallyWithIdleTime, minWindowSize, maxWindowWidth, forcedWindowWidth, maxWindowHeight, forcedWindowHeight;

//Content Updating -----------------------------------------------------------------------------------------------------
#pragma mark Content Updating

- (id<AIContainingObject>)contactList
{
	return (id<AIContainingObject>)contactList;
}

- (void)reloadListObject:(NSNotification *)notification
{
	AIListObject *object = notification.object;
	
	//Treat a nil object as equivalent to the whole contact list
	if (!object || (object == (AIListObject *)contactList)) {
		[contactListView reloadData];
	} else {
		for (AIProxyListObject *proxyObject in object.proxyObjects) {
            if ([(AIListObject<AIContainingObject> *)proxyObject.listObject isExpanded])
                [contactListView reloadItem:proxyObject reloadChildren:YES];
            else
                [contactListView reloadItem:proxyObject reloadChildren:NO];
        }
	}
}

/*!
 * @brief List object attributes changed
 *
 * Resize horizontally if desired and the display name changed
 */
- (void)listObjectAttributeChangesComplete:(NSNotification *)notification
{	
	[super listObjectAttributeChangesComplete:notification];
	
	if (((AIListObject *)notification.object).isStranger)
		return;
	
	NSSet *keys = [[notification userInfo] objectForKey:@"Keys"];

	//Resize the contact list horizontally
	if (self.autoResizeHorizontally) {
		if ([keys containsObject:@"Display Name"] || [keys containsObject:@"Long Display Name"] ||
				(self.autoResizeHorizontallyWithIdleTime && [keys containsObject:@"idleReadable"])) {
			[self contactListDesiredSizeChanged];
		}
	}
}

/*!
 * @brief The outline view selection changed
 *
 * On the next run loop, post Interface_ContactSelectionChanged.  Why wait for the next run loop?
 * If we post this notification immediately, our outline view may not yet be key, and the contact controller
 * will return nil for 'selectedListObject'.  If we wait, the outline view will be definitely be set as key, and
 * everything will work as expected.
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:Interface_ContactSelectionChanged
															object:nil];
	});
}

#pragma mark Drag & Drop

/*! 
 * @brief Method to check if operations need to be performed
 */
- (NSDragOperation)outlineView:(NSOutlineView*)outlineView 
				  validateDrop:(id <NSDraggingInfo>)info
				  proposedItem:(AIProxyListObject *)item
			proposedChildIndex:(NSInteger)idx
{
    NSArray			*types = [[info draggingPasteboard] types];
	NSDragOperation retVal = NSDragOperationNone;
	
	//No dropping into contacts
	BOOL allowBetweenContactDrop = (idx == NSOutlineViewDropOnItemIndex);
	AIListObject *proposedListObject = item.listObject;

	if ([types containsObject:@"AIListObject"]) {
		
		id			 dragItem;
		BOOL		 hasGroup = NO, hasNonGroup = NO;
		for (dragItem in dragItems) {
			if ([dragItem isKindOfClass:[AIListGroup class]])
				hasGroup = YES;
			if (![dragItem isKindOfClass:[AIListGroup class]])
				hasNonGroup = YES;
			if (hasGroup && hasNonGroup) break;
		}
		
		//Don't allow a drop within the contact list or within a group if we contain a mixture of groups and non-groups (e.g. contacts)
		if (hasGroup && hasNonGroup) return NSDragOperationNone;
		
		id	primaryDragItem = [dragItems objectAtIndex:0];

		/* If this is a reorder within a metacontact, allow it in all cases. */
		if (([primaryDragItem isKindOfClass:[AIListContact class]] && [proposedListObject isKindOfClass:[AIListContact class]]) &&
			([(AIListContact *)primaryDragItem parentContact] == [(AIListContact *)proposedListObject parentContact])) {
			return ((idx != NSOutlineViewDropOnItemIndex) ? NSDragOperationMove : NSDragOperationNone);
		}
		
		if ([primaryDragItem isKindOfClass:[AIListGroup class]]) {
			NSUInteger dropIndex = idx;
			
			//Disallow dragging groups into or onto other objects
			if (item != nil) {
				AIProxyListObject *currentGroupProxy = item;

				// Iterate until we reach the highest level.
				while ([outlineView parentForItem:currentGroupProxy] != nil) {
					currentGroupProxy = (AIProxyListObject *)[outlineView parentForItem:currentGroupProxy];
				}

				dropIndex = [self.contactList visibleIndexOfObject:currentGroupProxy.listObject];
			}
			
			if ([self.contactList containsObject:primaryDragItem]) {
				NSUInteger visibleIndex = [self.contactList visibleIndexOfObject:primaryDragItem];
				
				// If this is a drop on or directly below, we're not moving anywhere.
				if (visibleIndex == dropIndex || visibleIndex == dropIndex-1) {
					return NSDragOperationNone;
				}
			}
			
			[outlineView setDropItem:nil dropChildIndex:dropIndex];
				
			return NSDragOperationPrivate;
		}

		//We have one or more contacts. Don't allow them to drop on the contact list itself
		if (!item && adium.contactController.useContactListGroups) {
			/* The user is hovering on the contact list itself.
			 * If groups are shown at all, assuming we have any items in the list at all, she is hovering near but not in a group.
			 *   If (index > 0), the drag is below the end of a group. That group is at (index - 1) in the outline view's root.
			 *   If (index == 0), the drag is at the very top of the contact list.
			 * Do this right by shifting the drop to that group. 
			 */
			AIProxyListObject *itemAboveProposedIndex = (AIProxyListObject *)[[outlineView dataSource] outlineView:outlineView
																											 child:((idx > 0) ? (idx - 1) : 0)
																											ofItem:nil];
			if (![itemAboveProposedIndex isKindOfClass:[AIListGroup class]]) {
				itemAboveProposedIndex = [outlineView parentForItem:itemAboveProposedIndex];
			}

			idx = ((idx > 0) ?
					 [[outlineView dataSource] outlineView:outlineView numberOfChildrenOfItem:itemAboveProposedIndex] :
					 NSOutlineViewDropOnItemIndex);
			
			item = itemAboveProposedIndex;
			proposedListObject = item.listObject;

			[outlineView setDropItem:item dropChildIndex:idx];
		}

		if ((idx == NSOutlineViewDropOnItemIndex) && [proposedListObject isKindOfClass:[AIListContact class]] &&
			([info draggingSource] == [self contactListView])) {
			//Dropping into a contact or attaching groups: "link"
			if (([contactListView rowForItem:primaryDragItem] == -1) ||
				[primaryDragItem isKindOfClass:[AIListContact class]]) {
				retVal = NSDragOperationLink;

				if ([primaryDragItem isKindOfClass:[AIListContact class]] &&
					[proposedListObject isKindOfClass:[AIListContact class]] &&
					[[(AIListContact *)proposedListObject parentContact] isKindOfClass:[AIMetaContact class]]) {
					/* Dragging a contact into a contact which is already within a metacontact.
					 * This should retarget to combine the dragged contact with the metacontact.
					 */
					[outlineView setDropItem:[AIProxyListObject existingProxyListObjectForListObject:[(AIListContact *)item parentContact]
																				inListObject:[(AIListContact *)item parentContact].containingObjects.anyObject]
							  dropChildIndex:NSOutlineViewDropOnItemIndex];
				}

			} else {
				retVal = NSDragOperationMove;
			}
		
		} else if (!item || [outlineView isExpandable:item]) {
			//Figure out where we would insert the dragged item if the sort controller manages the location and it's going into an expandable item
			
			//XXX If we can sort manually but the sort controller also has some control (e.g. status sort with manual ordering), we should get a hint and make use of it.
			
			AISortController *sortController = [AISortController activeSortController];
			AIListObject<AIContainingObject> *container = proposedListObject ? (AIListObject<AIContainingObject> *)proposedListObject : adium.contactController.contactList;

			if (!sortController.canSortManually && [container containsObject:[dragItems objectAtIndex:0]]) {
				// We can't sort manually, and the container already has this item. No operation will take place.
				retVal = NSDragOperationNone;
			} else if (![sortController canSortManually]) {
				// We can't sort manually, but this container doesn't already have the item.
				
				NSUInteger insertIndex = [sortController indexForInserting:[dragItems objectAtIndex:0]
															   intoObjects:container.visibleContainedObjects
															   inContainer:container];

				[outlineView setDropItem:item dropChildIndex:insertIndex];
				
				retVal = ([NSEvent optionKey] ? NSDragOperationCopy : NSDragOperationPrivate);
			} else {
				// We can sort manually.
				
				/* A drop just below a metacontact will appear to be in the group (and should be).
				 * Adjust to fit reality accordingly.
				 */
				if (proposedListObject && [proposedListObject isKindOfClass:[AIMetaContact class]]) {
					BOOL isExpanded = [outlineView isItemExpanded:item];
					if ((isExpanded && (idx == [[outlineView dataSource] outlineView:outlineView
																numberOfChildrenOfItem:item])) ||
						(!isExpanded && (idx != NSOutlineViewDropOnItemIndex))) {
						
						AIProxyListObject<AIContainingObject> *parentObject = [outlineView parentForItem:item];

						[outlineView setDropItem:parentObject dropChildIndex:[parentObject visibleIndexOfObject:proposedListObject] + 1];
					}
				}
				
				retVal = ([NSEvent optionKey] ? NSDragOperationCopy : NSDragOperationPrivate);
			}
		} else {
			retVal = NSDragOperationPrivate;
		}

	} else if ([types containsObject:NSFilenamesPboardType] ||
			   [types containsObject:NSRTFPboardType] ||
			   [types containsObject:NSURLPboardType] ||
			   [types containsObject:NSStringPboardType] ||
			   [types containsObject:AIiTunesTrackPboardType]) {
		retVal = ((proposedListObject && [proposedListObject isKindOfClass:[AIListContact class]]) ? NSDragOperationLink : NSDragOperationNone);

	} else if (!allowBetweenContactDrop) {
		retVal = NSDragOperationNone;
	}

	return retVal;
}

- (NSArray *)arrayOfAllContactsFromArray:(NSArray *)inArray
{
	NSMutableArray *realDragItems = [NSMutableArray array];
	AIListObject   *aDragItem;
	for (aDragItem in inArray) {
		if ([aDragItem isKindOfClass:[AIMetaContact class]]) {
			[realDragItems addObjectsFromArray:[(AIMetaContact *)aDragItem containedObjects]];

		} else if ([aDragItem isKindOfClass:[AIListContact class]]) {
			//For listContacts, add all contacts with the same service and UID (on all accounts)
			[realDragItems addObjectsFromArray:[[adium.contactController allContactsWithService:aDragItem.service 
																							UID:aDragItem.UID] allObjects]];
		}
	}
	
	return realDragItems;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(AIProxyListObject *)item childIndex:(NSInteger)idx
{
	BOOL		success = YES;
	NSPasteboard *draggingPasteboard = [info draggingPasteboard];
	NSString	*availableType;

    if ((availableType = [draggingPasteboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]])) {
		//Kill the selection now, (in a more finder-esque way)
		[outlineView deselectAll:nil];

		//The tree root is not associated with our root contact list group, so we need to make that association here
		//XXX The contactList is actually an ESObjectWithProperties because it could also be an AIChat.  Confusing.
		if (item == nil) 
			item = [AIProxyListObject proxyListObjectForListObject:(AIListObject *)contactList inListObject:nil];

		//If we don't have drag items, we are dragging from another instance; build our own dragItems array
		//using the supplied internalObjectIDs
		if (!dragItems) {
			NSArray			*dragItemsUniqueIDs;
			NSMutableArray	*arrayOfDragItems;
			NSString		*uniqueID;
			
			dragItemsUniqueIDs = [draggingPasteboard propertyListForType:@"AIListObjectUniqueIDs"];
			arrayOfDragItems = [NSMutableArray array];
			
			/* XXX We need to know which source group these drag items came from such that we
			 * 1) use the right proxy object
			 * 2) can remove from that source group if moving into a new group
			 */
			for (uniqueID in dragItemsUniqueIDs) {
				[arrayOfDragItems addObject:[AIProxyListObject proxyListObjectForListObject:[adium.contactController existingListObjectWithUniqueID:uniqueID]
																			   inListObject:nil]];
			}
			
			//We will release this when the drag is completed
			dragItems = arrayOfDragItems;
		}		
		
		[[AIContactObserverManager sharedManager] delayListObjectNotifications];

		AILogWithSignature(@"Dropping into %@ (%@)", item, item.listObject);

		//Move the list object to its new location
		if ([item.listObject isKindOfClass:[AIListGroup class]]) {
			/* Can't drop into the offline group */

			if (item.listObject != adium.contactController.offlineGroup) {
				AIListGroup *group = (AIListGroup *)(item.listObject);
				
				for (AIProxyListObject *proxyObject in dragItems) {
					AIListObject *listObject = proxyObject.listObject;
					
					NSAssert2([group canContainObject:listObject], @"BUG: Attempting to drop %@ into %@", listObject, group);
					
					// Allow a drag into a group already containing the list object
					// if the group isn't containing -this- proxy.
					if (!([group containsObject:listObject] && proxyObject.containingObject == group)) {
						if([listObject isKindOfClass:[AIListContact class]]) {
							NSSet *sourceGroups = nil;
							
							if ([NSEvent optionKey]) {
								sourceGroups = [NSSet set];
							} else {
								if ([proxyObject.containingObject isKindOfClass:[AIChat class]]) {
									/*  Passing an empty sourceGroups set is equivalent to a simple addition.
									 *
									 * If we're dragging from a chat, just do an add; a move is nonsense.
									 */
									AILogWithSignature(@"Moving out of a meta or a chat");
									sourceGroups = [NSSet set];
								} else {
									sourceGroups = [NSSet setWithObject:proxyObject.containingObject];
								}
							}

							// Contact being moved to a new group.
							// Holding option copies into the new group (like in Finder)
							
							AILogWithSignature(@"Moving %@ from %@ to %@", listObject, sourceGroups, group);
							[adium.contactController moveContact:(AIListContact *)listObject
													  fromGroups:sourceGroups
													  intoGroups:[NSSet setWithObject:group]];

						} else if ([listObject isKindOfClass:[AIListGroup class]]) {							
							// Group being moved to a new detached window.
							NSAssert([group isKindOfClass:[AIContactList class]], @"Target group not an AIContactList");

							[adium.contactController moveGroup:(AIListGroup *)listObject
											   fromContactList:((AIListGroup *)listObject).contactList 
												 toContactList:(AIContactList *)group];
						}
					}
					
					[group moveContainedObject:listObject toIndex:idx];
					[adium.contactController sortListObject:listObject];
				}
				
				[[NSNotificationCenter defaultCenter] postNotificationName:Contact_OrderChanged
																	object:(dragItems.count > 1 ? nil : item.listObject)
																  userInfo:nil];
			} else {
				success = NO;
			}
			
		} else if ([item isKindOfClass:[AIMetaContact class]]) {
			if ([[dragItems objectAtIndex:0] isKindOfClass:[AIListContact class]] &&
				([(AIListContact *)[dragItems objectAtIndex:0] parentContact] != item.listObject)) {
				/* We are dragging a contact into a metacontact, and that contact isn't already part
				 * of that metacontact. This needs confirmation! */
				[self promptToCombineItems:dragItems withContact:(AIListContact *)(item.listObject)];

			} else {
				/* We're moving things around within a metacontact. Only get the contacts which are actually within it. */
				NSArray *startingArray = [self arrayOfAllContactsFromArray:dragItems];
				NSMutableSet *set = [NSMutableSet setWithArray:startingArray];
				[set intersectSet:[NSSet setWithArray:((AIMetaContact *)item).containedObjects]];

				for (AIListObject *obj in set) {
					[(AIMetaContact *)item moveContainedObject:(AIListContact *)obj toIndex:idx];
				}
			}
			[outlineView reloadData];

		} else if ([item isKindOfClass:[AIListContact class]]) {
			[self promptToCombineItems:dragItems withContact:(AIListContact *)(item.listObject)];
		}
				 
		[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];

		
	} else if ((availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:
																				   NSFilenamesPboardType, AIiTunesTrackPboardType, nil]])) {
		//Drag and Drop file transfer for the contact list.
		if ([item isKindOfClass:[AIListContact class]]) {
			NSArray			*files = nil;
			NSString		*file;
			
			if ([availableType isEqualToString:NSFilenamesPboardType]) {
				files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
				
			} else if ([availableType isEqualToString:AIiTunesTrackPboardType]) {
				files = [[info draggingPasteboard] filesFromITunesDragPasteboard];
			}

			NSMutableAttributedString *mutableString = [[NSMutableAttributedString alloc] initWithString:@""];
			
			for (file in files) {
				AITextAttachmentExtension   *attachment = [[AITextAttachmentExtension alloc] init];
				[attachment setPath:file];
				[attachment setString:[file lastPathComponent]];
				
				NSTextAttachmentCell		*cell = [[NSTextAttachmentCell alloc] initImageCell:[attachment iconImage]];
				[attachment setHasAlternate:NO];
				[attachment setAttachmentCell:cell];
				
				[mutableString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
			}
		
			AIChat *chat = [adium.chatController openChatWithContact:(AIListContact *)(item.listObject)
												  onPreferredAccount:YES];
			
			[chat.chatContainer.messageViewController addToTextEntryView:mutableString];
			
			[adium.interfaceController setActiveChat:chat];
			[NSApp activateIgnoringOtherApps:YES];
			[NSApp arrangeInFront:nil];

		} else {
			AILogWithSignature(@"No contact available to receive files");
			NSBeep();
		}

	} else if ((availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSRTFPboardType,
																				   NSURLPboardType, NSStringPboardType, nil]])) {
		//Drag and drop text sending via the contact list.
		if ([item isKindOfClass:[AIListContact class]]) {
			/* This will send the message. Alternately, we could just insert it into the text view... */
			NSAttributedString				*messageAttributedString = nil;
			
			if ([availableType isEqualToString:NSRTFPboardType]) {
				//for RTF data, we want to preserve the formatting, so use dataForType:
				messageAttributedString = [NSAttributedString stringWithData:[[info draggingPasteboard] dataForType:NSRTFPboardType]];
			}
			else if ([availableType isEqualToString:NSURLPboardType]) {
				//NSURLPboardType contains an NSURL object
				messageAttributedString = [NSAttributedString stringWithString:[[NSURL URLFromPasteboard:[info draggingPasteboard]] absoluteString]];
			}
			else if ([availableType isEqualToString:NSStringPboardType]) {
				//this is just plain text, so stringForType: works fine
				messageAttributedString = [NSAttributedString stringWithString:[[info draggingPasteboard] stringForType:NSStringPboardType]];
			}
			
			if(messageAttributedString && [messageAttributedString length] !=0) {
				AIChat *chat = [adium.chatController openChatWithContact:(AIListContact *)(item.listObject)
													  onPreferredAccount:YES];
				
				[chat.chatContainer.messageViewController addToTextEntryView:messageAttributedString];
				
				[adium.interfaceController setActiveChat:chat];
				[NSApp activateIgnoringOtherApps:YES];
				[NSApp arrangeInFront:nil];
			}
			else {
				success = NO;
			}

		} else {
			success = NO;
		}
	}
	
	[super outlineView:outlineView acceptDrop:info item:item childIndex:idx];
	
    return success;
}

- (void)promptToCombineItems:(NSArray *)items withContact:(AIListContact *)inContact
{
	for (AIListContact *listContact in [items arrayByAddingObject:inContact]) {
		// Make sure all of the items can join the contact.
		if (!listContact.canJoinMetaContacts) {
			NSRunAlertPanel(AILocalizedString(@"Unable to Combine", nil),
							AILocalizedString(@"%@ is not able to be combined into a meta contact.", nil),
							AILocalizedStringFromTable(@"OK", @"Buttons", "Verb 'OK' on a button"),
							nil,
							nil,
							listContact.displayName);
			return;
		}
	}
	
	NSString	*promptTitle;
	
	//Appropriate prompt
	if ([items count] == 1) {
		promptTitle = [NSString stringWithFormat:AILocalizedString(@"Combine %@ and %@?","Title of the prompt when combining two contacts. Each %@ will be filled with a contact name."),
					   [[items objectAtIndex:0] displayName], inContact.displayName];
	} else {
		promptTitle = [NSString stringWithFormat:AILocalizedString(@"Combine these contacts with %@?","Title of the prompt when combining two or more contacts with another.  %@ will be filled with a contact name."),
					   inContact.displayName];
	}
	
	//Metacontact creation, prompt the user
	NSDictionary	*context = [NSDictionary dictionaryWithObjectsAndKeys:
								inContact, @"destinationListContact",
								items, @"dragitems", nil];
	
	NSBeginInformationalAlertSheet(promptTitle,
								   AILocalizedString(@"Combine","Button title for accepting the action of combining multiple contacts into a metacontact"),
								   AILocalizedString(@"Cancel",nil),
								   nil,
								   nil,
								   self,
								   @selector(mergeContactSheetDidEnd:returnCode:contextInfo:),
								   nil,
								   (__bridge_retained void *)(context), //we're responsible for retaining the content object
								   AILocalizedString(@"Once combined, Adium will treat these contacts as a single individual both on your contact list and when sending messages.\n\nYou may un-combine these contacts by getting info on the combined contact.","Explanation of metacontact creation"));
}	

- (void)mergeContactSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSDictionary	*context = (__bridge NSDictionary *)contextInfo;

	if (returnCode == 1) {
		AIListObject	*destinationListContact = [context objectForKey:@"destinationListContact"];
		NSArray			*draggedItems = [context objectForKey:@"dragitems"];

		//Group the destination and then the dragged items into a metaContact
		[adium.contactController groupContacts:[[NSArray arrayWithObject:destinationListContact]
								arrayByAddingObjectsFromArray:[self arrayOfAllContactsFromArray:draggedItems]]];

		//XXX multiple containers: we need to make sure that the metacontacts respect manual ordering correctly
		
		[[NSNotificationCenter defaultCenter] postNotificationName:Contact_OrderChanged object:nil];
	}
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == contactListView && [keyPath isEqualToString:@"desiredHeight"]) {
		if ([[change objectForKey:NSKeyValueChangeNewKey] integerValue] != [[change objectForKey:NSKeyValueChangeOldKey] integerValue])
			[self contactListDesiredSizeChanged];
		
	}
}

#pragma mark Preferences

- (AIContactListWindowStyle)windowStyle
{
	NSNumber	*windowStyleNumber = [adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE 
																			  group:PREF_GROUP_APPEARANCE];
	return (windowStyleNumber ? [windowStyleNumber intValue] : AIContactListWindowStyleStandard);
}



@end
