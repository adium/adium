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

typedef struct _PurpleSrvResponse PurpleSrvResponse;
typedef struct _PurpleSrvQueryData PurpleSrvQueryData;

struct _PurpleSrvResponse {
	char hostname[256];
	int port;
	int weight;
	int pref;
};

typedef void (*PurpleSrvCallback)(PurpleSrvResponse *resp, int results, gpointer data);

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

#ifdef __cplusplus
}
#endif

#endif /* _PURPLE_DNSSRV_H */
