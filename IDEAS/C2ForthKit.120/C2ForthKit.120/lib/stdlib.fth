\ stdlib.fth

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

\ ****************************
\ *S STDLIB - Standard Library
\ ****************************

#32 constant #ExitChain			\ -- u
\ *G Maximum number of entries in the exit chain.
#ExitChain cells buffer: ExitChain	\ -- addr
\ *G Buffer for exit chain entries.
0 Value ExitChainIdx			\ -- 0|addr
\ *G Anchor for exit chain.

: _abort        \ --
\ *G Terminate the current program no matter what.
\ *C   void abort( void );
  true abort" Deliberate abnormal termination via ABORT()"
;

: _exit         \ n --
\ *G As with *\b{abort()} except with a return status code and the
\ ** fact that an exit() is not considered abnormal termination.
\ *C   void exit( int status );
  begin
    ExitChainIdx
  while
    ExitChainIdx 1- dup to ExitChainIdx
    cells ExitChain + @ execute
  repeat
  cr ." Program exit with status code " . abort
;

: _atexit       \ xt -- ior
\ *G Specify a function which will be executed when *\b{exit()} occurs.
\ *C   int atexit( void(*func)(void));
  ExitChainIdx #ExitChain = if
    drop -1
  else
    ExitChain ExitChainIdx cells + !
    ExitChainIdx 1+ to ExitChainIdx
    0
  then
;

: _malloc       \ size -- ptr | 0
\ *G Attempt to allocate S bytes of heap and return a pointer.
\ *C   void *malloc( size_t s );
  allocate if drop 0 then
;

: _free         \ ptr --
\ *G Release *\b{malloc()}ed memory.
\ *C   void free( void *ptr );
  ?dup if free drop then
;

: _realloc      \ size ptr -- 'ptr | 0
\ *G Attempt to resize the allocated block P to the new size S.
\ *C   void *realloc( void *p, size_t s );
  ?dup if
    over if
      swap resize if drop 0 then
    else
      nip _free
    then
  else
    drop _malloc
  then
;

: _atoi         \ s -- n
\ *G Convert an ascii string to a decimal number.
\ *C   int atoi( const char *s );
  dup c@ [char] - = if -1 >r 1+ else 0 >r then
  0 >r
  begin
    dup c@
    [char] 0 [char] 9 within?
    if
      dup c@ [char] 0 - r> 10 * + >r
      1+ false
    else
      drop true
    then
  until
  r> r> if negate then
;


\ ======
\ *> ###
\ ======
