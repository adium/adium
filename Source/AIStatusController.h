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

#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIContactObserverManager.h>

@class AIStatus, AIService, AdiumIdleManager, AIStatusGroup;

@interface AIStatusController : NSObject <AIStatusController, AIListObjectObserver> {
@private
	//Status states
	AIStatusGroup			*_rootStateGroup;
	NSMutableSet			*_flatStatusSet;
	NSMutableArray			*builtInStateArray;

	AIStatus				*offlineStatusState; //Shared state used to symbolize the offline 'status'
	
	AIStatus				*_activeStatusState; //Cached active status state
	NSMutableSet			*_allActiveStatusStates; //Cached all active status states
	NSMutableDictionary		*statusDictsByServiceCodeUniqueID[STATUS_TYPES_COUNT];
	NSMutableSet			*builtInStatusTypes[STATUS_TYPES_COUNT];

	NSMutableSet			*accountsToConnect;

	//State menu support
	NSMutableArray			*stateMenuPluginsArray;
	NSMutableDictionary		*stateMenuItemArraysDict;

	NSInteger						activeStatusUpdateDelays;
	NSInteger						statusMenuRebuildDelays;

	NSArray					*_sortedFullStateArray;

	NSMutableSet			*stateMenuItemsNeedingUpdating;
	
	AdiumIdleManager		*idleManager;
}

@end

@interface NSObject (AIStatusController_StatusMenuTarget)
- (void)selectStatus:(id)sender;
@end
