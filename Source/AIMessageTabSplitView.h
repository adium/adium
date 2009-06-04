//
//  AIMessageTabSplitView.h
//  Adium
//
//  Created by Evan Schoenberg on 4/9/07.
//

#import <AIUtilities/AISplitView.h>

@interface AIMessageTabSplitView : AISplitView {
	NSColor *leftColor;
	NSColor *rightColor;
}

- (void)setLeftColor:(NSColor *)inLeftColor rightColor:(NSColor *)inRightColor;

@end
