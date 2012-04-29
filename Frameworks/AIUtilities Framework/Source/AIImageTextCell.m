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

/*
    A cell that displays an image and text
*/

#import "AIImageTextCell.h"
#import "AIParagraphStyleAdditions.h"
#import "AIAttributedStringAdditions.h"

#define DEFAULT_MAX_IMAGE_WIDTH			24
#define DEFAULT_IMAGE_TEXT_PADDING		6

@interface NSCell (UndocumentedHighlightDrawing)
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
@end

@implementation AIImageTextCell

//Init
- (id)init
{
	if ((self = [super init])) {
		font = nil;
		subString = nil;
		highlightWhenNotKey = NO;
		maxImageWidth = DEFAULT_MAX_IMAGE_WIDTH;
		imageTextPadding = DEFAULT_IMAGE_TEXT_PADDING;
		[self setLineBreakMode:NSLineBreakByTruncatingTail];
	}

	return self;
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIImageTextCell *newCell = [super copyWithZone:zone];

	newCell->font = nil;
	[newCell setFont:font];

	newCell->subString = nil;
	[newCell setSubString:subString];
	
	[newCell setMaxImageWidth:maxImageWidth];

	return newCell;
}

#pragma mark Accessors

/*! @brief Set whether the strings are considered highlighted even if the window is not key
 *
 * @par		If \c YES, the text is drawn as highlighted even when not the key wndow. If \c NO, it is drawn normally.
 */
- (void) setHighlightWhenNotKey:(BOOL)flag
{
	highlightWhenNotKey = flag;
}

/*
 * @brief Set the string value
 *
 * We redirect a call to setStringValue into one to setObjectValue. 
 * This prevents NSCell from messing up our font (normally, setStringValue: resets any font set on the cell).
 */
- (void)setStringValue:(NSString *)inString
{
	[self setObjectValue:inString];
}


//Font used to display our text
- (void)setFont:(NSFont *)inFont
{
    if (font != inFont) {
        font = inFont;
    }
}
- (NSFont *)font
{
    return font;
}


//Substring (Displayed in gray below our main string)
- (void)setSubString:(NSString *)inSubString
{
	if (subString != inSubString) {
		subString = inSubString;
	}
}

- (void)setMaxImageWidth:(float)inWidth
{
	maxImageWidth = inWidth;
}

- (void)setImageTextPadding:(float)inImageTextPadding
{
	imageTextPadding = inImageTextPadding;
}

- (BOOL) drawsImageAfterMainString {
	return imageAfterMainString;
}
- (void) setDrawsImageAfterMainString:(BOOL)flag {
	imageAfterMainString = flag;
}

- (void)setLineBreakMode:(NSLineBreakMode)inLineBreakMode
{
	lineBreakMode = inLineBreakMode;
}

- (NSLineBreakMode)lineBreakMode
{
	return lineBreakMode;
}

#pragma mark Drawing

- (NSSize)cellSizeForBounds:(NSRect)cellFrame
{
	NSString	*title = [self objectValue];
	NSImage		*image = [self image];
	NSSize		cellSize = NSZeroSize;
	
	if (image) {
		NSSize	destSize = [image size];

		//Center image vertically, or scale as needed
		if (destSize.height > cellFrame.size.height) {
			CGFloat proportionChange = cellFrame.size.height / destSize.height;
			destSize.height = cellFrame.size.height;
			destSize.width = destSize.width * proportionChange;
		}
		
		if (destSize.width > maxImageWidth) {
			CGFloat proportionChange = maxImageWidth / destSize.width;
			destSize.width = maxImageWidth;
			destSize.height = destSize.height * proportionChange;
		}

		cellSize.width += destSize.width + imageTextPadding;
		cellSize.height = destSize.height;
	}
	
	if (title != nil) {
		NSDictionary	*attributes;
		NSSize			titleSize;

		cellSize.width += (imageTextPadding * 2);
		
		//Truncating paragraph style
		NSParagraphStyle	*paragraphStyle = [NSParagraphStyle styleWithAlignment:[self alignment]
																	 lineBreakMode:lineBreakMode];
		
		//
		if ([self font]) {
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				[self font], NSFontAttributeName,
				nil];
		} else {
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				nil];
		}
		
		titleSize = [title sizeWithAttributes:attributes];
		
		if (subString) {
			NSSize			subStringSize;

			attributes = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:10]
													 forKey:NSFontAttributeName];
			subStringSize = [subString sizeWithAttributes:attributes];
			
			//Use the wider of the two strings as the required width
			if (subStringSize.width > titleSize.width) {
				cellSize.width += subStringSize.width;
			} else {
				cellSize.width += titleSize.width;
			}
			
			if (cellSize.height < (subStringSize.height + titleSize.height)) {
				cellSize.height = (subStringSize.height + titleSize.height);
			}
		} else {
			//No substring
			cellSize.width += titleSize.width;
			if (cellSize.height < titleSize.height) {
				cellSize.height = titleSize.height;
			}
		}
	}
	
	return cellSize;
}

