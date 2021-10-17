/* TSEPOS 13 14 13 */
#ifndef __STRING__
#define __STRING__

#include <stddef.h>

extern void *memset( void *, int c, size_t s );
extern size_t strlen( const char *s );
extern char *strcpy( char *d, const char *s );
extern void *memcpy( void *d, const void *s, size_t len );
extern long int strtol( const char *s, char **endptr, int base );
extern int memcmp( const void *s1, const void *s2, size_t n );
extern char *strcat( char *s1, const char *s2 );
#endif
