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

#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import "CBPurpleAccount.h"
#import "CBPurpleServicePlugin.h"
#import "adiumPurpleCore.h"
#import "adiumPurpleEventloop.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AILoginControllerProtocol.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AICorePluginLoader.h>
#import <Adium/AIService.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIContactObserverManager.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIContactObserverManager.h>
#import <AIUtilities/AIImageAdditions.h>

#import <CoreFoundation/CoreFoundation.h>
#import <libpurple/libpurple.h>
#import <glib.h>
#import <stdlib.h>

#import "ESPurpleAIMAccount.h"
#import "CBPurpleOscarAccount.h"

#import "ESiTunesPlugin.h"

#import "adiumPurpleAccounts.h"

//Purple slash command interface
#import <libpurple/cmds.h>

#import "libpurple_extensions/oscar-adium.h"

@interface SLPurpleCocoaAdapter ()
- (void)initLibPurple;
- (BOOL)attemptPurpleCommandOnMessage:(NSString *)originalMessage fromAccount:(AIAccount *)sourceAccount inChat:(AIChat *)chat;
@end


static NSMutableArray		*libpurplePluginArray = nil;

@implementation SLPurpleCocoaAdapter

/*!
 * @brief Return the shared instance
 */
+ (SLPurpleCocoaAdapter *)sharedInstance
{
    /*
     * A pointer to the single instance of this class active in the application.
     * The purple callbacks need to be C functions with specific prototypes, so they
     * can't be ObjC methods. The ObjC callbacks do need to be ObjC methods. This
     * allows the C ones to call the ObjC ones.
     **/
    static SLPurpleCocoaAdapter *_sharedInstance;
    static dispatch_once_t sharedInstanceGuard;
    dispatch_once(&sharedInstanceGuard, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

/*!
 * @brief Plugin loaded
 *
 * Initialize each libpurple plugin.  These plugins should not do anything within libpurple itself; this should be done in
 * -[plugin initLibpurplePlugin].
 */
+ (void)pluginDidLoad
{
	libpurplePluginArray = [[NSMutableArray alloc] init];

	for (NSString *libpurplePluginPath in [adium allResourcesForName:@"PlugIns"
													  withExtensions:@"AdiumLibpurplePlugin"]) {
		[AICorePluginLoader loadPluginAtPath:libpurplePluginPath
							  confirmLoading:YES
								 pluginArray:libpurplePluginArray];
	}
}

+ (NSArray *)libpurplePluginArray
{
	return libpurplePluginArray;
}

//Register the account purpleside in the purple thread
- (void)addAdiumAccount:(CBPurpleAccount *)adiumAccount
{
	//Note that purple_account_new() calls purple_accounts_find() first, returning an existing PurpleAccount if there is one.
	PurpleAccount *account = purple_account_new([adiumAccount purpleAccountName], [adiumAccount protocolPlugin]);

	if (account->ui_data) {
		[(CBPurpleAccount *)account->ui_data autorelease];
		[(CBPurpleAccount *)account->ui_data setPurpleAccount:nil];
	}
	account->ui_data = [adiumAccount retain];

	[adiumAccount setPurpleAccount:account];

	purple_accounts_add(account);
	purple_account_set_status_list(account, "offline", YES, NULL);
}

//Remove an account purpleside
- (void)removeAdiumAccount:(CBPurpleAccount *)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);

	if (account) {
		[(CBPurpleAccount *)account->ui_data release];
		account->ui_data = nil;
		
		purple_accounts_remove(account);
	}

	[adiumAccount setPurpleAccount:NULL];
}

#pragma mark Initialization
- (id)init
{
	if ((self = [super init])) {
		[self initLibPurple];		
	}
	
    return self;
}

static void ZombieKiller_Signal(int i)
{
	int status;
	pid_t child_pid;

	while ((child_pid = waitpid(-1, &status, WNOHANG)) > 0);
}

- (void)networkDidChange:(NSNotification *)inNotification
{
	purple_signal_emit(purple_network_get_handle(), "network-configuration-changed", NULL);
}

- (void)debugLoggingIsEnabledDidChange:(NSNotification *)inNotification
{
	configurePurpleDebugLogging();
}

void adium_glib_print(const char *string)
{
    @autoreleasepool {
		AILog(@"(GLib): %s", string);
    }
}

void adium_glib_log(const gchar *log_domain, GLogLevelFlags flags, const gchar *message, gpointer user_data)
{
	if (!AIDebugLoggingIsEnabled()) return;
	
    @autoreleasepool {
		
		NSString *level;
		
		if (!log_domain) log_domain = "general";
		
		if ((flags & G_LOG_LEVEL_ERROR) == G_LOG_LEVEL_ERROR)
			level = @"ERROR";
		else if ((flags & G_LOG_LEVEL_CRITICAL) == G_LOG_LEVEL_CRITICAL)
			level = @"CRITICAL";
		else if ((flags & G_LOG_LEVEL_WARNING) == G_LOG_LEVEL_WARNING)
			level = @"WARNING";
		else if ((flags & G_LOG_LEVEL_MESSAGE) == G_LOG_LEVEL_MESSAGE)
			level = @"MESSAGE";
		else if ((flags & G_LOG_LEVEL_INFO) == G_LOG_LEVEL_INFO)
			level = @"INFO";
		else if ((flags & G_LOG_LEVEL_DEBUG) == G_LOG_LEVEL_DEBUG)
			level = @"MISC";
		else
			level = @"UNKNOWN";
		
		
		AILog(@"(GLib : %s): %@: %s", log_domain, level, message);
    }
}

