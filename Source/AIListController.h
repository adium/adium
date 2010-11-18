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

#import <Adium/AIAbstractListController.h>
#import <Adium/AIContactControllerProtocol.h>

@class AIAbstractListController;

typedef enum {
	AIDockToBottom_No = 0,
    AIDockToBottom_VisibleFrame,
	AIDockToBottom_TotalFrame
} AIDockToBottomType;

@interface AIListController : AIAbstractListController {
    NSSize					minWindowSize;
    BOOL					autoResizeVertically;
    BOOL					autoResizeHorizontally;
	BOOL					autoResizeHorizontallyWithIdleTime;
	NSInteger						maxWindowWidth;
	NSInteger						forcedWindowWidth;

	AIDockToBottomType 		dockToBottomOfScreen;

	BOOL					needsAutoResize;
}

- (id)initWithContactList:(id<AIContainingObject>)aContactList
			inOutlineView:(AIListOutlineView *)inContactListView
			 inScrollView:(AIAutoScrollView *)inScrollView_contactList
				 delegate:(id<AIListControllerDelegate>)inDelegate;

- (id<AIContainingObject>) contactList;

//Call to close down and release the listController
- (void)close;

- (void)contactListDesiredSizeChanged;
- (void)contactListWillSlideOnScreen;

@property (nonatomic) BOOL autoResizeHorizontally;
@property (nonatomic) BOOL autoResizeHorizontallyWithIdleTime;
@property (nonatomic) BOOL autoResizeVertically;
@property (nonatomic) NSInteger maxWindowWidth;
@property (nonatomic) NSSize minWindowSize;
@property (nonatomic) NSInteger forcedWindowWidth;

- (NSRect)_desiredWindowFrameUsingDesiredWidth:(BOOL)useDesiredWidth desiredHeight:(BOOL)useDesiredHeight;

- (void)reloadListObject:(NSNotification *)notification;

@end

