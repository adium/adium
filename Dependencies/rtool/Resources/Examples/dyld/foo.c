#include <stdio.h>
#include <stdlib.h>

static trace(const char *call)
{
	printf("-- %s --\n", call);
}

int foo (void) {
	
	trace("libfoo");
	
	return 0;
}