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

#ifndef PECAN_STATUS_H
#define PECAN_STATUS_H

/**
 * Status types.
 */
typedef enum
{
    PECAN_STATUS_NONE,
    PECAN_STATUS_ONLINE,
    PECAN_STATUS_BUSY,
    PECAN_STATUS_IDLE,
    PECAN_STATUS_BRB,
    PECAN_STATUS_AWAY,
    PECAN_STATUS_PHONE,
    PECAN_STATUS_LUNCH,
    PECAN_STATUS_OFFLINE,
    PECAN_STATUS_HIDDEN

} PecanStatusType;

struct MsnSession;

/**
 * Updates the status of the user.
 *
 * @param session The MSN session.
 */
void pecan_update_status (struct MsnSession *session);

/**
 * Updates the personal message of the user.
 *
 * @param session The MSN session.
 */
void pecan_update_personal_message (struct MsnSession *session);

#endif /* PECAN_STATUS_H */
