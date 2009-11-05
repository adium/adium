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
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111-1301  USA
 */

#ifndef PECAN_PRINTF_H
#define PECAN_PRINTF_H

#include <glib.h>

#define PECAN_CUSTOM_PRINTF

#ifdef PECAN_CUSTOM_PRINTF
gchar *pecan_strdup_vprintf (const gchar *format, va_list args);
gchar *pecan_strdup_printf (const gchar *format, ...);
#else
#define pecan_strdup_vprintf g_strdup_vprintf
#define pecan_strdup_printf g_strdup_printf
#endif /* PECAN_CUSTOM_PRINTF */

#endif /* PECAN_PRINTF_H */
