//
//  AIContactListRecentImagesWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 12/19/05.
//

#import <Adium/AIWindowController.h>

@class AIImageGridView, AIColoredBoxView, AIMenuItemView, AIContactListImagePicker;

@interface AIContactListRecentImagesWindowController : AIWindowController {
	IBOutlet	AIImageGridView	 *imageGridView;
	IBOutlet	AIColoredBoxView *coloredBox;
	IBOutlet	AIMenuItemView	 *menuItemView;
	IBOutlet	NSTextField		 *label_recentIcons;
	
	AIContactListImagePicker *picker;

	int currentHoveredIndex;
}

+ (void)showWindowFromPoint:(NSPoint)inPoint
				imagePicker:(AIContactListImagePicker *)inPicker;

- (void)positionFromPoint:(NSPoint)inPoint;

@end
