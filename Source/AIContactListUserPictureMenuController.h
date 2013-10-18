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


#import <AIUtilities/AIImageCollectionView.h>


@class AIImageCollectionView, AIImageCollectionViewDelegate, AIContactListImagePicker;

/*!
 * @class AIContactListUserPictureMenuController
 * @brief Handles fast User Picture switching
 *
 * Opens a contextual (pop-up) menu, allowing to switch user picture.
 * Supports changing for individual accounts, image editing and caputring from a camera.
 */
@interface AIContactListUserPictureMenuController : NSObject <AIImageCollectionViewDelegate> {
	IBOutlet NSMenu *__weak menu;
	IBOutlet AIImageCollectionView *__weak imageCollectionView;
	
	AIContactListImagePicker *__weak imagePicker;
	
	NSArray *images;

@private
	NSMutableArray *AI_topLevelObjects;
}

@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet AIImageCollectionView *imageCollectionView;
@property (weak) AIContactListImagePicker *imagePicker;
@property (copy) NSArray *images;

/*!
 * @brief Open the menu
 *
 * @param aPoint	The bottom-left corner of our parent view
 * @param picker	Our parent AIContactListImagePicker
 */
+ (void)popUpMenuForImagePicker:(AIContactListImagePicker *)picker;

@end
