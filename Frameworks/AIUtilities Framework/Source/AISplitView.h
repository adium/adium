//
//  AISplitView.h
//  AIUtilities.framework
//
//  Created by Adam Iser on 2/6/05.
//  Copyright 2005 the Adium Team. All rights reserved.
//


/*!
 * @class AISplitView
 * @brief <tt>NSSplitView</tt> subclass with additional customization
 *
 * This subclass of NSSplitView allows the user to adjust the thickness of the divider and disable drawing of the
 * divider 'dot' graphic.
 */
@interface AISplitView : NSSplitView {
	CGFloat	dividerThickness;
	BOOL	drawDivider;
}

/*!
 * @brief Set the thickness of the split divider
 *
 * Set the thickness of the split divider
 * @param inThickness Desired divider thickness
 */
- (void)setDividerThickness:(CGFloat)inThickness;

/*!
 * @brief Toggle drawing of the divider graphics
 *
 * Toggle display of the divider graphics (The 'dot' in the center of the divider)
 * @param inDraw NO to disable drawing of the dot, YES to enable it
 */
- (void)setDrawsDivider:(BOOL)inDraw;

@end