- (void)initLibPurple
{
	/* Initializing libpurple may result in loading a ton of buddies if our permit and deny lists are large; that, in
	 * turn, would create and update a ton of contacts.
	 */
	[[AIContactObserverManager sharedManager] delayListObjectNotifications];
	
	// Redirect every possible glib error message to AILog
	g_set_print_handler(adium_glib_print);
	g_set_printerr_handler(adium_glib_print);
	
	for (NSString *domain in [NSArray arrayWithObjects:@"GLib", @"GModule", @"GLib-GObject", @"GThread", @"Gnt", @"GStreamer", @"stderr", nil]) {
		g_log_set_handler([domain UTF8String], G_LOG_LEVEL_MASK | G_LOG_FLAG_FATAL | G_LOG_FLAG_RECURSION, adium_glib_log, NULL);
	}
	
	g_log_set_handler(NULL, G_LOG_LEVEL_MASK | G_LOG_FLAG_FATAL | G_LOG_FLAG_RECURSION, adium_glib_log, NULL);
	
	// Init the glib type system (used by GObjects)
	g_type_init();
	
	/* Don't let gstreamer load 'system path' plugins - if the user has gstreamer installed elsewhere,
	 * or if this is a poor, confused developer who has built gstreamer locally, this will lead to very
	 * bad behavior.
	 */
	setenv("GST_PLUGIN_SYSTEM_PATH", " ", 1);
	
	
	//Set the gaim user directory to be within this user's directory
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Adium 1.0.3 moved to libpurple"]) {
		//Remove old icons cache
		[[NSFileManager defaultManager]  removeItemAtPath:[[[adium.loginController userDirectory] stringByAppendingPathComponent:@"libgaim"] stringByAppendingPathComponent:@"icons"]
												  error:NULL];
		
		//Update the rest
		[[NSFileManager defaultManager] moveItemAtPath:[[adium.loginController userDirectory] stringByAppendingPathComponent:@"libgaim"]
										  toPath:[[adium.loginController userDirectory] stringByAppendingPathComponent:@"libpurple"]
										 error:NULL];
		
		[[NSUserDefaults standardUserDefaults] setBool:YES
												forKey:@"Adium 1.0.3 moved to libpurple"];
	}
	
	//Set the purple user directory to be within this user's directory
	NSString	*purpleUserDir = [[adium.loginController userDirectory] stringByAppendingPathComponent:@"libpurple"];
	purple_util_set_user_dir([[purpleUserDir stringByExpandingTildeInPath] fileSystemRepresentation]);

	//Set the caches path
	purple_buddy_icons_set_cache_dir([[[adium cachesPath] stringByExpandingTildeInPath] fileSystemRepresentation]);

	/* Delete blist.xml once when 1.2.4 runs to clear out any old silliness, including improperly blocked Yahoo contacts */
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Adium 1.2.4 deleted blist.xml"]) {
		[[NSFileManager defaultManager] removeItemAtPath:
			[[[NSString stringWithUTF8String:purple_user_dir()] stringByAppendingPathComponent:@"blist"] stringByAppendingPathExtension:@"xml"]
												 error:NULL];
		[[NSUserDefaults standardUserDefaults] setBool:YES
												forKey:@"Adium 1.2.4 deleted blist.xml"];
	}
	
	purple_core_set_ui_ops(adium_purple_core_get_ops());
	purple_eventloop_set_ui_ops(adium_purple_eventloop_get_ui_ops());

	//Initialize the libpurple core; this will call back on the function specified in our core UI ops for us to finish configuring libpurple
	if (!purple_core_init("Adium")) {
		NSLog(@"*** FATAL ***: Failed to initialize purple core");
		AILog(@"*** FATAL ***: Failed to initialize purple core");
	}

	//Libpurple's async DNS lookup tends to create zombies.
	{
		struct sigaction act;
		
		act.sa_handler = ZombieKiller_Signal;		
		//Send for terminated but not stopped children
		act.sa_flags = SA_NOCLDWAIT;

		sigaction(SIGCHLD, &act, NULL);
	}
	
	//Observe for network changes to tell libpurple about it
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(networkDidChange:)
									   name:AINetworkDidChangeNotification
									 object:nil];

	/* Be sure to enable debug logging if it is turned on after launch */
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(debugLoggingIsEnabledDidChange:)
												 name:AIDebugLoggingEnabledNotification
											   object:nil];

	
	/* For any behaviors which occur on the next run loop, provide a buffer time of continued expectation of 
	 * heavy activity.
	 */
	[[AIContactObserverManager sharedManager] delayListObjectNotificationsUntilInactivity];
	
	[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];

}

#pragma mark Lookup functions

static NSString* serviceClassForPurpleProtocolID(const char *protocolID)
{
	NSString	*serviceClass = nil;
	if (protocolID) {
		if (!strcmp(protocolID, "prpl-oscar"))
			serviceClass = @"AIM-compatible";
		else if (!strcmp(protocolID, "prpl-gg"))
			serviceClass = @"Gadu-Gadu";
		else if (!strcmp(protocolID, "prpl-jabber"))
			serviceClass = @"Jabber";
		else if (!strcmp(protocolID, "prpl-meanwhile"))
			serviceClass = @"Sametime";
		else if (!strcmp(protocolID, "prpl-msn"))
			serviceClass = @"MSN";
		else if (!strcmp(protocolID, "prpl-novell"))
			serviceClass = @"GroupWise";
		else if (!strcmp(protocolID, "prpl-yahoo"))
			serviceClass = @"Yahoo!";
		else if (!strcmp(protocolID, "prpl-zephyr"))
			serviceClass = @"Zephyr";
	}
	
	return serviceClass;
}

/*
 * Finds an instance of CBPurpleAccount for a pointer to a PurpleAccount struct.
 */
CBPurpleAccount* accountLookup(PurpleAccount *account)
{
	CBPurpleAccount *adiumPurpleAccount = (account ? (CBPurpleAccount *)account->ui_data : nil);
	/* If the account doesn't have its ui_data associated yet (we haven't tried to connect) but we want this
	 * lookup data, we have to do some manual parsing.  This is used for example from the OTR preferences.
	 */
	if (!adiumPurpleAccount && account) {
		const char	*protocolID = account->protocol_id;
		NSString	*serviceClass = serviceClassForPurpleProtocolID(protocolID);

		for (adiumPurpleAccount in adium.accountController.accounts) {
			if ([adiumPurpleAccount isKindOfClass:[CBPurpleAccount class]] &&
			   [adiumPurpleAccount.service.serviceClass isEqualToString:serviceClass] &&
			   [adiumPurpleAccount.UID caseInsensitiveCompare:[NSString stringWithUTF8String:account->username]] == NSOrderedSame) {
				break;
			}
		}
	}
    return adiumPurpleAccount;
}

PurpleAccount* accountLookupFromAdiumAccount(CBPurpleAccount *adiumAccount)
{
	return [adiumAccount purpleAccount];
}

AIListContact* contactLookupFromBuddy(PurpleBuddy *buddy)
{
	//Get the node's ui_data
	AIListContact *theContact = (buddy ? (AIListContact *)buddy->node.ui_data : nil);

	//If the node does not have ui_data yet, we need to create a contact and associate it
	if (!theContact && buddy) {
		NSString	*UID;
	
		UID = [NSString stringWithUTF8String:purple_normalize(purple_buddy_get_account(buddy), purple_buddy_get_name(buddy))];
		
		theContact = [accountLookup(purple_buddy_get_account(buddy)) contactWithUID:UID];
		
		//Associate the handle with ui_data and the buddy with our statusDictionary
		buddy->node.ui_data = [theContact retain];
		
		//This is the first time the contact has been accessed from the buddy; reset the icon cache for it
		[AIUserIcons flushCacheForObject:theContact];
	}
	
	return theContact;
}

AIListContact* contactLookupFromIMConv(PurpleConversation *conv)
{
	return nil;
}

AIChat* groupChatLookupFromConv(PurpleConversation *conv)
{
	AIChat *chat;
	
	chat = (AIChat *)conv->ui_data;
	if (!chat) {
		NSString *name = [NSString stringWithUTF8String:purple_conversation_get_name(conv)];
		
		CBPurpleAccount *account = accountLookup(purple_conversation_get_account(conv));
        
        /* 
         * Need to start a new chat, associating with the PurpleConversation.
         *
         * This may call back through to us recursively, via:
         *   -[CBPurpleAccount chatWithContact:identifier:]
         *   -[AIChatController chatWithContact:]
         *   -[CBPurpleAccount openChat:]
         *   -[SLPurpleCocoaAdaper openChat:onAccount:]
         *   convLookupFromChat()
         *   groupChatLookupFromConv()
         *
         * That's fine, as we'll get the same lookups the second time through; we just need to be cautious.
         */
		chat = [account chatWithName:name identifier:[NSValue valueWithPointer:conv]];
		if (!chat.chatCreationDictionary) {
			// If we don't have a chat creation dictionary (i.e., we didn't initiate the join), create one.
			chat.chatCreationDictionary = [account extractChatCreationDictionaryFromConversation: conv];
		}
        if (conv->ui_data != chat) {
            [(AIChat *)(conv->ui_data) release];
            conv->ui_data = [chat retain];
        }
		AILog(@"group chat lookup assigned %@ to %p (%s)",chat,conv, purple_conversation_get_name(conv));
	}

	return chat;
}

AIChat* existingChatLookupFromConv(PurpleConversation *conv)
{
	return (conv ? conv->ui_data : nil);
}

AIChat* chatLookupFromConv(PurpleConversation *conv)
{
	switch(purple_conversation_get_type(conv)) {
		case PURPLE_CONV_TYPE_CHAT:
			return groupChatLookupFromConv(conv);
			break;
		case PURPLE_CONV_TYPE_IM:
			return imChatLookupFromConv(conv);
			break;
		default:
			return existingChatLookupFromConv(conv);
			break;
	}
}

