/*
 * libfacebook
 *
 * libfacebook is the property of its developers.  See the COPYRIGHT file
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

#ifndef FBAPI_H
#define FBAPI_H

#ifdef __cplusplus
extern "C" {
#endif

#include <glib.h>

#include "connection.h"

#define PURPLE_FBAPI_KEY "INSERT_KEY_HERE"

typedef struct _PurpleFbApiCall PurpleFbApiCall;

/**
 * This is the callback function when a response is received to an API
 * request.  The response will always be parsed as XML.
 *
 * error_message will be set if the physical TCP connection failed, or
 * if the API call returned <error_response> as the top level node in
 * the document.
 *
 * error will be set if and only if error_message is set.
 *
 * response will be null if error_message is non-null or if the
 * response was not valid XML.  So if error_message == NULL &&
 * response == NULL then you know the body was malformed XML.
 */
typedef void (*PurpleFbApiCallback)(PurpleFbApiCall *apicall, gpointer user_data, const xmlnode *response, PurpleConnectionError error, const gchar *error_message);

/**
 * Construct the body of a Facebook API request.
 *
 * @param account PurpleAccount of the user
 * @param method The API method to call.  For example, auth.getSession or
 *        events.get.
 * @param attrs key/value pairs of request arguments.  The list must be
 *        terminated with a NULL.  It should not contain the method,
 *        api_key, call_id, or sig parameters--these will be appended
 *        for you.
 */
GString *purple_fbapi_construct_request(PurpleAccount *account, const char *method, ...) G_GNUC_NULL_TERMINATED;

/**
 * @param account PurpleAccount of the user
 * @param args key/value pairs that will be POSTed to the API URL.  The
 *        list must be terminated with a NULL.  It should not contain
 *        the method, api_key, call_id, or sig parameters--these will be
 *        appended for you.
 * @see purple_fbapi_request
 */
PurpleFbApiCall *purple_fbapi_request_vargs(PurpleAccount *account, PurpleFbApiCallback callback, gpointer user_data, GDestroyNotify user_data_destroy_func, const char *method, va_list args);

/**
 * @param account PurpleAccount of the user
 * @param callback The callback function that should be called when we
 *        receive a response from the server.
 * @param user_data Optional data to pass to the callback function.
 * @param user_data_destroy_func An option function to be called and
 *        passed user_data to free it after this request has finished
 *        or been canceled.
 * @param method The API method to call.  For example, auth.getSession or
 *        events.get.
 * @param attrs key/value pairs that will be POSTed to the API URL.  The
 *        list must be terminated with a NULL.  It should not contain
 *        the method, api_key, call_id, or sig parameters--these will be
 *        appended for you.
 */
PurpleFbApiCall *purple_fbapi_request(PurpleAccount *account, PurpleFbApiCallback callback, gpointer user_data, GDestroyNotify user_data_destroy_func, const char *method, ...) G_GNUC_NULL_TERMINATED;

/*
 * Destroy a single pending API request.
 */
void purple_fbapi_request_destroy(PurpleFbApiCall *apicall);

/**
 * Destroy all pending API requests.
 */
void purple_fbapi_uninit(void);

#ifdef __cplusplus
}
#endif

#endif /* FBAPI_H */
