#include <stdio.h>

extern int A(void);

int main(int argc, const char * argv[])
{
	puts("-- main() return A()");
	return A();
}