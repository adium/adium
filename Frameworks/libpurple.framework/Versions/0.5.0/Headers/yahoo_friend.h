/**
 * @file yahoo_friend.h The Yahoo! protocol plugin YahooFriend object
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

#ifndef _YAHOO_FRIEND_H_
#define _YAHOO_FRIEND_H_

#include "yahoo.h"
#include "yahoo_packet.h"

typedef enum {
	YAHOO_PRESENCE_DEFAULT = 0,
	YAHOO_PRESENCE_ONLINE,
	YAHOO_PRESENCE_PERM_OFFLINE
} YahooPresenceVisibility;

/* these are called friends instead of buddies mainly so I can use variables
 * named f and not confuse them with variables named b
 */
typedef struct _YahooFriend {
	enum yahoo_status status;
	gchar *msg;
	gchar *game;
	int idle;
	int away;
	gboolean sms;
	gchar *ip;
	gboolean bicon_sent_request;
	YahooPresenceVisibility presence;
	int protocol; /* 1=LCS, 2=MSN*/
	long int version_id;
	gchar *alias_id;
} YahooFriend;

YahooFriend *yahoo_friend_find(PurpleConnection *gc, const char *name);
YahooFriend *yahoo_friend_find_or_new(PurpleConnection *gc, const char *name);

void yahoo_friend_set_ip(YahooFriend *f, const char *ip);
const char *yahoo_friend_get_ip(YahooFriend *f);

void yahoo_friend_set_game(YahooFriend *f, const char *game);
const char *yahoo_friend_get_game(YahooFriend *f);

void yahoo_friend_set_status_message(YahooFriend *f, char *msg);
const char *yahoo_friend_get_status_message(YahooFriend *f);

void yahoo_friend_set_alias_id(YahooFriend *f, const char *alias_id);
const char *yahoo_friend_get_alias_id(YahooFriend *f);

void yahoo_friend_set_buddy_icon_need_request(YahooFriend *f, gboolean needs);
gboolean yahoo_friend_get_buddy_icon_need_request(YahooFriend *f);

void yahoo_friend_free(gpointer p);

void yahoo_process_presence(PurpleConnection *gc, struct yahoo_packet *pkt);
void yahoo_friend_update_presence(PurpleConnection *gc, const char *name,
		YahooPresenceVisibility presence);

#endif /* _YAHOO_FRIEND_H_ */
