//
//  AIGenericViewCell.h
//  Adium
//
//  Created by Mac-arena the Bored Zo on Sun May 09 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import <AppKit/NSCell.h>

/*
 * @class AIGenericViewCell
 * @brief A cell which can display any view
 *
 * This cell allows any view to be used in a table or outlineview.
 * Based on sample code from SubViewTableView by Joar Wingfors, http://www.joar.com/code/
 */
@interface AIGenericViewCell : NSCell
{
	NSView	*embeddedView;
}

/*
 * @brief Set the NSView this cell displays
 *
 * This should be called before the cell is used, such as in a tableView:willDisplayCell: type delegate method.
 *
 * @param inView The view to display
 */
- (void)setEmbeddedView:(NSView *)inView;

/*
 * @brief Used within AIUtilities to generate a drag image from this cell
 *
 * This is a hack, and it's not a particularly great one.  A drawing context must be locked before this is called.
 *
 * @param cellFrame The frame of the cell
 * @param controlView The view into which the cell is drawing
 */
- (void)drawEmbeddedViewWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

@end
