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

#define AIOutlineViewUserDidExpandItemNotification		@"AIOutlineViewUserDidExpandItemNotification"
#define AIOutlineViewUserDidCollapseItemNotification	@"AIOutlineViewUserDidCollapseItemNotification"

@class NSMutableString;
@class NSMenu, NSEvent, NSOutlineView, NSImage;
@class AIOutlineView;



/*!
 * @protocol AIOutlineViewDelegate
 * @brief Delegate protocol for <tt>AIOutlineView</tt>
 *
 * Implementation of all methods is optional.
 */
@protocol AIOutlineViewDelegate <NSOutlineViewDelegate, NSOutlineViewDataSource>
@optional
/*!
 * @brief Requests a contextual menu for an event from the delegate
 *
 * This delegate method gives the delegate an opportunity to return an <tt>NSMenu</tt> to be displayed when the user right-clicks (control-clicks) in the outline view.  The passed event can be used to determine where the click occurred to make the menu sensitive to which row or column was clicked.
 * @param outlineView The <tt>NSOutlineView</tt> which was clicked
 * @param theEvent The event of the click
 * @return An <tt>NSMenu</tt> to be displayed, or nil if no menu should be displayed
 */
- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForEvent:(NSEvent *)theEvent;

/*!
 * outlineView:setExpandState:ofItem:
 * @brief Informs the delegate that the item was collapsed or exapnded
 *
 * This delegate method informs the delegate that the item was collapsed or expanded.
 * @param outlineView The <tt>NSOutlineView</tt> which was changed
 * @param state YES if the item is now expanded; NO if it is no collapsed
 * @param item The item which was changed
 */
- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item;

/*!
 * @brief Requests the correct expanded state for an item
 *
 * After reloading data, NSOutlineView collapses all items, which is generally not a desired behavior.  <tt>AIOutlineView</tt> provides the delegate an opportunity to specify whether each item should be exapnded or collapsed after a reload. This delegate method should return the correct expanded state of the passed item.
 * @param outlineView The <tt>NSOutlineView</tt> which is reloading data
 * @param item The item whose expanded state is requested
 * @return YES if the item should be expanded; NO if it should be collapsed
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item;

/*!
 * @brief Informs the delegate of a request to delete the selected rows
 *
 * Informs the delegate of a request to delete the selected rows (via the delete key, generally). The delegate may wish to retrieve the currently selected rows and remove them from the data source and subsequently reload the outline view.
 * @param outlineView The <tt>NSOutlineView</tt> from which the user wants to delete one or more rows.
 */
- (void)outlineViewDeleteSelectedRows:(NSOutlineView *)outlineView;

/*!
 * @brief Passes on NSObject's <tt>draggedImage:endedAt:operation:</tt> to the delegate
 *
 * Passes on NSObject's <tt>draggedImage:endedAt:operation:</tt>, which is invoked in the dragging source as the drag ends, 
 * to the delegate.  See <tt>NSObject</tt>'s documentation for more details.
 *
 * @param outlineView The <tt>NSOutlineView</tt> which ended the drag
 * @param image The <tt>NSImage</tt> drag image
 * @param screenPoint An <tt>NSPoint</tt> in screen coordinates
 * @param operation The <tt>NSDragOperation</tt> of the drag
 */
- (void)outlineView:(NSOutlineView *)outlineView draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation;

/*!
 * @brief Informs the delegate of a request to show or hide the fine panel
 *
 * Informs the delegate of a request to show the find panel if it is hidden, and hide it if shown. The delegate must implement the find panel UI and filtering
 * @param outlineView The <tt>NSOutlineView</tt> that the user wants to filter
 */
- (void)outlineViewToggleFindPanel:(NSOutlineView *)outlineView;


/*!
 * @brief Informs the delegate of a request to forward a key down event to the find panel text field, displaying it if necessary
 *
 * Informs the delegate of a request to forward a key down event to the find panel text field,displaying it if necessary. The key down event was recieved by outlineView, and it determined it should be added to the search string
 * @param outlineView The <tt>NSOutlineView</tt> that the user wants to filter
 * @param theEvent The key down event
 *
 * @result YES if the find panel handled theEvent. If NO, outlineView will forward theEvent to super for handling
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView forwardKeyEventToFindPanel:(NSEvent *)theEvent;

@end

/*!
 * @protocol AIAlternatingRowsProtocol
 * @brief Delegate protocol for <tt>AIOutlineView</tt>
 *
 * Implementation of all methods is optional.
 */
@protocol AIAlternatingRowsProtocol

/*!
 * @brief Draws rows of the view with alternating colors
 *
 * @param rect The <tt>NSRect</tt> defining the background to color.
 */
- (void)drawAlternatingRowsInRect:(NSRect)rect;
@end


/*!
 * @class AIOutlineView
 * @brief An NSOutlineView subclass with several improvments
 *
 * <p>This <tt>NSOutlineView</tt> subclass has several improvements and serves as the base class for the other outline view subclasses in the AIUtilities framework.</p>
 * <p>It supports contextual menu, expanded state, deletion, and dragging-ended notification methods for its delegate (see the <tt>AIOutlineViewDelegate</tt> protocol description for details).</p>
 * <p>It posts AIOutlineViewUserDidExpandItemNotification and AIOutlineViewUserDidCollapseItemNotification to the default NSNotificationCenter when items expand and collapse, respectively; for these notifications, the object is the <tt>AIOutlineView</tt> and the userInfo is an NSDictionary with the changed item in the key @"Object".
 * <p>It supports improved keyboard navigation of the outline view, including supporting the delete key.</p>
 * <p>It adds the use of tab and backtab to cycle through matches when using KFTypeSelectTableView</p>
 * <p>Finally, it fixes a crash when reloadData is called from 'outlineView:setObjectValue:forTableColumn:byItem:' while the last row is edited in a way that will reduce the number of rows in the outline view (crash fix is relevant on all system versions as of OS X 10.3.7).</p>
*/
@interface AIOutlineView : NSOutlineView {
    BOOL		needsReload;
	BOOL		ignoreExpandCollapse;
}
- (void)performFindPanelAction:(id)sender;
@end
