/*
 * Purple's oscar protocol plugin
 * This file is the legal property of its developers.
 * Please see the AUTHORS file distributed alongside this file.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111-1301  USA
*/

/*
 * Main libfaim header.  Must be included in client for prototypes/macros.
 *
 * "come on, i turned a chick lesbian; i think this is the hackish equivalent"
 *                                                -- Josh Myer
 *
 */

#ifndef _OSCAR_H_
#define _OSCAR_H_

#include "internal.h"
#include "circbuffer.h"
#include "debug.h"
#include "eventloop.h"
#include "proxy.h"
#include "sslconn.h"

#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <sys/types.h>
#include <stdlib.h>
#include <stdarg.h>
#include <errno.h>
#include <time.h>

#ifndef _WIN32
#include <sys/time.h>
#include <unistd.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#else
#include "libc_interface.h"
#endif

typedef struct _ByteStream         ByteStream;
typedef struct _ClientInfo         ClientInfo;
typedef struct _FlapConnection     FlapConnection;
typedef struct _FlapFrame          FlapFrame;
typedef struct _IcbmArgsCh2        IcbmArgsCh2;
typedef struct _IcbmCookie         IcbmCookie;
typedef struct _OscarData          OscarData;
typedef struct _QueuedSnac         QueuedSnac;

typedef guint32 aim_snacid_t;

#include "snactypes.h"

#ifdef __cplusplus
extern "C" {
#endif

#define FAIM_SNAC_HASH_SIZE 16

/*
 * Current Maximum Length for usernames (not including NULL)
 *
 * Currently only names up to 16 characters can be registered
 * however it is apparently legal for them to be larger.
 */
#define MAXSNLEN 97

/*
 * Current Maximum Length for Instant Messages
 *
 * This was found basically by experiment, but not wholly
 * accurate experiment.  It should not be regarded
 * as completely correct.  But its a decent approximation.
 *
 * Note that although we can send this much, its impossible
 * for WinAIM clients (up through the latest (4.0.1957)) to
 * send any more than 1kb.  Amaze all your windows friends
 * with utterly oversized instant messages!
 */
#define MAXMSGLEN 2544

/*
 * Maximum size of a Buddy Icon.
 */
#define MAXICONLEN 7168
#define AIM_ICONIDENT "AVT1picture.id"

/*
 * Current Maximum Length for Chat Room Messages
 *
 * This is actually defined by the protocol to be
 * dynamic, but I have yet to see due cause to
 * define it dynamically here.  Maybe later.
 *
 */
#define MAXCHATMSGLEN 512

/*
 * Found by trial and error.
 */
#define MAXAVAILMSGLEN 251

/**
 * Maximum length for the password of an ICQ account
 */
#define MAXICQPASSLEN 8

#define AIM_MD5_STRING "AOL Instant Messenger (SM)"

/*
 * Client info.  Filled in by the client and passed in to
 * aim_send_login().  The information ends up getting passed to OSCAR
 * through the initial login command.
 *
 */
struct _ClientInfo
{
	const char *clientstring;
	guint16 clientid;
	guint16 major;
	guint16 minor;
	guint16 point;
	guint16 build;
	guint32 distrib;
	const char *country; /* two-letter abbrev */
	const char *lang; /* two-letter abbrev */
};

/* Needs to be checked */
#define CLIENTINFO_AIM_3_5_1670 { \
	"AOL Instant Messenger (SM), version 3.5.1670/WIN32", \
	0x0004, \
	0x0003, 0x0005, \
	0x0000, 0x0686, \
	0x0000002a, \
	"us", "en", \
}

/* Needs to be checked */
/* Latest winaim without ssi */
#define CLIENTINFO_AIM_4_1_2010 { \
	"AOL Instant Messenger (SM), version 4.1.2010/WIN32", \
	0x0004, \
	0x0004, 0x0001, \
	0x0000, 0x07da, \
	0x0000004b, \
	"us", "en", \
}

/* Needs to be checked */
#define CLIENTINFO_AIM_4_3_2188 { \
	"AOL Instant Messenger (SM), version 4.3.2188/WIN32", \
	0x0109, \
	0x0400, 0x0003, \
	0x0000, 0x088c, \
	0x00000086, \
	"us", "en", \
}

/* Needs to be checked */
#define CLIENTINFO_AIM_4_8_2540 { \
	"AOL Instant Messenger (SM), version 4.8.2540/WIN32", \
	0x0109, \
	0x0004, 0x0008, \
	0x0000, 0x09ec, \
	0x000000af, \
	"us", "en", \
}

/* Needs to be checked */
#define CLIENTINFO_AIM_5_0_2938 { \
	"AOL Instant Messenger, version 5.0.2938/WIN32", \
	0x0109, \
	0x0005, 0x0000, \
	0x0000, 0x0b7a, \
	0x00000000, \
	"us", "en", \
}

#define CLIENTINFO_AIM_5_1_3036 { \
	"AOL Instant Messenger, version 5.1.3036/WIN32", \
	0x0109, \
	0x0005, 0x0001, \
	0x0000, 0x0bdc, \
	0x000000d2, \
	"us", "en", \
}

#define CLIENTINFO_AIM_5_5_3415 { \
	"AOL Instant Messenger, version 5.5.3415/WIN32", \
	0x0109, \
	0x0005, 0x0005, \
	0x0000, 0x0057, \
	0x000000ef, \
	"us", "en", \
}

#define CLIENTINFO_AIM_5_9_3702 { \
	"AOL Instant Messenger, version 5.9.3702/WIN32", \
	0x0109, \
	0x0005, 0x0009, \
	0x0000, 0x0e76, \
	0x00000111, \
	"us", "en", \
}

#define CLIENTINFO_ICHAT_1_0 { \
	"Apple iChat", \
	0x311a, \
	0x0001, 0x0000, \
	0x0000, 0x003c, \
	0x000000c6, \
	"us", "en", \
}

/* Needs to be checked */
#define CLIENTINFO_ICQ_4_65_3281 { \
	"ICQ Inc. - Product of ICQ (TM) 2000b.4.65.1.3281.85", \
	0x010a, \
	0x0004, 0x0041, \
	0x0001, 0x0cd1, \
	0x00000055, \
	"us", "en", \
}

/* Needs to be checked */
#define CLIENTINFO_ICQ_5_34_3728 { \
	"ICQ Inc. - Product of ICQ (TM).2002a.5.34.1.3728.85", \
	0x010a, \
	0x0005, 0x0022, \
	0x0001, 0x0e8f, \
	0x00000055, \
	"us", "en", \
}

#define CLIENTINFO_ICQ_5_45_3777 { \
	"ICQ Inc. - Product of ICQ (TM).2003a.5.45.1.3777.85", \
	0x010a, \
	0x0005, 0x002d, \
	0x0001, 0x0ec1, \
	0x00000055, \
	"us", "en", \
}

#define CLIENTINFO_ICQ6_6_0_6059 { \
	"ICQ Client", \
	0x010a, \
	0x0006, 0x0000, \
	0x0000, 0x17ab, \
	0x00007535, \
	"us", "en", \
}

#define CLIENTINFO_ICQBASIC_14_3_1068 { \
	"ICQBasic", \
	0x010a, \
	0x0014, 0x0003, \
	0x0000, 0x042c, \
	0x0000043d, \
	"us", "en", \
}

#define CLIENTINFO_ICQBASIC_14_34_3000 { \
	"ICQBasic", \
	0x010a, \
	0x0014, 0x0034, \
	0x0000, 0x0bb8, \
	0x0000043d, \
	"us", "en", \
}

#define CLIENTINFO_ICQBASIC_14_34_3096 { \
	"ICQBasic", \
	0x010a, \
	0x0014, 0x0034, \
	0x0000, 0x0c18, \
	0x0000043d, \
	"us", "en", \
}

#define CLIENTINFO_NETSCAPE_7_0_1 { \
	"Netscape 2000 an approved user of AOL Instant Messenger (SM)", \
	0x1d0d, \
	0x0007, 0x0000, \
	0x0001, 0x0000, \
	0x00000058, \
	"us", "en", \
}

/*
 * We need to use the major-minor-micro versions from the official
 * AIM and ICQ programs here or AOL won't let us use certain features.
 *
 * 0x00000611 is the distid given to us by AOL for use as the default
 * libpurple distid.
 */
#define CLIENTINFO_PURPLE_AIM { \
	NULL, \
	0x0109, \
	0x0005, 0x0001, \
	0x0000, 0x0bdc, \
	0x00000611, \
	"us", "en", \
}

#define CLIENTINFO_PURPLE_ICQ { \
	NULL, \
	0x010a, \
	0x0014, 0x0034, \
	0x0000, 0x0c18, \
	0x00000611, \
	"us", "en", \
}

