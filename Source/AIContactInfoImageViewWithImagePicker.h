//
//  AIContactInfoImageViewWithImagePicker.h
//  Adium
//
//  Created by Evan Schoenberg on 10/1/06.
//

#import <AIUtilities/AIImageViewWithImagePicker.h>

@interface AIContactInfoImageViewWithImagePicker : AIImageViewWithImagePicker {
	BOOL				resetImageHovered;
	NSTrackingRectTag	resetImageTrackingTag;
	BOOL				showResetImageButton;
}

- (void)setShowResetImageButton:(BOOL)inShowResetImageButton;

@end