AIChat* imChatLookupFromConv(PurpleConversation *conv)
{
	AIChat			*chat;
	
	chat = (AIChat *)conv->ui_data;

	if (!chat) {
		//No chat is associated with the IM conversation
		AIListContact   *sourceContact;
		PurpleBuddy		*buddy;
		PurpleAccount	*account;
		
		account = purple_conversation_get_account(conv);
//		AILog(@"%x purple_conversation_get_name(conv) %s; normalizes to %s",account,purple_conversation_get_name(conv),purple_normalize(account,purple_conversation_get_name(conv)));

		//First, find the PurpleBuddy with whom we are conversing
		buddy = purple_find_buddy(account, purple_conversation_get_name(conv));
		if (!buddy) {
			//No purple_buddy corresponding to the purple_conversation_get_name(conv) is on our list, so create one
			buddy = purple_buddy_new(account, purple_normalize(account, purple_conversation_get_name(conv)), NULL);	//create a PurpleBuddy
		}

		NSCAssert(buddy != nil, @"buddy was nil");

		sourceContact = contactLookupFromBuddy(buddy);
		/* 
         * Need to start a new chat, associating with the PurpleConversation.
         *
         * This may call back through to us recursively, via:
         *   -[CBPurpleAccount chatWithContact:identifier:]
         *   -[AIChatController chatWithContact:]
         *   -[CBPurpleAccount openChat:]
         *   -[SLPurpleCocoaAdaper openChat:onAccount:]
         *   convLookupFromChat()
         *   imChatLookupFromConv()
         *
         * That's fine, as we'll get the same lookups the second time through; we just need to be cautious.
         */
		chat = [accountLookup(account) chatWithContact:sourceContact identifier:[NSValue valueWithPointer:conv]];

		if (!chat) {
			NSString	*errorString;

			errorString = [NSString stringWithFormat:@"conv %x: Got nil chat in lookup for sourceContact %@ (%x ; \"%s\" ; \"%s\") on adiumAccount %@ (%x ; \"%s\")",
				conv,
				sourceContact,
				buddy,
				(buddy ? purple_buddy_get_name(buddy) : ""),
				((buddy && purple_buddy_get_account(buddy) && purple_buddy_get_name(buddy)) ? purple_normalize(purple_buddy_get_account(buddy), purple_buddy_get_name(buddy)) : ""),
				accountLookup(account),
				account,
				(account ? purple_account_get_username(account) : "")];

			NSCAssert(chat != nil, errorString);
		}

		//Associate the PurpleConversation with the AIChat
        if (conv->ui_data != chat) {
            [(AIChat *)(conv->ui_data) release];
            conv->ui_data = [chat retain];
        }
	}
    
	return chat;	
}

PurpleConversation* convLookupFromChat(AIChat *chat, id adiumAccount)
{
	PurpleConversation	*conv = [[chat identifier] pointerValue];
	PurpleAccount		*account = accountLookupFromAdiumAccount(adiumAccount);

	if (!conv && adiumAccount && purple_account_get_connection(account)) {
		AIListObject *listObject = chat.listObject;
		
		//If we have a listObject, we are dealing with a one-on-one chat, so proceed accordingly
		if (listObject) {
			char *destination;
			
			destination = g_strdup(purple_normalize(account, [listObject.UID UTF8String]));
			
			conv = purple_conversation_new(PURPLE_CONV_TYPE_IM, account, destination);
			
			//associate the AIChat with the purple conv
			if (conv) imChatLookupFromConv(conv);

			g_free(destination);
			
		} else {
			//Otherwise, we have a multiuser chat.
			
			//All multiuser chats should have a non-nil name.
			NSString	*chatName = chat.name;
			if (chatName) {
				const char *name = [chatName UTF8String];
				
				/*
				 Look for an existing purpleChat.  If we find one, our job is complete.
				 
				 We will never find one if we are joining a chat on our own (via the Join Chat dialogue).
				 
				 We should never get to this point if we were invited to a chat, as groupChatLookupFromConv(),
				 which was called when we accepted the invitation and got the chat information from Purple,
				 will have associated the PurpleConversation with the chat and we would have stopped after
				 [[chat identifier] pointerValue] above.
				 
				 However, there's no reason not to check just in case.
				 */
				PurpleChat *purpleChat = purple_blist_find_chat(account, name);
				if (!purpleChat) {
					
					/*
					 If we don't have a PurpleChat with this name on this account, we need to create one.
					 Our chat, which should have been created via the Adium Join Chat API, should have
					 a ChatCreationInfo property with the information we need to ask Purple to
					 perform the join.
					 */
					NSDictionary	*chatCreationInfo = [chat valueForProperty:@"chatCreationInfo"];
					chatCreationInfo = [(CBPurpleAccount *)chat.account willJoinChatUsingDictionary:chatCreationInfo];

					if (!chatCreationInfo) {
						AILog(@"*** No chat creation info for %@ on %@",chat,adiumAccount);
						return NULL;
					}
					
					AILog(@"Creating a chat with name %s (Creation info: %@).", name, chatCreationInfo);

					GHashTable				*components;
					
					//Prpl Info
					PurpleConnection		*gc = purple_account_get_connection(account);
					GList					*list, *tmp;
					struct proto_chat_entry *pce;

					g_return_val_if_fail(gc != NULL, NULL);

					//Create a hash table
					//The hash table should contain char* objects created via a g_strdup method
					components = g_hash_table_new_full(g_str_hash, g_str_equal,
													   g_free, g_free);
					
					for (NSString *identifier in chatCreationInfo) {
						id		value = [chatCreationInfo objectForKey:identifier];
						char	*valueUTF8String = NULL;
						
						if ([value isKindOfClass:[NSNumber class]]) {
							valueUTF8String = g_strdup_printf("%ld",(long int)[value integerValue]);

						} else if ([value isKindOfClass:[NSString class]]) {
							valueUTF8String = g_strdup([value UTF8String]);

						} else {
							AILog(@"Invalid value %@ for identifier %@",value,identifier);
						}
						
						//Store our chatCreationInfo-supplied value in the compnents hash table
						if (valueUTF8String) {
							g_hash_table_replace(components,
												 g_strdup([identifier UTF8String]),
												 valueUTF8String);
						}
					}
					
					if (chat.lastMessageDate) {
						NSTimeInterval lastMessageInterval = [chat.lastMessageDate timeIntervalSince1970];
						NSString *historySince = [[NSDate dateWithTimeIntervalSince1970:lastMessageInterval + 1]
                                                  descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%SZ"
                                                                       timeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]
                                                                         locale:nil];

						g_hash_table_replace(components, g_strdup("history_since"), g_strdup([historySince UTF8String]));
					} else {
						AILogWithSignature(@"No last message found for history on %@", chat);
					}


					//In debug mode, verify we didn't miss any required values
					if (AIDebugLoggingIsEnabled()) {
						/* Get the chat_info for our desired account.  This will be a GList of proto_chat_entry
						 * objects, each of which has a label and identifier.  Each may also have is_int, with a minimum
						 * and a maximum integer value.
						 */
						if ((PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl))->chat_info)
						{
							list = (PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl))->chat_info(gc);

							//Look at each proto_chat_entry in the list to verify we have it in chatCreationInfo
							for (tmp = list; tmp; tmp = tmp->next)
							{
								pce = tmp->data;
								char	*identifier = g_strdup(pce->identifier);
								
								NSString	*value = [chatCreationInfo objectForKey:[NSString stringWithUTF8String:identifier]];
								if (!value) {
									AILog(@"Danger, Will Robinson! %s is in the proto_info but can't be found in %@",identifier,chatCreationInfo);
								}
								
								g_free(identifier);
							}
						}
					}

					/* Join the chat serverside - the GHashTable components, coupled with the originating PurpleConnection,
					 * now contains all the information the prpl will need to process our request.
					 */
					AILog(@"In the event of an emergency, your GHashTable may be used as a flotation device...");
					serv_join_chat(gc, components);
					g_hash_table_unref(components);
				}
			}
		}
	}
	
	return conv;
}

