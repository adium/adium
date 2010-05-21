// From Colloquy (http://colloquy.info/)

#import <AppKit/NSTextField.h>

@class NSFont;

@interface JVFontPreviewField : NSTextField {
	NSFont *_actualFont;
	BOOL _showPointSize;
	BOOL _showFontFace;

	BOOL					shouldDrawFocusRing;
	NSResponder				*lastResp;
}
- (IBAction)chooseFontWithFontPanel:(id)sender;
- (void)setShowPointSize:(BOOL)show;
- (void)setShowFontFace:(BOOL)show;
@end

@interface NSObject (JVFontPreviewFieldDelegate)
- (BOOL)fontPreviewField:(JVFontPreviewField *)field shouldChangeToFont:(NSFont *)font;
- (void)fontPreviewField:(JVFontPreviewField *)field didChangeToFont:(NSFont *)font;
@end
