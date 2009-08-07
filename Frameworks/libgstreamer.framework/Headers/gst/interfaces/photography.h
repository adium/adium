/* GStreamer
 *
 * Copyright (C) 2008 Nokia Corporation <multimedia@maemo.org>
 *
 * photography.h: photography interface for digital imaging
 *
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

#ifndef __GST_PHOTOGRAPHY_H__
#define __GST_PHOTOGRAPHY_H__

#ifndef GST_USE_UNSTABLE_API
#warning "The GstPhotography interface is unstable API and may change in future."
#warning "You can define GST_USE_UNSTABLE_API to avoid this warning." 
#endif

#include <gst/gst.h>
#include <gst/interfaces/photography-enumtypes.h>

G_BEGIN_DECLS

#define GST_TYPE_PHOTOGRAPHY \
  (gst_photography_get_type ())
#define GST_PHOTOGRAPHY(obj) \
  (GST_IMPLEMENTS_INTERFACE_CHECK_INSTANCE_CAST ((obj), GST_TYPE_PHOTOGRAPHY, GstPhotography))
#define GST_IS_PHOTOGRAPHY(obj) \
  (GST_IMPLEMENTS_INTERFACE_CHECK_INSTANCE_TYPE ((obj), GST_TYPE_PHOTOGRAPHY))
#define GST_PHOTOGRAPHY_GET_IFACE(inst) \
  (G_TYPE_INSTANCE_GET_INTERFACE ((inst), GST_TYPE_PHOTOGRAPHY, GstPhotographyInterface))


/* Custom GstMessage name that will be sent to GstBus when autofocusing
   is complete */
#define GST_PHOTOGRAPHY_AUTOFOCUS_DONE "autofocus-done"

/* Custom GstMessage name that will be sent to GstBus when shake risk changes */
#define GST_PHOTOGRAPHY_SHAKE_RISK "shake-risk"

/**
 * GstPhotography:
 *
 * Opaque #GstPhotography data structure.
 */
typedef struct _GstPhotography GstPhotography;

typedef enum
{
  GST_PHOTOGRAPHY_WB_MODE_AUTO = 0,
  GST_PHOTOGRAPHY_WB_MODE_DAYLIGHT,
  GST_PHOTOGRAPHY_WB_MODE_CLOUDY,
  GST_PHOTOGRAPHY_WB_MODE_SUNSET,
  GST_PHOTOGRAPHY_WB_MODE_TUNGSTEN,
  GST_PHOTOGRAPHY_WB_MODE_FLUORESCENT
} GstWhiteBalanceMode;

typedef enum
{
  GST_PHOTOGRAPHY_COLOUR_TONE_MODE_NORMAL = 0,
  GST_PHOTOGRAPHY_COLOUR_TONE_MODE_SEPIA,
  GST_PHOTOGRAPHY_COLOUR_TONE_MODE_NEGATIVE,
  GST_PHOTOGRAPHY_COLOUR_TONE_MODE_GRAYSCALE,
  GST_PHOTOGRAPHY_COLOUR_TONE_MODE_NATURAL,
  GST_PHOTOGRAPHY_COLOUR_TONE_MODE_VIVID,
  GST_PHOTOGRAPHY_COLOUR_TONE_MODE_COLORSWAP,
  GST_PHOTOGRAPHY_COLOUR_TONE_MODE_SOLARIZE,
  GST_PHOTOGRAPHY_COLOUR_TONE_MODE_OUT_OF_FOCUS
} GstColourToneMode;

typedef enum
{
  GST_PHOTOGRAPHY_SCENE_MODE_MANUAL = 0,
  GST_PHOTOGRAPHY_SCENE_MODE_CLOSEUP,
  GST_PHOTOGRAPHY_SCENE_MODE_PORTRAIT,
  GST_PHOTOGRAPHY_SCENE_MODE_LANDSCAPE,
  GST_PHOTOGRAPHY_SCENE_MODE_SPORT,
  GST_PHOTOGRAPHY_SCENE_MODE_NIGHT,
  GST_PHOTOGRAPHY_SCENE_MODE_AUTO
} GstSceneMode;

typedef enum
{
  GST_PHOTOGRAPHY_FLASH_MODE_AUTO = 0,
  GST_PHOTOGRAPHY_FLASH_MODE_OFF,
  GST_PHOTOGRAPHY_FLASH_MODE_ON,
  GST_PHOTOGRAPHY_FLASH_MODE_FILL_IN,
  GST_PHOTOGRAPHY_FLASH_MODE_RED_EYE
} GstFlashMode;

