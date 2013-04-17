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

#import <Adium/AIListContactBubbleToFitCell.h>


@implementation AIListContactBubbleToFitCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return newCell;
}

//Adjust the bubble rect to tightly fit our label string
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	NSSize				nameSize = [[self labelString] sizeWithAttributes:[self labelAttributes]];
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
	
	//Handle the icons (only works properly if they are on the same side as the text)
	
	//User icon
	if (userIconVisible) {
		CGFloat userIconChange;

		userIconChange = userIconSize.width;
		userIconChange += USER_ICON_LEFT_PAD + USER_ICON_RIGHT_PAD;
		
		rect.size.width += userIconChange;
		
		//Shift left to accomodate an icon on the right
		if (userIconPosition == LIST_POSITION_RIGHT) {
			rect.origin.x -= userIconChange;
		}
	}
	
	//Status icon
	if (statusIconsVisible &&
	   (statusIconPosition != LIST_POSITION_BADGE_LEFT && statusIconPosition != LIST_POSITION_BADGE_RIGHT)) {
		CGFloat	statusIconChange;

		statusIconChange = [[self statusImage] size].width;
		statusIconChange += STATUS_ICON_LEFT_PAD + STATUS_ICON_RIGHT_PAD;
		
		rect.size.width += statusIconChange;
		
		//Shift left to accomodate an icon on the right
		if (statusIconPosition == LIST_POSITION_RIGHT || statusIconPosition == LIST_POSITION_FAR_RIGHT) {
			rect.origin.x -= statusIconChange;
		}
	}
	
	//Service icon
	if (serviceIconsVisible &&
	   (serviceIconPosition != LIST_POSITION_BADGE_LEFT && serviceIconPosition != LIST_POSITION_BADGE_RIGHT)) {
		CGFloat serviceIconChange;
		
		serviceIconChange = [[self serviceImage] size].width;
		serviceIconChange += SERVICE_ICON_LEFT_PAD + SERVICE_ICON_RIGHT_PAD;
		
		rect.size.width += serviceIconChange;
		
		//Shift left to accomodate an icon on the right
		if (serviceIconPosition == LIST_POSITION_RIGHT || serviceIconPosition == LIST_POSITION_FAR_RIGHT) {
			rect.origin.x -= serviceIconChange;
		}
	}

	//Don't let the bubble try to draw larger than the width we were passed, which was the full width possible
	if (rect.size.width > originalWidth) rect.size.width = originalWidth;
	if (rect.origin.x < originalX) rect.origin.x = originalX;
	
	return rect;
}

@end
