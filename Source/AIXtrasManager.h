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
#import "AIXtraPreviewController.h"

@class AIXtraInfo;

#define AIXtraTypeDockIcon			@"adiumicon"
#define AIXtraTypeStatusIcons		@"adiumstatusicons"
#define AIXtraTypeEmoticons			@"adiumemoticonset"
#define AIXtraTypeScript			@"adiumscripts"
#define AIXtraTypeMessageStyle		@"adiummessagestyle"
#define AIXtraTypeListTheme			@"listtheme"
#define AIXtraTypeListLayout		@"listlayout"
#define AIXtraTypeServiceIcons		@"adiumserviceicons"
#define AIXtraTypeMenuBarIcons		@"adiummenubaricons"

@interface AIXtrasManager : AIPlugin <NSToolbarDelegate> {
	NSMutableDictionary						*disabledXtras;
	NSMutableArray							*categories;
	NSMutableArray							*selectedCategory;
	IBOutlet NSWindow						*window;
	IBOutlet NSTableView		*tableView_categories;;
	IBOutlet NSTableView					*xtraList;
	IBOutlet NSTextView						*infoView;
	IBOutlet NSScrollView					*previewContainerView;
	IBOutlet id<AIXtraPreviewController>	previewController;
	IBOutlet NSView							*readmeView;
	IBOutlet NSSegmentedControl				*showInfoControl;
	
	IBOutlet NSView	*view_shelf;
	IBOutlet NSView	*view_content;
	

	NSString								*infoPath;
	BOOL									showInfo; //YES = info, NO = preview
	
	NSMutableDictionary						*toolbarItems;
}

+ (AIXtrasManager *) sharedManager;
- (void) showXtras;
- (void) loadXtras;
- (NSArray *) arrayOfXtrasAtPaths:(NSArray *)paths;
- (IBAction) browseXtras:(id)sender;
- (IBAction) deleteXtra:(id)sender;
- (IBAction) checkForUpdates:(id)sender;
- (void) updatePreview;

- (IBAction) setShowsInfo:(id)sender;

+ (BOOL) createXtraBundleAtPath:(NSString *)path;

@end
