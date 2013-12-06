// From Colloquy
/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Adium/JVFontPreviewField.h>

@implementation JVFontPreviewField

- (id) initWithCoder:(NSCoder *) coder {
	self = [super initWithCoder:coder];
	if ( [coder allowsKeyedCoding] ) {
		_showPointSize = [coder decodeBoolForKey:@"showPointSize"];
		_showFontFace = [coder decodeBoolForKey:@"showFontFace"];
		_actualFont = [coder decodeObjectForKey:@"actualFont"];
	} else {
		[coder decodeValueOfObjCType:@encode( char ) at:&_showPointSize];
		[coder decodeValueOfObjCType:@encode( char ) at:&_showFontFace];
		_actualFont = [coder decodeObject];
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

- (void) changeFont:(id) sender {
	NSFont *font = [sender convertFont:[self font]];
	NSObject <NSObject,JVFontPreviewFieldDelegate> *__delegate = (id <NSObject,JVFontPreviewFieldDelegate>)self.delegate;

	if (!font) return;

	if ([__delegate respondsToSelector:@selector(fontPreviewField:shouldChangeToFont:)])
		if (![__delegate fontPreviewField:self shouldChangeToFont:font]) return;

	[self setFont:font];

	if ([__delegate respondsToSelector:@selector(fontPreviewField:didChangeToFont:)])
		[__delegate fontPreviewField:self didChangeToFont:font];
}

- (NSUInteger) validModesForFontPanel:(NSFontPanel *) fontPanel
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

		[super setFont:[[NSFontManager sharedFontManager] convertFont:_actualFont toSize:11.0f]];
		
		if (_showPointSize) {
			text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %.0f", (_showFontFace ? [_actualFont displayName] : [_actualFont familyName]), [_actualFont pointSize]]];
		} else {
			text = [[NSMutableAttributedString alloc] initWithString:( _showFontFace ? [_actualFont displayName] : [_actualFont familyName] )];
		}
		
		NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		
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
	
	_actualFont = font;
	
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
