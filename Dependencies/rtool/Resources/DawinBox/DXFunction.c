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
 *  DXFunction.c
 *  rtool DarwinBox
 *
 *  Created by plumber on 07/05/26.
 *  Copyright 2007 OpenSpecies. All rights reserved.
 *
 */

#include "DX.h"

/*
* DXGetExecutablePath(void)
*/
char *DXGetExecutablePath(void)
{
	char *P;
	char *x;
	int res;
	uint32_t l;
	
	l = MAXPATHLEN *2;
	DXALLOCATE(x, l);
	res = _NSGetExecutablePath(x, &l);
#if 0
	DXRELEASE(x);
#endif
	P = (char *)dirname((const char *)x);
	
	return P;
}

/*
* private __DXGetAnyString(CFStringRef r, CFStringEncoding E)
* /System/Library/Frameworks/CoreFoundation.framework/Versions/A/Headers/CFStringEncodingExt.h
*/
static char *__DXGetAnyString(CFStringRef r, CFStringEncoding E)
{
	char *P;
	CFIndex l = 0;
	char *S = NULL;
	
	if (NULL != r) {
		l = CFStringGetMaximumSizeForEncoding(CFStringGetLength(r), E) + 1;
		DXALLOCATE(S , l);
		CFStringGetCString(r, S, l, E);
#if 0
		DXRELEASE(S);
#endif
	}
	P = S;
	
	return P;
}

/*
* DXGetString(CFStringRef r)
*/
char *DXGetString(CFStringRef r)
{
	char *P;
	P = __DXGetAnyString(r, kCFStringEncodingUTF8);
	
	return P;
}

/*
* DXGetStringWithEncoding(CFStringRef r, CFStringEncoding E)
*/
char *DXGetStringWithEncoding(CFStringRef r, CFStringEncoding E)
{
	char *P;
	P = __DXGetAnyString(r, E);
	
	return P;
}

/*
* private __DXGetBundlePath(CFStringRef ID)
*/
static char *__DXGetBundlePath(CFStringRef ID)
{
	char *P;
	CFBundleRef b;
	CFURLRef u;
	CFStringRef r = NULL;
	
	if (NULL != ID)
		b = CFBundleGetBundleWithIdentifier(ID);
	else {
		b = CFBundleGetMainBundle();
	}
	if(b) {
		u = CFBundleCopyBundleURL(b);
		r = CFURLCopyFileSystemPath(u, kCFURLPOSIXPathStyle);
		if (u) { CFRelease(u); }
	}
	P = ( NULL != r) ? DXGetString(r) : NULL;
	
	return P;
}

/*
* private __DXGetAnyBundleResourcesPath(CFStringRef ID)
*/
static char *__DXGetAnyBundleResourcesPath(CFStringRef ID)
{
	char *P;
	char *S;
	char x[MAXPATHLEN *2];
	if (NULL != ID) {
		if( NULL != (S = __DXGetBundlePath(ID)) )
			sprintf(x, "%s/%s", S, "Resources");
	} else {
		if( (NULL != (S = __DXGetBundlePath(NULL))) )
			sprintf(x, "%s/%s/%s", S, "Contents", "Resources");
	}
	P = strlen(x) > 0 && S ? strdup(x) : NULL;
	
	return P;
}

/*
* DXGetMainBundlePath(void)
*/
char *DXGetMainBundlePath(void)
{
	char *P;
	P = __DXGetBundlePath(NULL);
	
	return P;
}

/*
* DXGetBundlePathWithIdentifier(const void *SID)
*/
char *DXGetBundlePathWithIdentifier(const void *SID)
{
	char *P;
	P = __DXGetBundlePath(DXCFSTR(SID, kCFStringEncodingASCII));
	
	return P;
}

/*
* DXGetMainBundleResourcesPath(void)
*/
char *DXGetMainBundleResourcesPath(void)
{
	char *P;
	P = __DXGetAnyBundleResourcesPath(NULL);
	
	return P;
}

/*
* DXGetMainBundleResourcesPath(const void *SID)
*/
char *DXGetBundleResourcesPathWithIdentifier(const void *SID)
{
	char *P;
	P = __DXGetAnyBundleResourcesPath(DXCFSTR(SID, kCFStringEncodingASCII));
	
	return P;
}
