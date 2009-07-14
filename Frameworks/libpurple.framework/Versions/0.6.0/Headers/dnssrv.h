/**
 * @file dnssrv.h
 */

/* purple
 *
 * Copyright (C) 2005, Thomas Butter <butter@uni-mannheim.de>
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

#ifndef _PURPLE_DNSSRV_H
#define _PURPLE_DNSSRV_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct _PurpleSrvQueryData PurpleSrvQueryData;
typedef struct _PurpleSrvResponse PurpleSrvResponse;
typedef struct _PurpleTxtResponse PurpleTxtResponse;

#include <glib.h>

struct _PurpleSrvResponse {
	char hostname[256];
	int port;
	int weight;
	int pref;
};

/**
 * @param resp An array of PurpleSrvResponse of size results.  The array
 *        is sorted based on the order described in the DNS SRV RFC.
 *        Users of this API should try each record in resp in order,
 *        starting at the beginning.
 */
typedef void (*PurpleSrvCallback)(PurpleSrvResponse *resp, int results, gpointer data);

/**
 * Callback that returns the data retrieved from a DNS TXT lookup.
 *
 * @param responses   A GList of PurpleTxtResponse objects.
 * @param data        The extra data passed to purple_txt_resolve.
 */
typedef void (*PurpleTxtCallback)(GList *responses, gpointer data);

/**
 * Queries an SRV record.
 *
 * @param protocol Name of the protocol (e.g. "sip")
 * @param transport Name of the transport ("tcp" or "udp")
 * @param domain Domain name to query (e.g. "blubb.com")
 * @param cb A callback which will be called with the results
 * @param extradata Extra data to be passed to the callback
 */
PurpleSrvQueryData *purple_srv_resolve(const char *protocol, const char *transport, const char *domain, PurpleSrvCallback cb, gpointer extradata);

/**
 * Cancel an SRV DNS query.
 *
 * @param query_data The request to cancel.
 */
void purple_srv_cancel(PurpleSrvQueryData *query_data);

/**
 * Queries an TXT record.
 *
 * @param owner Name of the protocol (e.g. "_xmppconnect")
 * @param domain Domain name to query (e.g. "blubb.com")
 * @param cb A callback which will be called with the results
 * @param extradata Extra data to be passed to the callback
 *
 * @since 2.6.0
 */
PurpleSrvQueryData *purple_txt_resolve(const char *owner, const char *domain, PurpleTxtCallback cb, gpointer extradata);

/**
 * Cancel an TXT DNS query.
 *
 * @param query_data The request to cancel.
 * @since 2.6.0
 */
void purple_txt_cancel(PurpleSrvQueryData *query_data);

/**
 * Get the value of the current TXT record.
 *
 * @param resp  The TXT response record
 * @returns The value of the current TXT record.
 * @since 2.6.0
 */
const gchar *purple_txt_response_get_content(PurpleTxtResponse *resp);

/**
 * Destroy a TXT DNS response object.
 *
 * @param response The PurpleTxtResponse to destroy.
 * @since 2.6.0
 */
void purple_txt_response_destroy(PurpleTxtResponse *resp);

#ifdef __cplusplus
}
#endif

#endif /* _PURPLE_DNSSRV_H */
