/*
 * This is the property of its developers.  See the COPYRIGHT file
 * for more details.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#include <sys/time.h>

#include "internal.h"
#include "cipher.h"
#include "debug.h"
#include "util.h"

#include "fbapi.h"

#define PACKAGE "pidgin"

#define API_URL "http://api.facebook.com/restserver.php"
#define API_SECRET "INSERT_SECRET_HERE"
#define MAX_CONNECTION_ATTEMPTS 3

struct _PurpleFbApiCall {
	gchar *request;
	PurpleUtilFetchUrlData *url_data;
	PurpleFbApiCallback callback;
	gpointer user_data;
	GDestroyNotify user_data_destroy_func;
	unsigned int attempt_number;
};

static GSList *apicalls = NULL;

/*
 * Try to strip characters that are not valid XML.  The string is
 * changed in-place.  This was needed because of this bug:
 * http://bugs.developers.facebook.com/show_bug.cgi?id=2840
 * That bug has been fixed, so it's possible this isn't necessary
 * anymore.
 *
 * This page lists which characters are valid:
 * http://www.w3.org/TR/2008/REC-xml-20081126/#charsets
 *
 * Valid XML characters are:
 * #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
 *
 * Invalid XML characters are:
 * [#x0-#x8] | #xB | #xC | [#xE-#x1F] | [#xD800-#xDFFF] | #xFFFE | #xFFFF
 * | [#x110000-#xFFFFFFFF]
 *
 * Note: We could maybe use purple_utf8_strip_unprintables() for this (that
 *       function was added after we had already started using this), but
 *       we know this function works and changing it is scary.
 */
static void purple_fbapi_xml_salvage(char *str)
{
	gchar *tmp;
	gunichar unichar;

	for (tmp = str; tmp[0] != '\0'; tmp = g_utf8_next_char(tmp))
	{
		unichar = g_utf8_get_char(tmp);
		if ((unichar >= 0x1 && unichar <= 0x8)
				|| unichar == 0xb
				|| unichar == 0xc
				|| (unichar >= 0xe && unichar <= 0x1f)
				|| (unichar >= 0xd800 && unichar <= 0xdfff)
				|| unichar == 0xfffe
				|| unichar == 0xffff
				|| unichar >= 0x110000)
		{
			/* This character is not valid XML so replace it with question marks */
			purple_debug_error("fbapi", "Replacing invalid "
					"XML character %08x with question marks\n",
					unichar);

			tmp[0] = '?';
			if (unichar & 0x0000ff00)
				tmp[1] = '?';
			if (unichar & 0x00ff0000)
				tmp[2] = '?';
			if (unichar & 0xff000000)
				tmp[3] = '?';
		}
	}
}

