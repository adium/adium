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

#ifndef MSN_H
#define MSN_H

#include "pecan_config.h"
#include "pecan_printf.h" /** @todo remove this */

#define MSN_BUF_LEN 8192

#define USEROPT_MSNSERVER 3
#define MSN_SERVER "messenger.hotmail.com"
#define MSN_HTTPCONN_SERVER "gateway.messenger.hotmail.com"
#define USEROPT_MSNPORT 4
#define MSN_PORT 1863

#define MSN_TYPING_RECV_TIMEOUT 6
#define MSN_TYPING_SEND_TIMEOUT	4

#define HOTMAIL_URL "http://www.hotmail.com/cgi-bin/folders"
#define PASSPORT_URL "http://lc1.law13.hotmail.passport.com/cgi-bin/dologin?login="
#define PROFILE_URL "http://spaces.live.com/profile.aspx?mem="

#define USEROPT_HOTMAIL 0

#define BUDDY_ALIAS_MAXLEN 387

#define MSN_FT_GUID "{5D3E02AB-6190-11d3-BBBB-00C04F795683}"

#define MSN_CLIENTINFO \
	"Client-Name: Purple/" VERSION "\r\n" \
	"Chat-Logging: Y\r\n"

/* Index into attention_types */
#define MSN_NUDGE 0

typedef enum
{
	MSN_CLIENT_CAP_WIN_MOBILE = 0x00001,
	MSN_CLIENT_CAP_UNKNOWN_1  = 0x00002,
	MSN_CLIENT_CAP_INK_GIF    = 0x00004,
	MSN_CLIENT_CAP_INK_ISF    = 0x00008,
	MSN_CLIENT_CAP_VIDEO_CHAT = 0x00010,
	MSN_CLIENT_CAP_BASE       = 0x00020,
	MSN_CLIENT_CAP_MSNMOBILE  = 0x00040,
	MSN_CLIENT_CAP_MSNDIRECT  = 0x00080,
	MSN_CLIENT_CAP_WEBMSGR    = 0x00100,
	MSN_CLIENT_CAP_DIRECTIM   = 0x04000,
	MSN_CLIENT_CAP_WINKS      = 0x08000,
	MSN_CLIENT_CAP_SEARCH     = 0x10000

} MsnClientCaps;

typedef enum
{
	MSN_CLIENT_VER_5_0 = 0x00,
	MSN_CLIENT_VER_6_0 = 0x10,	/* MSNC1 */
	MSN_CLIENT_VER_6_1 = 0x20,	/* MSNC2 */
	MSN_CLIENT_VER_6_2 = 0x30,	/* MSNC3 */
	MSN_CLIENT_VER_7_0 = 0x40,	/* MSNC4 */
	MSN_CLIENT_VER_7_5 = 0x50	/* MSNC5 */

} MsnClientVerId;

#define MSN_CLIENT_ID_VERSION      MSN_CLIENT_VER_7_0
#define MSN_CLIENT_ID_RESERVED_1   0x00
#define MSN_CLIENT_ID_RESERVED_2   0x00
#define MSN_CLIENT_ID_CAPABILITIES MSN_CLIENT_CAP_BASE

#define MSN_CLIENT_ID \
	((MSN_CLIENT_ID_VERSION    << 24) | \
	 (MSN_CLIENT_ID_RESERVED_1 << 16) | \
	 (MSN_CLIENT_ID_RESERVED_2 <<  8) | \
	 (MSN_CLIENT_ID_CAPABILITIES))

#endif /* MSN_H */
