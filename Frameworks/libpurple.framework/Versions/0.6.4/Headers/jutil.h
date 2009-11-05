/**
 * @file jutil.h utility functions
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
#ifndef PURPLE_JABBER_JUTIL_H_
#define PURPLE_JABBER_JUTIL_H_

typedef struct _JabberID {
	char *node;
	char *domain;
	char *resource;
} JabberID;

#include "jabber.h"

JabberID* jabber_id_new(const char *str);
void jabber_id_free(JabberID *jid);

char *jabber_get_resource(const char *jid);
char *jabber_get_bare_jid(const char *jid);
char *jabber_id_get_bare_jid(const JabberID *jid);

const char *jabber_normalize(const PurpleAccount *account, const char *in);

/* Returns true if JID is the bare JID of our server. */
gboolean jabber_is_own_server(JabberStream *js, const char *jid);

/* Returns true if JID is the bare JID of our account. */
gboolean jabber_is_own_account(JabberStream *js, const char *jid);

gboolean jabber_nodeprep_validate(const char *);
gboolean jabber_domain_validate(const char *);
gboolean jabber_resourceprep_validate(const char *);

PurpleConversation *jabber_find_unnormalized_conv(const char *name, PurpleAccount *account);

char *jabber_calculate_data_sha1sum(gconstpointer data, size_t len);
#endif /* PURPLE_JABBER_JUTIL_H_ */
