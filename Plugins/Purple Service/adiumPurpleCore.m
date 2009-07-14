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

#import "adiumPurpleCore.h"

#import "adiumPurpleAccounts.h"
#import "adiumPurpleBlist.h"
#import "adiumPurpleConnection.h"
#import "adiumPurpleConversation.h"
#import "adiumPurpleDnsRequest.h"
#import "adiumPurpleEventloop.h"
#import "adiumPurpleFt.h"
#import "adiumPurpleNotify.h"
#import "adiumPurplePrivacy.h"
#import "adiumPurpleRequest.h"
#import "adiumPurpleRoomlist.h"
#import "adiumPurpleSignals.h"
#import "adiumPurpleWebcam.h"
#import "adiumPurpleCertificateTrustWarning.h"

#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import "AILibpurplePlugin.h"
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <Adium/AIAccountControllerProtocol.h>

#pragma mark Debug
// Debug ------------------------------------------------------------------------------------------------------
#if (PURPLE_DEBUG)
static void adiumPurpleDebugPrint(PurpleDebugLevel level, const char *category, const char *debug_msg)
{
	//Log error
	if (!category) category = "general"; //Category can be nil
	AILog(@"(Libpurple: %s) %s",category, debug_msg);
}

static PurpleDebugUiOps adiumPurpleDebugOps = {
    adiumPurpleDebugPrint
};

PurpleDebugUiOps *adium_purple_debug_get_ui_ops(void)
{
	return &adiumPurpleDebugOps;
}
#endif

// Core ------------------------------------------------------------------------------------------------------

extern gboolean purple_init_ssl_plugin(void);
extern gboolean purple_init_ssl_openssl_plugin(void);
extern gboolean purple_init_ssl_cdsa_plugin(void);

static void init_all_plugins()
{
	AILog(@"adiumPurpleCore: load_all_plugins()");

	//First, initialize our built-in plugins
	purple_init_ssl_plugin();
#ifdef HAVE_CDSA
	purple_init_ssl_cdsa_plugin();
#else
	#ifdef HAVE_OPENSSL
		purple_init_ssl_openssl_plugin();
	#else
		#warning No SSL plugin!
	#endif
#endif

	//Load each plugin
	for (id <AILibpurplePlugin>	plugin in [SLPurpleCocoaAdapter libpurplePluginArray]) {
		if ([plugin respondsToSelector:@selector(installLibpurplePlugin)]) {
			[plugin installLibpurplePlugin];
		}
	}
#ifdef HAVE_CDSA
	{
		PurplePlugin *cdsa_plugin = purple_plugins_find_with_name("CDSA");
		if(cdsa_plugin) {
			gboolean ok = NO;
			purple_plugin_ipc_call(cdsa_plugin, "register_certificate_ui_cb", &ok, adium_query_cert_chain);
		}
	}
#endif
}

static void load_external_plugins(void)
{
	//Load each plugin	
	for (id <AILibpurplePlugin>	plugin in [SLPurpleCocoaAdapter libpurplePluginArray]) {
		if ([plugin respondsToSelector:@selector(loadLibpurplePlugin)]) {
			[plugin loadLibpurplePlugin];
		}
	}	
}

static void adiumPurplePrefsInit(void)
{
    //Disable purple away handling - we do it ourselves
	purple_prefs_set_bool("/purple/away/away_when_idle", FALSE);
	purple_prefs_set_string("/purple/away/auto_reply","never");

	//Disable purple idle reporting - we do it ourselves
	purple_prefs_set_bool("/purple/away/report_idle", FALSE);

    //Disable purple conversation logging
    purple_prefs_set_bool("/purple/logging/log_chats", FALSE);
    purple_prefs_set_bool("/purple/logging/log_ims", FALSE);

    //Typing preference
    purple_prefs_set_bool("/purple/conversations/im/send_typing", TRUE);
	
	//Use server alias where possible
	purple_prefs_set_bool("/purple/buddies/use_server_alias", TRUE);

	//Ensure we are using caching
	purple_buddy_icons_set_caching(TRUE);	
}

static void adiumPurpleCoreDebugInit(void)
{
#if (PURPLE_DEBUG)
	AILog(@"adiumPurpleCoreDebugInit()");
    purple_debug_set_ui_ops(adium_purple_debug_get_ui_ops());
#endif	
}

static void associateLibpurpleAccounts(void)
{
	for (CBPurpleAccount *adiumAccount in adium.accountController.accounts) {
		if ([adiumAccount isKindOfClass:[CBPurpleAccount class]]) {
			PurpleAccount *account = purple_accounts_find(adiumAccount.purpleAccountName, adiumAccount.protocolPlugin);
			if (account) {
				[(CBPurpleAccount *)account->ui_data autorelease];
				account->ui_data = [adiumAccount retain];

				[adiumAccount setPurpleAccount:account];				
			}
		}
	}
}