PurpleConversation* existingConvLookupFromChat(AIChat *chat)
{
	return (PurpleConversation *)[[chat identifier] pointerValue];
}

void* adium_purple_get_handle(void)
{
	static NSInteger adium_purple_handle;
	
	return &adium_purple_handle;
}

#pragma mark Images

static NSString *_messageImageCachePathWithoutExtension(int imageID, AIAccount* adiumAccount)
{
    NSString    *messageImageCacheFilename = [NSString stringWithFormat:@"TEMP-Image_%@_%i", adiumAccount.internalObjectID, imageID];
    return [[adium cachesPath] stringByAppendingPathComponent:messageImageCacheFilename];
}

NSString *processPurpleImages(NSString* inString, AIAccount* adiumAccount)
{
	NSScanner			*scanner;
    NSString			*chunkString = nil;
    NSMutableString		*newString;
	NSString			*targetString = @"<IMG ID=";
	NSCharacterSet		*quoteApostropheCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\'"];
    int imageID;
	
	if ([inString rangeOfString:targetString options:NSCaseInsensitiveSearch].location == NSNotFound) {
		return inString;
	}
	
    //set up
	newString = [[NSMutableString alloc] init];
	
    scanner = [NSScanner scannerWithString:inString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	//A purple image tag takes the form <IMG ID='12'></IMG> where 12 is the reference for use in PurpleStoredImage* purple_imgstore_get(int)
	
	//Parse the incoming HTML
    while (![scanner isAtEnd]) {
		//Find the beginning of a purple IMG ID tag
		if ([scanner scanUpToString:targetString intoString:&chunkString]) {
			[newString appendString:chunkString];
		}
		
		if ([scanner scanString:targetString intoString:&chunkString]) {
			//Skip past a quote or apostrophe
			[scanner scanCharactersFromSet:quoteApostropheCharacterSet intoString:NULL];
			
			//Get the image ID from the tag
			[scanner scanInt:&imageID];

			//Skip past a quote or apostrophe
			[scanner scanCharactersFromSet:quoteApostropheCharacterSet intoString:NULL];

			//Scan past a >
			[scanner scanString:@">" intoString:nil];
			
			//Get the image, then write it out as a png
			PurpleStoredImage		*purpleImage = purple_imgstore_find_by_id(imageID);
			if (purpleImage) {
				NSString		*filename = (purple_imgstore_get_filename(purpleImage) ?
											 [NSString stringWithUTF8String:purple_imgstore_get_filename(purpleImage)] :
											 @"Image");
				NSString		*imagePath = _messageImageCachePathWithoutExtension(imageID, adiumAccount);
				
				//First make an NSImage, then request a TIFFRepresentation to avoid an obscure bug in the PNG writing routines
				//Exception: PNG writer requires compacted components (bits/component * components/pixel = bits/pixel)
				NSData *data = [NSData dataWithBytes:purple_imgstore_get_data(purpleImage)
											  length:purple_imgstore_get_size(purpleImage)];
				
				NSString *extension = [NSImage extensionForBitmapImageFileType:[NSImage fileTypeOfData:data]];
				if (!extension) {
					//We don't know what it is; try to make a png out of it
					NSImage				*image = [[NSImage alloc] initWithData:data];
					NSData				*imageTIFFData = [image TIFFRepresentation];
					NSBitmapImageRep	*bitmapRep = [NSBitmapImageRep imageRepWithData:imageTIFFData];
					
					data = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
					extension = @"png";
					[image release];
				}
				
				filename = [filename stringByAppendingPathExtension:extension];
				imagePath = [imagePath stringByAppendingPathExtension:extension];

				//If writing the file is successful, write an <IMG SRC="filepath"> tag to our string; the 'scaledToFitImage' class lets us apply CSS to directIM images only
				if ([data writeToFile:imagePath atomically:YES]) {
					[newString appendString:[NSString stringWithFormat:@"<IMG CLASS=\"scaledToFitImage\" SRC=\"%@\" ALT=\"%@\">",
						imagePath, filename]];	
				}

			} else {
				//If we didn't get a purpleImage, just leave the tag for now.. maybe it was important?
				[newString appendFormat:@"<IMG ID=\"%ld\">",chunkString];
			}
		}
	}

	return ([newString autorelease]);
}

#pragma mark Notify
// Notify ----------------------------------------------------------------------------------------------------------
// We handle the notify messages within SLPurpleCocoaAdapter so we can use our localized string macro
- (void *)handleNotifyMessageOfType:(PurpleNotifyMsgType)type withTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary;
{

    NSString *primaryString = [NSString stringWithUTF8String:primary];
	NSString *secondaryString = secondary ? [NSString stringWithUTF8String:secondary] : nil;
	
	NSString *titleString;
	if (title) {
		titleString = [NSString stringWithFormat:AILocalizedString(@"Adium Notice: %@",nil),[NSString stringWithUTF8String:title]];
	} else {
		titleString = AILocalizedString(@"Adium : Notice", nil);
	}
	
	NSString *errorMessage = nil;
	NSString *description = nil;
	
	if (primary && strcmp(primary, _("Already there")) == 0) 
		return NULL;

	//Suppress notification warnings we have no interest in seeing
	if (secondaryString) {
		if ((strcmp(secondary, _("Not supported by host")) == 0) || /* OSCAR */
			(strcmp(secondary, _("Not logged in")) == 0) || /* OSCAR */
			(strcmp(secondary, _("Your buddy list was downloaded from the server.")) == 0) || /* Gadu-gadu */
			(strcmp(secondary, _("Your buddy list was stored on the server.")) == 0) /* Gadu-gadu */) {
			return NULL;
		}
		
		if ([secondaryString isEqualToString:
			 [NSString stringWithFormat:[NSString stringWithUTF8String:_("Could not add the buddy %s for an unknown reason.")], "1"]]) {
			/* Rather random error displayed by OSCAR (since forever, as of libpurple 2.4.0) for some clients while connecting */
			return NULL;
		}
		
		if ([secondaryString rangeOfString:@"Your contact is using Windows Live"].location != NSNotFound) {
			 /* Yahoo without MSN support - English string from the server */
			return NULL;
		}

	} 
	
	if ([primaryString rangeOfString: @"did not get sent"].location != NSNotFound) {
		//Oscar send error
		//This may not ever occur as of libpurple 2.4.0; I can't find the phrase 'did not get sent' in any of the code. -evands
		NSString *targetUserName = [[[[primaryString componentsSeparatedByString:@" message to "] objectAtIndex:1] componentsSeparatedByString:@" did not get "] objectAtIndex:0];
		
		errorMessage = [NSString stringWithFormat:AILocalizedString(@"Your message to %@ did not get sent",nil),targetUserName];
		
		if (secondaryString) {
			if ([secondaryString rangeOfString:[NSString stringWithUTF8String:_("Rate")]].location != NSNotFound) {
				description = AILocalizedString(@"You are sending messages too quickly; wait a moment and try again.",nil);
			} else if ([secondaryString rangeOfString:[NSString stringWithUTF8String:_("Service unavailable")]].location != NSNotFound ||
					   [secondaryString rangeOfString:[NSString stringWithUTF8String:_("Not logged in")]].location != NSNotFound) {
				description = AILocalizedString(@"Connection error.",nil);
				
			} else if ([secondaryString rangeOfString:[NSString stringWithUTF8String:_("Refused by client")]].location != NSNotFound) {
				description = AILocalizedString(@"Your message was refused by the other user.",nil);
				
			} else if ([secondaryString rangeOfString:[NSString stringWithUTF8String:_("Reply too big")]].location != NSNotFound) {
				description = AILocalizedString(@"Your message was too big.",nil);
				
			} else if ([secondaryString rangeOfString:[NSString stringWithUTF8String:_("In local permit/deny")]].location != NSNotFound) {
				description = AILocalizedString(@"The other user is in your deny list.",nil);
				
			} else if ([secondaryString rangeOfString:[NSString stringWithUTF8String:_("Too evil")]].location != NSNotFound) {
				description = AILocalizedString(@"Warning level is too high.",nil);
				
			} else if ([secondaryString rangeOfString:[NSString stringWithUTF8String:_("User temporarily unavailable")]].location != NSNotFound) {
				description = AILocalizedString(@"The other user is temporarily unavailable.",nil);
			}
		}
		
		if (!description)
			description = AILocalizedString(@"No reason was given.",nil);
    }
	
	//If we didn't grab a translated version, at least display the English version Purple supplied
	[adium.interfaceController handleMessage:([errorMessage length] ? errorMessage : primaryString)
							   withDescription:([description length] ? description : ([secondaryString length] ? secondaryString : @"") )
							   withWindowTitle:titleString];
	
	return NULL;
}

/* XXX ugly */
- (void *)handleNotifyFormattedWithTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary text:(const char *)text
{
	NSString *titleString = (title ? [NSString stringWithUTF8String:title] : nil);
	NSString *primaryString = (primary ? [NSString stringWithUTF8String:primary] : nil);
	
	if (!titleString) {
		titleString = primaryString;
		primaryString = nil;
	}
	
	NSString *secondaryString = (secondary ? [NSString stringWithUTF8String:secondary] : nil);
	if (!primaryString) {
		primaryString = secondaryString;
		secondaryString = nil;
	}
	
	static AIHTMLDecoder	*notifyFormattedHTMLDecoder = nil;
	if (!notifyFormattedHTMLDecoder) notifyFormattedHTMLDecoder = [[AIHTMLDecoder decoder] retain];

	NSString	*textString = (text ? [NSString stringWithUTF8String:text] : nil); 
	if (textString) textString = [[notifyFormattedHTMLDecoder decodeHTML:textString] string];
	
	NSString	*description = nil;
	if ([textString length] && [secondaryString length]) {
		description = [NSString stringWithFormat:@"%@\n\n%@",secondaryString,textString];
		
	} else if (textString) {
		description = textString;
		
	} else if (secondaryString) {
		description = secondaryString;
		
	}
	
	NSString	*message = primaryString;
	
	[adium.interfaceController handleMessage:(message ? message : @"")
							   withDescription:(description ? description : @"")
							   withWindowTitle:(titleString ? titleString : @"")];

	return NULL;
}


#pragma mark File transfers
- (void)displayFileSendError
{
	[adium.interfaceController handleMessage:AILocalizedString(@"File Send Error",nil)
							   withDescription:AILocalizedString(@"An error was encountered sending the file.",nil)
							   withWindowTitle:AILocalizedString(@"File Send Error",nil)];
}

#pragma mark Thread accessors
- (void)disconnectAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	AILog(@"Setting %x disabled and offline (%s)...",account,
		  purple_status_type_get_id(purple_account_get_status_type_with_primitive(account, PURPLE_STATUS_OFFLINE)));

	purple_account_set_enabled(account, "Adium", NO);
}

