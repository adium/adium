/**
 * @file soap.h
 * 	header file for SOAP connection related process
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,  USA
 */

#ifndef _MSN_SOAP_H
#define _MSN_SOAP_H

#include "session.h"
#include "sslconn.h"
#include "xmlnode.h"

#include <glib.h>

typedef struct _MsnSoapMessage MsnSoapMessage;
typedef void (*MsnSoapCallback)(MsnSoapMessage *request,
	MsnSoapMessage *response, gpointer cb_data);

struct _MsnSoapMessage {
	char *action;
	xmlnode *xml;
	GSList *headers;
};

MsnSoapMessage *msn_soap_message_new(const char *action, xmlnode *xml);

void msn_soap_message_send(MsnSession *session, MsnSoapMessage *message,
	const char *host, const char *path, gboolean secure,
	MsnSoapCallback cb, gpointer cb_data);

#endif
