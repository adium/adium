//
//  AIHoveringPopUpButtonCell.h
//  Adium
//
//  Created by Evan Schoenberg on 12/16/05.
//

@interface AIHoveringPopUpButtonCell : NSButtonCell {
	NSMutableAttributedString		*title;
	NSSize							textSize;

	NSImage							*currentImage;
	NSSize							imageSize;

	NSMutableDictionary				*statusAttributes;
	NSMutableParagraphStyle			*statusParagraphStyle;
	
	BOOL					hovered;
	CGFloat					hoveredFraction;
}

- (void)setTitle:(NSString *)inTitle;
- (void)setImage:(NSImage *)inImage;

- (void)setHovered:(BOOL)inHovered animate:(BOOL)animate;
- (BOOL)hovered;
- (CGFloat)trackingWidth;

@end