- (void)registerAccount:(id)adiumAccount
{
	purple_account_set_register_callback(accountLookupFromAdiumAccount(adiumAccount), adiumPurpleAccountRegisterCb, adiumAccount);
	purple_account_register(accountLookupFromAdiumAccount(adiumAccount));
}

static void purpleUnregisterCb(PurpleAccount *account, gboolean success, void *user_data) {
	[(CBPurpleAccount*)user_data unregisteredAccount:success?YES:NO];
}

- (void)unregisterAccount:(id)adiumAccount
{
	purple_account_unregister(accountLookupFromAdiumAccount(adiumAccount), purpleUnregisterCb, adiumAccount);
}

//Called on the purple thread, actually performs the specified command (it should have already been tested by 
//attemptPurpleCommandOnMessage:... below.
- (BOOL)doCommand:(NSString *)originalMessage
			fromAccount:(id)sourceAccount
				 inChat:(AIChat *)chat
{
	PurpleConversation	*conv = convLookupFromChat(chat, sourceAccount);
	PurpleCmdStatus		status;
	char				*markup, *error;
	const char			*cmd;
	BOOL				didCommand = NO;

	if (!conv || ([originalMessage length] < 2)) return NO;
	
	cmd = [originalMessage UTF8String];
	
	//cmd+1 will be the cmd without the leading character, which should be "/"
	markup = g_markup_escape_text(cmd+1, -1);
	status = purple_cmd_do_command(conv, cmd+1, markup, &error);
	g_free(markup);
	
	//The only error status which is possible now is either 
	switch (status) {
		case PURPLE_CMD_STATUS_FAILED:
		{
			purple_conv_present_error(purple_conversation_get_name(conv), purple_conversation_get_account(conv), "Command failed");
			didCommand = YES;
			break;
		}	
		case PURPLE_CMD_STATUS_WRONG_ARGS:
		{
			purple_conv_present_error(purple_conversation_get_name(conv), purple_conversation_get_account(conv), "Wrong number of arguments");
			didCommand = YES;			
			break;
		}
		case PURPLE_CMD_STATUS_OK:
			didCommand = YES;
			break;
		case PURPLE_CMD_STATUS_NOT_FOUND:
		case PURPLE_CMD_STATUS_WRONG_TYPE:
		case PURPLE_CMD_STATUS_WRONG_PRPL:
			/* Ignore this command and let the message send; the user probably doesn't even know what they typed is a command */
			didCommand = NO;
			break;
	}

	return didCommand;
}

/*!
 * @brief Check a message for purple / commands=
 *
 * @result YES if a command was performed; NO if it was not
 */
- (BOOL)attemptPurpleCommandOnMessage:(NSString *)originalMessage fromAccount:(AIAccount *)sourceAccount inChat:(AIChat *)chat
{
	BOOL				didCommand = NO;
	
	if ([originalMessage hasPrefix:@"/"]) {	
		didCommand = [self doCommand:originalMessage
						 fromAccount:sourceAccount
							  inChat:chat];
	}

	return didCommand;
}

/*!
 * @brief Send a notification over a service which supports that
 *
 * This should not be called for an account whose service doesn't support sending notifications (check before calling).
 * Doing so will return without displaying an error; the message should be sent as a normal message in this case.
 *
 * @param type An AINotificationType.
 * @param sourceAccount The account from which to send
 * @param chat The chat in which to send the notification
 */
- (void)sendNotificationOfType:(AINotificationType)type
				   fromAccount:(id)sourceAccount
						inChat:(AIChat *)chat
{
	PurpleConversation	*conv = convLookupFromChat(chat,sourceAccount);

	purple_prpl_send_attention(purple_conversation_get_gc(conv),
							   purple_conversation_get_name(conv),
							   type);
}