#define CLIENTINFO_AIM_KNOWNGOOD CLIENTINFO_AIM_5_1_3036
#define CLIENTINFO_ICQ_KNOWNGOOD CLIENTINFO_ICQBASIC_14_34_3096

typedef enum
{
	OSCAR_DISCONNECT_DONE, /* not considered an error */
	OSCAR_DISCONNECT_LOCAL_CLOSED, /* peer connections only, not considered an error */
	OSCAR_DISCONNECT_REMOTE_CLOSED,
	OSCAR_DISCONNECT_REMOTE_REFUSED, /* peer connections only */
	OSCAR_DISCONNECT_LOST_CONNECTION,
	OSCAR_DISCONNECT_INVALID_DATA,
	OSCAR_DISCONNECT_COULD_NOT_CONNECT,
	OSCAR_DISCONNECT_RETRYING /* peer connections only */
} OscarDisconnectReason;

#define OSCAR_CAPABILITY_BUDDYICON             0x0000000000000001LL
#define OSCAR_CAPABILITY_TALK                  0x0000000000000002LL
#define OSCAR_CAPABILITY_DIRECTIM              0x0000000000000004LL
#define OSCAR_CAPABILITY_CHAT                  0x0000000000000008LL
#define OSCAR_CAPABILITY_GETFILE               0x0000000000000010LL
#define OSCAR_CAPABILITY_SENDFILE              0x0000000000000020LL
#define OSCAR_CAPABILITY_GAMES                 0x0000000000000040LL
#define OSCAR_CAPABILITY_ADDINS                0x0000000000000080LL
#define OSCAR_CAPABILITY_SENDBUDDYLIST         0x0000000000000100LL
#define OSCAR_CAPABILITY_GAMES2                0x0000000000000200LL
#define OSCAR_CAPABILITY_ICQ_DIRECT            0x0000000000000400LL
#define OSCAR_CAPABILITY_APINFO                0x0000000000000800LL
#define OSCAR_CAPABILITY_ICQRTF                0x0000000000001000LL
#define OSCAR_CAPABILITY_EMPTY                 0x0000000000002000LL
#define OSCAR_CAPABILITY_ICQSERVERRELAY        0x0000000000004000LL
#define OSCAR_CAPABILITY_UNICODEOLD            0x0000000000008000LL
#define OSCAR_CAPABILITY_TRILLIANCRYPT         0x0000000000010000LL
#define OSCAR_CAPABILITY_UNICODE               0x0000000000020000LL
#define OSCAR_CAPABILITY_INTEROPERATE          0x0000000000040000LL
#define OSCAR_CAPABILITY_SHORTCAPS             0x0000000000080000LL
#define OSCAR_CAPABILITY_HIPTOP                0x0000000000100000LL
#define OSCAR_CAPABILITY_SECUREIM              0x0000000000200000LL
#define OSCAR_CAPABILITY_SMS                   0x0000000000400000LL
#define OSCAR_CAPABILITY_VIDEO                 0x0000000000800000LL
#define OSCAR_CAPABILITY_ICHATAV               0x0000000001000000LL
#define OSCAR_CAPABILITY_LIVEVIDEO             0x0000000002000000LL
#define OSCAR_CAPABILITY_CAMERA                0x0000000004000000LL
#define OSCAR_CAPABILITY_ICHAT_SCREENSHARE     0x0000000008000000LL
#define OSCAR_CAPABILITY_TYPING                0x0000000010000000LL
#define OSCAR_CAPABILITY_NEWCAPS               0x0000000020000000LL
#define OSCAR_CAPABILITY_XTRAZ                 0x0000000040000000LL
#define OSCAR_CAPABILITY_GENERICUNKNOWN        0x0000000080000000LL
#define OSCAR_CAPABILITY_LAST                  0x0000000100000000LL

/*
 * Byte Stream type. Sort of.
 *
 * Use of this type serves a couple purposes:
 *   - Buffer/buflen pairs are passed all around everywhere. This turns
 *     that into one value, as well as abstracting it slightly.
 *   - Through the abstraction, it is possible to enable bounds checking
 *     for robustness at the cost of performance.  But a clean failure on
 *     weird packets is much better than a segfault.
 *   - I like having variables named "bs".
 *
 * Don't touch the insides of this struct.  Or I'll have to kill you.
 *
 */
struct _ByteStream
{
	guint8 *data;
	guint32 len;
	guint32 offset;
};

struct _QueuedSnac
{
	guint16 family;
	guint16 subtype;
	FlapFrame *frame;
};

struct _FlapFrame
{
	guint8 channel;
	guint16 seqnum;
	ByteStream data;        /* payload stream */
};

struct _FlapConnection
{
	OscarData *od;              /**< Pointer to parent session. */
	gboolean connected;
	time_t lastactivity;             /**< Time of last transmit. */
	guint destroy_timeout;
	OscarDisconnectReason disconnect_reason;
	gchar *error_message;
	guint16 disconnect_code;

	/* A few variables that are only used when connecting */
	PurpleProxyConnectData *connect_data;
	guint16 cookielen;
	guint8 *cookie;
	gpointer new_conn_data;

	int fd;
	PurpleSslConnection *gsc;
	guint8 header[6];
	gssize header_received;
	FlapFrame buffer_incoming;
	PurpleCircBuffer *buffer_outgoing;
	guint watcher_incoming;
	guint watcher_outgoing;

	guint16 type;
	guint16 subtype;
	guint16 seqnum_out; /**< The sequence number of most recently sent packet. */
	guint16 seqnum_in; /**< The sequence number of most recently received packet. */
	GSList *groups;
	GSList *rateclasses; /* Contains nodes of struct rateclass. */
	struct rateclass *default_rateclass;
	GHashTable *rateclass_members; /* Key is family and subtype, value is pointer to the rateclass struct to use. */

	GQueue *queued_snacs; /**< Contains QueuedSnacs. */
	GQueue *queued_lowpriority_snacs; /**< Contains QueuedSnacs to send only once queued_snacs is empty */
	guint queued_timeout;

	void *internal; /* internal conn-specific libfaim data */
};

struct _IcbmCookie
{
	guchar cookie[8];
	int type;
	void *data;
	time_t addtime;
	struct _IcbmCookie *next;
};

#include "peer.h"

/*
 * AIM Session: The main client-data interface.
 *
 */
struct _OscarData
{
	/** Only used when connecting with clientLogin */
	PurpleUtilFetchUrlData *url_data;

	gboolean iconconnecting;
	gboolean set_icon;

	GSList *create_rooms;

	gboolean conf;
	gboolean reqemail;
	gboolean setemail;
	char *email;
	gboolean setnick;
	char *newformatting;
	gboolean chpass;
	char *oldp;
	char *newp;

	GSList *oscar_chats;
	GHashTable *buddyinfo;
	GSList *requesticon;

	gboolean use_ssl;
	gboolean icq;
	guint getblisttimer;

	struct {
		guint maxwatchers; /* max users who can watch you */
		guint maxbuddies; /* max users you can watch */
		guint maxgroups; /* max groups in server list */
		guint maxpermits; /* max users on permit list */
		guint maxdenies; /* max users on deny list */
		guint maxsiglen; /* max size (bytes) of profile */
		guint maxawaymsglen; /* max size (bytes) of posted away message */
	} rights;

	PurpleConnection *gc;

	void *modlistv;

	/*
	 * Outstanding snac handling
	 *
	 * TODO: Should these be per-connection? -mid
	 */
	void *snac_hash[FAIM_SNAC_HASH_SIZE];
	aim_snacid_t snacid_next;

	/*
	 * TODO: Data specific to a certain family should go into a
	 *       hashtable and the core parts of libfaim shouldn't
	 *       need to know about them.
	 */

	IcbmCookie *msgcookies;
	struct aim_icq_info *icq_info;

	/** Only used when connecting with the old-style BUCP login. */
	struct aim_authresp_info *authinfo;
	struct aim_emailinfo *emailinfo;

	struct {
		struct aim_userinfo_s *userinfo;
	} locate;

	struct {
		gboolean have_rights;
	} bos;

	/* Server-stored information (ssi) */
	struct {
		gboolean received_data;
		guint16 numitems;
		struct aim_ssi_item *official;
		struct aim_ssi_item *local;
		struct aim_ssi_tmp *pending;
		time_t timestamp;
		gboolean waiting_for_ack;
		gboolean in_transaction;
	} ssi;

	/** Contains pointers to handler functions for each family/subtype. */
	GHashTable *handlerlist;

	/** A linked list containing FlapConnections. */
	GSList *oscar_connections;
	guint16 default_port;

	/** A linked list containing PeerConnections. */
	GSList *peer_connections;
};

