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


@protocol AIImageCollectionViewDelegate;

#pragma mark - AIImageCollectionView

/*!
 * @class AIImageCollectionView
 * @brief NSCollectionView subclass
 *
 * Displays images in a grid
 * supports item highlighting and selection
 */
@interface AIImageCollectionView : NSCollectionView {
@protected
	IBOutlet NSArrayController *itemsController;
	
	NSInteger highlightStyle;
	CGFloat highlightSize;
	CGFloat highlightCornerRadius;

	NSUInteger highlightedIndex;
}

@property (readwrite, assign) id <AIImageCollectionViewDelegate, NSCollectionViewDelegate> delegate;

@property (assign) IBOutlet NSArrayController *itemsController;

@property (assign) NSInteger highlightStyle;
@property (assign) CGFloat highlightSize;
@property (assign) CGFloat highlightCornerRadius;
@property (assign) NSUInteger highlightedIndex;

#pragma mark -

/*!
 * @brief Set the image for item at index
 *
 * @param <tt>NSImage</tt>
 * @param <tt>NSUInteger</tt>
 */
- (void)setImage:(NSImage *)anImage forItemAtIndex:(NSUInteger)anIndex;

@end

#pragma mark -

/*!
 * @brief AIImageCollectionViewCornerStyle
 *
 * Item & Highlight corners style, squared|rounded
 */
enum {
	AIImageCollectionViewCornerSquaredStyle = 0,
	AIImageCollectionViewCornerRoundedStyle = 1
};

typedef NSInteger AIImageCollectionViewCornerStyle;

/*!
 * @brief AIImageCollectionViewHighlightStyle
 *
 * Highlight style, border|background
 */
enum {
	AIImageCollectionViewHighlightBorderStyle = 0,
	AIImageCollectionViewHighlightBackgroundStyle = 1
};

typedef NSInteger AIImageCollectionViewHighlightStyle;

#pragma mark - AIImageCollectionViewDelegate

/*!
 * @protocol AIImageCollectionViewDelegate
 * @brief Sends highlighting/selection related messages to a delegate
 */
@protocol AIImageCollectionViewDelegate <NSObject>

@optional

- (BOOL)imageCollectionView:(AIImageCollectionView *)imageCollectionView shouldSelectItemAtIndex:(NSUInteger)index;
- (BOOL)imageCollectionView:(AIImageCollectionView *)imageCollectionView shouldHighlightItemAtIndex:(NSUInteger)index;
- (BOOL)imageCollectionView:(AIImageCollectionView *)imageCollectionView shouldDeleteItemsAtIndexes:(NSIndexSet *)indexes;
- (void)imageCollectionView:(AIImageCollectionView *)imageCollectionView didSelectItemAtIndex:(NSUInteger)index;
- (void)imageCollectionView:(AIImageCollectionView *)imageCollectionView didHighlightItemAtIndex:(NSUInteger)index;
- (void)imageCollectionView:(AIImageCollectionView *)imageCollectionView didDeleteItemsAtIndexes:(NSIndexSet *)indexes;

@end
