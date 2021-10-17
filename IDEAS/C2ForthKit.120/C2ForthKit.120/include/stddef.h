/* TSEPOS 8 7 8 */

#ifndef __STDDEF__
#define __STDDEF__

#ifndef NULL
        #define NULL            (void*)0
#endif

typedef int             ptrdiff_t;
typedef unsigned int    size_t;
typedef int             wchar_t;

#define	offsetof(type, member)	((size_t)(&((type *)0)->member))

#endif
