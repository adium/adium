#ifdef __ppc__
#include "libgadu-ppc.h"
#elif defined(__i386__)
#include "libgadu-i386.h"
#else
#error This isn't a recognized platform.
#endif
