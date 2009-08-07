/**
 * @file presence.h Presence
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
#ifndef PURPLE_JABBER_PRESENCE_H_
#define PURPLE_JABBER_PRESENCE_H_

#include "buddy.h"
#include "jabber.h"
#include "xmlnode.h"

void jabber_set_status(PurpleAccount *account, PurpleStatus *status);

/**
 *	Send a full presence stanza.
 *
 *	@param js       A JabberStream object.
 *	@param force    Force sending the presence stanza, irrespective of whether
 *	                the contents seem to have changed.
 */
void jabber_presence_send(JabberStream *js, gboolean force);

xmlnode *jabber_presence_create(JabberBuddyState state, const char *msg, int priority); /* DEPRECATED */
xmlnode *jabber_presence_create_js(JabberStream *js, JabberBuddyState state, const char *msg, int priority);
void jabber_presence_parse(JabberStream *js, xmlnode *packet);
void jabber_presence_subscription_set(JabberStream *js, const char *who,
		const char *type);
void jabber_presence_fake_to_self(JabberStream *js, PurpleStatus *status);
void purple_status_to_jabber(const PurpleStatus *status, JabberBuddyState *state, char **msg, int *priority);

#endif /* PURPLE_JABBER_PRESENCE_H_ */
