//
//  AILogFileUpgradeWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 6/22/06.
//

#import "AILogFileUpgradeWindowController.h"


@implementation AILogFileUpgradeWindowController
- (void)windowDidLoad
{
	[progressIndicator setDoubleValue:0];
	[super windowDidLoad];
}

- (void)setProgress:(double)progress
{
	[progressIndicator setDoubleValue:progress];
}
@end
