/*
 * Copyright (c) 2006 plumber <OpenSpecies@gnu-darwin.org>
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
 *  ShareToResources.c
 *  CF Driver
 *
 *  Created by plumber on 09/09/06.
 *  Copyright 2006 OpenSpecies. All rights reserved.
 *
 */
 
#include <CoreFoundation/CoreFoundation.h>

#define ktheStringIdentifier "com.MyCompany.MyApplication.MyLib"

static char *CFStringToCString(CFStringRef TheCFStr)
{
	CFIndex buffSize;
	char *buff;
	
	if(TheCFStr != NULL)
	{
		buffSize = CFStringGetMaximumSizeForEncoding(
						CFStringGetLength(TheCFStr),kCFStringEncodingUTF8
					) + 1;

		buff = (char*) malloc(buffSize);
		
		if (CFStringGetCString(TheCFStr,buff,buffSize,kCFStringEncodingUTF8))
		{
			return buff;
		}
		
		free(buff);
	}
	
	return NULL;
}

/*
* char *ShareToResources(void);
* if not NULL needs to be dealloced by the user.
*/
char *ShareToResources(void)
{
	CFBundleRef theBundleRef;
	CFURLRef theBundleURL;
	CFStringRef theBundlePath;
	CFStringRef ResourcesPath = NULL;
	
	
	theBundleRef = CFBundleGetBundleWithIdentifier(
						CFSTR(ktheStringIdentifier)
					);
	/* test
	theBundleRef = CFBundleGetMainBundle();
	*/
	
	if (theBundleRef)
	{
		theBundleURL = CFBundleCopyBundleURL(theBundleRef);
		theBundlePath = CFURLCopyFileSystemPath(theBundleURL,kCFURLPOSIXPathStyle);
	
		if (theBundleURL) CFRelease(theBundleURL);
		
		if( (ResourcesPath = CFStringCreateWithFormat(kCFAllocatorDefault,NULL,CFSTR("%@/Resources"),theBundlePath)) )
		{
			return CFStringToCString(ResourcesPath);
		}
	}

	return NULL;
}

/* test
int main(void)
{
	printf("%s",ShareToResources());
	
	return 0;
}
*/