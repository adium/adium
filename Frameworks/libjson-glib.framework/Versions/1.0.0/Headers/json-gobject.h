/* json-gobject.h - JSON GObject integration
 * 
 * This file is part of JSON-GLib
 * Copyright (C) 2007  OpenedHand Ltd.
 * Copyright (C) 2009  Intel Corp.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *   Emmanuele Bassi  <ebassi@linux.intel.com>
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

JsonNode *json_serializable_serialize_property           (JsonSerializable *serializable,
                                                          const gchar      *property_name,
                                                          const GValue     *value,
                                                          GParamSpec       *pspec);
gboolean  json_serializable_deserialize_property         (JsonSerializable *serializable,
                                                          const gchar      *property_name,
                                                          GValue           *value,
                                                          GParamSpec       *pspec,
                                                          JsonNode         *property_node);

JsonNode *json_serializable_default_serialize_property   (JsonSerializable *serializable,
                                                          const gchar      *property_name,
                                                          const GValue     *value,
                                                          GParamSpec       *pspec);
gboolean  json_serializable_default_deserialize_property (JsonSerializable *serializable,
                                                          const gchar      *property_name,
                                                          GValue           *value,
                                                          GParamSpec       *pspec,
                                                          JsonNode         *property_node);

/**
 * JsonBoxedSerializeFunc:
 * @boxed: a #GBoxed
 *
 * Serializes the passed #GBoxed and stores it inside a #JsonNode
 *
 * Return value: the newly created #JsonNode
 *
 * Since: 0.10
 */
typedef JsonNode *(* JsonBoxedSerializeFunc) (gconstpointer boxed);

/**
 * JsonBoxedDeserializeFunc:
 * @node: a #JsonNode
 *
 * Deserializes the contents of the passed #JsonNode into a #GBoxed
 *
 * Return value: the newly created boxed type
 *
 * Since: 0.10
 */
typedef gpointer (* JsonBoxedDeserializeFunc) (JsonNode *node);

void      json_boxed_register_serialize_func   (GType                    gboxed_type,
                                                JsonNodeType             node_type,
                                                JsonBoxedSerializeFunc   serialize_func);
void      json_boxed_register_deserialize_func (GType                    gboxed_type,
                                                JsonNodeType             node_type,
                                                JsonBoxedDeserializeFunc deserialize_func);
gboolean  json_boxed_can_serialize             (GType                    gboxed_type,
                                                JsonNodeType            *node_type);
gboolean  json_boxed_can_deserialize           (GType                    gboxed_type,
                                                JsonNodeType             node_type);
JsonNode *json_boxed_serialize                 (GType                    gboxed_type,
                                                gconstpointer            boxed);
gpointer  json_boxed_deserialize               (GType                    gboxed_type,
                                                JsonNode                *node);

JsonNode *json_gobject_serialize               (GObject                 *gobject);
GObject * json_gobject_deserialize             (GType                    gtype,
                                                JsonNode                *node);

GObject * json_gobject_from_data               (GType                    gtype,
                                                const gchar             *data,
                                                gssize                   length,
                                                GError                 **error);
gchar *   json_gobject_to_data                 (GObject                 *gobject,
                                                gsize                   *length);

#ifndef JSON_DISABLE_DEPRECATED
GObject * json_construct_gobject               (GType                    gtype,
                                                const gchar             *data,
                                                gsize                    length,
                                                GError                 **error) G_GNUC_DEPRECATED;
gchar *   json_serialize_gobject               (GObject                 *gobject,
                                                gsize                   *length) G_GNUC_MALLOC G_GNUC_DEPRECATED;
#endif /* JSON_DISABLE_DEPRECATED */


G_END_DECLS

#endif /* __JSON_GOBJECT_H__ */
