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

#ifndef PECAN_LOG_H
#define PECAN_LOG_H

#include <glib.h>
#include "msn.h"

#define PECAN_DEBUG

#if defined(PECAN_DEBUG)

/* #define PECAN_DEBUG_MSG */
/* #define PECAN_DEBUG_SLPMSG */
/* #define PECAN_DEBUG_HTTP */

/* #define PECAN_DEBUG_SLP_VERBOSE */
/* #define PECAN_DEBUG_SLP_FILES  */

/* #define PECAN_DEBUG_NS */
/* #define PECAN_DEBUG_SB */
/* #define PECAN_DEBUG_DC */

/* #define PECAN_DEBUG_DC_FILES */

enum PecanLogLevel
{
    PECAN_LOG_LEVEL_NONE,
    PECAN_LOG_LEVEL_ERROR,
    PECAN_LOG_LEVEL_WARNING,
    PECAN_LOG_LEVEL_INFO,
    PECAN_LOG_LEVEL_DEBUG,
    PECAN_LOG_LEVEL_LOG
};

typedef enum PecanLogLevel PecanLogLevel;

void msn_base_log_helper (PecanLogLevel level, const gchar *file, const gchar *function, gint line, const gchar *fmt, ...);
void msn_dump_file (const gchar *buffer, gsize len);

#define pecan_print(...) g_print (__VA_ARGS__);

#define msn_base_log(level, ...) msn_base_log_helper (level, __FILE__, __func__, __LINE__, __VA_ARGS__);

#define pecan_error(...) msn_base_log (PECAN_LOG_LEVEL_ERROR, __VA_ARGS__);
#define pecan_warning(...) msn_base_log (PECAN_LOG_LEVEL_WARNING, __VA_ARGS__);
#define pecan_info(...) msn_base_log (PECAN_LOG_LEVEL_INFO, __VA_ARGS__);
#define pecan_debug(...) msn_base_log (PECAN_LOG_LEVEL_DEBUG, __VA_ARGS__);
#define pecan_log(...) msn_base_log (PECAN_LOG_LEVEL_LOG, __VA_ARGS__);

#elif !defined(PECAN_DEBUG)

#define pecan_print(...) {}
#define pecan_error(...) {}
#define pecan_warning(...) {}
#define pecan_info(...) {}
#define pecan_debug(...) {}
#define pecan_log(...) {}
#define msn_dump_file(...) {}

#endif /* !defined(PECAN_DEBUG) */

#endif /* PECAN_LOG_H */
