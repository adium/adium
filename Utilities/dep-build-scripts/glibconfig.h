#ifdef __ppc__
#include <glibconfig-ppc.h>
#elif defined(__i386__)
#include <glibconfig-i386.h>
#elif defined(__x86_64__)
#include <glibconfig-x86_64.h>
#else
#error This isn't a recognized platform.
#endif
