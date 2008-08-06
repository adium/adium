#include <stdio.h>
#include <stdlib.h>

static trace(const char *call)
{
	printf("-- %s --\n", call);
}

int bar (void) {
	
	trace("libbar");
	
	return 0;
}