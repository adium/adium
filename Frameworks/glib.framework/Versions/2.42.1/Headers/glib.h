/* GLIB - Library of useful routines for C programming
 * Copyright (C) 1995-1997  Peter Mattis, Spencer Kimball and Josh MacDonald
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, see <http://www.gnu.org/licenses/>.
 */

/*
 * Modified by the GLib Team and others 1997-2000.  See the AUTHORS
 * file for a list of people on the GLib Team.  See the ChangeLog
 * files for a list of changes.  These files are distributed with
 * GLib at ftp://ftp.gtk.org/pub/gtk/.
 */

#ifndef __G_LIB_H__
#define __G_LIB_H__

#define __GLIB_H_INSIDE__

#include <libgthread/glib/galloca.h>
#include <libgthread/glib/garray.h>
#include <libgthread/glib/gasyncqueue.h>
#include <libgthread/glib/gatomic.h>
#include <libgthread/glib/gbacktrace.h>
#include <libgthread/glib/gbase64.h>
#include <libgthread/glib/gbitlock.h>
#include <libgthread/glib/gbookmarkfile.h>
#include <libgthread/glib/gbytes.h>
#include <libgthread/glib/gcharset.h>
#include <libgthread/glib/gchecksum.h>
#include <libgthread/glib/gconvert.h>
#include <libgthread/glib/gdataset.h>
#include <libgthread/glib/gdate.h>
#include <libgthread/glib/gdatetime.h>
#include <libgthread/glib/gdir.h>
#include <libgthread/glib/genviron.h>
#include <libgthread/glib/gerror.h>
#include <libgthread/glib/gfileutils.h>
#include <libgthread/glib/ggettext.h>
#include <libgthread/glib/ghash.h>
#include <libgthread/glib/ghmac.h>
#include <libgthread/glib/ghook.h>
#include <libgthread/glib/ghostutils.h>
#include <libgthread/glib/giochannel.h>
#include <libgthread/glib/gkeyfile.h>
#include <libgthread/glib/glist.h>
#include <libgthread/glib/gmacros.h>
#include <libgthread/glib/gmain.h>
#include <libgthread/glib/gmappedfile.h>
#include <libgthread/glib/gmarkup.h>
#include <libgthread/glib/gmem.h>
#include <libgthread/glib/gmessages.h>
#include <libgthread/glib/gnode.h>
#include <libgthread/glib/goption.h>
#include <libgthread/glib/gpattern.h>
#include <libgthread/glib/gpoll.h>
#include <libgthread/glib/gprimes.h>
#include <libgthread/glib/gqsort.h>
#include <libgthread/glib/gquark.h>
#include <libgthread/glib/gqueue.h>
#include <libgthread/glib/grand.h>
#include <libgthread/glib/gregex.h>
#include <libgthread/glib/gscanner.h>
#include <libgthread/glib/gsequence.h>
#include <libgthread/glib/gshell.h>
#include <libgthread/glib/gslice.h>
#include <libgthread/glib/gslist.h>
#include <libgthread/glib/gspawn.h>
#include <libgthread/glib/gstrfuncs.h>
#include <libgthread/glib/gstring.h>
#include <libgthread/glib/gstringchunk.h>
#include <libgthread/glib/gtestutils.h>
#include <libgthread/glib/gthread.h>
#include <libgthread/glib/gthreadpool.h>
#include <libgthread/glib/gtimer.h>
#include <libgthread/glib/gtimezone.h>
#include <libgthread/glib/gtrashstack.h>
#include <libgthread/glib/gtree.h>
#include <libgthread/glib/gtypes.h>
#include <libgthread/glib/gunicode.h>
#include <libgthread/glib/gurifuncs.h>
#include <libgthread/glib/gutils.h>
#include <libgthread/glib/gvarianttype.h>
#include <libgthread/glib/gvariant.h>
#include <libgthread/glib/gversion.h>
#include <libgthread/glib/gversionmacros.h>
#ifdef G_PLATFORM_WIN32
#include <libgthread/glib/gwin32.h>
#endif

#ifndef G_DISABLE_DEPRECATED
#include <libgthread/glib/deprecated/gallocator.h>
#include <libgthread/glib/deprecated/gcache.h>
#include <libgthread/glib/deprecated/gcompletion.h>
#include <libgthread/glib/deprecated/gmain.h>
#include <libgthread/glib/deprecated/grel.h>
#include <libgthread/glib/deprecated/gthread.h>
#endif /* G_DISABLE_DEPRECATED */

#undef __GLIB_H_INSIDE__

#endif /* __G_LIB_H__ */