static void purple_fbapi_request_fetch_cb(PurpleUtilFetchUrlData *url_data, gpointer user_data, const gchar *url_text, gsize len, const gchar *error_message)
{
	PurpleFbApiCall *apicall;
	xmlnode *response;
	PurpleConnectionError error = PURPLE_CONNECTION_ERROR_OTHER_ERROR;
	char *error_message2 = NULL;

	apicall = user_data;

	if (error_message != NULL) {
		/* Request failed */

		if (apicall->attempt_number < MAX_CONNECTION_ATTEMPTS) {
			/* Retry! */
			apicall->url_data = purple_util_fetch_url_request(API_URL,
					TRUE, NULL, FALSE, apicall->request, FALSE,
					purple_fbapi_request_fetch_cb, apicall);
			apicall->attempt_number++;
			return;
		}

		response = NULL;
		error_message2 = g_strdup(error_message);
		error = PURPLE_CONNECTION_ERROR_NETWORK_ERROR;
	} else if (url_text != NULL && len > 0) {
		/* Parse the response as XML */
		response = xmlnode_from_str(url_text, len);

		if (response == NULL)
		{
			gchar *salvaged;

			if (g_utf8_validate(url_text, len, NULL)) {
				salvaged = g_strdup(url_text);
			} else {
				/* Facebook responded with invalid UTF-8.  Bastards. */
				purple_debug_error("fbapi", "Response is not valid UTF-8\n");
				salvaged = purple_utf8_salvage(url_text);
			}

			purple_fbapi_xml_salvage(salvaged);
			response = xmlnode_from_str(salvaged, -1);
			g_free(salvaged);
		}

		if (response == NULL) {
			purple_debug_error("fbapi", "Could not parse response as XML: %*s\n",
			(int)len, url_text);
			error_message2 = g_strdup(_("Invalid response from server"));
		} else if (g_str_equal(response->name, "error_response")) {
			/*
			 * The response is an error message, in the standard format
			 * for errors from API calls.
			 */
			xmlnode *tmp;
			char *tmpstr;

			tmp = xmlnode_get_child(response, "error_code");
			if (tmp != NULL) {
				tmpstr = xmlnode_get_data_unescaped(tmp);
				if (tmpstr != NULL && strcmp(tmpstr, "293") == 0) {
					error_message2 = g_strdup(_("Need chat permission"));
					error = PURPLE_CONNECTION_ERROR_AUTHENTICATION_FAILED;
				}
				g_free(tmpstr);
			}
			if (error_message2 == NULL) {
				error = PURPLE_CONNECTION_ERROR_OTHER_ERROR;
				tmp = xmlnode_get_child(response, "error_msg");
				if (tmp != NULL)
					error_message2 = xmlnode_get_data_unescaped(tmp);
			}
			if (error_message2 == NULL)
				error_message2 = g_strdup(_("Unknown"));
		} else {
			error_message2 = NULL;
		}
	} else {
		/* Response body was empty */
		response = NULL;
		error_message2 = NULL;
	}

	if (apicall->attempt_number > 1 || error_message2 != NULL)
		purple_debug_error("fbapi", "Request '%s' %s after %u attempts: %s\n",
				apicall->request,
				error_message == NULL ? "succeeded" : "failed",
				apicall->attempt_number, error_message2);

	/*
	 * The request either succeeded or failed the maximum number of
	 * times.  In either case, pass control off to the callback
	 * function and let them decide what to do.
	 */
	apicall->callback(apicall, apicall->user_data, response, error, error_message2);
	apicall->url_data = NULL;
	purple_fbapi_request_destroy(apicall);

	xmlnode_free(response);
	g_free(error_message2);
}

static gboolean concat_params(gpointer key, gpointer value, gpointer data)
{
	GString *tmp;

	tmp = data;
	g_string_append_printf(tmp, "%s=%s", (const char *)key, (const char *)value);

	return FALSE;
}

/**
 * @return A Newly allocated base16 encoded version of the md5
 *         signature calculated using the algorithm described on the
 *         Facebook developer wiki.  This string must be g_free'd.
 */
static char *generate_signature(const char *api_secret, const GTree *params)
{
	GString *tmp;
	unsigned char hashval[16];

	tmp = g_string_new(NULL);
	g_tree_foreach((GTree *)params, concat_params, tmp);
	g_string_append(tmp, api_secret);

	purple_cipher_digest_region("md5", (const unsigned char *)tmp->str,
			tmp->len, sizeof(hashval), hashval, NULL);
	g_string_free(tmp, TRUE);

	return purple_base16_encode(hashval, sizeof(hashval));
}

static gboolean append_params_to_body(gpointer key, gpointer value, gpointer data)
{
	GString *body;

	body = data;

	if (body->len > 0)
		g_string_append_c(body, '&');

	g_string_append(body, purple_url_encode(key));
	g_string_append_c(body, '=');
	g_string_append(body, purple_url_encode(value));

	return FALSE;
}

