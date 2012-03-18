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

#import "AITextViewWithPlaceholder.h"

#define PLACEHOLDER_SPACING		2

@implementation AITextViewWithPlaceholder

//Current implementation suggested by Philippe Mougin on the cocoadev mailing list

- (void)setPlaceholderString:(NSString *)inPlaceholderString
{
  //  NSDictionary *attributes;
	
//	attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor], NSForegroundColorAttributeName, nil];
	[self setPlaceholder:[[NSAttributedString alloc] initWithString:inPlaceholderString
														  attributes:nil]];
}

- (void)setPlaceholder:(NSAttributedString *)inPlaceholder
{
	if (inPlaceholder != placeholder) {
		
		NSMutableAttributedString	*tempPlaceholder = [inPlaceholder mutableCopy];
		[tempPlaceholder addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(0, [tempPlaceholder length])];

		placeholder = tempPlaceholder;
	
		[self setNeedsDisplay:YES];
	}
}

- (NSAttributedString *)placeholder
{
    return placeholder;
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];

	if (placeholder &&
		([[self string] isEqualToString:@""]) && 
		([[self window] firstResponder] != self)) {
		NSSize	size = [self frame].size;
		NSSize	textContainerInset = [self textContainerInset];
		textContainerInset.width += 4;
		textContainerInset.height += 2;

		[placeholder drawInRect:NSMakeRect(textContainerInset.width, 
										   textContainerInset.height, 
										   size.width - (textContainerInset.width * 2),
										   size.height - (textContainerInset.height * 2))];
	}
}

- (BOOL)becomeFirstResponder
{
	if (placeholder) [self setNeedsDisplay:YES];

	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
	if (placeholder) [self setNeedsDisplay:YES];
	
	return [super resignFirstResponder];
}
@end
