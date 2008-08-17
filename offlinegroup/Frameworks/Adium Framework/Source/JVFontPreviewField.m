// From Colloquy

#import <Adium/JVFontPreviewField.h>

@implementation JVFontPreviewField

- (id) initWithCoder:(NSCoder *) coder {
	self = [super initWithCoder:coder];
	if ( [coder allowsKeyedCoding] ) {
		_showPointSize = [coder decodeBoolForKey:@"showPointSize"];
		_showFontFace = [coder decodeBoolForKey:@"showFontFace"];
		_actualFont = [[coder decodeObjectForKey:@"actualFont"] retain];
	} else {
		[coder decodeValueOfObjCType:@encode( char ) at:&_showPointSize];
		[coder decodeValueOfObjCType:@encode( char ) at:&_showFontFace];
		_actualFont = [[coder decodeObject] retain];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder {
	[super encodeWithCoder:coder];
	if ( [coder allowsKeyedCoding] ) {
		[coder encodeBool:_showPointSize forKey:@"showPointSize"];
		[coder encodeBool:_showFontFace forKey:@"showFontFace"];
		[coder encodeObject:_actualFont forKey:@"actualFont"];
	} else {
		[coder encodeValueOfObjCType:@encode( char ) at:&_showPointSize];
		[coder encodeValueOfObjCType:@encode( char ) at:&_showFontFace];
		[coder encodeObject:_actualFont];
	}
}

- (void) dealloc {
	[_actualFont release];
	_actualFont = nil;
	[super dealloc];
}

- (void) changeFont:(id) sender {
	NSFont *font = [sender convertFont:[self font]];

	if (!font) return;

	if ([[self delegate] respondsToSelector:@selector(fontPreviewField:shouldChangeToFont:)])
		if (![[self delegate] fontPreviewField:self shouldChangeToFont:font]) return;

	[self setFont:font];

	if ([[self delegate] respondsToSelector:@selector(fontPreviewField:didChangeToFont:)])
		[[self delegate] fontPreviewField:self didChangeToFont:font];
}

#ifndef MAC_OS_X_VERSION_10_3
#define NSFontPanelStandardModesMask 0
#define NSFontPanelSizeModeMask 0
#define NSFontPanelFaceModeMask 0
#endif

- (unsigned int) validModesForFontPanel:(NSFontPanel *) fontPanel
{
	unsigned int ret = NSFontPanelStandardModesMask;
	if (!_showPointSize) ret ^= NSFontPanelSizeModeMask;
	if (!_showFontFace) ret ^= NSFontPanelFaceModeMask;
	return ret;
}

- (BOOL) becomeFirstResponder 
{
	[[NSFontManager sharedFontManager] setSelectedFont:_actualFont isMultiple:NO];
	return YES;
}

/*!
 * @brief Take no action on mouse down
 * 
 * We return YES for isEditable, but we don't actually want the user to be able to edit us.
 */
- (void)mouseDown:(NSEvent *)inEvent
{
	[[self window] makeFirstResponder:self];
}

/*!
 * @brief We want to say we are editable so that the font panel talks to us properly
 *
 * For example, if isEditable returns NO, typing a font size into the size text area and hitting enter has no effect.
 */
- (BOOL)isEditable
{
	return YES;
}

- (void) updateDisplayedFont
{
	if (_actualFont) {
		NSMutableAttributedString *text = nil;

		[super setFont:[[NSFontManager sharedFontManager] convertFont:_actualFont toSize:11.]];
		
		if (_showPointSize) {
			text = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %.0f", (_showFontFace ? [_actualFont displayName] : [_actualFont familyName]), [_actualFont pointSize]]] autorelease];
		} else {
			text = [[[NSMutableAttributedString alloc] initWithString:( _showFontFace ? [_actualFont displayName] : [_actualFont familyName] )] autorelease];
		}
		
		NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		
		[paraStyle setMinimumLineHeight:NSHeight([self bounds])];
		[paraStyle setMaximumLineHeight:NSHeight([self bounds])];
		[text addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(0, [text length])];
		
		[self setObjectValue:text];
	}
}

- (IBAction) chooseFontWithFontPanel:(id) sender
{
	[[self window] makeFirstResponder:self];
	
	[self setKeyboardFocusRingNeedsDisplayInRect:[self frame]];

	[[NSFontManager sharedFontManager] orderFrontFontPanel:nil];
}

- (void) setFont:(NSFont *)font
{
	if (!font) return;
	
	[_actualFont autorelease];
	_actualFont = [font retain];
	
	[self updateDisplayedFont];
}

- (void) setShowPointSize:(BOOL) show 
{
	_showPointSize = show;
	[self updateDisplayedFont];
}

- (void) setShowFontFace:(BOOL) show
{
	_showFontFace = show;
	[self updateDisplayedFont];
}


//Drawing ------------------------------------------------------------------------
#pragma mark Drawing
//Focus ring drawing code by Nicholas Riley, posted on cocoadev and available at:
//http://cocoa.mamasam.com/COCOADEV/2002/03/2/29535.php
- (BOOL)needsDisplay
{
	NSResponder *resp = nil;
	NSWindow	*window = [self window];
	
	if ([window isKeyWindow]) {
		resp = [window firstResponder];
		if (resp == lastResp) {
			return [super needsDisplay];
		}
		
	} else if (lastResp == nil) {
		return [super needsDisplay];
		
	}
	
	shouldDrawFocusRing = (resp != nil &&
						   [resp isKindOfClass:[NSView class]] &&
						   [(NSView *)resp isDescendantOf:self]); // [sic]
	lastResp = resp;
	
	[self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
	return YES;
}

//Draw a focus ring around our view
- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	if (shouldDrawFocusRing) {
		NSSetFocusRingStyle(NSFocusRingOnly);
		NSRectFill(rect);
	}
} 
	
@end
