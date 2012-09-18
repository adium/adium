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

#import "adiumPurpleSignals.h"
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/ESFileTransfer.h>

static void buddy_status_changed_cb(PurpleBuddy *buddy, PurpleStatus *oldstatus, PurpleStatus *status, PurpleBuddyEvent event);
static void buddy_idle_changed_cb(PurpleBuddy *buddy, gboolean old_idle, gboolean idle, PurpleBuddyEvent event);

static void buddy_event_cb(PurpleBuddy *buddy, PurpleBuddyEvent event)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (buddy) {
		SEL				updateSelector = nil;
		id				data = nil;
		BOOL			letAccountHandleUpdate = YES;
		CBPurpleAccount	*account = accountLookup(purple_buddy_get_account(buddy));
		AIListContact   *theContact = contactLookupFromBuddy(buddy);

		switch (event) {
			case PURPLE_BUDDY_SIGNON: {
				updateSelector = @selector(updateSignon:withData:);
				break;
			}
			case PURPLE_BUDDY_SIGNOFF: {
				updateSelector = @selector(updateSignoff:withData:);
				break;
			}
			case PURPLE_BUDDY_SIGNON_TIME: {
				PurplePresence	*presence = purple_buddy_get_presence(buddy);
				time_t			loginTime = purple_presence_get_login_time(presence);
				
				updateSelector = @selector(updateSignonTime:withData:);
				data = (loginTime ? [NSDate dateWithTimeIntervalSince1970:loginTime] : nil);

				break;
			}

			case PURPLE_BUDDY_EVIL: {
				updateSelector = @selector(updateEvil:withData:);
				//This is an update of the AIM Warning Level. We really, really don't care.
				/*
				if (buddy->evil) {
					data = [NSNumber numberWithInt:buddy->evil];
				}
				 */
				break;
			}
			case PURPLE_BUDDY_ICON: {
				PurpleBuddyIcon *buddyIcon = purple_buddy_get_icon(buddy);
				updateSelector = @selector(updateIcon:withData:);
				AILog(@"Buddy icon update for %s",purple_buddy_get_name(buddy));
				if (buddyIcon) {
					const guchar  *iconData;
					size_t		len;
					
					iconData = purple_buddy_icon_get_data(buddyIcon, &len);
					
					if (iconData && len) {
						data = [NSData dataWithBytes:iconData
											  length:len];
						AILog(@"[buddy icon: %s got data]",purple_buddy_get_name(buddy));
					}
				}
				break;
			}
			case PURPLE_BUDDY_NAME: {
				updateSelector = @selector(renameContact:toUID:);

				data = [NSString stringWithUTF8String:purple_buddy_get_name(buddy)];
				AILog(@"Renaming %@ to %@",theContact,data);
				break;
			}
			default: {
				data = [NSNumber numberWithInteger:event];
				break;
			}
		}
		
		if (letAccountHandleUpdate) {
			if (updateSelector) {
				[account performSelector:updateSelector
							  withObject:theContact
							  withObject:data];
			} else {
				[account updateContact:theContact
							  forEvent:data];
			}
		}
		
		/* If a status event didn't change from its previous value, we won't be notified of it.
		 * That's generally a good thing, but we clear some values when a contact signs off, including
		 * status, idle time, and signed-on time.  Manually update these as appropriate when we're informed of
		 * a signon.
		 */
		if ((event == PURPLE_BUDDY_SIGNON) || (event == PURPLE_BUDDY_SIGNOFF)) {
			PurplePresence	*presence = purple_buddy_get_presence(buddy);
			PurpleStatus		*status = purple_presence_get_active_status(presence);
			buddy_status_changed_cb(buddy, NULL, status, event);
			
			if (event == PURPLE_BUDDY_SIGNON) {
				buddy_idle_changed_cb(buddy, FALSE, purple_presence_is_idle(presence), event);
				buddy_event_cb(buddy, PURPLE_BUDDY_SIGNON_TIME);
			}
		}
	}
	
	[pool release];
}