//Returns YES if the message was sent (and should therefore be displayed).  Returns NO if it was not sent or was otherwise used.
- (void)sendEncodedMessage:(NSString *)encodedMessage
			   fromAccount:(id)sourceAccount
					inChat:(AIChat *)chat
				 withFlags:(PurpleMessageFlags)flags
{	
	const char *encodedMessageUTF8String;
	
	if (encodedMessage && (encodedMessageUTF8String = [encodedMessage UTF8String])) {
		PurpleConversation	*conv = convLookupFromChat(chat,sourceAccount);

		switch (purple_conversation_get_type(conv)) {				
			case PURPLE_CONV_TYPE_IM: {
				PurpleConvIm			*im = purple_conversation_get_im_data(conv);
				purple_conv_im_send_with_flags(im, encodedMessageUTF8String, flags);
				break;
			}

			case PURPLE_CONV_TYPE_CHAT: {
				PurpleConvChat	*purpleChat = purple_conversation_get_chat_data(conv);
				purple_conv_chat_send(purpleChat, encodedMessageUTF8String);
				break;
			}
			
			case PURPLE_CONV_TYPE_ANY:
				AILog(@"What in the world? Got PURPLE_CONV_TYPE_ANY.");
				break;

			case PURPLE_CONV_TYPE_MISC:
			case PURPLE_CONV_TYPE_UNKNOWN:
				break;
		}
	} else {
		AILog(@"*** Error encoding %@ to UTF8",encodedMessage);
	}
}

- (void)sendTyping:(AITypingState)typingState inChat:(AIChat *)chat
{
	PurpleConversation *conv = convLookupFromChat(chat,nil);
	if (conv) {
		//		BOOL isTyping = (([typingState intValue] == AINotTyping) ? FALSE : TRUE);

		PurpleTypingState purpleTypingState;
		
		switch (typingState) {
			case AINotTyping:
			default:
				purpleTypingState = PURPLE_NOT_TYPING;
				break;
			case AITyping:
				purpleTypingState = PURPLE_TYPING;
				break;
			case AIEnteredText:
				purpleTypingState = PURPLE_TYPED;
				break;
		}
	
		serv_send_typing(purple_conversation_get_gc(conv),
						 purple_conversation_get_name(conv),
						 purpleTypingState);
	}	
}

- (void)addUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName withAlias:(NSString *)alias
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	const char	*groupUTF8String, *buddyUTF8String, *aliasUTF8String;
	PurpleGroup	*group;
	PurpleBuddy	*buddy;
	
	//Find the group (Create if necessary)
	groupUTF8String = (groupName ? [groupName UTF8String] : "Buddies");
	if (!(group = purple_find_group(groupUTF8String))) {
		group = purple_group_new(groupUTF8String);
		purple_blist_add_group(group, NULL);
	}
	
	buddyUTF8String = [objectUID UTF8String];
	aliasUTF8String = alias.length ? [alias UTF8String] : NULL;
	
	// Find an existing buddy in the group.
	buddy = purple_find_buddy_in_group(account, buddyUTF8String, group);
	if (!buddy) {
		buddy = purple_buddy_new(account, buddyUTF8String, aliasUTF8String);
		
		/* purple_blist_add_buddy() will move an existing contact serverside, but will not add a buddy serverside.
		 * We're working with a new contact, hopefully, so we want to call serv_add_buddy() after modifying the purple list.
		 * This is the order done in add_buddy_cb() in gtkblist.c */
		purple_blist_add_buddy(buddy, NULL, group, NULL);
	}

	AILog(@"Adding buddy %s to group %s with alias %s",purple_buddy_get_name(buddy), group->name, aliasUTF8String);

	purple_account_add_buddy(account, buddy);
}

- (void)removeUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:(NSString *)groupName
{
	const char	*groupUTF8String;
	PurpleGroup	*group;
	
	// Find the right buddy; group -> buddy in group -> remove that buddy
	
	groupUTF8String = (groupName ? [groupName UTF8String] : "Buddies");
	if ((group = purple_find_group(groupUTF8String))) {
		PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
		PurpleBuddy 	*buddy;
		
		if ((buddy = purple_find_buddy_in_group(account, [objectUID UTF8String], group))) {
			/* Remove this contact from the server-side and purple-side lists. 
			 * Updating purpleside does not change the server.
			 *
			 * Purple has a commented XXX as to whether this order or the reverse (blist, then serv) is correct.
			 * We'll use the order which purple uses as of purple 1.1.4. */
			
			AILog(@"Removing buddy %s from group %s", purple_buddy_get_name(buddy), purple_group_get_name(purple_buddy_get_group(buddy)));
			
			purple_account_remove_buddy(account, buddy, group);
			purple_blist_remove_buddy(buddy);
		}
	}
}

- (void)moveUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroups:(NSSet *)oldGroups toGroups:(NSSet *)groupNames withAlias:(NSString *)alias;
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	
	for (NSString *groupName in groupNames) {
		if (!oldGroups.count) {
			// If we don't have any source groups, silently turn this into an add.
			[self addUID:objectUID onAccount:adiumAccount toGroup:groupName withAlias:alias];
			continue;
		}
		
		PurpleGroup *group;
		const char *groupUTF8String = (groupName ? [groupName UTF8String] : "Buddies");
		
		// Find the PurpleGroup, otherwise create a new one.
		if (!(group = purple_find_group(groupUTF8String))) {
			group = purple_group_new(groupUTF8String);
			purple_blist_add_group(group, NULL);
		}
		
		for (NSString *sourceGroupName in oldGroups) {
			PurpleGroup *oldGroup;
			
			if ((oldGroup = purple_find_group([sourceGroupName UTF8String]))) {
				PurpleBuddy *buddy;	
				
				if ((buddy = purple_find_buddy_in_group(account, [objectUID UTF8String], oldGroup))) {
					// Perform the add to the new group. This will turn into a move, and will update serverside.
					AILog(@"Buddy %p (%@) moving serverside to %@", buddy, objectUID, groupName);

    			if (strcmp(purple_account_get_protocol_id(account), "prpl-yahoo") == 0) {
    				/* XXX File a bug report with the need for this special-case w/ libpurple -evands 10/14/10 */

    				/* Work around a Yahoo! bug in which buddies in multiple groups can't be moved properly.
    				 *
    				 * Traverse all buddies on this account.
    				 * If the buddy is in the old group (it must be, for us to reach this point given the if
    				 * statement above) and is also in another group, we need to remove it from the old group before
    				 * this move. Otherwise, it won't work. However, if we remove it from the old group and it *isn't* in 
    				 * another group already, Yahoo will force reauthorization, which is ugly.  */
    				GSList	*buddies = purple_find_buddies(account, [objectUID UTF8String]);
    				
    				BOOL isInGroupBesidesOldGroup = NO;
    				for (GSList	*bb = buddies; bb != NULL; bb = bb->next) {
    					PurpleBuddy *aBuddy = (PurpleBuddy *)bb->data;
    					if (purple_buddy_get_group(aBuddy) != oldGroup) {
    						isInGroupBesidesOldGroup = YES;
    					}
    				}

    				if (isInGroupBesidesOldGroup) {
    					purple_account_remove_buddy(account, buddy, oldGroup);
    					AILog(@"Removed because it met the Yahoo! workaround criteria");
    				}

    			}
    			
					purple_blist_add_buddy(buddy, NULL, group, NULL);
					// Continue so we avoid the "add to group" code below.
					continue;
				}
			}
			
			// If we got this far, the move failed; turn into an add.
			[self addUID:objectUID onAccount:adiumAccount toGroup:groupName withAlias:alias];
		}
	}
}

