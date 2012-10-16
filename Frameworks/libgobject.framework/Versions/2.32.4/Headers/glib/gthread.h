/* GLIB - Library of useful routines for C programming
 * Copyright (C) 1995-1997  Peter Mattis, Spencer Kimball and Josh MacDonald
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * licence, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
 * USA.
 */

/*
 * Modified by the GLib Team and others 1997-2000.  See the AUTHORS
 * file for a list of people on the GLib Team.  See the ChangeLog
 * files for a list of changes.  These files are distributed with
 * GLib at ftp://ftp.gtk.org/pub/gtk/.
 */

#if !defined (__GLIB_H_INSIDE__) && !defined (GLIB_COMPILATION)
#error "Only <glib.h> can be included directly."
#endif

#ifndef __G_THREAD_H__
#define __G_THREAD_H__

#include <glib/gatomic.h>
#include <glib/gerror.h>

G_BEGIN_DECLS

#define G_THREAD_ERROR g_thread_error_quark ()
GQuark g_thread_error_quark (void);

typedef enum
{
  G_THREAD_ERROR_AGAIN /* Resource temporarily unavailable */
} GThreadError;

typedef gpointer (*GThreadFunc) (gpointer data);

typedef struct _GThread         GThread;

typedef union  _GMutex          GMutex;
typedef struct _GRecMutex       GRecMutex;
typedef struct _GRWLock         GRWLock;
typedef struct _GCond           GCond;
typedef struct _GPrivate        GPrivate;
typedef struct _GOnce           GOnce;

union _GMutex
{
  /*< private >*/
  gpointer p;
  guint i[2];
};

struct _GRWLock
{
  /*< private >*/
  gpointer p;
  guint i[2];
};

struct _GCond
{
  /*< private >*/
  gpointer p;
  guint i[2];
};

struct _GRecMutex
{
  /*< private >*/
  gpointer p;
  guint i[2];
};

#define G_PRIVATE_INIT(notify) { NULL, (notify), { NULL, NULL } }
struct _GPrivate
{
  /*< private >*/
  gpointer       p;
  GDestroyNotify notify;
  gpointer future[2];
};

typedef enum
{
  G_ONCE_STATUS_NOTCALLED,
  G_ONCE_STATUS_PROGRESS,
  G_ONCE_STATUS_READY
} GOnceStatus;

#define G_ONCE_INIT { G_ONCE_STATUS_NOTCALLED, NULL }
struct _GOnce
{
  volatile GOnceStatus status;
  volatile gpointer retval;
};

#define G_LOCK_NAME(name)             g__ ## name ## _lock
#define G_LOCK_DEFINE_STATIC(name)    static G_LOCK_DEFINE (name)
#define G_LOCK_DEFINE(name)           GMutex G_LOCK_NAME (name)
#define G_LOCK_EXTERN(name)           extern GMutex G_LOCK_NAME (name)

#ifdef G_DEBUG_LOCKS
#  define G_LOCK(name)                G_STMT_START{             \
      g_log (G_LOG_DOMAIN, G_LOG_LEVEL_DEBUG,                   \
             "file %s: line %d (%s): locking: %s ",             \
             __FILE__,        __LINE__, G_STRFUNC,              \
             #name);                                            \
      g_mutex_lock (&G_LOCK_NAME (name));                       \
   }G_STMT_END
#  define G_UNLOCK(name)              G_STMT_START{             \
      g_log (G_LOG_DOMAIN, G_LOG_LEVEL_DEBUG,                   \
             "file %s: line %d (%s): unlocking: %s ",           \
             __FILE__,        __LINE__, G_STRFUNC,              \
             #name);                                            \
     g_mutex_unlock (&G_LOCK_NAME (name));                      \
   }G_STMT_END
