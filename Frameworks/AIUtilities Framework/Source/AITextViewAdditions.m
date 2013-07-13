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

#import "AIColorAdditions.h"
#import "AITextViewAdditions.h"
#import "AITextAttributes.h"

@implementation NSTextView (AITextViewAdditions)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (void)changeDocumentBackgroundColor:(id)sender
{
	NSColor		*newColor = [sender color];
	NSRange		selectedText = [self selectedRange];
	
	if (selectedText.length > 0) {
		[[self textStorage] addAttribute:NSBackgroundColorAttributeName value:newColor range:[self selectedRange]];
	} else {
		[self setBackgroundColor:newColor];
		[[self textStorage] addAttribute:AIBodyColorAttributeName value:newColor range:NSMakeRange(0, [[[self textStorage] string] length])];
		
		[self setInsertionPointColor:[newColor contrastingColor]];
	}

	if (selectedText.length > 0) {
		[self setSelectedRange:selectedText];
	}
	
	[self didChangeText];
}
#pragma clang diagnostic pop
@end
