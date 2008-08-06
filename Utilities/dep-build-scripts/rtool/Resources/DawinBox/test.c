#include <stdio.h>
#include <strings.h>

#include "DX.h"
/* #include "DXMacros.h" */

#define kCFMyIdentifier "com.apple.CoreFoundation"
#define kAKMyIdentifier "com.apple.System"

#include <sys/cdefs.h>

char *__DXSTRCAT(char *__restrict x,const char * __restrict y) 
{
	char *P = x;
	for (; *x; ++x);
	while ((*x++ = *y++) != 0);
	return P;
}
/*
* int main(int argc, const char * argv[])
*/
int main(int argc, const char * argv[])
{
	printf("-- DXGetBundlePathWithIdentifier: %s \n", 
						DXGetBundlePathWithIdentifier(kCFMyIdentifier));
	printf("-- DXGetBundlePathWithIdentifier: %s \n", 
						DXGetBundlePathWithIdentifier("com.apple.AppKit"));
	printf("-- DXGetBundleResourcesPathWithIdentifier: %s \n", 
						DXGetBundleResourcesPathWithIdentifier(kAKMyIdentifier));
	printf("-- DXGetBundleResourcesPathWithIdentifier: %s \n", 
						DXGetBundleResourcesPathWithIdentifier("com.apple.CoreFoundation"));
	printf("-- DXGetMainBundleResourcesPath: %s \n", 
						DXGetMainBundleResourcesPath());
	printf("-- DXGetExecutablePath: %s \n", 
						DXGetExecutablePath());
	printf("-- DXGetMainBundlePath: %s \n", 
						DXGetMainBundlePath());
	
	int foo ;
	
	DXDUMP((int)foo,"%i");
	
	DXDUMP(DXGetBundlePathWithIdentifier(kCFMyIdentifier),"%s");
	
	int * bar;
	
	DXALLOCATE(bar,100);
	
	DXDUMP((long *)bar,"%d");
	
	DXRELEASE(bar);
	
	char y[255];
	char *x = "is not bad";
	strcpy (y,"this ");
	__DXSTRCAT(y,x);
	
	puts(y);
	
	return 0;
}