#  define G_TRYLOCK(name)                                       \
      (g_log (G_LOG_DOMAIN, G_LOG_LEVEL_DEBUG,                  \
             "file %s: line %d (%s): try locking: %s ",         \
             __FILE__,        __LINE__, G_STRFUNC,              \
             #name), g_mutex_trylock (&G_LOCK_NAME (name)))
#else  /* !G_DEBUG_LOCKS */
#  define G_LOCK(name) g_mutex_lock       (&G_LOCK_NAME (name))
#  define G_UNLOCK(name) g_mutex_unlock   (&G_LOCK_NAME (name))
#  define G_TRYLOCK(name) g_mutex_trylock (&G_LOCK_NAME (name))
#endif /* !G_DEBUG_LOCKS */

GThread *       g_thread_ref                    (GThread        *thread);
void            g_thread_unref                  (GThread        *thread);
GThread *       g_thread_new                    (const gchar    *name,
                                                 GThreadFunc     func,
                                                 gpointer        data);
GThread *       g_thread_try_new                (const gchar    *name,
                                                 GThreadFunc     func,
                                                 gpointer        data,
                                                 GError        **error);
GThread *       g_thread_self                   (void);
void            g_thread_exit                   (gpointer        retval);
gpointer        g_thread_join                   (GThread        *thread);
void            g_thread_yield                  (void);


void            g_mutex_init                    (GMutex         *mutex);
void            g_mutex_clear                   (GMutex         *mutex);
void            g_mutex_lock                    (GMutex         *mutex);
gboolean        g_mutex_trylock                 (GMutex         *mutex);
void            g_mutex_unlock                  (GMutex         *mutex);

void            g_rw_lock_init                  (GRWLock        *rw_lock);
void            g_rw_lock_clear                 (GRWLock        *rw_lock);
void            g_rw_lock_writer_lock           (GRWLock        *rw_lock);
gboolean        g_rw_lock_writer_trylock        (GRWLock        *rw_lock);
void            g_rw_lock_writer_unlock         (GRWLock        *rw_lock);
void            g_rw_lock_reader_lock           (GRWLock        *rw_lock);
gboolean        g_rw_lock_reader_trylock        (GRWLock        *rw_lock);
void            g_rw_lock_reader_unlock         (GRWLock        *rw_lock);

void            g_rec_mutex_init                (GRecMutex      *rec_mutex);
void            g_rec_mutex_clear               (GRecMutex      *rec_mutex);
void            g_rec_mutex_lock                (GRecMutex      *rec_mutex);
gboolean        g_rec_mutex_trylock             (GRecMutex      *rec_mutex);
void            g_rec_mutex_unlock              (GRecMutex      *rec_mutex);

void            g_cond_init                     (GCond          *cond);
void            g_cond_clear                    (GCond          *cond);
void            g_cond_wait                     (GCond          *cond,
                                                 GMutex         *mutex);
void            g_cond_signal                   (GCond          *cond);
void            g_cond_broadcast                (GCond          *cond);
gboolean        g_cond_wait_until               (GCond          *cond,
                                                 GMutex         *mutex,
                                                 gint64          end_time);

gpointer        g_private_get                   (GPrivate       *key);
void            g_private_set                   (GPrivate       *key,
                                                 gpointer        value);
void            g_private_replace               (GPrivate       *key,
                                                 gpointer        value);

gpointer        g_once_impl                     (GOnce          *once,
                                                 GThreadFunc     func,
                                                 gpointer        arg);
gboolean        g_once_init_enter               (volatile void  *location);
void            g_once_init_leave               (volatile void  *location,
                                                 gsize           result);

#ifdef G_ATOMIC_OP_MEMORY_BARRIER_NEEDED
# define g_once(once, func, arg) g_once_impl ((once), (func), (arg))
#else /* !G_ATOMIC_OP_MEMORY_BARRIER_NEEDED*/
# define g_once(once, func, arg) \
  (((once)->status == G_ONCE_STATUS_READY) ? \
   (once)->retval : \
   g_once_impl ((once), (func), (arg)))
#endif /* G_ATOMIC_OP_MEMORY_BARRIER_NEEDED */

#ifdef __GNUC__
# define g_once_init_enter(location) \
  (G_GNUC_EXTENSION ({                                               \
    G_STATIC_ASSERT (sizeof *(location) == sizeof (gpointer));       \
    (void) (0 ? (gpointer) *(location) : 0);                         \
    (!g_atomic_pointer_get (location) &&                             \
     g_once_init_enter (location));                                  \
  }))
# define g_once_init_leave(location, result) \
  (G_GNUC_EXTENSION ({                                               \
    G_STATIC_ASSERT (sizeof *(location) == sizeof (gpointer));       \
    (void) (0 ? *(location) = (result) : 0);                         \
    g_once_init_leave ((location), (gsize) (result));                \
  }))
#else
# define g_once_init_enter(location) \
  (g_once_init_enter((location)))
# define g_once_init_leave(location, result) \
  (g_once_init_leave((location), (gsize) (result)))
#endif

G_END_DECLS

#endif /* __G_THREAD_H__ */
