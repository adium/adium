/**
 * Copyright (C) 2008 Felipe Contreras.
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

#ifndef MSN_SESSION_PRIVATE_H
#define MSN_SESSION_PRIVATE_H

#include "session.h"
#include "io/pecan_node.h"

#include "ab/pecan_contact.h"
#include "ab/pecan_contactlist.h"

#include "io/pecan_node.h"

struct MsnNotification;
struct MsnNexus;
struct MsnSync;

struct _PurpleAccount;
struct _PurpleConversation;

struct MsnSession
{
    gchar *username;
    gchar *password;

    struct _PurpleAccount *account;
    PecanContact *user;

    guint protocol_ver;

    MsnLoginStep login_step; /**< The current step in the login process. */

    gboolean connected;
    gboolean logged_in; /**< A temporal flag to ignore local buddy list adds. */
    gboolean destroying; /**< A flag that states if the session is being destroyed. */
    gboolean http_method;
    gboolean server_alias;
    PecanNode *http_conn;

    struct MsnNotification *notification;
    struct MsnNexus *nexus;
    struct MsnSync *sync;

    PecanContactList *contactlist;

    int servconns_count; /**< The count of server connections. */
    GList *switches; /**< The list of all the switchboards. */
    GList *directconns; /**< The list of all the directconnections. */
    GList *slplinks; /**< The list of all the slplinks. */

    int conv_seq; /**< The current conversation sequence number. */

    struct
    {
        char *kv;
        char *sid;
        char *mspauth;
        unsigned long sl;
        int email_enabled;
        char *client_ip;
        int client_port;
        gchar *mail_url;
        gulong mail_url_timestamp;
    } passport_info;

    guint inbox_unread_count; /* The number of unread e-mails on the inbox. */
};

#endif /* MSN_SESSION_PRIVATE_H */
