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
 
#import <Adium/AIWindowController.h>
#import <Adium/AIAbstractListController.h>
#import "AIContactInfoContentController.h"

@class ESContactInfoListController, AIModularPaneCategoryView, AIContactInfoImageViewWithImagePicker, AIAutoScrollView,
	   AIListOutlineView, AIListObject;

@interface AIContactInfoWindowController : AIWindowController {	

	IBOutlet		AIContactInfoContentController  *contentController;
	IBOutlet		NSMatrix						*inspectorToolbar;
	IBOutlet		NSView							*inspectorContent;
	IBOutlet		NSView							*inspectorBottomBar;
	IBOutlet		NSBox							*bottomBarSeperator;
	
					NSView							*currentPane;
					NSArray							*loadedContent;
					
					AIListObject					*displayedObject;
					NSInteger								lastSegment;
	
	BOOL											deallocating;
}

+ (AIContactInfoWindowController *)showInfoWindowForListObject:(AIListObject *)listObject;
+ (void)closeInfoWindow;
- (void)setDisplayedListObject:(AIListObject *)inObject;

- (IBAction)segmentSelected:(id)sender;

@end