/* Valid for calling aim_icq_setstatus() and for aim_userinfo_t->icqinfo.status */
#define AIM_ICQ_STATE_NORMAL            0x00000000
#define AIM_ICQ_STATE_AWAY              0x00000001
#define AIM_ICQ_STATE_DND               0x00000002
#define AIM_ICQ_STATE_OUT               0x00000004
#define AIM_ICQ_STATE_BUSY              0x00000010
#define AIM_ICQ_STATE_CHAT              0x00000020
#define AIM_ICQ_STATE_INVISIBLE         0x00000100
#define AIM_ICQ_STATE_EVIL              0x00003000
#define AIM_ICQ_STATE_DEPRESSION        0x00004000
#define AIM_ICQ_STATE_ATHOME            0x00005000
#define AIM_ICQ_STATE_ATWORK            0x00006000
#define AIM_ICQ_STATE_LUNCH             0x00002001
#define AIM_ICQ_STATE_EVIL              0x00003000
#define AIM_ICQ_STATE_WEBAWARE          0x00010000
#define AIM_ICQ_STATE_HIDEIP            0x00020000
#define AIM_ICQ_STATE_BIRTHDAY          0x00080000
#define AIM_ICQ_STATE_DIRECTDISABLED    0x00100000
#define AIM_ICQ_STATE_ICQHOMEPAGE       0x00200000
#define AIM_ICQ_STATE_DIRECTREQUIREAUTH 0x10000000
#define AIM_ICQ_STATE_DIRECTCONTACTLIST 0x20000000

/**
 * Only used when connecting with the old-style BUCP login.
 */
struct aim_clientrelease
{
	char *name;
	guint32 build;
	char *url;
	char *info;
};

/**
 * Only used when connecting with the old-style BUCP login.
 */
struct aim_authresp_info
{
	char *bn;
	guint16 errorcode;
	char *errorurl;
	guint16 regstatus;
	char *email;
	char *bosip;
	guint16 cookielen;
	guint8 *cookie;
	char *chpassurl;
	struct aim_clientrelease latestrelease;
	struct aim_clientrelease latestbeta;
};

/* Callback data for redirect. */
struct aim_redirect_data
{
	guint16 group;
	const char *ip;
	guint16 cookielen;
	const guint8 *cookie;
	const char *ssl_cert_cn;
	guint8 use_ssl;
	struct { /* group == SNAC_FAMILY_CHAT */
		guint16 exchange;
		const char *room;
		guint16 instance;
	} chat;
};

int oscar_connect_to_bos(PurpleConnection *gc, OscarData *od, const char *host, guint16 port, guint8 *cookie, guint16 cookielen, const char *tls_certname);

/* family_auth.c */

/**
 * Only used when connecting with the old-style BUCP login.
 */
int aim_request_login(OscarData *od, FlapConnection *conn, const char *bn);

/**
 * Only used when connecting with the old-style BUCP login.
 */
int aim_send_login(OscarData *od, FlapConnection *conn, const char *bn, const char *password, gboolean truncate_pass, ClientInfo *ci, const char *key, gboolean allow_multiple_logins);

/**
 * Only used when connecting with the old-style BUCP login.
 */
/* 0x000b */ int aim_auth_securid_send(OscarData *od, const char *securid);

/**
 * Only used when connecting with clientLogin.
 */
void send_client_login(OscarData *od, const char *username);

/* flap_connection.c */
FlapConnection *flap_connection_new(OscarData *, int type);
void flap_connection_close(OscarData *od, FlapConnection *conn);
void flap_connection_destroy(FlapConnection *conn, OscarDisconnectReason reason, const gchar *error_message);
void flap_connection_schedule_destroy(FlapConnection *conn, OscarDisconnectReason reason, const gchar *error_message);
FlapConnection *flap_connection_findbygroup(OscarData *od, guint16 group);
FlapConnection *flap_connection_getbytype(OscarData *, int type);
FlapConnection *flap_connection_getbytype_all(OscarData *, int type);
void flap_connection_recv_cb(gpointer data, gint source, PurpleInputCondition cond);
void flap_connection_recv_cb_ssl(gpointer data, PurpleSslConnection *gsc, PurpleInputCondition cond);

void flap_connection_send(FlapConnection *conn, FlapFrame *frame);
void flap_connection_send_version(OscarData *od, FlapConnection *conn);
void flap_connection_send_version_with_cookie(OscarData *od, FlapConnection *conn, guint16 length, const guint8 *chipsahoy);
void flap_connection_send_version_with_cookie_and_clientinfo(OscarData *od, FlapConnection *conn, guint16 length, const guint8 *chipsahoy, ClientInfo *ci, gboolean allow_multiple_login);
void flap_connection_send_snac(OscarData *od, FlapConnection *conn, guint16 family, const guint16 subtype, guint16 flags, aim_snacid_t snacid, ByteStream *data);
void flap_connection_send_snac_with_priority(OscarData *od, FlapConnection *conn, guint16 family, const guint16 subtype, guint16 flags, aim_snacid_t snacid, ByteStream *data, gboolean high_priority);
void flap_connection_send_keepalive(OscarData *od, FlapConnection *conn);
FlapFrame *flap_frame_new(OscarData *od, guint16 channel, int datalen);

/* oscar_data.c */
typedef int (*aim_rxcallback_t)(OscarData *od, FlapConnection *conn, FlapFrame *frame, ...);

OscarData *oscar_data_new(void);
void oscar_data_destroy(OscarData *);
void oscar_data_addhandler(OscarData *od, guint16 family, guint16 subtype, aim_rxcallback_t newhandler, guint16 flags);
aim_rxcallback_t aim_callhandler(OscarData *od, guint16 family, guint16 subtype);

/* misc.c */
#define AIM_VISIBILITYCHANGE_PERMITADD    0x05
#define AIM_VISIBILITYCHANGE_PERMITREMOVE 0x06
#define AIM_VISIBILITYCHANGE_DENYADD      0x07
#define AIM_VISIBILITYCHANGE_DENYREMOVE   0x08

#define AIM_PRIVFLAGS_ALLOWIDLE           0x01
#define AIM_PRIVFLAGS_ALLOWMEMBERSINCE    0x02

#define AIM_WARN_ANON                     0x01



/* 0x0001 - family_oservice.c */
/* 0x0002 */ void aim_srv_clientready(OscarData *od, FlapConnection *conn);
/* 0x0004 */ void aim_srv_requestnew(OscarData *od, guint16 serviceid);
/* 0x0006 */ void aim_srv_reqrates(OscarData *od, FlapConnection *conn);
/* 0x0008 */ void aim_srv_rates_addparam(OscarData *od, FlapConnection *conn);
/* 0x0009 */ void aim_srv_rates_delparam(OscarData *od, FlapConnection *conn);
/* 0x000c */ void aim_srv_sendpauseack(OscarData *od, FlapConnection *conn);
/* 0x000e */ void aim_srv_reqpersonalinfo(OscarData *od, FlapConnection *conn);
/* 0x0011 */ void aim_srv_setidle(OscarData *od, guint32 idletime);
/* 0x0014 */ void aim_srv_setprivacyflags(OscarData *od, FlapConnection *conn, guint32);
/* 0x0016 */ void aim_srv_nop(OscarData *od, FlapConnection *conn);
/* 0x0017 */ void aim_srv_setversions(OscarData *od, FlapConnection *conn);
/* 0x001e */ int aim_srv_setextrainfo(OscarData *od, gboolean seticqstatus, guint32 icqstatus, gboolean setstatusmsg, const char *statusmsg, const char *itmsurl);


void aim_bos_reqrights(OscarData *od, FlapConnection *conn);
int aim_bos_changevisibility(OscarData *od, FlapConnection *conn, int, const char *);
void aim_bos_setgroupperm(OscarData *od, FlapConnection *conn, guint32 mask);



#define AIM_CLIENTTYPE_UNKNOWN  0x0000
#define AIM_CLIENTTYPE_MC       0x0001
#define AIM_CLIENTTYPE_WINAIM   0x0002
#define AIM_CLIENTTYPE_WINAIM41 0x0003
#define AIM_CLIENTTYPE_AOL_TOC  0x0004
guint16 aim_im_fingerprint(const guint8 *msghdr, int len);

#define AIM_RATE_CODE_CHANGE     0x0001
#define AIM_RATE_CODE_WARNING    0x0002
#define AIM_RATE_CODE_LIMIT      0x0003
#define AIM_RATE_CODE_CLEARLIMIT 0x0004
void aim_ads_requestads(OscarData *od, FlapConnection *conn);



/* family_icbm.c */
#define AIM_OFT_SUBTYPE_SEND_FILE	0x0001
#define AIM_OFT_SUBTYPE_SEND_DIR	0x0002
#define AIM_OFT_SUBTYPE_GET_FILE	0x0011
#define AIM_OFT_SUBTYPE_GET_LIST	0x0012

#define AIM_TRANSFER_DENY_NOTSUPPORTED	0x0000
#define AIM_TRANSFER_DENY_DECLINE	0x0001
#define AIM_TRANSFER_DENY_NOTACCEPTING	0x0002

