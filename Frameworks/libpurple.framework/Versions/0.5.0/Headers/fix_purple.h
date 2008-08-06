/**
 * Copyright (C) 2007-2008 Felipe Contreras
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
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef FIX_PURPLE_H
#define FIX_PURPLE_H

struct _PurpleConnection;

#include <glib.h>

#if !GLIB_CHECK_VERSION(2,3,1)

#if GLIB_SIZEOF_LONG == 8
#define G_GSIZE_FORMAT "lu"
#else
#define G_GSIZE_FORMAT "u"
#endif

#endif /* !GLIB_CHECK_VERSION(2,3,1) */

void purple_buddy_set_displayname (struct _PurpleConnection *gc, const gchar *who, const gchar *value);
void purple_buddy_set_nickname (struct _PurpleConnection *gc, const gchar *who, const gchar *value);

#endif /* FIX_PURPLE_H */
