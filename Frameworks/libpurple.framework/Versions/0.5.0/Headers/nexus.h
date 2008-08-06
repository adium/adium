/**
 * Copyright (C) 2007-2008 Felipe Contreras
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

#ifndef MSN_NEXUS_H
#define MSN_NEXUS_H

#include <glib.h>

typedef struct MsnNexus MsnNexus;

#include "session.h"

struct _PurpleSslConnection;

typedef void (*_PurpleInputFunction) (gpointer, gint, guint);

struct MsnNexus
{
	MsnSession *session;

	char *login_host;
	char *login_path;
	GHashTable *challenge_data;
	struct _PurpleSslConnection *gsc;

	guint input_handler;

	char *write_buf;
	gssize written_len;
	_PurpleInputFunction written_cb;

	char *read_buf;
	gsize read_len;
};

void msn_nexus_connect(MsnNexus *nexus);
MsnNexus *msn_nexus_new(MsnSession *session);
void msn_nexus_destroy(MsnNexus *nexus);

#endif /* MSN_NEXUS_H */
