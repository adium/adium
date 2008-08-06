/**
 * @file jutil.h utility functions
 *
 * purple
 *
 * Copyright (C) 2003 Nathan Walp <faceprint@faceprint.com>
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
#ifndef _PURPLE_JABBER_SI_H_
#define _PURPLE_JABBER_SI_H_

#include "ft.h"

#include "jabber.h"

void jabber_bytestreams_parse(JabberStream *js, xmlnode *packet);
void jabber_si_parse(JabberStream *js, xmlnode *packet);
PurpleXfer *jabber_si_new_xfer(PurpleConnection *gc, const char *who);
void jabber_si_xfer_send(PurpleConnection *gc, const char *who, const char *file);

#endif /* _PURPLE_JABBER_SI_H_ */
