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


@class AIListObject;

@interface AIPreferenceController : NSObject <AIPreferenceController> {
@private
	NSMutableArray			*paneArray;						//Loaded preference panes
	NSMutableArray			*advancedPaneArray;
	NSMutableDictionary		*observers;						//Preference change observers

	NSMutableDictionary		*prefCache;						//Preference cache
	NSMutableDictionary		*objectPrefCache;				//Object specific preferences cache

	NSInteger				preferenceChangeDelays;			//Number of active delays (0 = not delayed)
	NSMutableSet			*delayedNotificationGroups;  	//Groups with delayed changes
}

@end

@interface AIPreferenceController (AIPreferenceContainerAccess)
- (void)informObserversOfChangedKey:(NSString *)key inGroup:(NSString *)group object:(AIListObject *)object;
@end