typedef enum
{
  GST_PHOTOGRAPHY_FOCUS_STATUS_NONE = 0,
  GST_PHOTOGRAPHY_FOCUS_STATUS_RUNNING,
  GST_PHOTOGRAPHY_FOCUS_STATUS_FAIL,
  GST_PHOTOGRAPHY_FOCUS_STATUS_SUCCESS
} GstFocusStatus;

typedef enum
{
  GST_PHOTOGRAPHY_CAPS_NONE = (0 << 0),
  GST_PHOTOGRAPHY_CAPS_EV_COMP = (1 << 0),
  GST_PHOTOGRAPHY_CAPS_ISO_SPEED = (1 << 1),
  GST_PHOTOGRAPHY_CAPS_WB_MODE = (1 << 2),
  GST_PHOTOGRAPHY_CAPS_TONE = (1 << 3),
  GST_PHOTOGRAPHY_CAPS_SCENE = (1 << 4),
  GST_PHOTOGRAPHY_CAPS_FLASH = (1 << 5),
  GST_PHOTOGRAPHY_CAPS_ZOOM = (1 << 6),
  GST_PHOTOGRAPHY_CAPS_FOCUS = (1 << 7),
  GST_PHOTOGRAPHY_CAPS_APERTURE = (1 << 8),
  GST_PHOTOGRAPHY_CAPS_EXPOSURE = (1 << 9),
  GST_PHOTOGRAPHY_CAPS_SHAKE = (1 << 10)
} GstPhotoCaps;

typedef enum
{
  GST_PHOTOGRAPHY_SHAKE_RISK_LOW = 0,
  GST_PHOTOGRAPHY_SHAKE_RISK_MEDIUM,
  GST_PHOTOGRAPHY_SHAKE_RISK_HIGH,
} GstPhotoShakeRisk;

typedef struct
{
  GstWhiteBalanceMode wb_mode;
  GstColourToneMode tone_mode;
  GstSceneMode scene_mode;
  GstFlashMode flash_mode;
  guint32 exposure;
  guint aperture;
  gfloat ev_compensation;
  guint iso_speed;
  gfloat zoom;
} GstPhotoSettings;

/**
 * GstPhotoCapturePrepared:
 * @data: user data that has been given, when registering the callback
 * @configured_caps: #GstCaps defining the configured capture format.
 *     Ownership of these caps stays in the element.
 *
 * This callback will be called when the element has finished preparations
 * for photo capture.
 */
typedef void (*GstPhotoCapturePrepared) (gpointer data,
    const GstCaps *configured_caps);

/**
 * GstPhotographyInterface:
 * @parent: parent interface type.
 * @get_ev_compensation: vmethod to get ev exposure compensation value
 * @get_iso_speed: vmethod to get iso speed (light sensitivity) value
 * @get_aperture: vmethod to get aperture value
 * @get_exposure: vmethod to get exposure time value
 * @get_white_balance_mode: vmethod to get white balance mode value
 * @get_colour_tone_mode: vmethod to get colour tone mode value
 * @get_scene_mode: vmethod to get scene mode value
 * @get_flash_mode: vmethod to get flash mode value
 * @get_zoom: vmethod to get zoom factor value
 * @set_ev_compensation: vmethod to set ev exposure compensation value
 * @set_iso_speed: vmethod to set iso speed (light sensitivity) value
 * @set_aperture: vmethod to set aperture value
 * @set_exposure: vmethod to set exposure time value
 * @set_white_balance_mode: vmethod to set white balance mode value
 * @set_colour_tone_mode: vmethod to set colour tone mode value
 * @set_scene_mode: vmethod to set scene mode value
 * @set_flash_mode: vmethod to set flash mode value
 * @set_zoom: vmethod to set zoom factor value
 * @get_capabilities: vmethod to get supported capabilities of the interface
 * @prepare_for_capture: vmethod to tell the element to prepare for capturing
 * @set_autofocus: vmethod to set autofocus on/off
 * @set_config: vmethod to set all configuration parameters at once
 * @get_config: vmethod to get all configuration parameters at once
 *
 * #GstPhotographyInterface interface.
 */
