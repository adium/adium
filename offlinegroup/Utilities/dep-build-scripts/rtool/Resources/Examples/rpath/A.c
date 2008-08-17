#include <stdio.h>

extern int B(void);
int A(void);

int A() {
	puts("-- A() return B()");
	return B();
}