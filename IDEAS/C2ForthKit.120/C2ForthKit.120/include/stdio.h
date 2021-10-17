/* TSEPOS 20 1 20 */
#ifndef __STDIO__
#define __STDIO__

#ifndef NULL
  #define NULL (void*)0
#endif

typedef int     FILE;

extern  FILE *stderr;
extern  FILE *stdout;

extern  int     puts( const char *text );
extern  int     sprintf( char *b, const char *fmt, ... );
extern  int     printf( const char *fmt, ... );
extern  int     fprintf( FILE *stream, const char *fmt, ... );
extern  int     getchar( void );
extern  int     putchar( char c );

#endif