static GString *purple_fbapi_construct_request_vargs(PurpleAccount *account, const char *method, va_list args)
{
	GTree *params;
	const char *api_key, *api_secret;
	const char *key, *value;
	char call_id[21];
	char *signature;
	GString *body;

	/* Read all paramters into a sorted tree */
	params = g_tree_new((GCompareFunc)strcmp);
	while ((key = va_arg(args, const char *)) != NULL)
	{
		value = va_arg(args, const char *);
		g_tree_insert(params, (char *)key, (char *)value);

		/* If we have an access_token then we need a call_id */
		if (g_str_equal(key, "access_token")) {
			struct timeval tv;
			if (gettimeofday(&tv, NULL) != 0) {
				time_t now;
				purple_debug_error("fbapi",
						"Error calling gettimeofday(): %s\n",
						g_strerror(errno));
				now = time(NULL);
				strftime(call_id, sizeof(call_id), "%s000000", localtime(&now));
			} else {
				char tmp[22];
				strftime(tmp, sizeof(tmp), "%s", localtime(&tv.tv_sec));
				sprintf(call_id, "%s%06lu", tmp, (long unsigned int)tv.tv_usec);
			}
			g_tree_insert(params, "call_id", call_id);
		}
	}

	api_key = purple_account_get_string(account, "fb_api_key", PURPLE_FBAPI_KEY);
	api_secret = purple_account_get_string(account, "fb_api_secret", API_SECRET);

	/* Add the method and api_key parameters to the list */
	g_tree_insert(params, "method", (char *)method);
	g_tree_insert(params, "api_key", (char *)api_key);

	/* Add the signature parameter to the list */
	signature = generate_signature((char *)api_secret, params);
	g_tree_insert(params, "sig", signature);

	/* Construct the body of the HTTP POST request */
	body = g_string_new(NULL);
	g_tree_foreach(params, append_params_to_body, body);
	g_tree_destroy(params);
	g_free(signature);

	return body;
}

GString *purple_fbapi_construct_request(PurpleAccount *account, const char *method, ...)
{
	va_list args;
	GString *body;

	va_start(args, method);
	body = purple_fbapi_construct_request_vargs(account, method, args);
	va_end(args);

	return body;
}

PurpleFbApiCall *purple_fbapi_request_vargs(PurpleAccount *account, PurpleFbApiCallback callback, gpointer user_data, GDestroyNotify user_data_destroy_func, const char *method, va_list args)
{
	GString *body;
	PurpleFbApiCall *apicall;

	body = purple_fbapi_construct_request_vargs(account, method, args);

	/* Construct an HTTP POST request */
	apicall = g_new(PurpleFbApiCall, 1);
	apicall->callback = callback;
	apicall->user_data = user_data;
	apicall->user_data_destroy_func = user_data_destroy_func;
	apicall->attempt_number = 1;

	apicall->request = g_strdup_printf("POST /restserver.php HTTP/1.0\r\n"
			"Connection: close\r\n"
			"Accept: */*\r\n"
			"Content-Type: application/x-www-form-urlencoded; charset=UTF-8\r\n"
			"Content-Length: %zu\r\n\r\n%s", (size_t)body->len, body->str);
	g_string_free(body, TRUE);

	apicall->url_data = purple_util_fetch_url_request(API_URL,
			TRUE, NULL, FALSE, apicall->request, FALSE,
			purple_fbapi_request_fetch_cb, apicall);

	apicalls = g_slist_prepend(apicalls, apicall);

	return apicall;
}

PurpleFbApiCall *purple_fbapi_request(PurpleAccount *account, PurpleFbApiCallback callback, gpointer user_data, GDestroyNotify user_data_destroy_func, const char *method, ...)
{
	va_list args;
	PurpleFbApiCall *apicall;

	va_start(args, method);
	apicall = purple_fbapi_request_vargs(account, callback, user_data, user_data_destroy_func, method, args);
	va_end(args);

	return apicall;
}

void purple_fbapi_request_destroy(PurpleFbApiCall *apicall)
{
	apicalls = g_slist_remove(apicalls, apicall);

	if (apicall->url_data != NULL)
		purple_util_fetch_url_cancel(apicall->url_data);

	if (apicall->user_data != NULL && apicall->user_data_destroy_func != NULL)
		apicall->user_data_destroy_func(apicall->user_data);

	g_free(apicall->request);
	g_free(apicall);
}

void purple_fbapi_uninit(void)
{
	while (apicalls != NULL)
		purple_fbapi_request_destroy(apicalls->data);
}
