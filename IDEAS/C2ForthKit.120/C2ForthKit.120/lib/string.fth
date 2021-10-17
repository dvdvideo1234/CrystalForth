\ string.fth

((
Copyright (c) 1998, 2003, 2007, 2012
MicroProcessor Engineering
133 Hill Lane
Southampton SO15 5AF
England

tel:   +44 (0)23 8063 1441
fax:   +44 (0)23 8033 9691
email: mpe@mpeforth.com
       tech-support@mpeforth.com
web:   http://www.mpeforth.com
Skype: mpe_sfp

From North America, our telephone and fax numbers are:
       011 44 23 8063 1441
       011 44 23 8033 9691
       901 313 4312 (North American access number to UK office)


To do
=====

Change history
==============
20121220 SFP001 Update for VFX Forth 4.6.
		DocGen overhaul.
))


\ =======
\ *> libc
\ =======

\ *******************************
\ *S STRING - Simple String Tools
\ *******************************
\ *P As with all the other libraries, this one has been stripped.
\ ** Sufficient functionality is provided for most programs and
\ ** those functions missing can be easily written in C using the
\ ** ones supplied.

: _memset       \ size value source -- source
\ *G Set memory (bytes).
\ *C   void *memset( void *, int c, size_t s );
  dup >r
  rot bounds ?do
    dup i c!
  loop
  drop
  r>
;

: _strlen       \ z$ -- len
\ *G Return the length of the supplied string not including the
\ ** zero terminator.
\ *C   size_t strlen( const char *s );
  zcount nip
;

: _strcpy       \ source dest -- dest
\ *G Copy the string S to the char array at D.
\ ** Returns the pointer to the destination.
\ *C   char *strcpy( char *d, const char *s );
  swap zcount 1+        \ dest s-a s-l --
  2 pick swap move
;

: _memcpy       \ len source dest -- dest
\ *G Copy memory.
\ *C void *memcpy( void *d, const void *s, size_t len );
  rot over >r ?dup if move else 2drop then r>
;

: _strtol       \ base **endptr *s -- val
\ *G Attempt to convert the string S to a long integer using
\ ** BASE as the radix. ENDPTR points to a CHAR* pointer which
\ ** will hold the address of the first part of the source string
\ ** which cannot be converted as a numeric digit.
\ *C   long int strtol( const char *s, char **endptr, int base );
  swap abort" Cannot yet handle strtol() with endptr set"
  base @ >r
  swap base !
  zcount evaluate
  r> base !
;

: _memcmp       \ len s1 s2 -- v
\ *G Compare two blocks of memory.
\ *C int memcmp( const void *s1, const void *s2, size_t n );
  rot tuck      \ s1 len s2 len
  compare
;

: _strcat       \ source dest -- dest
\ *G Append string S2 onto the char array at S1.
\ *C   char *strcat( char *s1, const char *s2 );
  dup >r
  zcount +              \ source memdest --
  over zcount nip       \ source memdest source-len --
  1+ move
  r>
;


\ ======
\ *> ###
\ ======