#define AIM_IMPARAM_FLAG_CHANNEL_MSGS_ALLOWED   0x00000001
#define AIM_IMPARAM_FLAG_MISSED_CALLS_ENABLED   0x00000002
#define AIM_IMPARAM_FLAG_EVENTS_ALLOWED         0x00000008
#define AIM_IMPARAM_FLAG_SMS_SUPPORTED          0x00000010
#define AIM_IMPARAM_FLAG_OFFLINE_MSGS_ALLOWED   0x00000100

/**
 * This flag tells the server that we always send HTML in messages
 * sent from an ICQ account to an ICQ account.  (If this flag is
 * not sent then plaintext is sent ICQ<-->ICQ (HTML is sent in all
 * other cases)).
 *
 * If we send an HTML message to an old client that doesn't support
 * HTML messages, then the oscar servers will merrily strip the HTML
 * for us.
 *
 * All incoming IMs are treated as HTML.
 */
#define AIM_IMPARAM_FLAG_USE_HTML_FOR_ICQ       0x00000400

/* This is what the server will give you if you don't set them yourself. */
/* This is probably out of date. */
#define AIM_IMPARAM_DEFAULTS { \
	0, \
	AIM_IMPARAM_FLAG_CHANNEL_MSGS_ALLOWED | AIM_IMPARAM_FLAG_MISSED_CALLS_ENABLED, \
	512, /* !! Note how small this is. */ \
	(99.9)*10, (99.9)*10, \
	1000 /* !! And how large this is. */ \
}

/* This is what most AIM versions use. */
/* This is probably out of date. */
#define AIM_IMPARAM_REASONABLE { \
	0, \
	AIM_IMPARAM_FLAG_CHANNEL_MSGS_ALLOWED | AIM_IMPARAM_FLAG_MISSED_CALLS_ENABLED, \
	8000, \
	(99.9)*10, (99.9)*10, \
	0 \
}

struct aim_icbmparameters
{
	guint16 maxchan;
	guint32 flags; /* AIM_IMPARAM_FLAG_ */
	guint16 maxmsglen; /* message size that you will accept */
	guint16 maxsenderwarn; /* this and below are *10 (999=99.9%) */
	guint16 maxrecverwarn;
	guint32 minmsginterval; /* in milliseconds? */
};

/*
 * TODO: Should probably combine this with struct chat_connection.
 */
struct aim_chat_roominfo
{
	guint16 exchange;
	char *name;
	guint8 namelen;
	guint16 instance;
};

struct chat_connection
{
	char *name;
	char *show; /* AOL did something funny to us */
	guint16 exchange;
	guint16 instance;
	FlapConnection *conn;
	int id;
	PurpleConnection *gc;
	PurpleConversation *conv;
	int maxlen;
	int maxvis;
};

/*
 * All this chat struct stuff should be in family_chat.c
 */
void oscar_chat_destroy(struct chat_connection *cc);

#define AIM_IMFLAGS_AWAY				0x0001 /* mark as an autoreply */
#define AIM_IMFLAGS_ACK					0x0002 /* request a receipt notice */
#define AIM_IMFLAGS_BUDDYREQ			0x0010 /* buddy icon requested */
#define AIM_IMFLAGS_HASICON				0x0020 /* already has icon */
#define AIM_IMFLAGS_SUBENC_MACINTOSH	0x0040 /* damn that Steve Jobs! */
#define AIM_IMFLAGS_CUSTOMFEATURES		0x0080 /* features field present */
#define AIM_IMFLAGS_EXTDATA				0x0100
#define AIM_IMFLAGS_X					0x0200
#define AIM_IMFLAGS_MULTIPART			0x0400 /* ->mpmsg section valid */
#define AIM_IMFLAGS_OFFLINE				0x0800 /* send to offline user */
#define AIM_IMFLAGS_TYPINGNOT			0x1000 /* typing notification */

#define AIM_CHARSET_ASCII   0x0000 /* ISO 646 */
#define AIM_CHARSET_UNICODE 0x0002 /* ISO 10646 (UTF-16/UCS-2BE) */
#define AIM_CHARSET_LATIN_1 0x0003 /* ISO 8859-1 */

/*
 * Multipart message structures.
 */
typedef struct aim_mpmsg_section_s
{
	guint16 charset;
	guint16 charsubset;
	gchar *data;
	guint16 datalen;
	struct aim_mpmsg_section_s *next;
} aim_mpmsg_section_t;

typedef struct aim_mpmsg_s
{
	unsigned int numparts;
	aim_mpmsg_section_t *parts;
} aim_mpmsg_t;

int aim_mpmsg_init(OscarData *od, aim_mpmsg_t *mpm);
int aim_mpmsg_addraw(OscarData *od, aim_mpmsg_t *mpm, guint16 charset, guint16 charsubset, const gchar *data, guint16 datalen);
int aim_mpmsg_addascii(OscarData *od, aim_mpmsg_t *mpm, const char *ascii);
int aim_mpmsg_addunicode(OscarData *od, aim_mpmsg_t *mpm, const guint16 *unicode, guint16 unicodelen);
void aim_mpmsg_free(OscarData *od, aim_mpmsg_t *mpm);

/*
 * Arguments to aim_send_im_ext().
 *
 * This is really complicated.  But immensely versatile.
 *
 */
struct aim_sendimext_args
{

	/* These are _required_ */
	const char *destbn;
	guint32 flags; /* often 0 */

	/* Only required if not using multipart messages */
	const char *msg;
	int msglen;

	/* Required if ->msg is not provided */
	aim_mpmsg_t *mpmsg;

	/* Only used if AIM_IMFLAGS_HASICON is set */
	guint32 iconlen;
	time_t iconstamp;
	guint32 iconsum;

	/* Only used if AIM_IMFLAGS_CUSTOMFEATURES is set */
	guint16 featureslen;
	guint8 *features;

	/* Only used if AIM_IMFLAGS_CUSTOMCHARSET is set and mpmsg not used */
	guint16 charset;
	guint16 charsubset;
};

/*
 * Arguments to aim_send_rtfmsg().
 */
struct aim_sendrtfmsg_args
{
	const char *destbn;
	guint32 fgcolor;
	guint32 bgcolor;
	const char *rtfmsg; /* must be in RTF */
};

/*
 * This information is provided in the Incoming ICBM callback for
 * Channel 1 ICBM's.
 *
 * Note that although CUSTOMFEATURES and CUSTOMCHARSET say they
 * are optional, both are always set by the current libfaim code.
 * That may or may not change in the future.  It is mainly for
 * consistency with aim_sendimext_args.
 *
 * Multipart messages require some explanation. If you want to use them,
 * I suggest you read all the comments in family_icbm.c.
 *
 */
struct aim_incomingim_ch1_args
{

	/* Always provided */
	aim_mpmsg_t mpmsg;
	guint32 icbmflags; /* some flags apply only to ->msg, not all mpmsg */
	time_t timestamp; /* Only set for offline messages */

	/* Only provided if message has a human-readable section */
	gchar *msg;
	int msglen;

	/* Only provided if AIM_IMFLAGS_HASICON is set */
	time_t iconstamp;
	guint32 iconlen;
	guint16 iconsum;

	/* Only provided if AIM_IMFLAGS_CUSTOMFEATURES is set */
	guint8 *features;
	guint8 featureslen;

	/* Only provided if AIM_IMFLAGS_EXTDATA is set */
	guint8 extdatalen;
	guint8 *extdata;

	/* Only used if AIM_IMFLAGS_CUSTOMCHARSET is set */
	guint16 charset;
	guint16 charsubset;
};

/* Valid values for channel 2 args->status */
#define AIM_RENDEZVOUS_PROPOSE   0x0000
#define AIM_RENDEZVOUS_CANCEL    0x0001
#define AIM_RENDEZVOUS_CONNECTED 0x0002

struct _IcbmArgsCh2
{
	guint16 status;
	guchar cookie[8];
	guint64 type; /* One of the OSCAR_CAPABILITY_ constants */
	const char *proxyip;
	const char *clientip;
	const char *verifiedip;
	guint16 port;
	gboolean use_proxy;
	guint16 errorcode;
	const char *msg; /* invite message or file description */
	guint16 msglen;
	const char *encoding;
	const char *language;
	guint16 requestnumber;
	union {
		struct {
			guint32 checksum;
			guint32 length;
			time_t timestamp;
			guint8 *icon;
		} icon;
		struct {
			struct aim_chat_roominfo roominfo;
		} chat;
		struct {
			guint16 msgtype;
			guint32 fgcolor;
			guint32 bgcolor;
			const char *rtfmsg;
		} rtfmsg;
		struct {
			guint16 subtype;
			guint16 totfiles;
			guint32 totsize;
			char *filename;
		} sendfile;
	} info;
	void *destructor; /* used internally only */
};

