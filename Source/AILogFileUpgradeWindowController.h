//
//  AILogFileUpgradeWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 6/22/06.
//

#import <Adium/AIWindowController.h>

@interface AILogFileUpgradeWindowController : AIWindowController {
	IBOutlet	NSTextField	*label_upgrading;
	IBOutlet	NSProgressIndicator	*progressIndicator;
}

- (void)setProgress:(double)progress;

@end
