//
//  AISearchFieldCell.h
//  Adium
//
//  Created by Evan Schoenberg on 5/1/08.
//


@interface AISearchFieldCell : NSSearchFieldCell {
	NSColor *backgroundColor;
}

- (void)setTextColor:(NSColor *)inTextColor backgroundColor:(NSColor *)inBackgroundColor;

@end