/* The core is ready... finish configuring libpurple and its plugins */
static void adiumPurpleCoreUiInit(void)
{		
	bindtextdomain("pidgin", [[[NSBundle bundleWithIdentifier:@"im.pidgin.libpurple"] resourcePath] fileSystemRepresentation]);
	bind_textdomain_codeset("pidgin", "UTF-8");
	textdomain("pidgin");
	
	const char *preferredLocale = [[[[NSBundle bundleForClass:[SLPurpleCocoaAdapter class]] preferredLocalizations] objectAtIndex:0] UTF8String];
	//We should be able to just do setlocale()... but it always returns NULL, which indicates failure
	/* setlocale(LC_MESSAGES, preferredLocale); */

	//So we'll set the environment variable for this process, which does work
	setenv("LC_ALL", preferredLocale, /* overwrite? */ 1);
	setenv("LC_MESSAGES", preferredLocale, /* overwrite? */ 1);

	//Initialize all external plugins.
	init_all_plugins();

	AILog(@"adiumPurpleCoreUiInit");
	//Initialize the core UI ops
    purple_blist_set_ui_ops(adium_purple_blist_get_ui_ops());
    purple_connections_set_ui_ops(adium_purple_connection_get_ui_ops());
    purple_privacy_set_ui_ops (adium_purple_privacy_get_ui_ops());	
	purple_accounts_set_ui_ops(adium_purple_accounts_get_ui_ops());

	//Configure signals for receiving purple events
	configureAdiumPurpleSignals();
	
	//Associate each libpurple account with the appropriate Adium AIAccount.
	associateLibpurpleAccounts();

	/* Why use Purple's accounts and blist list when we have the information locally?
		*		- Faster account connection: Purple doesn't have to recreate the local list
		*		- Privacy/blocking support depends on the accounts and blist files existing
		*
		*	Another possible advantage:
		*		- Using Purple's own buddy icon caching (which depends on both files) allows us to avoid
		*			re-requesting icons we already have locally on some protocols such as AIM.
		*/	
	//Setup the buddy list; then load the blist.
	purple_set_blist(purple_blist_new());
	AILog(@"adiumPurpleCore: purple_blist_load()...");
	purple_blist_load();

	//Configure the GUI-related UI ops last
	purple_roomlist_set_ui_ops (adium_purple_roomlist_get_ui_ops());
    purple_notify_set_ui_ops(adium_purple_notify_get_ui_ops());
    purple_request_set_ui_ops(adium_purple_request_get_ui_ops());
	purple_xfers_set_ui_ops(adium_purple_xfers_get_ui_ops());
	purple_dnsquery_set_ui_ops(adium_purple_dns_request_get_ui_ops());
	
	adiumPurpleConversation_init();

#if	ENABLE_WEBCAM
	initPurpleWebcamSupport();
#endif
	
	load_external_plugins();
}

static void adiumPurpleCoreQuit(void)
{
    AILog(@"Core quit");
    exit(0);
}

static GHashTable *adiumPurpleCoreGetUiInfo(void)
{
	static GHashTable *ui_info = NULL;
	if (!ui_info) {
		ui_info = g_hash_table_new(g_str_hash, g_str_equal);
		g_hash_table_insert(ui_info, "name", "Adium");
		
		/* I have a vague recollection of a crash if we didn't g_strdup() this, but it really shouldn't be necessary.
		 * The ui_info stays in memory forever, anyways, so it hardly matters. -evands
		 */
		g_hash_table_insert(ui_info, "version", g_strdup([[NSApp applicationVersion] UTF8String])); 
		g_hash_table_insert(ui_info, "website", "http://adium.im");
		g_hash_table_insert(ui_info, "dev_website", "http://trac.adium.im");
		g_hash_table_insert(ui_info, "client_type", "mac");
		
		/* AOL wants us to use the distid 1551 (0x060f) */
		g_hash_table_insert(ui_info, "prpl-aim-distid", GINT_TO_POINTER(1551));
		g_hash_table_insert(ui_info, "prpl-icq-distid", GINT_TO_POINTER(1551));
	}

	return ui_info;
}

static PurpleCoreUiOps adiumPurpleCoreOps = {
    adiumPurplePrefsInit,
    adiumPurpleCoreDebugInit,
    adiumPurpleCoreUiInit,
    adiumPurpleCoreQuit,
	adiumPurpleCoreGetUiInfo
};

PurpleCoreUiOps *adium_purple_core_get_ops(void)
{
	return &adiumPurpleCoreOps;
}
