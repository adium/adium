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

#include "fbapi.h"

#define PACKAGE "pidgin"

static JabberSaslState
fb_handle_challenge(JabberStream *js, xmlnode *packet,
                            xmlnode **response, char **msg)
{
	xmlnode *reply = NULL;
	gchar *challenge;
	guchar *decoded;
	gsize decoded_len;
	gchar **pairs, *method, *nonce;
	gsize i;
	GString *request;
	gchar *enc_out;

	/* Get base64-encoded challenge from XML */
	challenge = xmlnode_get_data(packet);
	if (challenge == NULL) {
		*msg = g_strdup(_("Invalid response from server"));
		return JABBER_SASL_STATE_FAIL;
	}

	/* Decode challenge */
	decoded = purple_base64_decode(challenge, &decoded_len);
	if (decoded == NULL) {
		purple_debug_error("jabber", "X-FACEBOOK-PLATFORM challenge "
						   "wasn't valid base64: %s\n", challenge);
	
		*msg = g_strdup(_("Invalid response from server"));

		g_free(challenge);
		return JABBER_SASL_STATE_FAIL;
	}
	g_free(challenge);

	/* NULL-terminate the challenge so we can parse it */
	challenge = g_strndup((const gchar *)decoded, decoded_len);
	g_free(decoded);
	purple_debug_misc("jabber", "X-FACEBOOK-PLATFORM decoded "
					  "challenge is %s\n", challenge);

	/* Get method and nonce */
	method = NULL;
	nonce = NULL;
	pairs = g_strsplit(challenge, "&", 0);
	for (i = 0; pairs[i] != NULL; i++) {
		if (g_str_has_prefix(pairs[i], "method=")) {
			g_free(method);
			// TODO: Should url decode this value
			method = g_strdup(strchr(pairs[i], '=') + 1);
		} else if (g_str_has_prefix(pairs[i], "nonce=")) {
			g_free(nonce);
			// TODO: Should url decode this value
			nonce = g_strdup(strchr(pairs[i], '=') + 1);
		}
	}
	g_strfreev(pairs);
	if (!method || !nonce) {
		purple_debug_error("jabber", "X-FACEBOOK-PLATFORM challenge "
						   "is missing method or nonce: %s\n", challenge);
		*msg = g_strdup(_("Invalid response from server"));

		g_free(method);
		g_free(nonce);
		g_free(challenge);
		return JABBER_SASL_STATE_FAIL;
	}
	g_free(challenge);

	request = purple_fbapi_construct_request(purple_connection_get_account(js->gc),
											 method,
											 "v", "1.0",
											 "access_token", purple_connection_get_password(js->gc),
											 "nonce", nonce,
											 NULL);
	g_free(method);
	g_free(nonce);

	purple_debug_misc("jabber", "X-FACEBOOK-PLATFORM response before "
					  "encoding is %s\n", request->str);
	enc_out = purple_base64_encode((const guchar *)request->str, request->len);
	g_string_free(request, TRUE);

	reply = xmlnode_new("response");
	xmlnode_set_namespace(reply, NS_XMPP_SASL);
	xmlnode_insert_data(reply, enc_out, -1);

	g_free(enc_out);

	*response = reply;

	return JABBER_SASL_STATE_CONTINUE;
}

static JabberSaslState
fb_start(JabberStream *js, xmlnode *packet, xmlnode **response, char **error)
{
	PurpleAccount *account;
	const char *username;
	gchar **parts;

	account = purple_connection_get_account(js->gc);
	username = purple_account_get_username(account);

	purple_debug_error("auth_fb", "account name is %s", username);

	parts = g_strsplit(username, "@", 0);
	if (parts[0] && strlen(parts[0]) && g_str_has_prefix(parts[0], "-")) {
		/* When connecting with X-FACEBOOK-PLATFORM, the password field must be set to the
		 * OAUTH 2.0 session key.
		 *
		 * X-FACEBOOK-PLATFORM is only valid for a facebook userID, which is prefixed with '-'
		 */
		xmlnode *auth = xmlnode_new("auth");
		xmlnode_set_namespace(auth, "urn:ietf:params:xml:ns:xmpp-sasl");
		xmlnode_set_attrib(auth, "mechanism", "X-FACEBOOK-PLATFORM");
		
		*response = auth;
		
		g_strfreev(parts);
		return JABBER_SASL_STATE_CONTINUE;		
	} else {
		g_strfreev(parts);
		return JABBER_SASL_STATE_FAIL;		
	}
}

static JabberSaslMech fb_mech = {
	127, /* priority; gint8 (-128 to 127). higher will be tried sooner if offerred by the server */
	"X-FACEBOOK-PLATFORM", /* name */
	fb_start,
	fb_handle_challenge, /* handle_challenge */
	NULL, /* handle_success */
	NULL, /* handle_failure */
	NULL  /* dispose */
};

JabberSaslMech *jabber_auth_get_fb_mech(void)
{
	return &fb_mech;
}
