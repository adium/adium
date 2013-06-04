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

#import <Adium/AIListGroupBubbleToFitCell.h>
#import <Adium/AIListObject.h>

@implementation AIListGroupBubbleToFitCell

/*!
 * @brief Return the attributed string to be displayed as the primary text of the cell
 *
 * We add our group count onto the name as necessary
 */
- (NSAttributedString *)displayName
{
	NSString *countText;
	AIListObject *listObject = [proxyObject listObject];

	if ([listObject boolValueForProperty:@"showCount"] &&
		(countText = [listObject valueForProperty:@"countText"])) {
		return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (%@)", [self labelString], countText]
												attributes:[self labelAttributes]] autorelease];

	} else {
		return super.displayName;
	}
}

/*!
 * @brief Cell width
 *
 * We'll be added a space and parenthesis to the group count if it's displayed, so we need to add on their width
 */
- (CGFloat)cellWidth
{
    AIListObject *listObject = [proxyObject listObject];
	CGFloat width = [super cellWidth];

	if ([listObject boolValueForProperty:@"showCount"] && 
		[listObject valueForProperty:@"countText"]) {
		//We'll be added a space and parenthesis to the group count if it's displayed
		NSAttributedString *countText = [[NSAttributedString alloc] initWithString:@" ()"
																		attributes:[self labelAttributes]];
		width += AIceil([countText size].width);
		[countText release];
	}
	
	return width;
}

- (NSRect)drawGroupCountWithFrame:(NSRect)inRect
{
	/* No-op: Don't let the usual group count drawing occur. We'll add the group count to
	 * the display name, flush with the name, rather than letting it draw right-justified, which
	 * would be outside our bubble.
	 */
	return inRect;
}

/*!
 * @brief Get the bubble rect for drawing
 *
 * Adjust the bubble rect to tightly fit our label string.
 */
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	NSSize				nameSize = [self.displayName size];
	CGFloat				originalWidth = rect.size.width;
	CGFloat				originalX = rect.origin.x;

	//Alignment
	switch ([self textAlignment]) {
		case NSCenterTextAlignment:
			rect.origin.x += ((rect.size.width - nameSize.width) / 2.0f) - [self leftPadding];
		break;
		case NSRightTextAlignment:
			rect.origin.x += (rect.size.width - nameSize.width) - [self leftPadding] - [self rightPadding];
		break;
		default:
		break;
	}
	
	//Fit the bubble to their name
	rect.size.width = nameSize.width + [self leftPadding] + [self rightPadding];
	
	//Until we get right aligned/centered flippies, this will do
	if ([self textAlignment] == NSLeftTextAlignment) {
		rect.size.width += [self flippyIndent];
	}
	
	//Don't let the bubble try to draw larger than the width we were passed, which was the full width possible
	if (rect.size.width > originalWidth) rect.size.width = originalWidth;
	if (rect.origin.x < originalX) rect.origin.x = originalX;
	
	return rect;
}

@end
