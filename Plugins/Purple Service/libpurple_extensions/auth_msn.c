/*
 * purple - Jabber Protocol Plugin
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
 *
 */
#include "internal.h"

#include "account.h"
#include "debug.h"
#include "request.h"
#include "util.h"
#include "xmlnode.h"

#include "jabber.h"
#include "auth.h"

#define PACKAGE "pidgin"

static JabberSaslState
fb_start(JabberStream *js, xmlnode *packet, xmlnode **response, char **error)
{
	PurpleAccount *account;
	const char *username;
	const char *auth_key;
	
	account = purple_connection_get_account(js->gc);
	username = purple_account_get_username(account);
	auth_key = purple_account_get_password(account);
	
	purple_debug_error("auth_msn", "account name is %s", username);
	
	xmlnode *auth = xmlnode_new("auth");
	xmlnode_set_namespace(auth, "urn:ietf:params:xml:ns:xmpp-sasl");
	xmlnode_set_attrib(auth, "mechanism", "X-MESSENGER-OAUTH2");
	xmlnode_insert_data(auth, auth_key, strlen(auth_key));
	
	*response = auth;
	
	return JABBER_SASL_STATE_CONTINUE;
}

static JabberSaslMech msn_mech = {
	127, /* priority; gint8 (-128 to 127). higher will be tried sooner if offerred by the server */
	"X-MESSENGER-OAUTH2", /* name */
	fb_start,
	NULL, /* handle_challenge */
	NULL, /* handle_success */
	NULL, /* handle_failure */
	NULL  /* dispose */
};

JabberSaslMech *jabber_auth_get_msn_mech(void)
{
	return &msn_mech;
}