/* Valid values for channel 4 args->type */
#define AIM_ICQMSG_AUTHREQUEST	0x0006
#define AIM_ICQMSG_AUTHDENIED	0x0007
#define AIM_ICQMSG_AUTHGRANTED	0x0008

struct aim_incomingim_ch4_args
{
	guint32 uin; /* Of the sender of the ICBM */
	guint8 type;
	guint8 flags;
	gchar *msg; /* Reason for auth request, deny, or accept */
	int msglen;
};

/* SNAC sending functions */
/* 0x0002 */ int aim_im_setparams(OscarData *od, struct aim_icbmparameters *params);
/* 0x0004 */ int aim_im_reqparams(OscarData *od);
/* 0x0006 */ int aim_im_sendch1_ext(OscarData *od, struct aim_sendimext_args *args);
/* 0x0006 */ int aim_im_sendch1(OscarData *, const char *destbn, guint16 flags, const char *msg);
/* 0x0006 */ int aim_im_sendch2_chatinvite(OscarData *od, const char *bn, const char *msg, guint16 exchange, const char *roomname, guint16 instance);
/* 0x0006 */ int aim_im_sendch2_icon(OscarData *od, const char *bn, const guint8 *icon, int iconlen, time_t stamp, guint16 iconsum);
/* 0x0006 */ int aim_im_sendch2_rtfmsg(OscarData *od, struct aim_sendrtfmsg_args *args);

/* 0x0006 */ void aim_im_sendch2_cancel(PeerConnection *peer_conn);
/* 0x0006 */ void aim_im_sendch2_connected(PeerConnection *peer_conn);
/* 0x0006 */ void aim_im_sendch2_odc_requestdirect(OscarData *od, guchar *cookie, const char *bn, const guint8 *ip, guint16 port, guint16 requestnumber);
/* 0x0006 */ void aim_im_sendch2_odc_requestproxy(OscarData *od, guchar *cookie, const char *bn, const guint8 *ip, guint16 pin, guint16 requestnumber);
/* 0x0006 */ void aim_im_sendch2_sendfile_requestdirect(OscarData *od, guchar *cookie, const char *bn, const guint8 *ip, guint16 port, guint16 requestnumber, const gchar *filename, guint32 size, guint16 numfiles);
/* 0x0006 */ void aim_im_sendch2_sendfile_requestproxy(OscarData *od, guchar *cookie, const char *bn, const guint8 *ip, guint16 pin, guint16 requestnumber, const gchar *filename, guint32 size, guint16 numfiles);

/* 0x0006 */ int aim_im_sendch2_geticqaway(OscarData *od, const char *bn, int type);
/* 0x0006 */ int aim_im_sendch4(OscarData *od, const char *bn, guint16 type, const char *message);
/* 0x0008 */ int aim_im_warn(OscarData *od, FlapConnection *conn, const char *destbn, guint32 flags);
/* 0x000b */ int aim_im_denytransfer(OscarData *od, const char *bn, const guchar *cookie, guint16 code);
/* 0x0010 */ int aim_im_reqofflinemsgs(OscarData *od);
/* 0x0014 */ int aim_im_sendmtn(OscarData *od, guint16 type1, const char *bn, guint16 type2);
/* 0x000b */ int icq_relay_xstatus (OscarData *od, const char *sn, const guchar* cookie);
void aim_icbm_makecookie(guchar* cookie);
gchar *oscar_encoding_extract(const char *encoding);
gchar *oscar_encoding_to_utf8(PurpleAccount *account, const char *encoding, const char *text, int textlen);
gchar *purple_plugin_oscar_decode_im_part(PurpleAccount *account, const char *sourcebn, guint16 charset, guint16 charsubset, const gchar *data, gsize datalen);


/* 0x0002 - family_locate.c */
/*
 * AIM User Info, Standard Form.
 */
#define AIM_FLAG_UNCONFIRMED     0x0001 /* "damned transients" */
#define AIM_FLAG_ADMINISTRATOR   0x0002
#define AIM_FLAG_AOL             0x0004
#define AIM_FLAG_OSCAR_PAY       0x0008
#define AIM_FLAG_FREE            0x0010
#define AIM_FLAG_AWAY            0x0020
#define AIM_FLAG_ICQ             0x0040
#define AIM_FLAG_WIRELESS        0x0080
#define AIM_FLAG_UNKNOWN100      0x0100
#define AIM_FLAG_IMFORWARDING    0x0200
#define AIM_FLAG_ACTIVEBUDDY     0x0400
#define AIM_FLAG_UNKNOWN800      0x0800
#define AIM_FLAG_ONEWAYWIRELESS  0x1000
#define AIM_FLAG_NOKNOCKKNOCK    0x00040000
#define AIM_FLAG_FORWARD_MOBILE  0x00080000

#define AIM_USERINFO_PRESENT_FLAGS        0x00000001
#define AIM_USERINFO_PRESENT_MEMBERSINCE  0x00000002
#define AIM_USERINFO_PRESENT_ONLINESINCE  0x00000004
#define AIM_USERINFO_PRESENT_IDLE         0x00000008
#define AIM_USERINFO_PRESENT_ICQEXTSTATUS 0x00000010
#define AIM_USERINFO_PRESENT_ICQIPADDR    0x00000020
#define AIM_USERINFO_PRESENT_ICQDATA      0x00000040
#define AIM_USERINFO_PRESENT_CAPABILITIES 0x00000080
#define AIM_USERINFO_PRESENT_SESSIONLEN   0x00000100
#define AIM_USERINFO_PRESENT_CREATETIME   0x00000200

struct userinfo_node
{
	char *bn;
	struct userinfo_node *next;
};

typedef struct aim_userinfo_s
{
	char *bn;
	guint16 warnlevel; /* evil percent * 10 (999 = 99.9%) */
	guint16 idletime; /* in seconds */
	guint16 flags;
	guint32 createtime; /* time_t */
	guint32 membersince; /* time_t */
	guint32 onlinesince; /* time_t */
	guint32 sessionlen;  /* in seconds */
	guint64 capabilities;
	struct {
		guint32 status;
		guint32 ipaddr;
		guint8 crap[0x25]; /* until we figure it out... */
	} icqinfo;
	guint32 present;

	guint8 iconcsumtype;
	guint16 iconcsumlen;
	guint8 *iconcsum;

	char *info;
	char *info_encoding;
	guint16 info_len;

	char *status;
	char *status_encoding;
	guint16 status_len;

	char *itmsurl;
	char *itmsurl_encoding;
	guint16 itmsurl_len;

	char *away;
	char *away_encoding;
	guint16 away_len;

	struct aim_userinfo_s *next;
} aim_userinfo_t;

#define AIM_SENDMEMBLOCK_FLAG_ISREQUEST  0
#define AIM_SENDMEMBLOCK_FLAG_ISHASH     1

int aim_sendmemblock(OscarData *od, FlapConnection *conn, guint32 offset, guint32 len, const guint8 *buf, guint8 flag);

struct aim_invite_priv
{
	char *bn;
	char *roomname;
	guint16 exchange;
	guint16 instance;
};

#define AIM_COOKIETYPE_UNKNOWN  0x00
#define AIM_COOKIETYPE_ICBM     0x01
#define AIM_COOKIETYPE_ADS      0x02
#define AIM_COOKIETYPE_BOS      0x03
#define AIM_COOKIETYPE_IM       0x04
#define AIM_COOKIETYPE_CHAT     0x05
#define AIM_COOKIETYPE_CHATNAV  0x06
#define AIM_COOKIETYPE_INVITE   0x07
/* we'll move OFT up a bit to give breathing room.  not like it really
 * matters. */
#define AIM_COOKIETYPE_OFTIM    0x10
#define AIM_COOKIETYPE_OFTGET   0x11
#define AIM_COOKIETYPE_OFTSEND  0x12
#define AIM_COOKIETYPE_OFTVOICE 0x13
#define AIM_COOKIETYPE_OFTIMAGE 0x14
#define AIM_COOKIETYPE_OFTICON  0x15

aim_userinfo_t *aim_locate_finduserinfo(OscarData *od, const char *bn);
void aim_locate_dorequest(OscarData *od);

/* 0x0002 */ int aim_locate_reqrights(OscarData *od);
/* 0x0004 */ int aim_locate_setcaps(OscarData *od, guint64 caps);
/* 0x0004 */ int aim_locate_setprofile(OscarData *od, const char *profile_encoding, const gchar *profile, const int profile_len, const char *awaymsg_encoding, const gchar *awaymsg, const int awaymsg_len);
/* 0x0005 */ int aim_locate_getinfo(OscarData *od, const char *, guint16);
/* 0x0009 */ int aim_locate_setdirinfo(OscarData *od, const char *first, const char *middle, const char *last, const char *maiden, const char *nickname, const char *street, const char *city, const char *state, const char *zip, int country, guint16 privacy);
/* 0x000b */ int aim_locate_000b(OscarData *od, const char *bn);
/* 0x000f */ int aim_locate_setinterests(OscarData *od, const char *interest1, const char *interest2, const char *interest3, const char *interest4, const char *interest5, guint16 privacy);
/* 0x0015 */ int aim_locate_getinfoshort(OscarData *od, const char *bn, guint32 flags);