- (void)renameGroup:(NSString *)oldGroupName onAccount:(id)adiumAccount to:(NSString *)newGroupName
{
    PurpleGroup *group = purple_find_group([oldGroupName UTF8String]);
	
	//If we don't have a group with this name, just ignore the rename request
    if (group) {
		//Rename purpleside, which will rename serverside as well
		purple_blist_rename_group(group, [newGroupName UTF8String]);
	}
}

- (void)deleteGroup:(NSString *)groupName onAccount:(id)adiumAccount
{
	PurpleGroup *group = purple_find_group([groupName UTF8String]);
	
	if (group) {
		purple_blist_remove_group(group);
	}
}

#pragma mark Alias
- (void)setAlias:(NSString *)alias forUID:(NSString *)UID onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (purple_account_is_connected(account)) {
		const char  *uidUTF8String = [UID UTF8String];
		PurpleBuddy   *buddy = purple_find_buddy(account, uidUTF8String);
		const char  *aliasUTF8String = [alias UTF8String];
		const char	*oldAlias = (buddy ? purple_buddy_get_alias(buddy) : nil);
	
		if (buddy && ((aliasUTF8String && !oldAlias) ||
					  (!aliasUTF8String && oldAlias) ||
					  ((oldAlias && aliasUTF8String && (strcmp(oldAlias,aliasUTF8String) != 0))))) {

			purple_blist_alias_buddy(buddy,aliasUTF8String);
			serv_alias_buddy(buddy);
			
			//If we had an alias before but no longer have, adiumPurpleBlistUpdate() is not going to send the update
			//(Because normally it's wasteful to send a nil alias to the account).  We need to manually invoke the update.
			if (oldAlias && !alias) {
				AIListContact *theContact = contactLookupFromBuddy(buddy);
				
				[adiumAccount updateContact:theContact
									toAlias:nil];
			}
		}
	}
}

#pragma mark Chats
- (void)openChat:(AIChat *)chat onAccount:(id)adiumAccount
{
	//Looking up the conv from the chat will create the PurpleConversation purpleside, joining the chat, opening the server
	//connection, or whatever else is done when a chat is opened.
	convLookupFromChat(chat,adiumAccount);
}

- (void)closeChat:(AIChat *)chat
{
	PurpleConversation *conv = existingConvLookupFromChat(chat);

	if (conv) {
		[chat setIdentifier:nil];

		/* We retained the chat when setting it as the ui_data; we are releasing here, so be sure to set conv->ui_data
		 * to nil so we don't try to do it again.
		 */
        AILogWithSignature(@"Destroying %p (and releasing chat %p)", conv, conv->ui_data);

		[(AIChat *)conv->ui_data release];
		conv->ui_data = nil;

		//Tell purple to destroy the conversation.
		purple_conversation_destroy(conv);
	}	
}

- (void)inviteContact:(AIListContact *)listContact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage;
{
	PurpleConversation	*conv;
	PurpleAccount			*account;
	PurpleConvChat		*purpleChat;
	AIAccount			*adiumAccount = chat.account;
	
	AILog(@"#### inviteContact:%@ toChat:%@",listContact.UID,chat.name);
	// dchoby98
	if (([adiumAccount isKindOfClass:[CBPurpleAccount class]]) &&
	   (conv = convLookupFromChat(chat, adiumAccount)) &&
	   (account = accountLookupFromAdiumAccount((CBPurpleAccount *)adiumAccount)) &&
	   (purpleChat = purple_conversation_get_chat_data(conv))) {

		//PurpleBuddy		*buddy = purple_find_buddy(account, [listObject.UID UTF8String]);
		AILog(@"#### addChatUser chat: %@ (%@) buddy: %@",chat.name, chat,listContact.UID);
		serv_chat_invite(purple_conversation_get_gc(conv),
						 purple_conv_chat_get_id(purpleChat),
						 (inviteMessage ? [inviteMessage UTF8String] : ""),
						 [listContact.UID UTF8String]);
		
	}
}

- (void)createNewGroupChat:(AIChat *)chat withListContact:(AIListContact *)contact
{
	//Create the chat
	convLookupFromChat(chat, chat.account);
	
	//Invite the contact, with no message
	[self inviteContact:contact toChat:chat withMessage:nil];
}

- (BOOL)contact:(AIListContact *)inContact isIgnoredInChat:(AIChat *)inChat
{
	PurpleConversation *conv = existingConvLookupFromChat(inChat);
	
	if (!conv)
		return NO;
	
	PurpleConvChat *convChat = purple_conversation_get_chat_data(conv);

	return (purple_conv_chat_is_user_ignored(convChat, [inContact.UID UTF8String]) ? YES : NO);
}

- (void)setContact:(AIListContact *)inContact ignored:(BOOL)inIgnored inChat:(AIChat *)inChat
{
	PurpleConversation *conv = existingConvLookupFromChat(inChat);
	
	if (!conv)
		return;
	
	PurpleConvChat *convChat = purple_conversation_get_chat_data(conv);
	
	if ([self contact:inContact isIgnoredInChat:inChat]) {
		purple_conv_chat_unignore(convChat, [inContact.UID UTF8String]);
	} else {
		purple_conv_chat_ignore(convChat, [inContact.UID UTF8String]);
	}
}

#pragma mark Account Status
/*!
 * @brief Generate a GList from a dictionary
 *
 * @param arguments An NSDictionary, whose keys and values will be used to form alternating key-value items in the GList 
 *
 * @result A GList, which the caller is responsible for freeing
 */
GList *createListFromDictionary(NSDictionary *arguments)
{
	GList *attrs = NULL;

	if ([arguments count]) {
		for (NSString *key in arguments) {
			id	valueObject;

			if ((valueObject = [arguments objectForKey:key])) {
				const char *value = NULL;

				if ([valueObject isKindOfClass:[NSNumber class]])
					value = GINT_TO_POINTER([valueObject integerValue]);
				else if ([valueObject isKindOfClass:[NSString class]])
					value = [valueObject UTF8String];
				else
					AILogWithSignature(@"Warning: unknown class %@ (%@) for key %@",
									   NSStringFromClass([valueObject class]), valueObject, key);

				//Append the key
				attrs = g_list_append(attrs, (gpointer)[key UTF8String]);

				//Now append the value
				attrs = g_list_append(attrs, (gpointer)value);

			} else {
				AILogWithSignature(@"Warning: could not determine value of %@ for key %@",
								   valueObject, key);
			}
		}
	}
	
	return attrs;
}

- (void)setStatusID:(const char *)statusID 
		   isActive:(NSNumber *)isActive
		  arguments:(NSMutableDictionary *)arguments
		  onAccount:(id)adiumAccount
{
	PurpleAccount	*account = accountLookupFromAdiumAccount(adiumAccount);
	GList			*attrs = createListFromDictionary(arguments);

	AILog(@"Setting status on %x (%s): ID %s, isActive %i, attributes %@",account, purple_account_get_username(account),
		  statusID, [isActive boolValue], arguments);

	purple_account_set_status_list(account, statusID, [isActive boolValue], attrs);
	g_list_free(attrs);

	if (purple_status_is_online(purple_account_get_active_status(account)) &&
		purple_account_is_disconnected(account))  {
		//This status is an online status, but the account is not connected or connecting

		//Ensure the account is enabled
		if (!purple_account_get_enabled(account, "Adium")) {
			purple_account_set_enabled(account, "Adium", YES);
		}

		//Now connect the account
		purple_account_connect(account);
	}	
}

- (void)setSongInformation:(NSDictionary *)arguments onAccount:(id)adiumAccount
{
	PurpleAccount	*account = accountLookupFromAdiumAccount(adiumAccount);
	GList			*attrs;
	PurpleStatus	*tune;

	tune = purple_presence_get_status(purple_account_get_presence(account), "tune");
	if (!tune)
		return;
	
	if (!arguments)
		purple_status_set_active(tune, FALSE);
	else
	{
		attrs = createListFromDictionary(arguments);
		purple_status_set_active_with_attrs_list(tune, TRUE, attrs);
		g_list_free(attrs);
	}
}	

