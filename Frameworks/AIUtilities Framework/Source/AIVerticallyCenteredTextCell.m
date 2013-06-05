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
 *A text cell with vertically centered text
 */

#import "AIVerticallyCenteredTextCell.h"
#import "AIAttributedStringAdditions.h"

@implementation AIVerticallyCenteredTextCell

- (id)init
{
	if ((self = [super init])) {
		[self setLineBreakMode:NSLineBreakByWordWrapping];
	}

	return self;
}

- (void)setLineBreakMode:(NSLineBreakMode)inLineBreakMode
{
	lineBreakMode = inLineBreakMode;
}

- (NSLineBreakMode)lineBreakMode
{
	return lineBreakMode;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSFont				*font  = [self font];
	NSString			*title = [self stringValue];
	NSAttributedString	*attributedTitle = [self attributedStringValue];
	BOOL				highlighted = ([self isHighlighted] &&
									   [[controlView window] firstResponder] == controlView &&
									   [[controlView window] isKeyWindow]);

	//Draw the cell's text
	if (title != nil) {
		NSDictionary	*attributes;
		CGFloat			 stringHeight;
		NSColor			*textColor;

		if (highlighted) {
			textColor = [NSColor alternateSelectedControlTextColor]; //Draw the text inverted
		} else {
			if ([self isEnabled]) {
				textColor = [NSColor controlTextColor]; //Draw the text regular
			} else {
				textColor = [NSColor grayColor]; //Draw the text disabled
			}
		}

		//Paragraph style for alignment and clipping
		NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[style setAlignment:[self alignment]];
		[style setLineBreakMode:[self lineBreakMode]];

		//
		if (font) {
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				font, NSFontAttributeName,
				style, NSParagraphStyleAttributeName,
				textColor, NSForegroundColorAttributeName,nil];
		} else {
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				style, NSParagraphStyleAttributeName,
				textColor, NSForegroundColorAttributeName,nil];
		}
		
		if (attributedTitle) {
			attributedTitle = [attributedTitle mutableCopy];
			[(NSMutableAttributedString *)attributedTitle addAttributes:attributes
																  range:NSMakeRange(0, [attributedTitle length])];

		} else {
			attributedTitle = [[NSAttributedString alloc] initWithString:title
															  attributes:attributes];
		}

		//Don't draw all the way to the edge of our cell frame
		cellFrame.size.width -= 2;
		
		//Calculate the centered rect
		stringHeight = [attributedTitle heightWithWidth:cellFrame.size.width];
		if (stringHeight < cellFrame.size.height) {
			cellFrame.origin.y += (cellFrame.size.height - stringHeight) / 2.0f;
		}

		//Draw the string
		[attributedTitle drawInRect:cellFrame];
	}
}

@end
