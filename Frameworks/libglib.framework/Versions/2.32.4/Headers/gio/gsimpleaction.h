/*
 * Copyright © 2010 Codethink Limited
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; either version 2 of the licence or (at
 * your option) any later version.
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
 * Authors: Ryan Lortie <desrt@desrt.ca>
 */

#if !defined (__GIO_GIO_H_INSIDE__) && !defined (GIO_COMPILATION)
#error "Only <gio/gio.h> can be included directly."
#endif

#ifndef __G_SIMPLE_ACTION_H__
#define __G_SIMPLE_ACTION_H__

#include <gio/giotypes.h>

G_BEGIN_DECLS

#define G_TYPE_SIMPLE_ACTION                                (g_simple_action_get_type ())
#define G_SIMPLE_ACTION(inst)                               (G_TYPE_CHECK_INSTANCE_CAST ((inst),                     \
                                                             G_TYPE_SIMPLE_ACTION, GSimpleAction))
#define G_IS_SIMPLE_ACTION(inst)                            (G_TYPE_CHECK_INSTANCE_TYPE ((inst),                     \
                                                             G_TYPE_SIMPLE_ACTION))

GType                   g_simple_action_get_type                        (void) G_GNUC_CONST;

GSimpleAction *         g_simple_action_new                             (const gchar        *name,
                                                                         const GVariantType *parameter_type);

GSimpleAction *         g_simple_action_new_stateful                    (const gchar        *name,
                                                                         const GVariantType *parameter_type,
                                                                         GVariant           *state);

void                    g_simple_action_set_enabled                     (GSimpleAction      *simple,
                                                                         gboolean            enabled);

void                    g_simple_action_set_state                       (GSimpleAction      *simple,
                                                                         GVariant           *value);

G_END_DECLS

#endif /* __G_SIMPLE_ACTION_H__ */
