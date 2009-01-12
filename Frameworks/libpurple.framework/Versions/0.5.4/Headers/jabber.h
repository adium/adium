/**
 * @file jabber.h
 *
 * purple
 *
 * Copyright (C) 2003 Nathan Walp <faceprint@faceprint.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111-1301  USA
 */
#ifndef _PURPLE_JABBER_H_
#define _PURPLE_JABBER_H_

typedef enum {
	JABBER_CAP_NONE           = 0,
	JABBER_CAP_XHTML          = 1 << 0,
	JABBER_CAP_COMPOSING      = 1 << 1,
	JABBER_CAP_SI             = 1 << 2,
	JABBER_CAP_SI_FILE_XFER   = 1 << 3,
	JABBER_CAP_BYTESTREAMS    = 1 << 4,
	JABBER_CAP_IBB            = 1 << 5,
	JABBER_CAP_CHAT_STATES    = 1 << 6,
	JABBER_CAP_IQ_SEARCH      = 1 << 7,
	JABBER_CAP_IQ_REGISTER    = 1 << 8,

	/* Google Talk extensions:
	 * http://code.google.com/apis/talk/jep_extensions/extensions.html
	 */
	JABBER_CAP_GMAIL_NOTIFY   = 1 << 9,
	JABBER_CAP_GOOGLE_ROSTER  = 1 << 10,

	JABBER_CAP_PING			  = 1 << 11,
	JABBER_CAP_ADHOC		  = 1 << 12,
	JABBER_CAP_BLOCKING       = 1 << 13,

	JABBER_CAP_RETRIEVED      = 1 << 31
} JabberCapabilities;

typedef struct _JabberStream JabberStream;

#include <libxml/parser.h>
#include <glib.h>
#include "circbuffer.h"
#include "connection.h"
#include "dnssrv.h"
#include "roomlist.h"
#include "sslconn.h"

#include "jutil.h"
#include "xmlnode.h"
#include "buddy.h"

#ifdef HAVE_CYRUS_SASL
#include <sasl/sasl.h>
#endif

#define CAPS0115_NODE "http://pidgin.im/caps"

/* Index into attention_types list */
#define JABBER_BUZZ 0

typedef enum {
	JABBER_STREAM_OFFLINE,
	JABBER_STREAM_CONNECTING,
	JABBER_STREAM_INITIALIZING,
	JABBER_STREAM_INITIALIZING_ENCRYPTION,
	JABBER_STREAM_AUTHENTICATING,
	JABBER_STREAM_REINITIALIZING,
	JABBER_STREAM_CONNECTED
} JabberStreamState;

struct _JabberStream
{
	int fd;

	PurpleSrvQueryData *srv_query_data;

	xmlParserCtxt *context;
	xmlnode *current;

	enum {
		JABBER_PROTO_0_9,
		JABBER_PROTO_1_0
	} protocol_version;
	enum {
		JABBER_AUTH_UNKNOWN,
		JABBER_AUTH_DIGEST_MD5,
		JABBER_AUTH_PLAIN,
		JABBER_AUTH_IQ_AUTH,
		JABBER_AUTH_CYRUS
	} auth_type;
	char *stream_id;
	JabberStreamState state;

	/* SASL authentication */
	char *expected_rspauth;

	GHashTable *buddies;
	gboolean roster_parsed;

	/*
	 * This boolean was added to eliminate a heinous bug where we would
	 * get into a loop with the server and move a buddy back and forth
	 * from one group to another.
	 *
	 * The sequence goes something like this:
	 * 1. Our resource and another resource both approve an authorization
	 *    request at the exact same time.  We put the buddy in group A and
	 *    the other resource put the buddy in group B.
	 * 2. The server receives the roster add for group B and sends us a
	 *    roster push.
	 * 3. We receive this roster push and modify our local blist.  This
	 *    triggers us to send a roster add for group B.
	 * 4. The server recieves our earlier roster add for group A and sends
	 *    us a roster push.
	 * 5. We receive this roster push and modify our local blist.  This
	 *    triggers us to send a roster add for group A.
	 * 6. The server receives our earlier roster add for group B and sends
	 *    us a roster push.
	 * (repeat steps 3 through 6 ad infinitum)
	 *
	 * This boolean is used to short-circuit the sending of a roster add
	 * when we receive a roster push.
	 *
	 * See these bug reports:
	 * http://trac.adiumx.com/ticket/8834
	 * http://developer.pidgin.im/ticket/5484
	 * http://developer.pidgin.im/ticket/6188
	 */
	gboolean currently_parsing_roster_push;

	GHashTable *chats;
	GList *chat_servers;
	PurpleRoomlist *roomlist;
	GList *user_directories;

	GHashTable *iq_callbacks;
	GHashTable *disco_callbacks;
	int next_id;

	GList *bs_proxies;
	GList *oob_file_transfers;
	GList *file_transfers;

	time_t idle;

	JabberID *user;
	PurpleConnection *gc;
	PurpleSslConnection *gsc;

	gboolean registration;

	char *avatar_hash;
	GSList *pending_avatar_requests;

	GSList *pending_buddy_info_requests;

	PurpleCircBuffer *write_buffer;
	guint writeh;