guint64 aim_locate_getcaps(OscarData *od, ByteStream *bs, int len);
guint64 aim_locate_getcaps_short(OscarData *od, ByteStream *bs, int len);
void aim_info_free(aim_userinfo_t *);
int aim_info_extract(OscarData *od, ByteStream *bs, aim_userinfo_t *);
int aim_putuserinfo(ByteStream *bs, aim_userinfo_t *info);
PurpleMood* icq_get_purple_moods(PurpleAccount *account);
const char* icq_get_custom_icon_description(const char *mood);
guint8* icq_get_custom_icon_data(const char *mood);
int icq_im_xstatus_request(OscarData *od, const char *sn);

/* 0x0003 - family_buddy.c */
/* 0x0002 */ void aim_buddylist_reqrights(OscarData *, FlapConnection *);
/* 0x0004 */ int aim_buddylist_set(OscarData *, FlapConnection *, const char *);
/* 0x0004 */ int aim_buddylist_addbuddy(OscarData *, FlapConnection *, const char *);
/* 0x0005 */ int aim_buddylist_removebuddy(OscarData *, FlapConnection *, const char *);



/* 0x000a - family_userlookup.c */
int aim_search_address(OscarData *, const char *);



/* 0x000d - family_chatnav.c */
/* 0x000e - family_chat.c */
/* These apply to exchanges as well. */
#define AIM_CHATROOM_FLAG_EVILABLE 0x0001
#define AIM_CHATROOM_FLAG_NAV_ONLY 0x0002
#define AIM_CHATROOM_FLAG_INSTANCING_ALLOWED 0x0004
#define AIM_CHATROOM_FLAG_OCCUPANT_PEEK_ALLOWED 0x0008

struct aim_chat_exchangeinfo
{
	guint16 number;
	guint16 flags;
	char *name;
	char *charset1;
	char *lang1;
	char *charset2;
	char *lang2;
};

#define AIM_CHATFLAGS_NOREFLECT 0x0001
#define AIM_CHATFLAGS_AWAY      0x0002
int aim_chat_send_im(OscarData *od, FlapConnection *conn, guint16 flags, const gchar *msg, int msglen, const char *encoding, const char *language);
int aim_chat_join(OscarData *od, guint16 exchange, const char *roomname, guint16 instance);
int aim_chat_attachname(FlapConnection *conn, guint16 exchange, const char *roomname, guint16 instance);
char *aim_chat_getname(FlapConnection *conn);
FlapConnection *aim_chat_getconn(OscarData *, const char *name);

void aim_chatnav_reqrights(OscarData *od, FlapConnection *conn);

int aim_chatnav_createroom(OscarData *od, FlapConnection *conn, const char *name, guint16 exchange);
int aim_chat_leaveroom(OscarData *od, const char *name);



/* 0x000f - family_odir.c */
struct aim_odir
{
	char *first;
	char *last;
	char *middle;
	char *maiden;
	char *email;
	char *country;
	char *state;
	char *city;
	char *bn;
	char *interest;
	char *nick;
	char *zip;
	char *region;
	char *address;
	struct aim_odir *next;
};

int aim_odir_email(OscarData *, const char *, const char *);
int aim_odir_name(OscarData *, const char *, const char *, const char *, const char *, const char *, const char *, const char *, const char *, const char *, const char *, const char *);
int aim_odir_interest(OscarData *, const char *, const char *);



/* 0x0010 - family_bart.c */
int aim_bart_upload(OscarData *od, const guint8 *icon, guint16 iconlen);
int aim_bart_request(OscarData *od, const char *bn, guint8 iconcsumtype, const guint8 *iconstr, guint16 iconstrlen);



/* 0x0013 - family_feedbag.c */
#define AIM_SSI_TYPE_BUDDY		0x0000
#define AIM_SSI_TYPE_GROUP		0x0001
#define AIM_SSI_TYPE_PERMIT		0x0002
#define AIM_SSI_TYPE_DENY		0x0003
#define AIM_SSI_TYPE_PDINFO		0x0004
#define AIM_SSI_TYPE_PRESENCEPREFS	0x0005
#define AIM_SSI_TYPE_ICONINFO		0x0014

#define AIM_SSI_ACK_SUCCESS		0x0000
#define AIM_SSI_ACK_ITEMNOTFOUND	0x0002
#define AIM_SSI_ACK_IDNUMINUSE		0x000a
#define AIM_SSI_ACK_ATMAX		0x000c
#define AIM_SSI_ACK_INVALIDNAME		0x000d
#define AIM_SSI_ACK_AUTHREQUIRED	0x000e

/* These flags are set in the 0x00c9 TLV of SSI type 0x0005 */
#define AIM_SSI_PRESENCE_FLAG_SHOWIDLE        0x00000400
#define AIM_SSI_PRESENCE_FLAG_NORECENTBUDDIES 0x00020000

struct aim_ssi_item
{
	char *name;
	guint16 gid;
	guint16 bid;
	guint16 type;
	GSList *data;
	struct aim_ssi_item *next;
};

struct aim_ssi_tmp
{
	guint16 action;
	guint16 ack;
	char *name;
	struct aim_ssi_item *item;
	struct aim_ssi_tmp *next;
};

/* These build the actual SNACs and queue them to be sent */
/* 0x0002 */ int aim_ssi_reqrights(OscarData *od);
/* 0x0004 */ int aim_ssi_reqdata(OscarData *od);
/* 0x0005 */ int aim_ssi_reqifchanged(OscarData *od, time_t localstamp, guint16 localrev);
/* 0x0007 */ int aim_ssi_enable(OscarData *od);
/* 0x0011 */ int aim_ssi_modbegin(OscarData *od);
/* 0x0012 */ int aim_ssi_modend(OscarData *od);
/* 0x0014 */ int aim_ssi_sendauth(OscarData *od, char *bn, char *msg);
/* 0x0018 */ int aim_ssi_sendauthrequest(OscarData *od, char *bn, const char *msg);
/* 0x001a */ int aim_ssi_sendauthreply(OscarData *od, char *bn, guint8 reply, const char *msg);

/* Client functions for retrieving SSI data */
struct aim_ssi_item *aim_ssi_itemlist_find(struct aim_ssi_item *list, guint16 gid, guint16 bid);
struct aim_ssi_item *aim_ssi_itemlist_finditem(struct aim_ssi_item *list, const char *gn, const char *bn, guint16 type);
struct aim_ssi_item *aim_ssi_itemlist_exists(struct aim_ssi_item *list, const char *bn);
char *aim_ssi_itemlist_findparentname(struct aim_ssi_item *list, const char *bn);
int aim_ssi_getpermdeny(struct aim_ssi_item *list);
guint32 aim_ssi_getpresence(struct aim_ssi_item *list);
char *aim_ssi_getalias(struct aim_ssi_item *list, const char *gn, const char *bn);
char *aim_ssi_getcomment(struct aim_ssi_item *list, const char *gn, const char *bn);
gboolean aim_ssi_waitingforauth(struct aim_ssi_item *list, const char *gn, const char *bn);

/* Client functions for changing SSI data */
int aim_ssi_addbuddy(OscarData *od, const char *name, const char *group, GSList *tlvlist, const char *alias, const char *comment, const char *smsnum, gboolean needauth);
int aim_ssi_addpermit(OscarData *od, const char *name);
int aim_ssi_adddeny(OscarData *od, const char *name);
int aim_ssi_delbuddy(OscarData *od, const char *name, const char *group);
int aim_ssi_delgroup(OscarData *od, const char *group);
int aim_ssi_delpermit(OscarData *od, const char *name);
int aim_ssi_deldeny(OscarData *od, const char *name);
int aim_ssi_movebuddy(OscarData *od, const char *oldgn, const char *newgn, const char *bn);
int aim_ssi_aliasbuddy(OscarData *od, const char *gn, const char *bn, const char *alias);
int aim_ssi_editcomment(OscarData *od, const char *gn, const char *bn, const char *alias);
int aim_ssi_rename_group(OscarData *od, const char *oldgn, const char *newgn);
int aim_ssi_cleanlist(OscarData *od);
int aim_ssi_deletelist(OscarData *od);
int aim_ssi_setpermdeny(OscarData *od, guint8 permdeny, guint32 vismask);
int aim_ssi_setpresence(OscarData *od, guint32 presence);
int aim_ssi_seticon(OscarData *od, const guint8 *iconsum, guint8 iconsumlen);
int aim_ssi_delicon(OscarData *od);