typedef struct _GstPhotographyInterface
{
  GTypeInterface parent;

  /* virtual functions */
    gboolean (*get_ev_compensation) (GstPhotography * photo, gfloat * ev_comp);
    gboolean (*get_iso_speed) (GstPhotography * photo, guint * iso_speed);
    gboolean (*get_aperture) (GstPhotography * photo, guint * aperture);
    gboolean (*get_exposure) (GstPhotography * photo, guint32 * exposure);
    gboolean (*get_white_balance_mode) (GstPhotography * photo,
      GstWhiteBalanceMode * wb_mode);
    gboolean (*get_colour_tone_mode) (GstPhotography * photo,
      GstColourToneMode * tone_mode);
    gboolean (*get_scene_mode) (GstPhotography * photo,
      GstSceneMode * scene_mode);
    gboolean (*get_flash_mode) (GstPhotography * photo,
      GstFlashMode * flash_mode);
    gboolean (*get_zoom) (GstPhotography * photo, gfloat * zoom);

    gboolean (*set_ev_compensation) (GstPhotography * photo, gfloat ev_comp);
    gboolean (*set_iso_speed) (GstPhotography * photo, guint iso_speed);
    gboolean (*set_aperture) (GstPhotography * photo, guint aperture);
    gboolean (*set_exposure) (GstPhotography * photo, guint32 exposure);
    gboolean (*set_white_balance_mode) (GstPhotography * photo,
      GstWhiteBalanceMode wb_mode);
    gboolean (*set_colour_tone_mode) (GstPhotography * photo,
      GstColourToneMode tone_mode);
    gboolean (*set_scene_mode) (GstPhotography * photo,
      GstSceneMode scene_mode);
    gboolean (*set_flash_mode) (GstPhotography * photo,
      GstFlashMode flash_mode);
    gboolean (*set_zoom) (GstPhotography * photo, gfloat zoom);

    GstPhotoCaps (*get_capabilities) (GstPhotography * photo);
    gboolean (*prepare_for_capture) (GstPhotography * photo,
      GstPhotoCapturePrepared func, GstCaps *capture_caps, gpointer user_data);
  void (*set_autofocus) (GstPhotography * photo, gboolean on);
    gboolean (*set_config) (GstPhotography * photo, GstPhotoSettings * config);
    gboolean (*get_config) (GstPhotography * photo, GstPhotoSettings * config);

  /*< private > */
  gpointer _gst_reserved[GST_PADDING];
} GstPhotographyInterface;

GType gst_photography_get_type (void);

/* virtual class function wrappers */
gboolean gst_photography_get_ev_compensation (GstPhotography * photo,
    gfloat * ev_comp);
gboolean gst_photography_get_iso_speed (GstPhotography * photo,
    guint * iso_speed);
gboolean gst_photography_get_aperture (GstPhotography * photo,
    guint * aperture);
gboolean gst_photography_get_exposure (GstPhotography * photo,
    guint32 * exposure);
gboolean gst_photography_get_white_balance_mode (GstPhotography * photo,
    GstWhiteBalanceMode * wb_mode);
gboolean gst_photography_get_colour_tone_mode (GstPhotography * photo,
    GstColourToneMode * tone_mode);
gboolean gst_photography_get_scene_mode (GstPhotography * photo,
    GstSceneMode * scene_mode);
gboolean gst_photography_get_flash_mode (GstPhotography * photo,
    GstFlashMode * flash_mode);
gboolean gst_photography_get_zoom (GstPhotography * photo, gfloat * zoom);

gboolean gst_photography_set_ev_compensation (GstPhotography * photo,
    gfloat ev_comp);
gboolean gst_photography_set_iso_speed (GstPhotography * photo,
    guint iso_speed);
gboolean gst_photography_set_aperture (GstPhotography * photo, guint aperture);
gboolean gst_photography_set_exposure (GstPhotography * photo, guint exposure);
gboolean gst_photography_set_white_balance_mode (GstPhotography * photo,
    GstWhiteBalanceMode wb_mode);
gboolean gst_photography_set_colour_tone_mode (GstPhotography * photo,
    GstColourToneMode tone_mode);
gboolean gst_photography_set_scene_mode (GstPhotography * photo,
    GstSceneMode scene_mode);
gboolean gst_photography_set_flash_mode (GstPhotography * photo,
    GstFlashMode flash_mode);
gboolean gst_photography_set_zoom (GstPhotography * photo, gfloat zoom);

GstPhotoCaps gst_photography_get_capabilities (GstPhotography * photo);

gboolean gst_photography_prepare_for_capture (GstPhotography * photo,
    GstPhotoCapturePrepared func, GstCaps *capture_caps, gpointer user_data);

void gst_photography_set_autofocus (GstPhotography * photo, gboolean on);

gboolean gst_photography_set_config (GstPhotography * photo,
    GstPhotoSettings * config);
gboolean gst_photography_get_config (GstPhotography * photo,
    GstPhotoSettings * config);

G_END_DECLS

#endif /* __GST_PHOTOGRAPHY_H__ */
