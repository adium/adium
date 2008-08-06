/**
 * @file transaction.h MSN transaction functions
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
#ifndef _MSN_TRANSACTION_H
#define _MSN_TRANSACTION_H

typedef struct _MsnTransaction MsnTransaction;

#include "command.h"
#include "cmdproc.h"

typedef void (*MsnTransCb)(MsnCmdProc *cmdproc, MsnCommand *cmd);
typedef void (*MsnTimeoutCb)(MsnCmdProc *cmdproc, MsnTransaction *trans);
typedef void (*MsnErrorCb)(MsnCmdProc *cmdproc, MsnTransaction *trans,
						   int error);

/**
 * A transaction. A sending command that will initiate the transaction.
 */
struct _MsnTransaction
{
	MsnCmdProc *cmdproc;
	unsigned int trId;

	char *command;
	char *params;

	int timer;

	void *data; /**< The data to be used on the different callbacks. */
	GHashTable *callbacks;
	gboolean has_custom_callbacks;
	MsnErrorCb error_cb;
	MsnTimeoutCb timeout_cb;

	char *payload;
	size_t payload_len;

	GQueue *queue;
	MsnCommand *pendent_cmd; /**< The command that is waiting for the result of
							   this transaction. */
};

MsnTransaction *msn_transaction_new(MsnCmdProc *cmdproc,
									const char *command,
									const char *format, ...);
void msn_transaction_destroy(MsnTransaction *trans);

char *msn_transaction_to_string(MsnTransaction *trans);
void msn_transaction_queue_cmd(MsnTransaction *trans, MsnCommand *cmd);
void msn_transaction_unqueue_cmd(MsnTransaction *trans, MsnCmdProc *cmdproc);
void msn_transaction_set_payload(MsnTransaction *trans,
								 const char *payload, int payload_len);
void msn_transaction_set_data(MsnTransaction *trans, void *data);
void msn_transaction_add_cb(MsnTransaction *trans, char *answer,
							MsnTransCb cb);
void msn_transaction_set_error_cb(MsnTransaction *trans, MsnErrorCb cb);
void msn_transaction_set_timeout_cb(MsnTransaction *trans, MsnTimeoutCb cb);

#endif /* _MSN_TRANSACTION_H */
