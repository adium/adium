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

#import "AIBorderlessListController.h"
#import "AIListOutlineView.h"

@implementation AIBorderlessListController

@synthesize enableEmptyListHiding;

- (id)initWithContactList:(id<AIContainingObject>)aContactList
			inOutlineView:(AIListOutlineView *)inContactListView
			 inScrollView:(AIAutoScrollView *)inScrollView_contactList
				 delegate:(id<AIListControllerDelegate>)inDelegate
{
	if ((self = [super initWithContactList:aContactList
							 inOutlineView:inContactListView
							  inScrollView:inScrollView_contactList
								  delegate:inDelegate])) {
		emptyListHiding = NO;
		enableEmptyListHiding = YES;

		[self reloadListObject:nil];
	}
	
	return self;
}

- (void)configureViewsAndTooltips
{
	[super configureViewsAndTooltips];
	
	[self reloadListObject:nil];
}
/*!
 * @brief When asked to reload a list object, check to ensure we have 1 or more visible rows
 *
 * If we have no rows visible, hide the contact list, redisplaying it when rows are visible again.
 * orderOut: doesn't appear to work for borderless windows, so we just go to an alpha value of 0.
 */
- (void)reloadListObject:(NSNotification *)notification
{
	[super reloadListObject:notification];

	NSInteger numberOfRows = [contactListView numberOfRows];

	if (numberOfRows && emptyListHiding) {	
		emptyListHiding = NO;		
		[[contactListView window] setAlphaValue:previousAlpha];
		[[contactListView window] orderFront:nil];

	} else if (!numberOfRows && !emptyListHiding && enableEmptyListHiding) {	
		emptyListHiding = YES;
		previousAlpha = [[contactListView window] alphaValue];
		[[contactListView window] setAlphaValue:0.0f];
	}
}

@end
