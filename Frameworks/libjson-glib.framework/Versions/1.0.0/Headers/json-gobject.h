/* json-gobject.h - JSON GObject integration
 * 
 * This file is part of JSON-GLib
 * Copyright (C) 2007  OpenedHand Ltd.
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
 * Author:
 *   Emmanuele Bassi  <ebassi@openedhand.com>
 */

#ifndef __JSON_GOBJECT_H__
#define __JSON_GOBJECT_H__

#include <json-glib/json-types.h>
#include <glib-object.h>

G_BEGIN_DECLS

#define JSON_TYPE_SERIALIZABLE                  (json_serializable_get_type ())
#define JSON_SERIALIZABLE(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), JSON_TYPE_SERIALIZABLE, JsonSerializable))
#define JSON_IS_SERIALIZABLE(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), JSON_TYPE_SERIALIZABLE))
#define JSON_SERIALIZABLE_GET_IFACE(obj)        (G_TYPE_INSTANCE_GET_INTERFACE ((obj), JSON_TYPE_SERIALIZABLE, JsonSerializableIface))

typedef struct _JsonSerializable        JsonSerializable; /* dummy */
typedef struct _JsonSerializableIface   JsonSerializableIface;

/**
 * JsonSerializableIface:
 * @serialize_property: virtual function for serializing a #GObject property
 *   into a #JsonNode
 * @deserialize_property: virtual function for deserializing a #JsonNode
 *   into a #GObject property
 *
 * Interface that allows serializing and deserializing #GObject<!-- -->s
 * with properties storing complex data types. The json_serialize_gobject()
 * function will check if the passed #GObject implements this interface,
 * so it can also be used to override the default property serialization
 * sequence.
 */
struct _JsonSerializableIface
{
  /*< private >*/
  GTypeInterface g_iface;

  /*< public >*/
  JsonNode *(* serialize_property)   (JsonSerializable *serializable,
                                      const gchar      *property_name,
                                      const GValue     *value,
                                      GParamSpec       *pspec);
  gboolean  (* deserialize_property) (JsonSerializable *serializable,
                                      const gchar      *property_name,
                                      GValue           *value,
                                      GParamSpec       *pspec,
                                      JsonNode         *property_node);
};

GType     json_serializable_get_type (void) G_GNUC_CONST;

JsonNode *json_serializable_serialize_property   (JsonSerializable *serializable,
                                                  const gchar      *property_name,
                                                  const GValue     *value,
                                                  GParamSpec       *pspec);
gboolean  json_serializable_deserialize_property (JsonSerializable *serializable,
                                                  const gchar      *property_name,
                                                  GValue           *value,
                                                  GParamSpec       *pspec,
                                                  JsonNode         *property_node);


GObject *json_construct_gobject (GType         gtype,
                                 const gchar  *data,
                                 gsize         length,
                                 GError      **error);
gchar *  json_serialize_gobject (GObject      *gobject,
                                 gsize        *length) G_GNUC_MALLOC;

G_END_DECLS

#endif /* __JSON_GOBJECT_H__ */
