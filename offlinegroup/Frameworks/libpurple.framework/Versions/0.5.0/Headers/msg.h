/**
 * @file msg.h Message functions
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
#ifndef _MSN_MSG_H_
#define _MSN_MSG_H_

typedef struct _MsnMessage MsnMessage;

#include "session.h"
#include "user.h"

#include "command.h"
#include "transaction.h"

typedef void (*MsnMsgCb)(MsnMessage *, void *data);

#define MSG_BODY_DEM	"\r\n\r\n"
#define MSG_LINE_DEM	"\r\n"

#define MSG_OIM_BODY_DEM	"\n\n"
#define MSG_OIM_LINE_DEM	"\n"

/*
typedef enum
{
	MSN_MSG_NORMAL,
	MSN_MSG_SLP_SB,
	MSN_MSG_SLP_DC

} MsnMsgType;
*/

typedef enum
{
	MSN_MSG_UNKNOWN,
	MSN_MSG_TEXT,
	MSN_MSG_TYPING,
	MSN_MSG_CAPS,
	MSN_MSG_SLP,
	MSN_MSG_NUDGE

} MsnMsgType;

typedef enum
{
	MSN_MSG_ERROR_NONE, /**< No error. */
	MSN_MSG_ERROR_TIMEOUT, /**< The message timedout. */
	MSN_MSG_ERROR_NAK, /**< The message could not be sent. */
	MSN_MSG_ERROR_SB, /**< The error comes from the switchboard. */
	MSN_MSG_ERROR_UNKNOWN /**< An unknown error occurred. */

} MsnMsgErrorType;

typedef struct
{
	guint32 session_id;
	guint32 id;
	guint64 offset;
	guint64 total_size;
	guint32 length;
	guint32 flags;
	guint32 ack_id;
	guint32 ack_sub_id;
	guint64 ack_size;

} MsnSlpHeader;

typedef struct
{
	guint32 value;

} MsnSlpFooter;

/**
 * A message.
 */
struct _MsnMessage
{
	size_t ref_count;           /**< The reference count.       */

	MsnMsgType type;

	gboolean msnslp_message;

	char *remote_user;
	char flag;

	char *content_type;
	char *charset;
	char *body;
	gsize body_len;

	MsnSlpHeader msnslp_header;
	MsnSlpFooter msnslp_footer;

	GHashTable *attr_table;
	GList *attr_list;

	gboolean ack_ref;           /**< A flag that states if this message has
								  been ref'ed for using it in a callback. */

	MsnCommand *cmd;
	MsnTransaction *trans;

	MsnMsgCb ack_cb; /**< The callback to call when we receive an ACK of this
					   message. */
	MsnMsgCb nak_cb; /**< The callback to call when we receive a NAK of this
					   message. */
	void *ack_data; /**< The data used by callbacks. */

	MsnMsgErrorType error; /**< The error of the message. */
};

/**
 * Creates a new, empty message.
 *
 * @return A new message.
 */
MsnMessage *msn_message_new(MsnMsgType type);

/**
 * Creates a new, empty MSNSLP message.
 *
 * @return A new MSNSLP message.
 */
MsnMessage *msn_message_new_msnslp(void);

/**
 * Creates a new nudge message.
 *
 * @return A new nudge message.
 */
MsnMessage *msn_message_new_nudge(void);

/**
 * Creates a new plain message.
 *
 * @return A new plain message.
 */
MsnMessage *msn_message_new_plain(const char *message);

/**
 * Creates a MSNSLP ack message.
 *
 * @param acked_msg The message to acknowledge.
 *
 * @return A new MSNSLP ack message.
 */
MsnMessage *msn_message_new_msnslp_ack(MsnMessage *acked_msg);

/**
 * Creates a new message based off a command.
 *
 * @param session The MSN session.
 * @param cmd     The command.
 *
 * @return The new message.
 */
MsnMessage *msn_message_new_from_cmd(MsnSession *session, MsnCommand *cmd);

/**
 * Parses the payload of a message.
 *
 * @param msg         The message.
 * @param payload     The payload.
 * @param payload_len The length of the payload.
 */