	gboolean reinit;

	JabberCapabilities server_caps;
	gboolean googletalk;
	char *server_name;

	char *gmail_last_time;
	char *gmail_last_tid;

	char *serverFQDN;

	/* OK, this stays at the end of the struct, so plugins can depend
	 * on the rest of the stuff being in the right place
	 */
#ifdef HAVE_CYRUS_SASL
	sasl_conn_t *sasl;
	sasl_callback_t *sasl_cb;
#else /* keep the struct the same size */
	void *sasl;
	void *sasl_cb;
#endif
	/* did someone say something about the end of the struct? */
#ifdef HAVE_CYRUS_SASL
	const char *current_mech;
	int auth_fail_count;
#endif

	int sasl_state;
	int sasl_maxbuf;
	GString *sasl_mechs;

	gboolean unregistration;
	PurpleAccountUnregistrationCb unregistration_cb;
	void *unregistration_user_data;
	
	gboolean vcard_fetched;

	/* does the local server support PEP? */
	gboolean pep;

	/* Is Buzz enabled? */
	gboolean allowBuzz;
	
	/* A list of JabberAdHocCommands supported by the server */
	GList *commands;
	
	/* last presence update to check for differences */
	JabberBuddyState old_state;
	char *old_msg;
	int old_priority;
	char *old_avatarhash;
	
	/* same for user tune */
	char *old_artist;
	char *old_title;
	char *old_source;
	char *old_uri;
	int old_length;
	char *old_track;
	
	char *certificate_CN;
	
	/* A purple timeout tag for the keepalive */
	int keepalive_timeout;

	PurpleSrvResponse *srv_rec;
	guint srv_rec_idx;
	guint max_srv_rec_idx;
	/**
	 * This linked list contains PurpleUtilFetchUrlData structs
	 * for when we lookup buddy icons from a url
	 */
	GSList *url_datas;
};

typedef gboolean (JabberFeatureEnabled)(JabberStream *js, const gchar *shortname, const gchar *namespace);

typedef struct _JabberFeature
{
	gchar *shortname;
	gchar *namespace;
	JabberFeatureEnabled *is_enabled;
} JabberFeature;

typedef struct _JabberBytestreamsStreamhost {
	char *jid;
	char *host;
	int port;
	char *zeroconf;
} JabberBytestreamsStreamhost;

/* what kind of additional features as returned from disco#info are supported? */
extern GList *jabber_features;

void jabber_process_packet(JabberStream *js, xmlnode **packet);
void jabber_send(JabberStream *js, xmlnode *data);
void jabber_send_raw(JabberStream *js, const char *data, int len);

void jabber_stream_set_state(JabberStream *js, JabberStreamState state);

void jabber_register_parse(JabberStream *js, xmlnode *packet);
void jabber_register_start(JabberStream *js);

char *jabber_get_next_id(JabberStream *js);

/** Parse an error into a human-readable string and optionally a disconnect
 *  reason.
 *  @param js     the stream on which the error occurred.
 *  @param packet the error packet
 *  @param reason where to store the disconnection reason, or @c NULL if you
 *                don't care or you don't intend to close the connection.
 */
char *jabber_parse_error(JabberStream *js, xmlnode *packet, PurpleConnectionError *reason);

void jabber_add_feature(const gchar *shortname, const gchar *namespace, JabberFeatureEnabled cb); /* cb may be NULL */
void jabber_remove_feature(const gchar *shortname);

/** PRPL functions */
const char *jabber_list_icon(PurpleAccount *a, PurpleBuddy *b);
const char* jabber_list_emblem(PurpleBuddy *b);
char *jabber_status_text(PurpleBuddy *b);
void jabber_tooltip_text(PurpleBuddy *b, PurpleNotifyUserInfo *user_info, gboolean full);
GList *jabber_status_types(PurpleAccount *account);
void jabber_login(PurpleAccount *account);
void jabber_close(PurpleConnection *gc);
void jabber_idle_set(PurpleConnection *gc, int idle);
void jabber_request_block_list(JabberStream *js);
void jabber_add_deny(PurpleConnection *gc, const char *who);
void jabber_rem_deny(PurpleConnection *gc, const char *who);
void jabber_keepalive(PurpleConnection *gc);
void jabber_register_gateway(JabberStream *js, const char *gateway);
void jabber_register_account(PurpleAccount *account);
void jabber_unregister_account(PurpleAccount *account, PurpleAccountUnregistrationCb cb, void *user_data);
gboolean jabber_send_attention(PurpleConnection *gc, const char *username, guint code);
GList *jabber_attention_types(PurpleAccount *account);
void jabber_convo_closed(PurpleConnection *gc, const char *who);
PurpleChat *jabber_find_blist_chat(PurpleAccount *account, const char *name);
gboolean jabber_offline_message(const PurpleBuddy *buddy);
int jabber_prpl_send_raw(PurpleConnection *gc, const char *buf, int len);
GList *jabber_actions(PurplePlugin *plugin, gpointer context);
void jabber_register_commands(void);
void jabber_init_plugin(PurplePlugin *plugin);

#endif /* _PURPLE_JABBER_H_ */
