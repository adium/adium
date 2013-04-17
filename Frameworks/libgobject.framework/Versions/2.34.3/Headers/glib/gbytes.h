/*
 * Copyright © 2009, 2010 Codethink Limited
 * Copyright © 2011 Collabora Ltd.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the licence, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Author: Ryan Lortie <desrt@desrt.ca>
 *         Stef Walter <stefw@collabora.co.uk>
 */

#if !defined (__GLIB_H_INSIDE__) && !defined (GLIB_COMPILATION)
#error "Only <glib.h> can be included directly."
#endif

#ifndef __G_BYTES_H__
#define __G_BYTES_H__

#include <glib/gtypes.h>
#include <glib/garray.h>

G_BEGIN_DECLS

GBytes *        g_bytes_new                     (gconstpointer   data,
                                                 gsize           size);

GBytes *        g_bytes_new_take                (gpointer        data,
                                                 gsize           size);

GBytes *        g_bytes_new_static              (gconstpointer   data,
                                                 gsize           size);

GBytes *        g_bytes_new_with_free_func      (gconstpointer   data,
                                                 gsize           size,
                                                 GDestroyNotify  free_func,
                                                 gpointer        user_data);

GBytes *        g_bytes_new_from_bytes          (GBytes         *bytes,
                                                 gsize           offset,
                                                 gsize           length);

gconstpointer   g_bytes_get_data                (GBytes         *bytes,
                                                 gsize          *size);

gsize           g_bytes_get_size                (GBytes         *bytes);

GBytes *        g_bytes_ref                     (GBytes         *bytes);

void            g_bytes_unref                   (GBytes         *bytes);

gpointer        g_bytes_unref_to_data           (GBytes         *bytes,
                                                 gsize          *size);

GByteArray *    g_bytes_unref_to_array          (GBytes         *bytes);

guint           g_bytes_hash                    (gconstpointer   bytes);

gboolean        g_bytes_equal                   (gconstpointer   bytes1,
                                                 gconstpointer   bytes2);

gint            g_bytes_compare                 (gconstpointer   bytes1,
                                                 gconstpointer   bytes2);

G_END_DECLS

#endif /* __G_BYTES_H__ */
