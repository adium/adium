/*
 * purple - Jabber Protocol Plugin
 *
 * Copyright (C) 2007, Andreas Monitzer <andy@monitzer.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA	 02111-1307	 USA
 *
 */

#ifndef _PURPLE_JABBER_CAPS_H_
#define _PURPLE_JABBER_CAPS_H_

typedef struct _JabberCapsClientInfo JabberCapsClientInfo;

#include "jabber.h"

/* Implementation of XEP-0115 */

typedef struct _JabberCapsIdentity {
	char *category;
	char *type;
	char *name;
} JabberCapsIdentity;

struct _JabberCapsClientInfo {
	GList *identities; /* JabberCapsIdentity */
	GList *features; /* char * */
};

typedef void (*jabber_caps_get_info_cb)(JabberCapsClientInfo *info, gpointer user_data);

void jabber_caps_init(void);

void jabber_caps_get_info(JabberStream *js, const char *who, const char *node, const char *ver, const char *ext, jabber_caps_get_info_cb cb, gpointer user_data);
void jabber_caps_free_clientinfo(JabberCapsClientInfo *clientinfo);

#endif /* _PURPLE_JABBER_CAPS_H_ */