static void buddy_status_changed_cb(PurpleBuddy *buddy, PurpleStatus *oldstatus, PurpleStatus *status, PurpleBuddyEvent event)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CBPurpleAccount		*account = accountLookup(purple_buddy_get_account(buddy));
	AIListContact		*theContact = contactLookupFromBuddy(buddy);
	NSNumber			*statusTypeNumber;
	NSString			*statusName;
	NSAttributedString	*statusMessage;	
	BOOL				isAvailable, isMobile;

	isAvailable = ((purple_status_type_get_primitive(purple_status_get_type(status)) == PURPLE_STATUS_AVAILABLE) ||
				   (purple_status_type_get_primitive(purple_status_get_type(status)) == PURPLE_STATUS_OFFLINE));
	isMobile = purple_presence_is_status_primitive_active(purple_buddy_get_presence(buddy), PURPLE_STATUS_MOBILE);
	statusTypeNumber = [NSNumber numberWithInteger:(isAvailable ? 
												AIAvailableStatusType : 
												AIAwayStatusType)];

	statusName = [account statusNameForPurpleBuddy:buddy];
	statusMessage = [account statusMessageForPurpleBuddy:buddy];

	//Will also notify
	[account updateStatusForContact:theContact
					   toStatusType:statusTypeNumber
						 statusName:statusName
					  statusMessage:statusMessage
						   isMobile:isMobile];
	[pool release];
}

static void buddy_idle_changed_cb(PurpleBuddy *buddy, gboolean old_idle, gboolean idle, PurpleBuddyEvent event)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CBPurpleAccount	*account = accountLookup(purple_buddy_get_account(buddy));
	AIListContact	*theContact = contactLookupFromBuddy(buddy);
	PurplePresence	*presence = purple_buddy_get_presence(buddy);
				
	if (idle) {
		time_t		idleTime = purple_presence_get_idle_time(presence);

		[account updateWentIdle:theContact
					   withData:(idleTime ?
									  [NSDate dateWithTimeIntervalSince1970:idleTime] :
									  nil)];
	} else {
		[account updateIdleReturn:theContact
						 withData:nil];
	}
	
	[pool release];
}

//This is called when a buddy is added or changes groups
static void buddy_added_cb(PurpleBuddy *buddy)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	PurpleAccount	*purpleAccount = purple_buddy_get_account(buddy);
	if (purple_account_is_connected(purpleAccount)) {
		CBPurpleAccount	*account = accountLookup(purpleAccount);
		PurpleGroup		*g = purple_buddy_get_group(buddy);
		NSString		*groupName = ((g && purple_group_get_name(g)) ? [NSString stringWithUTF8String:purple_group_get_name(g)] : nil);
		AIListContact	*listContact = contactLookupFromBuddy(buddy);
		/* We pass in purple_buddy_get_name(buddy) directly (without filtering or normalizing it) as it may indicate a 
		 * formatted version of the UID.  We have a signal for when a rename occurs, but passing here lets us get
		 * formatted names which are originally formatted in a way which differs from the results of normalization.
		 * For example, TekJew will normalize to tekjew in AIM; we want to use tekjew internally but display TekJew.
		 */
		[account addContact:listContact
				   toGroupName:groupName
				   contactName:[NSString stringWithUTF8String:purple_buddy_get_name(buddy)]];

		/* We won't get an initial alias update for this buddy if one is already set, so check and update appropriately.
		 *
		 * This will give us an alias we've set serverside (the "private server alias") if possible.
		 * Failing that, we will get an alias specified remotely (either by the server or by the buddy).
		 */
		const char *alias = purple_buddy_get_alias_only(buddy);

		if (alias) {
			[account updateContact:listContact
						   toAlias:[NSString stringWithUTF8String:alias]];
		}
		
		// Force a status update for the user. Useful for things like XMPP which might display an error message for an offline contact.
		buddy_status_changed_cb(buddy, NULL, purple_presence_get_active_status(purple_buddy_get_presence(buddy)), PURPLE_BUDDY_NONE);
	}
	[pool release];
}

static void buddy_removed_cb(PurpleBuddy *buddy)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	PurpleAccount	*purpleAccount = purple_buddy_get_account(buddy);
	if (purple_account_is_connected(purpleAccount)) {
		CBPurpleAccount	*account = accountLookup(purpleAccount);
		PurpleGroup		*g = purple_buddy_get_group(buddy);
		NSString		*groupName = ((g && purple_group_get_name(g)) ? [NSString stringWithUTF8String:purple_group_get_name(g)] : nil);
		AIListContact	*listContact = contactLookupFromBuddy(buddy);
		/* We pass in purple_buddy_get_name(buddy) directly (without filtering or normalizing it) as it may indicate a 
		 * formatted version of the UID.  We have a signal for when a rename occurs, but passing here lets us get
		 * formatted names which are originally formatted in a way which differs from the results of normalization.
		 * For example, TekJew will normalize to tekjew in AIM; we want to use tekjew internally but display TekJew.
		 */
		[account removeContact:listContact fromGroupName:groupName];
	}
	[pool release];
}

