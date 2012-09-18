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


#import "AISegmentedControl.h"

@interface NSSegmentedCell (ApplePrivate)
- (void)setMenuIndicatorShown:(BOOL)shown forSegment:(NSInteger)segment;
@end

@implementation AISegmentedControl
- (void)setMenuIndicatorShown:(BOOL)shown forSegment:(NSInteger)segment;
{
	if ([self.cell respondsToSelector:@selector(setMenuIndicatorShown:forSegment:)])
		[self.cell setMenuIndicatorShown:shown forSegment:segment];
}

//Display the menu set on the NSSegmentedControl for the specified segment
- (void)showMenuForSegment:(NSInteger)segment
{
	NSView *view = [self window].contentView;
	[self.menu popUpMenuPositioningItem:nil atLocation:self.frame.origin inView:view];
}

@end
