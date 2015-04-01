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
gtalk_start(JabberStream *js, xmlnode *packet, xmlnode **response, char **error)
{
	xmlnode *auth = xmlnode_new("auth");
	xmlnode_set_namespace(auth, "urn:ietf:params:xml:ns:xmpp-sasl");
	xmlnode_set_attrib(auth, "mechanism", "X-OAUTH2");
	xmlnode_set_attrib(auth, "auth:service", "oauth2");
	xmlnode_set_attrib(auth, "xmlns:auth", "http://www.google.com/talk/protocol/auth");
	
	*response = auth;
	
	return JABBER_SASL_STATE_CONTINUE;
}

static JabberSaslMech gtalk_mech = {
	127, /* priority; gint8 (-128 to 127). higher will be tried sooner if offerred by the server */
	"X-OAUTH2", /* name */
	gtalk_start,
	NULL, /* handle_challenge */
	NULL, /* handle_success */
	NULL, /* handle_failure */
	NULL  /* dispose */
};

JabberSaslMech *jabber_auth_get_gtalk_mech(void)
{
	return &gtalk_mech;
}
