/* TSEPOS 6 1 5 */

#ifndef __STDARG__
#define __STDARG__

struct  va_list
{
        int     depth;          // Original stack depth at VA_START.
        int     pick;           // Points at current parameter.
};

typedef struct va_list va_list;

extern int VM_depth( void );
extern int VM_va_depth( void );
extern int VM_pick( int i );

#define va_start(ap,plist) ( ap.depth = VM_va_depth(), ap.pick = 0 )
#define va_arg(ap,type)    ( (type) VM_pick(VM_depth()-ap.depth+ap.pick++) )
#define va_end(ap)         ( ap.pick = 0 )

#endif

