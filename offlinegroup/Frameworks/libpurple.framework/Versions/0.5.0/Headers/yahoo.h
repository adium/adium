/**
 * @file yahoo.h The Yahoo! protocol plugin
 *
 * purple
 *
 * Purple is the legal property of its developers, whose names are too numerous
 * to list here.  Please refer to the COPYRIGHT file distributed with this
 * source distribution.
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

#ifndef _YAHOO_H_
#define _YAHOO_H_

#include "circbuffer.h"
#include "prpl.h"

#define YAHOO_PAGER_HOST "scs.msg.yahoo.com"
#define YAHOO_PAGER_PORT 5050
#define YAHOO_PROFILE_URL "http://profiles.yahoo.com/"
#define YAHOO_MAIL_URL "https://login.yahoo.com/config/login?.src=ym"
#define YAHOO_XFER_HOST "filetransfer.msg.yahoo.com"
#define YAHOO_XFER_PORT 80
#define YAHOO_XFER_RELAY_HOST "relay.msg.yahoo.com"
#define YAHOO_XFER_RELAY_PORT 80
#define YAHOO_ROOMLIST_URL "http://insider.msg.yahoo.com/ycontent/"
#define YAHOO_ROOMLIST_LOCALE "us"
/* really we should get the list of servers from
 http://update.messenger.yahoo.co.jp/servers.html */
#define YAHOOJP_PAGER_HOST "cs.yahoo.co.jp"
#define YAHOOJP_PROFILE_URL "http://profiles.yahoo.co.jp/"
#define YAHOOJP_MAIL_URL "http://mail.yahoo.co.jp/"
#define YAHOOJP_XFER_HOST "filetransfer.msg.yahoo.co.jp"
#define YAHOOJP_WEBCAM_HOST "wc.yahoo.co.jp"
/*not sure, must test:*/
#define YAHOOJP_XFER_RELAY_HOST "relay.msg.yahoo.co.jp" 
#define YAHOOJP_XFER_RELAY_PORT 80
#define YAHOOJP_ROOMLIST_URL "http://insider.msg.yahoo.co.jp/ycontent/"
#define YAHOOJP_ROOMLIST_LOCALE "ja"

#define YAHOO_AUDIBLE_URL "http://us.dl1.yimg.com/download.yahoo.com/dl/aud"

#define WEBMESSENGER_URL "http://login.yahoo.com/config/login?.src=pg"

#define YAHOO_PICURL_SETTING "picture_url"
#define YAHOO_PICCKSUM_SETTING "picture_checksum"
#define YAHOO_PICEXPIRE_SETTING "picture_expire"

#define YAHOO_STATUS_TYPE_OFFLINE "offline"
#define YAHOO_STATUS_TYPE_AVAILABLE "available"
#define YAHOO_STATUS_TYPE_BRB "brb"
#define YAHOO_STATUS_TYPE_BUSY "busy"
#define YAHOO_STATUS_TYPE_NOTATHOME "notathome"
#define YAHOO_STATUS_TYPE_NOTATDESK "notatdesk"
#define YAHOO_STATUS_TYPE_NOTINOFFICE "notinoffice"
#define YAHOO_STATUS_TYPE_ONPHONE "onphone"
#define YAHOO_STATUS_TYPE_ONVACATION "onvacation"
#define YAHOO_STATUS_TYPE_OUTTOLUNCH "outtolunch"
#define YAHOO_STATUS_TYPE_STEPPEDOUT "steppedout"
#define YAHOO_STATUS_TYPE_AWAY "away"
#define YAHOO_STATUS_TYPE_INVISIBLE "invisible"
#define YAHOO_STATUS_TYPE_MOBILE "mobile"

#define YAHOO_CLIENT_VERSION_ID "2097087"
#define YAHOO_CLIENT_VERSION "8.1.0.421"

#define YAHOOJP_CLIENT_VERSION_ID "524223"
#define YAHOOJP_CLIENT_VERSION "7,0,1,1"


/* Index into attention types list. */
#define YAHOO_BUZZ 0

enum yahoo_status {
	YAHOO_STATUS_AVAILABLE = 0,
	YAHOO_STATUS_BRB,
	YAHOO_STATUS_BUSY,
	YAHOO_STATUS_NOTATHOME,
	YAHOO_STATUS_NOTATDESK,
	YAHOO_STATUS_NOTINOFFICE,
	YAHOO_STATUS_ONPHONE,
	YAHOO_STATUS_ONVACATION,
	YAHOO_STATUS_OUTTOLUNCH,
	YAHOO_STATUS_STEPPEDOUT,
	YAHOO_STATUS_INVISIBLE = 12,
	YAHOO_STATUS_CUSTOM = 99,
	YAHOO_STATUS_IDLE = 999,
	YAHOO_STATUS_WEBLOGIN = 0x5a55aa55,
	YAHOO_STATUS_OFFLINE = 0x5a55aa56, /* don't ask */
	YAHOO_STATUS_TYPING = 0x16,
	YAHOO_STATUS_DISCONNECTED = 0xffffffff /* in ymsg 15. doesnt mean the normal sense of 'disconnected' */
};

struct yahoo_buddy_icon_upload_data {
	PurpleConnection *gc;
	GString *str;
	char *filename;
	int pos;
	int fd;
	guint watcher;
};