/* 0x0015 - family_icq.c */
#define AIM_ICQ_INFO_SIMPLE	0x001
#define AIM_ICQ_INFO_SUMMARY	0x002
#define AIM_ICQ_INFO_EMAIL	0x004
#define AIM_ICQ_INFO_PERSONAL	0x008
#define AIM_ICQ_INFO_ADDITIONAL	0x010
#define AIM_ICQ_INFO_WORK	0x020
#define AIM_ICQ_INFO_INTERESTS	0x040
#define AIM_ICQ_INFO_ORGS	0x080
#define AIM_ICQ_INFO_UNKNOWN	0x100
#define AIM_ICQ_INFO_HAVEALL	0x1ff

#ifdef OLDSTYLE_ICQ_OFFLINEMSGS
struct aim_icq_offlinemsg
{
	guint32 sender;
	guint16 year;
	guint8 month, day, hour, minute;
	guint8 type;
	guint8 flags;
	char *msg;
	int msglen;
};
#endif /* OLDSTYLE_ICQ_OFFLINEMSGS */

struct aim_icq_info
{
	guint16 reqid;

	/* simple */
	guint32 uin;

	/* general and "home" information (0x00c8) */
	char *nick;
	char *first;
	char *last;
	char *email;
	char *homecity;
	char *homestate;
	char *homephone;
	char *homefax;
	char *homeaddr;
	char *mobile;
	char *homezip;
	guint16 homecountry;
/*	guint8 timezone;
	guint8 hideemail; */

	/* personal (0x00dc) */
	guint8 age;
	guint8 unknown;
	guint8 gender;
	char *personalwebpage;
	guint16 birthyear;
	guint8 birthmonth;
	guint8 birthday;
	guint8 language1;
	guint8 language2;
	guint8 language3;

	/* work (0x00d2) */
	char *workcity;
	char *workstate;
	char *workphone;
	char *workfax;
	char *workaddr;
	char *workzip;
	guint16 workcountry;
	char *workcompany;
	char *workdivision;
	char *workposition;
	char *workwebpage;

	/* additional personal information (0x00e6) */
	char *info;

	/* email (0x00eb) */
	guint16 numaddresses;
	char **email2;

	/* we keep track of these in a linked list because we're 1337 */
	struct aim_icq_info *next;

	/* status note info */
	guint8 icbm_cookie[8];
	char *status_note_title;
};

#ifdef OLDSTYLE_ICQ_OFFLINEMSGS
int aim_icq_reqofflinemsgs(OscarData *od);
int aim_icq_ackofflinemsgs(OscarData *od);
#endif
int aim_icq_setsecurity(OscarData *od, gboolean auth_required, gboolean webaware);
int aim_icq_changepasswd(OscarData *od, const char *passwd);
int aim_icq_getsimpleinfo(OscarData *od, const char *uin);
int aim_icq_getalias(OscarData *od, const char *uin);
int aim_icq_getallinfo(OscarData *od, const char *uin);
int aim_icq_sendsms(OscarData *od, const char *name, const char *msg, const char *alias);


/* 0x0017 - family_auth.c */
void aim_sendcookie(OscarData *, FlapConnection *, const guint16 length, const guint8 *);
void aim_admin_changepasswd(OscarData *, FlapConnection *, const char *newpw, const char *curpw);
void aim_admin_reqconfirm(OscarData *od, FlapConnection *conn);
void aim_admin_getinfo(OscarData *od, FlapConnection *conn, guint16 info);
void aim_admin_setemail(OscarData *od, FlapConnection *conn, const char *newemail);
void aim_admin_setnick(OscarData *od, FlapConnection *conn, const char *newnick);



/* 0x0018 - family_alert.c */
struct aim_emailinfo
{
	guint8 *cookie16;
	guint8 *cookie8;
	char *url;
	guint16 nummsgs;
	guint8 unread;
	char *domain;
	guint16 flag;
	struct aim_emailinfo *next;
};

int aim_email_sendcookies(OscarData *od);
int aim_email_activate(OscarData *od);



/* tlv.c - TLV handling */

/* TLV structure */
typedef struct aim_tlv_s
{
	guint16 type;
	guint16 length;
	guint8 *value;
} aim_tlv_t;

/* TLV handling functions */
char *aim_tlv_getvalue_as_string(aim_tlv_t *tlv);

aim_tlv_t *aim_tlv_gettlv(GSList *list, const guint16 type, const int nth);
int aim_tlv_getlength(GSList *list, const guint16 type, const int nth);
char *aim_tlv_getstr(GSList *list, const guint16 type, const int nth);
guint8 aim_tlv_get8(GSList *list, const guint16 type, const int nth);
guint16 aim_tlv_get16(GSList *list, const guint16 type, const int nth);
guint32 aim_tlv_get32(GSList *list, const guint16 type, const int nth);

/* TLV list handling functions */
GSList *aim_tlvlist_read(ByteStream *bs);
GSList *aim_tlvlist_readnum(ByteStream *bs, guint16 num);
GSList *aim_tlvlist_readlen(ByteStream *bs, guint16 len);
GSList *aim_tlvlist_copy(GSList *orig);

int aim_tlvlist_count(GSList *list);
int aim_tlvlist_size(GSList *list);
int aim_tlvlist_cmp(GSList *one, GSList *two);
int aim_tlvlist_write(ByteStream *bs, GSList **list);
void aim_tlvlist_free(GSList *list);

int aim_tlvlist_add_raw(GSList **list, const guint16 type, const guint16 length, const guint8 *value);
int aim_tlvlist_add_noval(GSList **list, const guint16 type);
int aim_tlvlist_add_8(GSList **list, const guint16 type, const guint8 value);
int aim_tlvlist_add_16(GSList **list, const guint16 type, const guint16 value);
int aim_tlvlist_add_32(GSList **list, const guint16 type, const guint32 value);
int aim_tlvlist_add_str(GSList **list, const guint16 type, const char *value);
int aim_tlvlist_add_caps(GSList **list, const guint16 type, const guint64 caps, const char *mood);
int aim_tlvlist_add_userinfo(GSList **list, guint16 type, aim_userinfo_t *userinfo);
int aim_tlvlist_add_chatroom(GSList **list, guint16 type, guint16 exchange, const char *roomname, guint16 instance);
int aim_tlvlist_add_frozentlvlist(GSList **list, guint16 type, GSList **tl);

int aim_tlvlist_replace_raw(GSList **list, const guint16 type, const guint16 lenth, const guint8 *value);
int aim_tlvlist_replace_str(GSList **list, const guint16 type, const char *str);
int aim_tlvlist_replace_noval(GSList **list, const guint16 type);
int aim_tlvlist_replace_8(GSList **list, const guint16 type, const guint8 value);
int aim_tlvlist_replace_16(GSList **list, const guint16 type, const guint16 value);
int aim_tlvlist_replace_32(GSList **list, const guint16 type, const guint32 value);

void aim_tlvlist_remove(GSList **list, const guint16 type);



/* util.c */
/* These are really ugly.  You'd think this was LISP.  I wish it was. */
#define aimutil_put8(buf, data) ((*(buf) = (guint8)(data)&0xff),1)
#define aimutil_get8(buf) ((*(buf))&0xff)
#define aimutil_put16(buf, data) ( \
		(*(buf) = (guint8)((data)>>8)&0xff), \
		(*((buf)+1) = (guint8)(data)&0xff),  \
		2)
#define aimutil_get16(buf) ((((*(buf))<<8)&0xff00) + ((*((buf)+1)) & 0xff))
#define aimutil_put32(buf, data) ( \
		(*((buf)) = (guint8)((data)>>24)&0xff), \
		(*((buf)+1) = (guint8)((data)>>16)&0xff), \
		(*((buf)+2) = (guint8)((data)>>8)&0xff), \
		(*((buf)+3) = (guint8)(data)&0xff), \
		4)
#define aimutil_get32(buf) ((((*(buf))<<24)&0xff000000) + \
		(((*((buf)+1))<<16)&0x00ff0000) + \
		(((*((buf)+2))<< 8)&0x0000ff00) + \
		(((*((buf)+3)    )&0x000000ff)))

/* Little-endian versions (damn ICQ) */
#define aimutil_putle8(buf, data) ( \
		(*(buf) = (guint8)(data) & 0xff), \
		1)
#define aimutil_getle8(buf) ( \
		(*(buf)) & 0xff \
		)
#define aimutil_putle16(buf, data) ( \
		(*((buf)+0) = (guint8)((data) >> 0) & 0xff),  \
		(*((buf)+1) = (guint8)((data) >> 8) & 0xff), \
		2)