static void connection_signed_on_cb(PurpleConnection *gc)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	GSList *buddies = purple_find_buddies(purple_connection_get_account(gc), /* buddy_name */ NULL);
	GSList *cur;
	for (cur = buddies; cur; cur = cur->next) {
		buddy_added_cb((PurpleBuddy *)cur->data);
	}
	g_slist_free(buddies);
	
	[pool release];
}

static void node_aliased_cb(PurpleBlistNode *node, char *old_alias)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (PURPLE_BLIST_NODE_IS_BUDDY(node)) {
		PurpleBuddy		*buddy = (PurpleBuddy *)node;
		CBPurpleAccount	*account = accountLookup(purple_buddy_get_account(buddy));
		const char		*alias;
		
		/* This will give us an alias we've set serverside (the "private server alias") if possible.
		 * Failing that, we will get an alias specified remotely (either by the server or by the buddy).
		 */
		alias = purple_buddy_get_alias_only(buddy);
		
		AILogWithSignature(@"%@ -> %s", contactLookupFromBuddy(buddy), alias);
		[account updateContact:contactLookupFromBuddy(buddy)
					   toAlias:(alias ? [NSString stringWithUTF8String:alias] : nil)];
	}
	
	[pool release];
}

static NSDictionary *dictionaryFromHashTable(GHashTable *data)
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	GList *l = g_hash_table_get_keys(data);	
	GList *ll;
	for (ll = l; ll; ll = ll->next) {
		void *key = ll->data;
		void *value = g_hash_table_lookup(data, key);
		
		if (!key || !value) continue;
		
		NSString *keyString = [NSString stringWithUTF8String:key];
		NSString *valueString = [NSString stringWithUTF8String:value];
		if ([valueString integerValue]) {
			[dict setValue:[NSNumber numberWithInteger:[valueString integerValue]]
					forKey:keyString];
		}  else {
			[dict setValue:valueString
					forKey:keyString];
		}
	}
	
	return dict;
}

static void chat_join_failed_cb(PurpleConnection *gc, GHashTable *components)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CBPurpleAccount	*account = accountLookup(purple_connection_get_account(gc));
	NSDictionary *componentDict = dictionaryFromHashTable(components);

	for (AIChat *chat in adium.chatController.openChats) {
		if ((chat.account == account) &&
			[account chatCreationDictionary:chat.chatCreationDictionary isEqualToDictionary:componentDict]) {
			[account chatJoinDidFail:chat];
			break;
		}
	}
	
	[pool release];
}

static void typing_changed(PurpleAccount *account, const char *name, AITypingState typingState)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CBPurpleAccount	*cbaccount = accountLookup(account);
	AIListContact *contact = contactLookupFromBuddy(purple_find_buddy(account, name));
	
	// Don't do anything for those who aren't on our contact list.
	if (contact.isStranger) {
		[pool release];
		return;
	}

	AIChat *chat = [adium.chatController existingChatWithContact:contact];
	
	if (typingState != AINotTyping && !chat) {
		chat = [adium.chatController chatWithContact:contact];
		AILogWithSignature(@"Made a chat for %s: %i", name, typingState);
	}

	if (chat)
		[cbaccount typingUpdateForIMChat:chat typing:[NSNumber numberWithInteger:typingState]];
	
	[pool release];
}

static void conversation_created_cb(PurpleConversation *conv, void *data) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_IM) {
		AIChat *chat = imChatLookupFromConv(conv);
		//When a conversation is created, we must clear the typing flag, as libpurple won't notify us properly
		[accountLookup(purple_conversation_get_account(conv)) typingUpdateForIMChat:chat typing:[NSNumber numberWithInteger:AINotTyping]];
	}
	[pool release];
}

/* The buddy-typing, buddy-typed, and buddy-typing-stopped signals will only be sent
 * when there isn't an open conversation, so we're not duplicating typing information here.
 *
 * adiumPurpleConversation has the typing code for open conversations.
 */
 
static void
buddy_typing_cb(PurpleAccount *account, const char *name, void *data) {
	typing_changed(account, name, AITyping);
}

static void
buddy_typed_cb(PurpleAccount *account, const char *name, void *data) {
	typing_changed(account, name, AIEnteredText);
}

static void
buddy_typing_stopped_cb(PurpleAccount *account, const char *name, void *data) {
	typing_changed(account, name, AINotTyping);
}

