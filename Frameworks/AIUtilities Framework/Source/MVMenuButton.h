//Adapted from Colloquy  (www.colloquy.info)

/*!
 * @class MVMenuButton
 * @brief Button with a popup menu for use with an NSToolbarItem
 *
 * Button which has a popup menu, including a menu arrow in the bottom right corner, for use as the custom view of an NSToolbarItem
 */
@interface MVMenuButton : NSButton <NSCopying> {
	NSImage				*bigImage;
	NSImage				*smallImage;
	NSToolbarItem 		*toolbarItem;
	NSBezierPath 		*arrowPath;
	
	BOOL				drawsArrow;
	NSControlSize 		controlSize;
}

/*!
 * @brief Set the <tt>NSControlSize</tt> at which the button will be displayed.
 * @param inSize A value of type <tt>NSControlSize</tt>
*/ 
- (void)setControlSize:(NSControlSize)inSize;
/*!
 * @brief The current <tt>NSControlSize</tt> at which the button will be displayed.
 * @return A value of type <tt>NSControlSize</tt>
*/ 
- (NSControlSize)controlSize;

/*!
 * @brief Set the image of the button
 *
 * It will be automatically sized as necessary.
 * @param inImage An <tt>NSImage</tt> to use.
*/ 
- (void)setImage:(NSImage *)inImage;
/*!
 * @brief Returns the image of the button
 * @return An <tt>NSImage</tt>.
*/ 
- (NSImage *)image;

/*!
 * @brief Set the toolbar item associated with this button
 *
 * This is used for synchronizing sizing.
 * @param item The <tt>NSToolbarItem</tt> to associate.
 */
- (void)setToolbarItem:(NSToolbarItem *)item;

/*!
 * @brief Returns the toolbar item associated with this button
 * @return The <tt>NSToolbarItem</tt>
 */
- (NSToolbarItem *)toolbarItem;

/*!
 * @brief Set whether the button draws a dropdown arrow.
 *
 * The arrow is black and positioned in the lower righthand corner of the button; it is used to indicate that clicking on the button will reveal further information or choices.
 * @param inDraw YES if the arrow should be drawn.
 */
- (void)setDrawsArrow:(BOOL)inDraw;

/*!
 * @brief Returns if the button draws its arrow
 * @return YES if the arrow is drawn.
 */
- (BOOL)drawsArrow;

@end
