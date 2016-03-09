/* Local libgadu configuration file. */

#undef printf

/* libpurple's config */
#include <config.h>

#define GG_LIBGADU_VERSION "1.12.0-rc2"

/* Defined if libgadu was compiled for bigendian machine. */
#undef GG_CONFIG_BIGENDIAN
#ifdef WORDS_BIGENDIAN
#  define GG_CONFIG_BIGENDIAN
#endif

/* Defined if this machine has gethostbyname_r(). */
#undef GG_CONFIG_HAVE_GETHOSTBYNAME_R

/* Define to 1 if you have the `_exit' function. */
#define HAVE__EXIT 1

/* Defined if libgadu was compiled and linked with fork support. */
#undef GG_CONFIG_HAVE_FORK
#ifndef _WIN32
#  define GG_CONFIG_HAVE_FORK
#endif

/* Defined if libgadu was compiled and linked with pthread support. */
/* We don't use pthreads - they may not be safe. */
#undef GG_CONFIG_HAVE_PTHREAD

/* Defined if this machine has C99-compiliant vsnprintf(). */
#undef HAVE_C99_VSNPRINTF
#ifndef _WIN32
#  define HAVE_C99_VSNPRINTF
#endif

/* Defined if this machine has va_copy(). */
#define GG_CONFIG_HAVE_VA_COPY

/* Defined if this machine has __va_copy(). */
#define GG_CONFIG_HAVE___VA_COPY

/* Defined if this machine supports long long. */
#undef GG_CONFIG_HAVE_LONG_LONG
#ifdef HAVE_LONG_LONG
#  define GG_CONFIG_HAVE_LONG_LONG
#endif

/* Defined if libgadu was compiled and linked with GnuTLS support. */
#undef GG_CONFIG_HAVE_GNUTLS
#ifdef HAVE_GNUTLS
#  define GG_CONFIG_HAVE_GNUTLS
#endif

/* Defined if libgadu was compiled and linked with OpenSSL support. */
/* OpenSSL cannot be used with libpurple due to licence type. */
#undef GG_CONFIG_HAVE_OPENSSL

/* Defined if libgadu was compiled and linked with zlib support. */
#define GG_CONFIG_HAVE_ZLIB

/* Defined if uintX_t types are defined in <stdint.h>. */
#undef GG_CONFIG_HAVE_STDINT_H
#ifdef HAVE_STDINT_H
#  define GG_CONFIG_HAVE_STDINT_H
#endif

/* Defined if uintX_t types are defined in <inttypes.h>. */
#undef GG_CONFIG_HAVE_INTTYPES_H
#ifdef HAVE_INTTYPES_H
#  define GG_CONFIG_HAVE_INTTYPES_H
#endif

/* Defined if uintX_t types are defined in <sys/types.h>. */
#undef GG_CONFIG_HAVE_SYS_TYPES_H
#ifdef HAVE_SYS_TYPES_H
#  define GG_CONFIG_HAVE_SYS_TYPES_H
#endif

/* Defined if this machine has uint64_t. */
#define GG_CONFIG_HAVE_UINT64_T

/* Defined if libgadu is GPL compliant (was not linked with OpenSSL or any
 * other non-GPL compliant library support). */
#define GG_CONFIG_IS_GPL_COMPLIANT

/* Defined if libgadu uses system defalt trusted CAs. */
#define GG_CONFIG_SSL_SYSTEM_TRUST
