/**
 * @file sync.h MSN list synchronization functions
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
#ifndef _MSN_SYNC_H_
#define _MSN_SYNC_H_

typedef struct _MsnSync MsnSync;

#include "session.h"
#include "table.h"
#include "user.h"

struct _MsnSync
{
	MsnSession *session;
	MsnTable *cbs_table;
	MsnTable *old_cbs_table;

	int num_users;
	int total_users;
	int num_groups;
	int total_groups;
	MsnUser *last_user;
};

void msn_sync_init(void);
void msn_sync_end(void);

MsnSync * msn_sync_new(MsnSession *session);
void msn_sync_destroy(MsnSync *sync);

#endif /* _MSN_SYNC_H_ */
