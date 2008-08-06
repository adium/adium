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

#import <Adium/AIListObject.h>

@class AISortController;

@interface AIListGroup : AIListObject <AIContainingObject> {
    int					visibleCount;		//The number of visible buddies in the sorted array
	
	NSMutableArray		*containedObjects;	//Manually ordered array of contents
    BOOL				expanded;			//Exanded/Collapsed state of this object
	BOOL				loadedExpanded;
}

- (id)initWithUID:(NSString *)inUID;

//Object Storage
- (AIListObject *)objectWithService:(AIService *)inService UID:(NSString *)inUID;

//Object Storage (PRIVATE: For contact controller only)
- (BOOL)addObject:(AIListObject *)inObject;
- (void)removeObject:(AIListObject *)inObject;

- (BOOL)moveGroupTo:(AIListObject<AIContainingObject> *)list;
- (BOOL)moveGroupFrom:(AIListObject<AIContainingObject> *)fromList to:(AIListObject<AIContainingObject> *)toList;
- (BOOL)moveAllGroupsFrom:(AIListGroup *)fromContactList to:(AIListGroup *)toContactList;

//Sorting (PRIVATE: For contact controller only)
- (void)sortListObject:(AIListObject *)inObject sortController:(AISortController *)sortController;
- (void)sortGroupAndSubGroups:(BOOL)subGroups sortController:(AISortController *)sortController;

//Visibility
- (unsigned)visibleCount;
- (void)visibilityOfContainedObject:(AIListObject *)inObject changedTo:(BOOL)inVisible;

//Expanded State (PRIVATE: For the contact list view to let us know our state)
- (void)setExpanded:(BOOL)inExpanded;
- (BOOL)isExpanded;

@end
