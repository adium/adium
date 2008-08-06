/*
 * Copyright (c) 2007 plumber <OpenSpecies@gnu-darwin.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/*
 *  DX.h
 *  rtool DarwinBox
 *
 *  Created by plumber on 07/05/26.
 *  Copyright 2007 OpenSpecies. All rights reserved.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/param.h>
#include <mach-o/dyld.h>
#include <stdlib.h>
#include <string.h>

#include <CoreFoundation/CoreFoundation.h>

/* BSD types compatibility */
#ifdef __bsdcomp
typedef unsigned char	u_char;
typedef unsigned short	u_short;
typedef unsigned int	u_int;
typedef unsigned long	u_long;
#endif

/* SYSV / SVR4 types compatibility */
#ifdef __sysvcomp
typedef unsigned char	unchar;
typedef unsigned short	ushort;
typedef unsigned int	uint;
typedef unsigned long	ulong;
#endif

#define DXEXPORT extern

#define DXALLOCATE(P,S)\
({ \
	P = malloc((size_t)S); \
})

#define DXRELEASE(P) \
({ \
	if(P && *P) { free(P); } \
})

#define DXSTREQ(s1,s2) (strcmp((s1),(s2)) == 0)

#define DXSTRCOPY(P,V) \
({ \
	P = strdup(V); \
})

#define DXCFSTR(P,E) \
({ \
	CFStringRef r = NULL; \
	r = CFStringCreateWithCStringNoCopy(NULL, P, E, NULL); \
})

#define DXTOSTRING(X) #X

#define DXDUMP(X,F) \
({ \
	printf("-- DXDUMP { File : %s (%u) %s = " F " } \n", __FILE__, __LINE__, #X, X); \
})

DXEXPORT char *DXGetExecutablePath(void);
DXEXPORT char *DXGetString(CFStringRef r);
DXEXPORT char *DXGetStringWithEncoding(CFStringRef r,CFStringEncoding E);
DXEXPORT char *DXGetMainBundlePath(void);
DXEXPORT char *DXGetBundlePathWithIdentifier(const void *SID);
DXEXPORT char *DXGetMainBundleResourcesPath(void);
DXEXPORT char *DXGetBundleResourcesPathWithIdentifier(const void *SID);

#ifdef __cplusplus
}
#endif