struct _YchtConn;

struct yahoo_data {
	PurpleConnection *gc;
	int fd;
	guchar *rxqueue;
	int rxlen;
	PurpleCircBuffer *txbuf;
	guint txhandler;
	GHashTable *friends;

	/**
	 * This is used to keep track of the IMVironment chosen
	 * by people you talk to.  We don't do very much with
	 * this right now... but at least now if the remote user
	 * selects an IMVironment we won't reset it back to the
	 * default of nothing.
	 */
	GHashTable *imvironments;

	int current_status;
	gboolean logged_in;
	GString *tmp_serv_blist, *tmp_serv_ilist, *tmp_serv_plist;
	GSList *confs;
	unsigned int conf_id; /* just a counter */
	gboolean chat_online;
	gboolean in_chat;
	char *chat_name;
	char *pending_chat_room;
	char *pending_chat_id;
	char *pending_chat_topic;
	char *pending_chat_goto;
	char *auth;
	gsize auth_written;
	char *cookie_y;
	char *cookie_t;
	int session_id;
	gboolean jp;
	gboolean wm; /* connected w/ web messenger method */
	/* picture aka buddy icon stuff */
	char *picture_url;
	int picture_checksum;

	/* ew. we have to check the icon before we connect,
	 * but can't upload it til we're connected. */
	struct yahoo_buddy_icon_upload_data *picture_upload_todo;
	PurpleProxyConnectData *buddy_icon_connect_data;

	struct _YchtConn *ycht;

	/**
	 * This linked list contains PurpleUtilFetchUrlData structs
	 * for when we lookup people profile or photo information.
	 */
	GSList *url_datas;
	GHashTable *xfer_peer_idstring_map;/*Hey, i dont know, but putting this HashTable next to friends gives a run time fault...*/
	GSList *cookies;/*contains all cookies, including _y and _t*/
	
	/**
	 * We may receive a list15 in multiple packets with no prior warning as to how many we'll be getting;
	 * the server expects us to keep track of the group for which it is sending us contact names.
	 */
	char *current_list15_grp;
};

#define YAHOO_MAX_STATUS_MESSAGE_LENGTH (255)

/* sometimes i wish prpls could #include things from other prpls. then i could just
 * use the routines from libfaim and not have to admit to knowing how they work. */
#define yahoo_put16(buf, data) ( \
		(*(buf) = (unsigned char)((data)>>8)&0xff), \
		(*((buf)+1) = (unsigned char)(data)&0xff),  \
		2)
#define yahoo_get16(buf) ((((*(buf))<<8)&0xff00) + ((*((buf)+1)) & 0xff))
#define yahoo_put32(buf, data) ( \
		(*((buf)) = (unsigned char)((data)>>24)&0xff), \
		(*((buf)+1) = (unsigned char)((data)>>16)&0xff), \
		(*((buf)+2) = (unsigned char)((data)>>8)&0xff), \
		(*((buf)+3) = (unsigned char)(data)&0xff), \
		4)
#define yahoo_get32(buf) ((((*(buf))<<24)&0xff000000) + \
		(((*((buf)+1))<<16)&0x00ff0000) + \
		(((*((buf)+2))<< 8)&0x0000ff00) + \
		(((*((buf)+3)    )&0x000000ff)))

/* util.c */
void yahoo_init_colorht(void);
void yahoo_dest_colorht(void);
char *yahoo_codes_to_html(const char *x);
char *yahoo_html_to_codes(const char *src);

/**
 * Encode some text to send to the yahoo server.
 *
 * @param gc The connection handle.
 * @param str The null terminated utf8 string to encode.
 * @param utf8 If not @c NULL, whether utf8 is okay or not.
 *             Even if it is okay, we may not use it. If we
 *             used it, we set this to @c TRUE, else to
 *             @c FALSE. If @c NULL, false is assumed, and
 *             it is not dereferenced.
 * @return The g_malloced string in the appropriate encoding.
 */
char *yahoo_string_encode(PurpleConnection *gc, const char *str, gboolean *utf8);

/**
 * Decode some text received from the server.
 *
 * @param gc The gc handle.
 * @param str The null terminated string to decode.
 * @param utf8 Did the server tell us it was supposed to be utf8?
 * @return The decoded, utf-8 string, which must be g_free()'d.
 */
char *yahoo_string_decode(PurpleConnection *gc, const char *str, gboolean utf8);

char *yahoo_convert_to_numeric(const char *str);

/* previously-static functions, now needed for yahoo_profile.c */
void yahoo_tooltip_text(PurpleBuddy *b, PurpleNotifyUserInfo *user_info, gboolean full);

/* yahoo_profile.c */
void yahoo_get_info(PurpleConnection *gc, const char *name);

/* needed for xfer, thought theyd be useful for other enhancements later on
   Returns list of cookies stored in yahoo_data formatted as a single null terminated string
   returned value must be g_freed
*/
gchar* yahoo_get_cookies(PurpleConnection *gc);

gboolean yahoo_send_attention(PurpleConnection *gc, const char *username, guint type);
GList *yahoo_attention_types(PurpleAccount *account);

#endif /* _YAHOO_H_ */
