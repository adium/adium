#include <stdio.h>
#include <stdlib.h>
#include <sys/param.h>
#include <mach-o/dyld.h>
#include <CoreFoundation/CoreFoundation.h>

int getNSGetExecutablePath(char *pname)
{
	int status = -1;
 	uint32_t pathsize;
	int result;
	char *given_path = malloc(MAXPATHLEN * 2);
	if (!given_path) return status;

	pathsize = MAXPATHLEN * 2;
	result = _NSGetExecutablePath(given_path, &pathsize);
	
	if (result == 0)
	{
		printf("-- getNSGetExecutablePath %s : %s --\n\n",pname,given_path);
		status = 0;
   }
   free (given_path);
   return status;
}