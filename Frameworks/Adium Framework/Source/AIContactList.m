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
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListContact.h>

@interface AIListGroup()
- (void)removeObject:(AIListObject *)inObject;
- (BOOL)addObject:(AIListObject *)inObject;
@end

@implementation AIContactList
- (NSString *)contentsBasedIdentifier
{
	return self.UID;
}

- (BOOL)canContainObject:(id)obj
{
	//if ([obj isKindOfClass:[AIListBookmark class]]) return YES;
	//if(adium.contactController.useContactListGroups)
	//	return [obj isKindOfClass:[AIListGroup class]] && ![obj isKindOfClass:[AIContactList class]];
	//else
//XXX because of - (NSString *)_mapIncomingGroupName:(NSString *)name in CBPurple Account, this doesn't work
		return YES; //ARGH
}

//Resorts the group contents (PRIVATE: For contact controller only)
- (void)sort
{
	if(adium.contactController.useContactListGroups)
	{
#warning rewrite this once we can enforce that AIContactLists only contain AIListGroups
		for (AIListObject *object in self) {
			if ([object isKindOfClass:[AIListGroup class]]) {
				[(AIListGroup *)object sort];
			}
		}
	}
	
	[super sort];
}

@end
