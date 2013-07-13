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

#import "AIHighlightingTextField.h"

@implementation AIHighlightingTextField

@synthesize selected, pane;

- (id)initWithFrame:(NSRect)frameRect
{
	if (!(self = [super initWithFrame:frameRect]))
		return nil;
	
	[self setEditable:NO];
	[self setBezeled:NO];
	[self setDrawsBackground:NO];
	[self setBackgroundColor:[NSColor selectedMenuItemColor]];
	
	return self;
}

- (void)setSelected:(BOOL)newSelected
{
	if (newSelected) {
		[self setDrawsBackground:YES];
		[self setTextColor:[NSColor selectedMenuItemTextColor]];
	} else {
		[self setDrawsBackground:NO];
		[self setTextColor:[NSColor textColor]];
	}
}

/*!
 * @brief Set the displayed string
 *
 * Set the label's string and give it some left-side padding.
 */
- (void)setString:(NSString *)aString withPane:(AIPreferencePane *)aPane
{
	self.pane = aPane;
	
	NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:aString];
	NSMutableParagraphStyle *mutParaStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[mutParaStyle setFirstLineHeadIndent:15.0];
	[attrStr addAttributes:[NSDictionary dictionaryWithObject:mutParaStyle forKey:NSParagraphStyleAttributeName]
					 range:NSMakeRange(0,[attrStr length])];
	[super setObjectValue:attrStr];
	[attrStr release];
}

@end
