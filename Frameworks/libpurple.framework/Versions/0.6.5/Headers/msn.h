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

#include "msg.h"

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

#define MSN_CAM_GUID "4BD96FC0-AB17-4425-A14A-439185962DC8"
#define MSN_CAM_REQUEST_GUID "1C9AA97E-9C05-4583-A3BD-908A196F1E92"
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
	MSN_CLIENT_CAP_WIN_MOBILE = 0x0000001,
	MSN_CLIENT_CAP_INK_GIF    = 0x0000004,
	MSN_CLIENT_CAP_INK_ISF    = 0x0000008,
	MSN_CLIENT_CAP_VIDEO_CHAT = 0x0000010,
	MSN_CLIENT_CAP_PACKET     = 0x0000020,
	MSN_CLIENT_CAP_MSNMOBILE  = 0x0000040,
	MSN_CLIENT_CAP_MSNDIRECT  = 0x0000080,
	MSN_CLIENT_CAP_WEBMSGR    = 0x0000200,
	MSN_CLIENT_CAP_TGW        = 0x0000800,
	MSN_CLIENT_CAP_SPACE      = 0x0001000,
	MSN_CLIENT_CAP_MCE        = 0x0002000,
	MSN_CLIENT_CAP_DIRECTIM   = 0x0004000,
	MSN_CLIENT_CAP_WINKS      = 0x0008000,
	MSN_CLIENT_CAP_SEARCH     = 0x0010000,
	MSN_CLIENT_CAP_BOT        = 0x0020000,
	MSN_CLIENT_CAP_VOICEIM    = 0x0040000,
	MSN_CLIENT_CAP_SCHANNEL   = 0x0080000,
	MSN_CLIENT_CAP_SIP_INVITE = 0x0100000,
	MSN_CLIENT_CAP_SDRIVE     = 0x0400000,
	MSN_CLIENT_CAP_ONECARE    = 0x1000000,
	MSN_CLIENT_CAP_P2P_TURN   = 0x2000000,
	MSN_CLIENT_CAP_P2P_BOOTSTRAP_VIA_UUN = 0x4000000,

} MsnClientCaps;

typedef enum
{
	MSN_CLIENT_EXT_CAP_RTC_VIDEO = 0x10,
	MSN_CLIENT_EXT_CAP_P2PV2     = 0x20
} MsnClientExtCaps;

typedef enum
{
	MSN_CLIENT_VER_5_0  = 0x00,
	MSN_CLIENT_VER_6_0  = 0x10,	/* MSNC1 */
	MSN_CLIENT_VER_6_1  = 0x20,	/* MSNC2 */
	MSN_CLIENT_VER_6_2  = 0x30,	/* MSNC3 */
	MSN_CLIENT_VER_7_0  = 0x40,	/* MSNC4 */
	MSN_CLIENT_VER_7_5  = 0x50,	/* MSNC5 */
	MSN_CLIENT_VER_8_0  = 0x60,	/* MSNC6 */
	MSN_CLIENT_VER_8_1  = 0x70,	/* MSNC7 */
	MSN_CLIENT_VER_8_5  = 0x80,	/* MSNC8 */
	MSN_CLIENT_VER_9_0  = 0x90,	/* MSNC9 */
	MSN_CLIENT_VER_14_0 = 0xA0	/* MSNC10 */

} MsnClientVerId;

#define MSN_CLIENT_ID_VERSION      MSN_CLIENT_VER_7_0
#define MSN_CLIENT_ID_CAPABILITIES (MSN_CLIENT_CAP_PACKET|MSN_CLIENT_CAP_INK_GIF|MSN_CLIENT_CAP_VOICEIM)

#define MSN_CLIENT_ID \
	((MSN_CLIENT_ID_VERSION    << 24) | \
	 (MSN_CLIENT_ID_CAPABILITIES))

#define MSN_CLIENT_EXT_ID 0

gboolean msn_email_is_valid(const char *passport);
void msn_act_id(PurpleConnection *gc, const char *entry);
void msn_send_privacy(PurpleConnection *gc);
void msn_send_im_message(MsnSession *session, MsnMessage *msg);

#endif /* _MSN_H_ */
