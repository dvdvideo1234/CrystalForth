/* TSEPOS 22 1 22 */

#ifndef __STDLIB__
#define __STDLIB__

#include <stddef.h>

#ifndef NULL
        #define NULL    (void*)0
#endif

#define EXIT_FAILURE    (~0)
#define EXIT_SUCCESS    (0)

extern void abort( void );
extern void exit( int status );
extern int atexit( void(*func)(void));
extern void *malloc( size_t s );
extern void *realloc( void *p, size_t s );
extern void free( void *ptr );
extern int atoi( const char *s );

#endif
