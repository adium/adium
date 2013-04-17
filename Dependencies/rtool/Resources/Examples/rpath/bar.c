#include <stdio.h>
#include <stdlib.h>

int bar (void)
{
	printf("-- libbar:bar() --\n");
	getNSGetExecutablePath((char *)"barLIb");
	return 0;
}