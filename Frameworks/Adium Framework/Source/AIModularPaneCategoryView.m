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

#import <Adium/AIModularPaneCategoryView.h>

#define FRAME_PADDING_OFFSET					2
#define TAB_PADDING_OFFSET						65

@implementation AIModularPaneCategoryView

- (BOOL)isFlipped{
	return YES;
}


//Desired Height -------------------------------------------------------------------------------------------------------
#pragma mark Desired Height
//Set and retrieve this view's desired height
- (void)setDesiredHeight:(CGFloat)inHeight{
    desiredHeight = inHeight;
}
- (CGFloat)desiredHeight{
    return desiredHeight;
}


//Dynamic Content ------------------------------------------------------------------------------------------------------
#pragma mark Toolbar
//Insert the passed modular panes into this view
- (void)setPanes:(NSArray *)paneArray
{
    AIPreferencePane	*pane;
    CGFloat					yPos = 0;
    
    //Add their views
    for (pane in paneArray) {
        NSView	*paneView = [pane view];

        //Add the view
        if (![paneView superview]) {
            [self addSubview:paneView];
            [paneView setFrameOrigin:NSMakePoint(0,yPos)];
			if ([pane resizable]) {
				[paneView setFrameSize:[self frame].size];
			} else if ([pane resizableHorizontally]) {
				[paneView setFrameSize:NSMakeSize([self frame].size.width, [paneView frame].size.height)];
			}
        }
        
		if ([pane respondsToSelector:@selector(localizePane)]) {
			[pane performSelector:@selector(localizePane)];
		}
		
        //Move down for the next view
        yPos += [paneView frame].size.height;
    }
    
    //Set the desired height of this view
    [self setDesiredHeight:yPos + 2 + FRAME_PADDING_OFFSET];
	containsPanes = YES;
}

//Returns YES if we contain no panes
- (BOOL)isEmpty
{
	return !containsPanes;
}

//Pass this a tab view containing module pane category views.  It will return the height of the tallest modular pane
//within that tab view
+ (CGFloat)heightForTabView:(NSTabView *)tabView
{
    CGFloat				maxHeight = 0;
	
    //Determine the tallest view contained within this tab view.
    for (NSTabViewItem *tabViewItem in [tabView tabViewItems]) {		
        for (NSView *subView in [tabViewItem.view subviews]) {
            CGFloat		height = ((AIModularPaneCategoryView *)subView).desiredHeight;

            if (height > maxHeight) {
                maxHeight = height;
            }
        }
    }
	
	return maxHeight + TAB_PADDING_OFFSET + FRAME_PADDING_OFFSET;
}

@end
