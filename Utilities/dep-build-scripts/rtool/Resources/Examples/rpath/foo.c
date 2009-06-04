#include <stdio.h>
#include <stdlib.h>

int foo (void)
{
	printf("-- libfoo:foo() returns libbar:bar() --\n");
	getNSGetExecutablePath((char *)"fooLIb");
	return bar();
}