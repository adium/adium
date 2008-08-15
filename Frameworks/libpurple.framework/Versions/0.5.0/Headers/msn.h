/**
 * @file msn.h The MSN protocol plugin
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
#ifndef _MSN_H_
#define _MSN_H_

/* #define MSN_DEBUG_MSG 1 */
/* #define MSN_DEBUG_SLPMSG 1 */
/* #define MSN_DEBUG_HTTP 1 */

/* #define MSN_DEBUG_SLP 1 */
/* #define MSN_DEBUG_SLP_VERBOSE 1 */
/* #define MSN_DEBUG_SLP_FILES 1 */

/* #define MSN_DEBUG_NS 1 */
/* #define MSN_DEBUG_SB 1 */

#include "internal.h"

#include "account.h"
#include "accountopt.h"
#include "blist.h"
#include "connection.h"
#include "conversation.h"
#include "debug.h"
#include "cipher.h"
#include "notify.h"
#include "privacy.h"
#include "proxy.h"
#include "prpl.h"
#include "request.h"
#include "servconn.h"
#include "sslconn.h"
#include "util.h"

#include "ft.h"

#define MSN_BUF_LEN 8192

/* Windows Live Messenger Server*/
#define MSN_SERVER "messenger.hotmail.com"
#define MSN_HTTPCONN_SERVER "gateway.messenger.hotmail.com"
#define MSN_PORT 1863
#define WLM_PROT_VER		15

#define WLM_MAX_PROTOCOL	15
#define WLM_MIN_PROTOCOL	15

#define MSN_TYPING_RECV_TIMEOUT 6
#define MSN_TYPING_SEND_TIMEOUT	4

#define PROFILE_URL "http://spaces.live.com/profile.aspx?mem="
#define PHOTO_URL	" contactparams:photopreauthurl=\""

#define BUDDY_ALIAS_MAXLEN 387

#define MSN_FT_GUID "5D3E02AB-6190-11D3-BBBB-00C04F795683"
#define MSN_OBJ_GUID "A4268EEC-FEC5-49E5-95C3-F126696BDBF6"

#define MSN_CLIENTINFO \
	"Client-Name: Purple/" VERSION "\r\n" \
	"Chat-Logging: Y\r\n"

/* Index into attention_types */
#define MSN_NUDGE 0

typedef enum
{
	MSN_LIST_FL_OP = 0x01,
	MSN_LIST_AL_OP = 0x02,
	MSN_LIST_BL_OP = 0x04,
	MSN_LIST_RL_OP = 0x08,
	MSN_LIST_PL_OP = 0x10

} MsnListOp;
#define MSN_LIST_OP_MASK	0x07

typedef enum
{
	MSN_CLIENT_CAP_WIN_MOBILE = 0x000001,
	MSN_CLIENT_CAP_INK_GIF    = 0x000004,
	MSN_CLIENT_CAP_INK_ISF    = 0x000008,
	MSN_CLIENT_CAP_VIDEO_CHAT = 0x000010,
	MSN_CLIENT_CAP_PACKET     = 0x000020,
	MSN_CLIENT_CAP_MSNMOBILE  = 0x000040,
	MSN_CLIENT_CAP_MSNDIRECT  = 0x000080,
	MSN_CLIENT_CAP_WEBMSGR    = 0x000200,
	MSN_CLIENT_CAP_TGW        = 0x000800,
	MSN_CLIENT_CAP_SPACE      = 0x001000,
	MSN_CLIENT_CAP_MCE        = 0x002000,
	MSN_CLIENT_CAP_DIRECTIM   = 0x004000,
	MSN_CLIENT_CAP_WINKS      = 0x008000,
	MSN_CLIENT_CAP_SEARCH     = 0x010000,
	MSN_CLIENT_CAP_BOT        = 0x020000,
	MSN_CLIENT_CAP_VOICEIM    = 0x040000,
	MSN_CLIENT_CAP_SCHANNEL   = 0x080000,
	MSN_CLIENT_CAP_SIP_INVITE = 0x100000,
	MSN_CLIENT_CAP_SDRIVE     = 0x400000

} MsnClientCaps;

typedef enum
{
	MSN_CLIENT_VER_5_0 = 0x00,
	MSN_CLIENT_VER_6_0 = 0x10,	/* MSNC1 */
	MSN_CLIENT_VER_6_1 = 0x20,	/* MSNC2 */
	MSN_CLIENT_VER_6_2 = 0x30,	/* MSNC3 */
	MSN_CLIENT_VER_7_0 = 0x40,	/* MSNC4 */
	MSN_CLIENT_VER_7_5 = 0x50,	/* MSNC5 */
	MSN_CLIENT_VER_8_0 = 0x60,	/* MSNC6 */
	MSN_CLIENT_VER_8_1 = 0x70,	/* MSNC7 */
	MSN_CLIENT_VER_8_5 = 0x80	/* MSNC8 */

} MsnClientVerId;

#define MSN_CLIENT_ID_VERSION      MSN_CLIENT_VER_7_0
#define MSN_CLIENT_ID_CAPABILITIES MSN_CLIENT_CAP_PACKET

#define MSN_CLIENT_ID \
	((MSN_CLIENT_ID_VERSION    << 24) | \
	 (MSN_CLIENT_ID_CAPABILITIES))

void msn_act_id(PurpleConnection *gc, const char *entry);
void msn_send_privacy(PurpleConnection *gc);

#endif /* _MSN_H_ */
