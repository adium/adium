/* GStreamer
 * Copyright (C) <2005,2006> Wim Taymans <wim@fluendo.com>
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
/*
 * Unless otherwise indicated, Source Code is licensed under MIT license.
 * See further explanation attached in License Statement (distributed in the file
 * LICENSE).
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#ifndef __GST_RTSP_TRANSPORT_H__
#define __GST_RTSP_TRANSPORT_H__

#include <gst/rtsp/gstrtspdefs.h>

G_BEGIN_DECLS

/**
 * GstRTSPTransMode:
 * @GST_RTSP_TRANS_UNKNOWN: invalid tansport mode
 * @GST_RTSP_TRANS_RTP: transfer RTP data
 * @GST_RTSP_TRANS_RDT: transfer RDT (RealMedia) data
 *
 * The transfer mode to use.
 */
typedef enum {
  GST_RTSP_TRANS_UNKNOWN =  0,
  GST_RTSP_TRANS_RTP     = (1 << 0),
  GST_RTSP_TRANS_RDT     = (1 << 1)
} GstRTSPTransMode;

/**
 * GstRTSPProfile:
 * @GST_RTSP_PROFILE_UNKNOWN: invalid profile
 * @GST_RTSP_PROFILE_AVP: the Audio/Visual profile
 * @GST_RTSP_PROFILE_SAVP: the secure Audio/Visual profile
 *
 * The transfer profile to use.
 */
typedef enum {
  GST_RTSP_PROFILE_UNKNOWN =  0,
  GST_RTSP_PROFILE_AVP     = (1 << 0),
  GST_RTSP_PROFILE_SAVP    = (1 << 1)
} GstRTSPProfile;

/**
 * GstRTSPLowerTrans:
 * @GST_RTSP_LOWER_TRANS_UNKNOWN: invalid transport flag
 * @GST_RTSP_LOWER_TRANS_UDP: stream data over UDP
 * @GST_RTSP_LOWER_TRANS_UDP_MCAST: stream data over UDP multicast
 * @GST_RTSP_LOWER_TRANS_TCP: stream data over TCP
 * @GST_RTSP_LOWER_TRANS_HTTP: stream data tunneled over HTTP. Since: 0.10.23
 *
 * The different transport methods.
 */
typedef enum {
  GST_RTSP_LOWER_TRANS_UNKNOWN   = 0,
  GST_RTSP_LOWER_TRANS_UDP       = (1 << 0),
  GST_RTSP_LOWER_TRANS_UDP_MCAST = (1 << 1),
  GST_RTSP_LOWER_TRANS_TCP       = (1 << 2),
  GST_RTSP_LOWER_TRANS_HTTP      = (1 << 4)
} GstRTSPLowerTrans;

/**
 * RTSPRange:
 * @min: minimum value of the range
 * @max: maximum value of the range
 *
 * A type to specify a range.
 */
typedef struct
{
  gint min;
  gint max;
} GstRTSPRange;

/**
 * GstRTSPTransport:
 *
 * A structure holding the RTSP transport values.
 */
typedef struct _GstRTSPTransport {
  GstRTSPTransMode  trans;
  GstRTSPProfile    profile;
  GstRTSPLowerTrans lower_transport;

  gchar         *destination;
  gchar         *source;
  guint          layers;
  gboolean       mode_play;
  gboolean       mode_record;
  gboolean       append;
  GstRTSPRange   interleaved;

  /* multicast specific */
  guint  ttl;

  /* UDP specific */
  GstRTSPRange   port;
  GstRTSPRange   client_port;
  GstRTSPRange   server_port;
  /* RTP specific */
  guint          ssrc;

} GstRTSPTransport;

GstRTSPResult      gst_rtsp_transport_new          (GstRTSPTransport **transport);
GstRTSPResult      gst_rtsp_transport_init         (GstRTSPTransport *transport);

GstRTSPResult      gst_rtsp_transport_parse        (const gchar *str, GstRTSPTransport *transport);
gchar*             gst_rtsp_transport_as_text      (GstRTSPTransport *transport);

GstRTSPResult      gst_rtsp_transport_get_mime     (GstRTSPTransMode trans, const gchar **mime);
GstRTSPResult      gst_rtsp_transport_get_manager  (GstRTSPTransMode trans, const gchar **manager, guint option);

GstRTSPResult      gst_rtsp_transport_free         (GstRTSPTransport *transport);

G_END_DECLS

#endif /* __GST_RTSP_TRANSPORT_H__ */