void msn_message_parse_payload(MsnMessage *msg, const char *payload,
							   size_t payload_len,
						  const char *line_dem,const char *body_dem);

/**
 * Destroys a message.
 *
 * @param msg The message to destroy.
 */
void msn_message_destroy(MsnMessage *msg);

/**
 * Increments the reference count on a message.
 *
 * @param msg The message.
 *
 * @return @a msg
 */
MsnMessage *msn_message_ref(MsnMessage *msg);

/**
 * Decrements the reference count on a message.
 *
 * This will destroy the structure if the count hits 0.
 *
 * @param msg The message.
 *
 * @return @a msg, or @c NULL if the new count is 0.
 */
MsnMessage *msn_message_unref(MsnMessage *msg);

/**
 * Generates the payload data of a message.
 *
 * @param msg      The message.
 * @param ret_size The returned size of the payload.
 *
 * @return The payload data of the message.
 */
char *msn_message_gen_payload(MsnMessage *msg, size_t *ret_size);

/**
 * Sets the flag for an outgoing message.
 *
 * @param msg  The message.
 * @param flag The flag.
 */
void msn_message_set_flag(MsnMessage *msg, char flag);

/**
 * Returns the flag for an outgoing message.
 *
 * @param msg The message.
 *
 * @return The flag.
 */
char msn_message_get_flag(const MsnMessage *msg);

#if 0
/**
 * Sets the body of a message.
 *
 * @param msg  The message.
 * @param body The body of the message.
 */
void msn_message_set_body(MsnMessage *msg, const char *body);

/**
 * Returns the body of the message.
 *
 * @param msg The message.
 *
 * @return The body of the message.
 */
const char *msn_message_get_body(const MsnMessage *msg);
#endif
/**
 * Sets the binary content of the message.
 *
 * @param msg  The message.
 * @param data The binary data.
 * @param len  The length of the data.
 */
void msn_message_set_bin_data(MsnMessage *msg, const void *data, size_t len);

/**
 * Returns the binary content of the message.
 *
 * @param msg The message.
 * @param len The returned length of the data.
 *
 * @return The binary data.
 */
const void *msn_message_get_bin_data(const MsnMessage *msg, size_t *len);

/**
 * Sets the content type in a message.
 *
 * @param msg  The message.
 * @param type The content-type.
 */
void msn_message_set_content_type(MsnMessage *msg, const char *type);

/**
 * Returns the content type in a message.
 *
 * @param msg The message.
 *
 * @return The content-type.
 */
const char *msn_message_get_content_type(const MsnMessage *msg);

/**
 * Sets the charset in a message.
 *
 * @param msg     The message.
 * @param charset The charset.
 */
void msn_message_set_charset(MsnMessage *msg, const char *charset);

/**
 * Returns the charset in a message.
 *
 * @param msg The message.
 *
 * @return The charset.
 */
const char *msn_message_get_charset(const MsnMessage *msg);

/**
 * Sets an attribute in a message.
 *
 * @param msg   The message.
 * @param attr  The attribute name.
 * @param value The attribute value.
 */
void msn_message_set_attr(MsnMessage *msg, const char *attr,
						  const char *value);

/**
 * Returns an attribute from a message.
 *
 * @param msg  The message.
 * @param attr The attribute.
 *
 * @return The value, or @c NULL if not found.
 */
const char *msn_message_get_attr(const MsnMessage *msg, const char *attr);

/**
 * Parses the body and returns it in the form of a hashtable.
 *
 * @param msg The message.
 *
 * @return The resulting hashtable.
 */
GHashTable *msn_message_get_hashtable_from_body(const MsnMessage *msg);

void msn_message_show_readable(MsnMessage *msg, const char *info,
							   gboolean text_body);

void msn_message_parse_slp_body(MsnMessage *msg, const char *body,
								size_t len);

char *msn_message_gen_slp_body(MsnMessage *msg, size_t *ret_size);

char *msn_message_to_string(MsnMessage *msg);

#endif /* _MSN_MSG_H_ */