#define aimutil_getle16(buf) ( \
		(((*((buf)+0)) << 0) & 0x00ff) + \
		(((*((buf)+1)) << 8) & 0xff00) \
		)
#define aimutil_putle32(buf, data) ( \
		(*((buf)+0) = (guint8)((data) >>  0) & 0xff), \
		(*((buf)+1) = (guint8)((data) >>  8) & 0xff), \
		(*((buf)+2) = (guint8)((data) >> 16) & 0xff), \
		(*((buf)+3) = (guint8)((data) >> 24) & 0xff), \
		4)
#define aimutil_getle32(buf) ( \
		(((*((buf)+0)) <<  0) & 0x000000ff) + \
		(((*((buf)+1)) <<  8) & 0x0000ff00) + \
		(((*((buf)+2)) << 16) & 0x00ff0000) + \
		(((*((buf)+3)) << 24) & 0xff000000))

int oscar_get_ui_info_int(const char *str, int default_value);
const char *oscar_get_ui_info_string(const char *str, const char *default_value);
gchar *oscar_get_clientstring(void);

guint16 aimutil_iconsum(const guint8 *buf, int buflen);
int aimutil_tokslen(char *toSearch, int theindex, char dl);
int aimutil_itemcnt(char *toSearch, char dl);
char *aimutil_itemindex(char *toSearch, int theindex, char dl);

gboolean oscar_util_valid_name(const char *bn);
gboolean oscar_util_valid_name_icq(const char *bn);
gboolean oscar_util_valid_name_sms(const char *bn);
int oscar_util_name_compare(const char *bn1, const char *bn2);




typedef struct {
	guint16 family;
	guint16 subtype;
	guint16 flags;
	guint32 id;
} aim_modsnac_t;

#define AIM_MODULENAME_MAXLEN 16
#define AIM_MODFLAG_MULTIFAMILY 0x0001
typedef struct aim_module_s
{
	guint16 family;
	guint16 version;
	guint16 toolid;
	guint16 toolversion;
	guint16 flags;
	char name[AIM_MODULENAME_MAXLEN+1];
	int (*snachandler)(OscarData *od, FlapConnection *conn, struct aim_module_s *mod, FlapFrame *rx, aim_modsnac_t *snac, ByteStream *bs);
	void (*shutdown)(OscarData *od, struct aim_module_s *mod);
	void *priv;
	struct aim_module_s *next;
} aim_module_t;

int aim__registermodule(OscarData *od, int (*modfirst)(OscarData *, aim_module_t *));
void aim__shutdownmodules(OscarData *od);
aim_module_t *aim__findmodulebygroup(OscarData *od, guint16 group);
aim_module_t *aim__findmodule(OscarData *od, const char *name);

int admin_modfirst(OscarData *od, aim_module_t *mod);
int buddylist_modfirst(OscarData *od, aim_module_t *mod);
int bos_modfirst(OscarData *od, aim_module_t *mod);
int search_modfirst(OscarData *od, aim_module_t *mod);
int stats_modfirst(OscarData *od, aim_module_t *mod);
int auth_modfirst(OscarData *od, aim_module_t *mod);
int msg_modfirst(OscarData *od, aim_module_t *mod);
int misc_modfirst(OscarData *od, aim_module_t *mod);
int chatnav_modfirst(OscarData *od, aim_module_t *mod);
int chat_modfirst(OscarData *od, aim_module_t *mod);
int locate_modfirst(OscarData *od, aim_module_t *mod);
int service_modfirst(OscarData *od, aim_module_t *mod);
int invite_modfirst(OscarData *od, aim_module_t *mod);
int translate_modfirst(OscarData *od, aim_module_t *mod);
int popups_modfirst(OscarData *od, aim_module_t *mod);
int adverts_modfirst(OscarData *od, aim_module_t *mod);
int odir_modfirst(OscarData *od, aim_module_t *mod);
int bart_modfirst(OscarData *od, aim_module_t *mod);
int ssi_modfirst(OscarData *od, aim_module_t *mod);
int icq_modfirst(OscarData *od, aim_module_t *mod);
int email_modfirst(OscarData *od, aim_module_t *mod);

void aim_genericreq_n(OscarData *od, FlapConnection *conn, guint16 family, guint16 subtype);
void aim_genericreq_n_snacid(OscarData *od, FlapConnection *conn, guint16 family, guint16 subtype);
void aim_genericreq_l(OscarData *od, FlapConnection *conn, guint16 family, guint16 subtype, guint32 *);
void aim_genericreq_s(OscarData *od, FlapConnection *conn, guint16 family, guint16 subtype, guint16 *);

/* bstream.c */
int byte_stream_new(ByteStream *bs, guint32 len);
int byte_stream_init(ByteStream *bs, guint8 *data, int len);
void byte_stream_destroy(ByteStream *bs);
int byte_stream_empty(ByteStream *bs);
int byte_stream_curpos(ByteStream *bs);
int byte_stream_setpos(ByteStream *bs, unsigned int off);
void byte_stream_rewind(ByteStream *bs);
int byte_stream_advance(ByteStream *bs, int n);
guint8 byte_stream_get8(ByteStream *bs);
guint16 byte_stream_get16(ByteStream *bs);
guint32 byte_stream_get32(ByteStream *bs);
guint8 byte_stream_getle8(ByteStream *bs);
guint16 byte_stream_getle16(ByteStream *bs);
guint32 byte_stream_getle32(ByteStream *bs);
int byte_stream_getrawbuf(ByteStream *bs, guint8 *buf, int len);
guint8 *byte_stream_getraw(ByteStream *bs, int len);
char *byte_stream_getstr(ByteStream *bs, int len);
int byte_stream_put8(ByteStream *bs, guint8 v);
int byte_stream_put16(ByteStream *bs, guint16 v);
int byte_stream_put32(ByteStream *bs, guint32 v);
int byte_stream_putle8(ByteStream *bs, guint8 v);
int byte_stream_putle16(ByteStream *bs, guint16 v);
int byte_stream_putle32(ByteStream *bs, guint32 v);
int byte_stream_putraw(ByteStream *bs, const guint8 *v, int len);
int byte_stream_putstr(ByteStream *bs, const char *str);
int byte_stream_putbs(ByteStream *bs, ByteStream *srcbs, int len);
int byte_stream_putuid(ByteStream *bs, OscarData *od);
int byte_stream_putcaps(ByteStream *bs, guint64 caps);

/**
 * Inserts a BART asset block into the given byte stream.  The flags
 * and length are set appropriately based on the value of data.
 */
void byte_stream_put_bart_asset(ByteStream *bs, guint16 type, ByteStream *data);

/**
 * A helper function that calls byte_stream_put_bart_asset with the
 * appropriate data ByteStream given the datastr.
 */
void byte_stream_put_bart_asset_str(ByteStream *bs, guint16 type, const char *datastr);

/*
 * Generic SNAC structure.  Rarely if ever used.
 */
typedef struct aim_snac_s {
	aim_snacid_t id;
	guint16 family;
	guint16 type;
	guint16 flags;
	void *data;
	time_t issuetime;
	struct aim_snac_s *next;
} aim_snac_t;

/* snac.c */
void aim_initsnachash(OscarData *od);
aim_snacid_t aim_newsnac(OscarData *, aim_snac_t *newsnac);
aim_snacid_t aim_cachesnac(OscarData *od, const guint16 family, const guint16 type, const guint16 flags, const void *data, const int datalen);
aim_snac_t *aim_remsnac(OscarData *, aim_snacid_t id);
void aim_cleansnacs(OscarData *, int maxage);
int aim_putsnac(ByteStream *, guint16 family, guint16 type, guint16 flags, aim_snacid_t id);

struct chatsnacinfo {
	guint16 exchange;
	char name[128];
	guint16 instance;
};

struct rateclass {
	guint16 classid;
	guint32 windowsize;
	guint32 clear;
	guint32 alert;
	guint32 limit;
	guint32 disconnect;
	guint32 current;
	guint32 max;
	guint8 dropping_snacs;

	struct timeval last; /**< The time when we last sent a SNAC of this rate class. */
};

int aim_cachecookie(OscarData *od, IcbmCookie *cookie);
IcbmCookie *aim_uncachecookie(OscarData *od, guint8 *cookie, int type);
IcbmCookie *aim_mkcookie(guint8 *, int, void *);
IcbmCookie *aim_checkcookie(OscarData *, const unsigned char *, const int);
int aim_freecookie(OscarData *od, IcbmCookie *cookie);
int aim_msgcookie_gettype(guint64 type);
int aim_cookie_free(OscarData *od, IcbmCookie *cookie);

int aim_chat_readroominfo(ByteStream *bs, struct aim_chat_roominfo *outinfo);

void flap_connection_destroy_chat(OscarData *od, FlapConnection *conn);

#ifdef __cplusplus
}
#endif

#endif /* _OSCAR_H_ */
