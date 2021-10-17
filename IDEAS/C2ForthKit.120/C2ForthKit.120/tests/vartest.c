
/* ===========================================================================

        File:           VARTEST.C

        Test:           Variadic functions

        Author:         SJC 00/01/06

        Results:        This program should tell you the result is 15.

=========================================================================== */

#include <stdio.h>
#include <stdarg.h>

int     add( int n, ... )
{
        int     i,j;
        va_list ap;

        va_start(ap,n);

        for     ( i=0,j=0 ; i<n ; i++ )
                j += va_arg(ap,int);

        va_end(ap);

        return j;
}


static  int tot;

void    main(           void )
{
        tot = add(5,1,2,3,4,5);
        printf("Total is %d\n",tot);
}

