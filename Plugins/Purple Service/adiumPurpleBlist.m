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

#import "adiumPurpleBlist.h"
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIListContact.h>

static void adiumPurpleBlistNewList(PurpleBuddyList *list)
{

}

static void adiumPurpleBlistNewNode(PurpleBlistNode *node)
{
	
}

static void adiumPurpleBlistShow(PurpleBuddyList *list)
{
	
}

//A buddy was removed from the list
static void adiumPurpleBlistRemove(PurpleBuddyList *list, PurpleBlistNode *node)
{
	@autoreleasepool {
		NSCAssert(node != nil, @"BlistRemove on null node");
		if (PURPLE_BLIST_NODE_IS_BUDDY(node)) {
			PurpleBuddy	*buddy = (PurpleBuddy *)node;
			
			[accountLookup(purple_buddy_get_account(buddy)) removeContact:contactLookupFromBuddy(buddy)];
			
			//Clear the ui_data
			[(id)buddy->node.ui_data release]; buddy->node.ui_data = NULL;
		}
	}
}

static void adiumPurpleBlistDestroy(PurpleBuddyList *list)
{
    //Here we're responsible for destroying what we placed in list's ui_data earlier
    AILog(@"adiumPurpleBlistDestroy");
}

static void adiumPurpleBlistSetVisible(PurpleBuddyList *list, gboolean show)
{
    AILog(@"adiumPurpleBlistSetVisible: %i",show);
}

static void adiumPurpleBlistRequestAddBuddy(PurpleAccount *account, const char *username, const char *group, const char *alias)
{
	@autoreleasepool {
		[accountLookup(account) requestAddContactWithUID:[NSString stringWithUTF8String:username]];
	}
}

static void adiumPurpleBlistRequestAddChat(PurpleAccount *account, PurpleGroup *group, const char *alias, const char *name)
{
    AILog(@"adiumPurpleBlistRequestAddChat");
}

static void adiumPurpleBlistRequestAddGroup(void)
{
    AILog(@"adiumPurpleBlistRequestAddGroup");
}

static PurpleBlistUiOps adiumPurpleBlistOps = {
    adiumPurpleBlistNewList,
    adiumPurpleBlistNewNode,
    adiumPurpleBlistShow,
    NULL,
    adiumPurpleBlistRemove,
    adiumPurpleBlistDestroy,
    adiumPurpleBlistSetVisible,
    adiumPurpleBlistRequestAddBuddy,
    adiumPurpleBlistRequestAddChat,
    adiumPurpleBlistRequestAddGroup,
    /* save_node */ NULL,
    /* remove_node */ NULL,
    /* save_account */ NULL,
    /* _purple_reserved1 */ NULL
};

PurpleBlistUiOps *adium_purple_blist_get_ui_ops(void)
{
	return &adiumPurpleBlistOps;
}
