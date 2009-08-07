//
//  SetupWizardBackgroundView.h
//  Adium
//
//  Created by Evan Schoenberg on 12/4/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//



@interface SetupWizardBackgroundView : NSView {
	NSRect transparentRect;
	NSImage	*backgroundImage;
}

- (void)setBackgroundImage:(NSImage *)inImage;
- (void)setTransparentRect:(NSRect)inTransparentRect;

@end
