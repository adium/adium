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

@class AIListObject, AIAdium;

typedef int(*sortfunc)(id, id, BOOL);

#define PREF_GROUP_CONTACT_SORTING			@"Sorting"

@interface AISortController : NSSortDescriptor {
	NSSet					*statusKeysRequiringResort;
	NSSet					*attributeKeysRequiringResort;
	BOOL					alwaysSortGroupsToTop;
	
	sortfunc				sortFunction;
	
	IBOutlet	NSView		*configureView;
	
	BOOL					becameActiveFirstTime;
}

- (BOOL)shouldSortForModifiedStatusKeys:(NSSet *)inModifiedKeys;
- (BOOL)shouldSortForModifiedAttributeKeys:(NSSet *)inModifiedKeys;
- (BOOL)alwaysSortGroupsToTopByDefault;
- (int)indexForInserting:(AIListObject *)inObject intoObjects:(NSArray *)inObjects;
- (NSArray *)sortListObjects:(NSArray *)inObjects;
- (NSView *)configureView;
- (void)forceIgnoringOfGroups:(BOOL)shouldForce;
- (BOOL)canSortManually;

//For subclasses to override
- (NSString *)identifier;
- (NSString *)displayName;
- (NSSet *)statusKeysRequiringResort;
- (NSSet *)attributeKeysRequiringResort;
- (sortfunc)sortFunction;
- (NSString *)configureSortMenuItemTitle;
- (NSString *)configureSortWindowTitle;
- (NSString *)configureNibName;
- (void)viewDidLoad;
- (IBAction)changePreference:(id)sender;
- (void)didBecomeActive;
- (void)didBecomeActiveFirstTime;

@end