static void
chat_joined_cb(PurpleConversation *conv, void *data) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//Pass chats along to the account
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_CHAT) {
		
		AIChat *chat = groupChatLookupFromConv(conv);
		
		[accountLookup(purple_conversation_get_account(conv)) addChat:chat];
	}
	
	[pool release];
}


static void
file_recv_request_cb(PurpleXfer *xfer)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	ESFileTransfer  *fileTransfer;
	
    //Purple doesn't return normalized user id, so it should be normalized manually
    char* who = g_strdup(purple_normalize(xfer->account, xfer->who));
    
	//Ask the account for an ESFileTransfer* object
	fileTransfer = [accountLookup(xfer->account) newFileTransferObjectWith:[NSString stringWithUTF8String:who]
					size:purple_xfer_get_size(xfer)
					remoteFilename:[NSString stringWithUTF8String:purple_xfer_get_filename(xfer)]];
    
    g_free(who);
	
	//Configure the new object for the transfer
	[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
	
	xfer->ui_data = [fileTransfer retain];
	
	/* Set a fake local filename to convince libpurple that we are handling the request. We are, but
	 * the code expects a synchronous response, and we rock out asynchronously.
	 */
	purple_xfer_set_local_filename(xfer, "");
	
	//Tell the account that we are ready to request the reception
	[accountLookup(purple_xfer_get_account(xfer)) requestReceiveOfFileTransfer:fileTransfer];
	
	[pool release];
}

void configureAdiumPurpleSignals(void)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	void *blist_handle = purple_blist_get_handle();
	void *handle       = adium_purple_get_handle();
	
	//Idle
	purple_signal_connect(blist_handle, "buddy-idle-changed",
						handle, PURPLE_CALLBACK(buddy_idle_changed_cb),
						GINT_TO_POINTER(0));
	
	//Status
	purple_signal_connect(blist_handle, "buddy-status-changed",
						handle, PURPLE_CALLBACK(buddy_status_changed_cb),
						GINT_TO_POINTER(0));

	//Icon
	purple_signal_connect(blist_handle, "buddy-icon-changed",
						handle, PURPLE_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_ICON));

	//Signon / Signoff
	purple_signal_connect(blist_handle, "buddy-signed-on",
						handle, PURPLE_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_SIGNON));
	purple_signal_connect(blist_handle, "buddy-signed-off",
						handle, PURPLE_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_SIGNOFF));	
	purple_signal_connect(blist_handle, "buddy-got-login-time",
						handle, PURPLE_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(PURPLE_BUDDY_SIGNON_TIME));	

	purple_signal_connect(blist_handle, "buddy-got-login-time",
						  handle, PURPLE_CALLBACK(buddy_event_cb),
						  GINT_TO_POINTER(PURPLE_BUDDY_SIGNON_TIME));	

	purple_signal_connect(blist_handle, "buddy-added",
						  handle, PURPLE_CALLBACK(buddy_added_cb),
						  NULL);
	
	purple_signal_connect(blist_handle, "buddy-removed",
						  handle, PURPLE_CALLBACK(buddy_removed_cb),
						  NULL);

	purple_signal_connect(blist_handle, "blist-node-aliased",
						  handle, PURPLE_CALLBACK(node_aliased_cb),
						  NULL);
	
	purple_signal_connect(purple_connections_get_handle(), "signed-on",
						  handle, PURPLE_CALLBACK(connection_signed_on_cb),
						  NULL);

	purple_signal_connect(purple_conversations_get_handle(), "conversation-created",
						  handle, PURPLE_CALLBACK(conversation_created_cb),
						  NULL);
	purple_signal_connect(purple_conversations_get_handle(), "chat-joined",
						  handle, PURPLE_CALLBACK(chat_joined_cb),
						  NULL);
	purple_signal_connect(purple_conversations_get_handle(), "chat-join-failed",
						  handle, PURPLE_CALLBACK(chat_join_failed_cb),
						  NULL);
	
	purple_signal_connect(purple_conversations_get_handle(), "buddy-typing",
						  handle, PURPLE_CALLBACK(buddy_typing_cb), NULL);
	
	purple_signal_connect(purple_conversations_get_handle(), "buddy-typed",
						  handle, PURPLE_CALLBACK(buddy_typed_cb), NULL);
	
	purple_signal_connect(purple_conversations_get_handle(), "buddy-typing-stopped",
						  handle, PURPLE_CALLBACK(buddy_typing_stopped_cb), NULL);

	purple_signal_connect(purple_xfers_get_handle(), "file-recv-request",
						  handle, PURPLE_CALLBACK(file_recv_request_cb), NULL);
	
	[pool release];
}
