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

#ifndef MSN_SESSION_H
#define MSN_SESSION_H

typedef struct MsnSession MsnSession;

#include "ab/pecan_contact.h"

struct MsnSwitchBoard;
struct _PurpleAccount;

/**
 * Types of errors.
 */
typedef enum
{
    MSN_ERROR_SERVCONN,
    MSN_ERROR_UNSUPPORTED_PROTOCOL,
    MSN_ERROR_HTTP_MALFORMED,
    MSN_ERROR_AUTH,
    MSN_ERROR_BAD_BLIST,
    MSN_ERROR_SIGN_OTHER,
    MSN_ERROR_SERV_DOWN,
    MSN_ERROR_SERV_UNAVAILABLE
} MsnErrorType;

/**
 * Login steps.
 */
typedef enum
{
    PECAN_LOGIN_STEP_START,
    PECAN_LOGIN_STEP_HANDSHAKE,
    PECAN_LOGIN_STEP_TRANSFER,
    PECAN_LOGIN_STEP_HANDSHAKE2,
    PECAN_LOGIN_STEP_AUTH_START,
    PECAN_LOGIN_STEP_AUTH,
    PECAN_LOGIN_STEP_GET_COOKIE,
    PECAN_LOGIN_STEP_AUTH_END,
    PECAN_LOGIN_STEP_SYN,
    PECAN_LOGIN_STEP_END
} MsnLoginStep;

#define PECAN_LOGIN_STEPS PECAN_LOGIN_STEP_END

#include "switchboard.h"

/**
 * Creates a new MSN session.
 *
 * @param account The account.
 *
 * @return The new MSN session.
 */
MsnSession *
msn_session_new (struct _PurpleAccount *account);

/**
 * Destroys an MSN session.
 *
 * @param session The MSN session.
 */
void
msn_session_destroy (MsnSession *session);

void
msn_session_set_username (MsnSession *session, const gchar *value);
const gchar *
msn_session_get_username (MsnSession *session);
void
msn_session_set_password (MsnSession *session, const gchar *value);
const gchar *
msn_session_get_password (MsnSession *session);

/**
 * Retrieves the session contact.
 *
 * @param The MSN session.
 *
 * @return The contact.
 */
PecanContact *
msn_session_get_contact (MsnSession *session);

/**
 * Gets the session account.
 *
 * @param The MSN session.
 *
 * @return The libpurple account.
 */
struct _PurpleAccount *
msn_session_get_account (MsnSession *session);

/**
 * Connects to and initiates an MSN session.
 *
 * @param session The MSN session.
 * @param host The dispatch server host.
 * @param port The dispatch server port.
 *
 * @return @c TRUE on success, @c FALSE on failure.
 */
gboolean
msn_session_connect (MsnSession *session,
                     const gchar *host,
                     gint port);

/**
 * Disconnects from an MSN session.
 *
 * @param session The MSN session.
 */
void
msn_session_disconnect (MsnSession *session);

 /**
 * Finds a switchboard with the given username.
 *
 * @param session The MSN session.
 * @param username The username to search for.
 *
 * @return The switchboard, if found.
 */
struct MsnSwitchBoard *
msn_session_find_swboard (const MsnSession *session,
                          const gchar *username);

 /**
 * Finds a switchboard with the given conversation.
 *
 * @param session The MSN session.
 * @param conv The conversation to search for.
 *
 * @return The switchboard, if found.
 */
struct MsnSwitchBoard *
msn_session_find_swboard_with_conv (const MsnSession *session,
                                    const struct _PurpleConversation *conv);

/**
 * Finds a switchboard with the given chat ID.
 *
 * @param session The MSN session.
 * @param chat_id The chat ID to search for.
 *
 * @return The switchboard, if found.
 */
struct MsnSwitchBoard *
msn_session_find_swboard_with_id (const MsnSession *session,
                                  gint chat_id);

/**
 * Returns a switchboard to communicate with certain username.
 *
 * @param session The MSN session.
 * @param username The username to search for.
 * @param flag The flag of the switchboard
 *
 * @return The switchboard.
 */
struct MsnSwitchBoard *
msn_session_get_swboard (MsnSession *session,
                         const gchar *username,
                         MsnSBFlag flag);

/**
 * Displays a non fatal error.
 *
 * @param session The MSN session.
 * @param msg The message to display.
 */
void
msn_session_warning (MsnSession *session,
                     const gchar *fmt,
                     ...);

/**
 * Sets an error for the MSN session.
 *
 * @param session The MSN session.
 * @param error The error.
 * @param info Extra information.
 */
void
msn_session_set_error (MsnSession *session,
                       MsnErrorType error,
                       const gchar *info);

/**
 * Sets the current step in the login proccess.
 *
 * @param session The MSN session.
 * @param step The current step.
 */
void
msn_session_set_login_step (MsnSession *session,
                            MsnLoginStep step);

/**
 * Finish the login proccess.
 *
 * @param session The MSN session.
 */
void
msn_session_finish_login (MsnSession *session);

#endif /* MSN_SESSION_H */
