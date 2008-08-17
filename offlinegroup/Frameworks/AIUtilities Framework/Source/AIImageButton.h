//
//  AIImageButton.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/16/04.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import <AIUtilities/MVMenuButton.h>

@class AIFloater;

/*!
 * @class AIImageButton
 * @brief Button which displays an image when clicked for use as the custom view of an NSToolbarItem.
 *
 * The image remains as long as the mouse button is held down; if it is an animating image, it will animate.  See <tt>MVMenuButton</tt> for the API.
 */
@interface AIImageButton : MVMenuButton {
	AIFloater	*imageFloater;
	BOOL		imageFloaterShouldBeOpen; //Track if the image float should currently be open; useful since the floater is desroyed on a delay.
}

@end
