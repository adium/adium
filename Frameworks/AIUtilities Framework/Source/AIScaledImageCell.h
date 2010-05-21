//
//  AIScaledImageCell.h
//  AIUtilities.framework
//
//  Created by Adam Iser on 8/17/04.
//

/*!
 * @class AIScaledImageCell
 * @brief An <tt>NSImageCell</tt> subclass which scales its image to fit.
 *
 * An <tt>NSImageCell</tt> subclass which scales its image to fit.  The image will be scaled proportionally if needed, modifying the size in the optimal direction.
 */
@interface AIScaledImageCell : NSImageCell {
	BOOL	isHighlighted;
	
	NSSize	maxSize;
}

/*
 * @brief Set the maximum image size
 *
 * A 0 width or height indicates no maximum. The default is NSZeroSize, no maximum besides the cell bounds.
 */
- (void)setMaxSize:(NSSize)inMaxSize;

@end
