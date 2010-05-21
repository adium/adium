#include <stdio.h>

int main(int argc, const char * argv[])
{
	printf("-- main() returns libfoo:foo() --\n");
	
	getNSGetExecutablePath((char *)argv[0]);
	return foo();
}