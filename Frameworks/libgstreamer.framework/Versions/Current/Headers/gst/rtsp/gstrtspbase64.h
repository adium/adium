/* GStreamer
 * Copyright (C) <2007> Mike Smith <msmith@xiph.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#ifndef __BASE64_H__
#define __BASE64_H__

#include <glib.h>

G_BEGIN_DECLS

#ifndef GST_DISABLE_DEPRECATED
gchar *gst_rtsp_base64_encode    (const gchar *data, gsize len);
#endif

void   gst_rtsp_base64_decode_ip (gchar *data, gsize *len);

G_END_DECLS

#endif
