//
//  AIMessageWindowOutgoingScrollView.h
//  Adium
//
//  Created by Evan Schoenberg on 1/13/08.
//


@interface AIMessageWindowOutgoingScrollView : NSScrollView {
	id accessibilityChild;
}

- (void)setAccessibilityChild:(id)inChild;

@end
