//
//  AIContactListRecentImagesWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 12/19/05.
//

#import <Adium/AIWindowController.h>
#import <AIUtilities/AIImageGridView.h>

@class AIImageGridView, AIColoredBoxView, AIMenuItemView, AIContactListImagePicker;

@interface AIContactListRecentImagesWindowController : AIWindowController <AIImageGridViewDelegate> {
	IBOutlet	AIImageGridView	 *imageGridView;
	IBOutlet	AIColoredBoxView *coloredBox;
	IBOutlet	AIMenuItemView	 *menuItemView;
	IBOutlet	NSTextField		 *label_recentIcons;
	
	AIContactListImagePicker *picker;

	NSInteger currentHoveredIndex;
}

+ (void)showWindowFromPoint:(NSPoint)inPoint
				imagePicker:(AIContactListImagePicker *)inPicker;

- (void)positionFromPoint:(NSPoint)inPoint;

@end