- (void)setInfo:(NSString *)profileHTML onAccount:(id)adiumAccount
{
	PurpleAccount 	*account = accountLookupFromAdiumAccount(adiumAccount);
	const char *profileHTMLUTF8 = [profileHTML UTF8String];

	purple_account_set_user_info(account, profileHTMLUTF8);

	if (purple_account_get_connection(account) != NULL && purple_account_is_connected(account)) {
		serv_set_info(purple_account_get_connection(account), profileHTMLUTF8);
	}
}

- (void)setBuddyIcon:(NSData *)buddyImageData onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (account) {
		NSUInteger len = [buddyImageData length];
		/* purple_buddy_icons_set_account_icon() takes responsibility for the buddy icon memory */
		NSAssert( UINT_MAX >= [buddyImageData length],
						 @"Attempting to send more data than libPurple can handle.  Abort." );
		purple_buddy_icons_set_account_icon(account, g_memdup([buddyImageData bytes], (unsigned int)len), len);
	}
}

- (void)setIdleSinceTo:(NSDate *)idleSince onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (purple_account_is_connected(account)) {
		NSTimeInterval idle = (idleSince != nil ? [idleSince timeIntervalSince1970] : 0);
		PurplePresence *presence;

		presence = purple_account_get_presence(account);

		purple_presence_set_idle(presence, (idle > 0), (long)idle);
	}
}

#pragma mark Get Info
- (void)getInfoFor:(NSString *)inUID onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (purple_account_is_connected(account)) {
		serv_get_info(purple_account_get_connection(account), purple_normalize(account, [inUID UTF8String]));
	}
}

#pragma mark Xfer
- (void)xferRequest:(PurpleXfer *)xfer
{
	purple_xfer_request(xfer);
}

- (void)xferRequestAccepted:(PurpleXfer *)xfer withFileName:(NSString *)xferFileName
{
	//Only start the file transfer if it's still not marked as cancelled and therefore can be begun.
	if ((purple_xfer_get_status(xfer) != PURPLE_XFER_STATUS_CANCEL_LOCAL) &&
		(purple_xfer_get_status(xfer) != PURPLE_XFER_STATUS_CANCEL_REMOTE)) {
		//XXX should do further error checking as done by purple_xfer_choose_file_ok_cb() in purple's ft.c
		purple_xfer_request_accepted(xfer, [xferFileName UTF8String]);
	}
}

- (void)xferRequestRejected:(PurpleXfer *)xfer
{
	purple_xfer_request_denied(xfer);
}

- (void)xferCancel:(PurpleXfer *)xfer
{
	if ((purple_xfer_get_status(xfer) == PURPLE_XFER_STATUS_UNKNOWN) ||
		(purple_xfer_get_status(xfer) == PURPLE_XFER_STATUS_NOT_STARTED) ||
		(purple_xfer_get_status(xfer) == PURPLE_XFER_STATUS_STARTED) ||
		(purple_xfer_get_status(xfer) == PURPLE_XFER_STATUS_ACCEPTED)) {
		purple_xfer_cancel_local(xfer);
	}
}

#pragma mark Account settings
- (void)setCheckMail:(NSNumber *)checkMail forAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	BOOL		shouldCheckMail = [checkMail boolValue];

	purple_account_set_check_mail(account, shouldCheckMail);
}

- (void)setDefaultPermitDenyForAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);

	if (account && purple_account_get_connection(account)) {
		account->perm_deny = PURPLE_PRIVACY_DENY_USERS;
		serv_set_permit_deny(purple_account_get_connection(account));
	}	
}

#pragma mark Protocol specific accessors
- (void)OSCAREditComment:(NSString *)inComment forUID:(NSString *)inUID onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (purple_account_is_connected(account)) {
		PurpleBuddy   *buddy;
		PurpleGroup   *g;
		OscarData   *od;

		const char  *uidUTF8String = [inUID UTF8String];

		if ((buddy = purple_find_buddy(account, uidUTF8String)) &&
			(g = purple_buddy_get_group(buddy)) && 
			(od = purple_account_get_connection(account)->proto_data)) {
			aim_ssi_editcomment(od, purple_group_get_name(g), uidUTF8String, [inComment UTF8String]);	
		}
	}
}

- (void)OSCARSetFormatTo:(NSString *)inFormattedUID onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);

	if (account &&
		purple_account_is_connected(account) &&
		[inFormattedUID length]) {
		
		oscar_reformat_screenname(purple_account_get_connection(account), [inFormattedUID UTF8String]);
	}
}

#pragma mark Request callbacks

- (void)performContactMenuActionFromDict:(NSDictionary *)dict forAccount:(id)adiumAccount
{
	PurpleBuddy		*buddy = [[dict objectForKey:@"PurpleBuddy"] pointerValue];
	void (*callback)(gpointer, gpointer);
	
	//Perform act's callback with the desired buddy and data
	callback = [[dict objectForKey:@"PurpleMenuActionCallback"] pointerValue];
	if (callback)
		callback((PurpleBlistNode *)buddy, [[dict objectForKey:@"PurpleMenuActionData"] pointerValue]);
}

- (void)performAccountMenuActionFromDict:(NSDictionary *)dict forAccount:(id)adiumAccount
{
	PurplePluginAction *act;
	PurpleAccount		 *account = accountLookupFromAdiumAccount(adiumAccount);

	if (account && purple_account_get_connection(account)) {
		act = purple_plugin_action_new(NULL, [[dict objectForKey:@"PurplePluginActionCallback"] pointerValue]);
		if (act->callback) {
			act->plugin = purple_account_get_connection(account)->prpl;
			act->context = purple_account_get_connection(account);
			act->user_data = [[dict objectForKey:@"PurplePluginActionCallbackUserData"] pointerValue];
			act->callback(act);
		}
		purple_plugin_action_free(act);
	}
}

/*!
* @brief Call the purple callback to pass on an authorization response
 *
 * @param inCallBackValue The cb to use
 * @param inUserDataValue Original user data
 */
- (void)doAuthRequestCbValue:(NSValue *)inCallBackValue withUserDataValue:(NSValue *)inUserDataValue 
{	
	PurpleAccountRequestAuthorizationCb callBack = [inCallBackValue pointerValue];
	if (callBack) {
		callBack([inUserDataValue pointerValue]);
	}
}

/*!
 * @brief Tell purple we closed an authorization request without a response
 */
- (void)closeAuthRequestWithHandle:(id)authRequestHandle
{
	purple_account_request_close(authRequestHandle);
}

#pragma mark Secure messaging

- (void)purpleConversation:(PurpleConversation *)conv setSecurityDetails:(NSDictionary *)securityDetailsDict
{
}

- (void)refreshedSecurityOfPurpleConversation:(PurpleConversation *)conv
{
	AILog(@"*** Refreshed security...");
}

- (void)dealloc
{
	purple_signals_disconnect_by_handle(adium_purple_get_handle());

	[super dealloc];
}

#ifdef HAVE_CDSA
- (CFArrayRef)copyServerCertificates:(PurpleSslConnection*)gsc {
	PurplePlugin *cdsa_plugin = purple_plugins_find_with_name("CDSA");
	if(!cdsa_plugin)
		return nil;
	CFArrayRef result;
	gboolean ok = NO;
	purple_plugin_ipc_call(cdsa_plugin, "copy_certificate_chain", &ok, gsc, &result);
	
	return result;
}
#endif

@end
