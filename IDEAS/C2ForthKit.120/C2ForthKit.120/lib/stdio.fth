\ stdio.fth - some of it

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
20121220 SFP001 Update for VFX Forth 4.6
))


\ =======
\ *> libc
\ =======

\ ****************************
\ *S STDIO - Standard IO Model
\ ****************************
\ *P The standard IO model has been stripped for C2Forth. There is no
\ ** file support, and the STDIO system relates to the debug serial
\ ** port on the target. These functions are for DEBUG only and should
\ ** not be used for runtime code since they affect performance. At
\ ** runtime communication should be between the target and the host
\ ** rather than the debug-console.

0 constant _stdout	\ -- x
\ *G The C *\b{stdout} value. Change as required by your host.
1 constant _stdin	\ -- x
\ *G The C *\b{stdin} value. Change as required by your host.
2 constant _stderr	\ -- x
\ *G The C *\b{stderr} value. Change as required by your host.

: _puts         \ char* -- len
\ *G Write a string of text to the the debug output channel
\ *C   int puts( const char *text );
  ?dup if
    dup >r begin dup c@ while dup c@ emit 1+ repeat r> -
  else
    S" (null)" dup >r type r>
  then
; doNotSin

: _sprintf      \ .... fmt buff -- .... len
\ *G Write a string of text using the printf() syntax to a memory
\ ** array.
\ *C   int sprintf( char *b, const char *fmt, ... );
  { fmt op | curpick olen pad? oplen -- }

  fmt 0= if 0 exit then

  0 -> olen
  0 -> curpick

  begin
    fmt c@
  while
    fmt c@ dup [char] % = if
      drop fmt 1+ -> fmt

      0 -> oplen
      0  -> pad?

      \ now process descriptor [0][n..n][action]

      \ peek next char for '0'
      fmt c@ [char] 0 = if
        fmt 1+ -> fmt
        true -> pad?
      then

      \ now read digits to make oplen
      begin
        fmt c@ [char] 0 [char] 9 within?
      while
        oplen 10 * -> oplen
        fmt c@ [char] 0 - oplen + -> oplen
        fmt 1+ -> fmt
      repeat

      \ and get op type
      fmt c@ upc
      fmt 1+ -> fmt
      case
        [char] % of
                [char] % op c!
                op 1+ -> op
                olen 1+ -> olen
        endof

        [char] S of
                curpick pick zcount
                bounds ?do
                  i c@ op c!
                  op 1+ -> op
                  olen 1+ -> olen
                loop
        endof

        [char] D of

                curpick pick
                dup 0< if [char] - op c! op 1+ -> op olen 1+ -> olen negate then
                s>d
                <#
                pad? oplen 0 <> and if
                  oplen 0 ?do # loop
                else
                  #S
                then
                #> bounds ?do
                  i c@ op c!
                  op 1+ -> op
                  olen 1+ -> olen
                loop

        endof

        [char] X of
                base @ >r hex
                curpick pick s>d
                <#
                pad? oplen 0 <> and if
                  oplen 0 ?do # loop
                else
                  #S
                then
                #> bounds ?do
                  i c@ op c!
                  op 1+ -> op
                  olen 1+ -> olen
                loop
                r> base !
        endof

        drop true abort" unhandled sprintf op type"
      end-case
      curpick 1+ -> curpick

    else
      op c!
      op 1+ -> op
      fmt 1+ -> fmt
      olen 1+ -> olen
    then
  repeat
  0 op c!

  olen
; doNotSin

\ 256 buffer: opline[		\ embedded use

: _printf      \ .... fmt -- .... len
\ *G Write a formated string to the debug console.
\ *C   int printf( const char *fmt, ... );
  { | opline[ 256 ] -- }	\ hosted use
  opline[ 256 erase
  opline[ _sprintf
  opline[ _puts drop
;

: _fprintf      \ ... fmt stream -- ... len
  drop _printf
;

: _getchar      \ -- char
\ *G Wait for and return the next key pressed.
\ *C   int getchar( void );
  key
;

: _putchar      \ char -- char
\ *G Transmit the character.
  dup emit
;

: _sscanf        \ ?????
\ *G Not implemented.
  true abort" sscanf() in STDIO not implemented."
; doNotSin


\ ======
\ *> ###
\ ======