/*!	@brief	Draw an image on the behalf of <code>drawInteriorWithFrame:</code>.
 *
 *	@par	This is a private method. It should not be called from outside this class. It is intended only for use by drawInteriorWithFrame:.
 *
 *	@par	If the image is taller than the height of \a cellFrame, the image will be drawn scaled down. If the image is shorter, it will be vertically centered.
 *
 *	@return	The size drawn into, which is not necessarily the same size as the image (it may be larger or smaller).
 */
- (NSSize)drawImage:(NSImage *)image withFrame:(NSRect)cellFrame
{
	NSSize	size = [image size];
	NSRect	destRect = { cellFrame.origin, size };
	
	//Adjust the rects
	destRect.origin.y += 0;
	destRect.origin.x += imageTextPadding;
	
	//Center image vertically, or scale as needed
	if (destRect.size.height > cellFrame.size.height) {
		 CGFloat proportionChange = cellFrame.size.height / size.height;
		 destRect.size.height = cellFrame.size.height;
		 destRect.size.width = size.width * proportionChange;
	 }
	 
	 if (destRect.size.width > maxImageWidth) {
		 CGFloat proportionChange = maxImageWidth / destRect.size.width;
		 destRect.size.width = maxImageWidth;
		 destRect.size.height = destRect.size.height * proportionChange;
	 }
	 
	if (destRect.size.height < cellFrame.size.height) {
		destRect.origin.y += (cellFrame.size.height - destRect.size.height) / 2.0f;
	} 
	
	BOOL flippedIt = NO;
	if (![image isFlipped]) {
		[image setFlipped:YES];
		flippedIt = YES;
	}
	
	[NSGraphicsContext saveGraphicsState];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[image drawInRect:destRect
			 fromRect:NSMakeRect(0,0,size.width,size.height)
			operation:NSCompositeSourceOver
			 fraction:1.0f];
	[NSGraphicsContext restoreGraphicsState];

	if (flippedIt) {
		[image setFlipped:NO];
	}

	return destRect.size;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[NSGraphicsContext saveGraphicsState];

	NSString	*title = [self stringValue];
	NSImage		*image = [self image];
	BOOL		highlighted = [self isHighlighted];

	//Draw the cell's image
	if ((!imageAfterMainString) && (image != nil)) {
		NSSize drawnImageSize = [self drawImage:image withFrame:cellFrame];

		//Decrease the cell width by the width of the image we drew and its left padding
		cellFrame.size.width -= imageTextPadding + drawnImageSize.width;
		
		//Shift the origin over to the right edge of the image we just drew
		NSAffineTransform *imageTranslation = [NSAffineTransform transform];
		[imageTranslation translateXBy:(imageTextPadding + drawnImageSize.width) yBy:0.0f];
		[imageTranslation concat];
	}
	
	//Draw the cell's text
	if (title != nil) {
		NSAttributedString	*attributedMainString = nil, *attributedSubString = nil;
		NSColor				*mainTextColor, *subStringTextColor;
		NSDictionary		*mainAttributes = nil, *subStringAttributes = nil;
		CGFloat				mainStringHeight = 0.0f, subStringHeight = 0.0f, textSpacing = 0.0f;

		//Determine the correct text color
		NSWindow			*window;

		//If we don't have a control view, or we do and it's the first responder, draw the text in the alternateSelectedControl text color (white)
		if (highlighted && (highlightWhenNotKey ||
							((window = [controlView window]) &&
							 ([window isKeyWindow] && ([window firstResponder] == controlView))))) {
			// Draw the text inverted
			mainTextColor = [NSColor alternateSelectedControlTextColor];
			subStringTextColor = [NSColor alternateSelectedControlTextColor];
		} else {
			if ([self isEnabled]) {
				// Draw the text regular
				mainTextColor = [NSColor controlTextColor];
				subStringTextColor = [NSColor colorWithCalibratedWhite:0.4f alpha:1.0f];
			} else {
				// Draw the text disabled
				mainTextColor = [NSColor grayColor];
				subStringTextColor = [NSColor colorWithCalibratedWhite:0.8f alpha:1.0f];
			}
		}
		
		/* Padding: Origin goes right by our padding amount, and the width decreases by twice it
		 * (for left and right padding).
		 */
		if ((!imageAfterMainString) && (image != nil)) {
			cellFrame.origin.x += imageTextPadding;
			cellFrame.size.width -= imageTextPadding * 2;
		}

		//Paragraph style
		NSParagraphStyle	*paragraphStyle = [NSParagraphStyle styleWithAlignment:[self alignment]
																	 lineBreakMode:lineBreakMode];		
		//
		if ([self font]) {
			mainAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				[self font], NSFontAttributeName,
				mainTextColor, NSForegroundColorAttributeName,
				nil];
		} else {
			mainAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				mainTextColor, NSForegroundColorAttributeName,
				nil];
		}
		
		attributedMainString = [[NSAttributedString alloc] initWithString:title
															   attributes:mainAttributes];
		
		if (subString) {
			// Keep the mainString NSDictionary attributes in case we're
			// using NSLineBreakByTruncatingMiddle line breaking (see below).
			subStringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:10], NSFontAttributeName,
				subStringTextColor, NSForegroundColorAttributeName,
				nil];
			
			attributedSubString = [[NSAttributedString alloc] initWithString:subString
																  attributes:subStringAttributes];
		}

		switch (lineBreakMode) {
			case NSLineBreakByWordWrapping:
			case NSLineBreakByCharWrapping:
				mainStringHeight = [attributedMainString heightWithWidth:cellFrame.size.width];
				if (subString) {
					subStringHeight = [attributedSubString heightWithWidth:cellFrame.size.width];
				}
				break;
			case NSLineBreakByClipping:
			case NSLineBreakByTruncatingHead:
			case NSLineBreakByTruncatingTail:
			case NSLineBreakByTruncatingMiddle:
				mainStringHeight = [title sizeWithAttributes:mainAttributes].height;
				if (subString) {
					subStringHeight = [subString sizeWithAttributes:subStringAttributes].height;
				}
				break;
		}

		//Calculate the centered rect
		if (!subString && mainStringHeight < cellFrame.size.height) {
			// Space out the main string evenly
			cellFrame.origin.y += (cellFrame.size.height - mainStringHeight) / 2.0f;
		} else if (subString) {
			// Space out our extra space evenly
			textSpacing = (cellFrame.size.height - mainStringHeight - subStringHeight) / 3.0f;
			// In case we don't have enough height..
			if (textSpacing < 0.0f)
				textSpacing = 0.0f;
			cellFrame.origin.y += textSpacing;
		}

		//Draw the string
		[attributedMainString drawInRect:cellFrame];

		//If we're supposed to draw the cell's image after the main string, this is when we do it.
		if (imageAfterMainString && (image != nil)) {
			[NSGraphicsContext saveGraphicsState];

			//Note that measuring the size of the attributedMainString should happen here, because we don't want to measure the string (which is expensive) if there isn't an image or we don't need to draw it here.
			NSSize attributedMainStringSize = [attributedMainString size];

			NSAffineTransform *spacingTranslation = [NSAffineTransform transform];
			[spacingTranslation translateXBy:(imageTextPadding + attributedMainStringSize.width) yBy:-(attributedMainStringSize.height / 2.0f)];
			[spacingTranslation concat];

			[self drawImage:image withFrame:cellFrame];

			[NSGraphicsContext restoreGraphicsState];
		}

		//Draw the substring
		if (subString) {
			NSAffineTransform *subStringTranslation = [NSAffineTransform transform];
			[subStringTranslation translateXBy:0.0f yBy:mainStringHeight + textSpacing];
			[subStringTranslation concat];
			
			//Draw the substring
			[attributedSubString drawInRect:cellFrame];
		}
	}

	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark Accessibility

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	if([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		return NSAccessibilityButtonRole;
		
    } else if([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
        return [self stringValue];
		
    } else if([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
		if (subString)
			return [NSString stringWithFormat:@"%@\n%@", [self stringValue], subString];
		else
			return [self stringValue];

	} else if([attribute isEqualToString:NSAccessibilityHelpAttribute]) {
        return [self stringValue];
		
	} else if ([attribute isEqualToString: NSAccessibilityWindowAttribute]) {
		return [super accessibilityAttributeValue:NSAccessibilityWindowAttribute];
		
	} else if ([attribute isEqualToString: NSAccessibilityTopLevelUIElementAttribute]) {
		return [super accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
		
    } else {
        return [super accessibilityAttributeValue:attribute];
    }
}


@end
