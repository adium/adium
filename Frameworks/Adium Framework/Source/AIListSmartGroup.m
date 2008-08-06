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
#import <Adium/AIListSmartGroup.h>
#import <Adium/AIContactControllerProtocol.h>
#import <AIUtilities/AIArrayAdditions.h>


@interface AIListSmartGroup (PRIVATE)
- (void)_recomputeVisibleCount;
@end

@implementation AIListSmartGroup

- (void)dealloc
{
    [super dealloc];
}

/* This is almost totally identical to the super's version, except it does not call -setContainingObject
 * and therefore doesn't screw up contacts when used as a search results filter.
 * TODO(augie) this should come out when we unbreak the contact controller.
 */
- (BOOL)addObject:(AIListObject *)inObject
{
	BOOL success = NO;
	
	if (![containedObjects containsObjectIdenticalTo:inObject]) {
		//Add the object
		[inObject retain];
		[containedObjects addObject:inObject];
		
		/* Sort this object on our own.  This always comes along with a content change, so calling contact controller's
			* sort code would invoke an extra update that we don't need.  We can skip sorting if this object is not visible,
			* since it will add to the bottom/non-visible section of our array.
			*/
		if ([inObject visible]) {
			//Update our visible count
			[self _recomputeVisibleCount];
			
			[self sortListObject:inObject
				  sortController:[[adium contactController] activeSortController]];
		}
		
		//
		[self setValue:[NSNumber numberWithInt:[containedObjects count]] 
					   forProperty:@"ObjectCount"
					   notify:NotifyNow];
		
		success = YES;
	}
	
	return success;
}

- (void)removeObject:(AIListObject *)inObject
{	
	if ([containedObjects containsObject:inObject]) {		
		//Remove the object
		[containedObjects removeObject:inObject];
		
		//Update our visible count
		[self _recomputeVisibleCount];
		
		//
		[self setValue:[NSNumber numberWithInt:[containedObjects count]]
					   forProperty:@"ObjectCount" 
					   notify:NotifyNow];
	}
}

@end
