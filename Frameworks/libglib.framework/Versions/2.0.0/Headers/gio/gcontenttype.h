/* GIO - GLib Input, Output and Streaming Library
 * 
 * Copyright (C) 2006-2007 Red Hat, Inc.
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
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Author: Alexander Larsson <alexl@redhat.com>
 */

#if !defined (__GIO_GIO_H_INSIDE__) && !defined (GIO_COMPILATION)
#error "Only <gio/gio.h> can be included directly."
#endif

#ifndef __G_CONTENT_TYPE_H__
#define __G_CONTENT_TYPE_H__

#include <glib.h>
#include <gio/gicon.h>

G_BEGIN_DECLS

gboolean g_content_type_equals            (const char   *type1,
					   const char   *type2);
gboolean g_content_type_is_a              (const char   *type,
					   const char   *supertype);
gboolean g_content_type_is_unknown        (const char   *type);
char *   g_content_type_get_description   (const char   *type);
char *   g_content_type_get_mime_type     (const char   *type);
GIcon *  g_content_type_get_icon          (const char   *type);
gboolean g_content_type_can_be_executable (const char   *type);

char *   g_content_type_guess             (const char   *filename,
					   const guchar *data,
					   gsize         data_size,
					   gboolean     *result_uncertain );

GList *  g_content_types_get_registered   (void);

G_END_DECLS

#endif /* __G_CONTENT_TYPE_H__ */
