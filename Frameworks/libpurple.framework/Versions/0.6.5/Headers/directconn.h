/**
 * @file directconn.h MSN direct connection functions
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
#ifndef _MSN_DIRECTCONN_H_
#define _MSN_DIRECTCONN_H_

typedef struct _MsnDirectConn MsnDirectConn;

#include "slplink.h"
#include "slp.h"
#include "msg.h"

struct _MsnDirectConn
{
	MsnSlpLink *slplink;
	MsnSlpCall *initial_call;

	PurpleProxyConnectData *connect_data;

	gboolean acked;

	char *nonce;

	int fd;

	int port;
	int inpa;

	int c;
};

MsnDirectConn *msn_directconn_new(MsnSlpLink *slplink);
gboolean msn_directconn_connect(MsnDirectConn *directconn,
								const char *host, int port);
void msn_directconn_listen(MsnDirectConn *directconn);
void msn_directconn_send_msg(MsnDirectConn *directconn, MsnMessage *msg);
void msn_directconn_parse_nonce(MsnDirectConn *directconn, const char *nonce);
void msn_directconn_destroy(MsnDirectConn *directconn);
void msn_directconn_send_handshake(MsnDirectConn *directconn);

#endif /* _MSN_DIRECTCONN_H_ */
