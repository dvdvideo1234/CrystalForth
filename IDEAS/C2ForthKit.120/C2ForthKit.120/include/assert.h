/* TSEPOS 7 17 6 */

/* ***************************************************************************

        ASSERT.H     Debug Assertion Diagnostic Code

        (c) 2000 MicroProcessor Engineering Limited
        133 Hill Lane
        Southampton
        SO15 5AF

************************************************************************** */

#ifndef __ASSERT__
#define __ASSERT__

#include <stdlib.h>

extern void __assert( char *, int, char *);

#define assert(e)       ((e) ? (void)0 : __assert(__FILE__,__LINE__,#e))

#endif

