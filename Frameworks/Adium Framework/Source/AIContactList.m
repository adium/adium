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

#import <Adium/AIContactList.h>
#import <Adium/AISortController.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListContact.h>

@implementation AIContactList
- (NSString *)contentsBasedIdentifier
{
	return [self UID];
}

- (BOOL)canContainObject:(id)obj
{
	if([adium.contactController useContactListGroups])
		return [obj isKindOfClass:[AIListGroup class]] && ![obj isKindOfClass:[AIContactList class]];
	else
		return YES; //ARGH
}

//Resorts the group contents (PRIVATE: For contact controller only)
- (void)sort
{
#warning rewrite this once we can enforce that AIContactLists only contain AIListGroups
	for (AIListObject *object in containedObjects) {
		if ([object isKindOfClass:[AIListGroup class]]) {
			[(AIListGroup *)object sort];
		}
	}
	
	//Sort this group
	if ([containedObjects count] > 1) {
		[containedObjects autorelease];
		containedObjects = [[[AISortController activeSortController] sortListObjects:containedObjects] mutableCopy];
	}
}

- (void)moveAllGroupsTo:(AIContactList *)toContactList 
{
	AIListObject *object = nil;
	for (object in containedObjects) {
		if ([object isKindOfClass:[AIListGroup class]]) {
			[self moveGroup:(AIListGroup *)object to:toContactList];
		}
	}
}

- (BOOL)moveGroup:(AIListGroup *)group to:(AIContactList *)toList
{
	// Check if group is not already there
	if([toList containsObject:group])
		return NO;
	
	[self removeObject:group];
	[toList addObject:group];
	[group setContainingObject:toList];
	
	return YES;
}


@end
