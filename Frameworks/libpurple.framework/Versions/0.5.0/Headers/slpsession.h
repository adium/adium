/**
 * @file slpsession.h SLP Session functions
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
#ifndef _MSN_SLPSESSION_H_
#define _MSN_SLPSESSION_H_

typedef struct _MsnSlpSession MsnSlpSession;

#include "slpcall.h"
#include "slpsession.h"
#include "slpmsg.h"

struct _MsnSlpSession
{
	/* MsnSlpLink *slplink; */
	MsnSlpCall *slpcall;

	long id;

	long app_id;
	char *call_id;
};

MsnSlpSession *msn_slp_session_new(MsnSlpCall *slpcall);
void msn_slp_session_destroy(MsnSlpSession *slpsession);
void msn_slpsession_send_slpmsg(MsnSlpSession *slpsession,
								MsnSlpMessage *slpmsg);
#endif /* _MSN_SLPSESSION_H_ */
